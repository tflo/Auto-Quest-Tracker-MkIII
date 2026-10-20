-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Portions: Copyright (c) 2022-2026 Thomas Floeren for the added/changed code of "Mk III" (aka version 2 and later)

local MYNAME, A = ...
local CLR = A.CLR

--[[===========================================================================
	Handle modifier keys while tracking/untracking a quest
===========================================================================]]--

local function TrackQuest_modifiers_handler(quest_id)
	-- Never track quest: Cmd-Option
	-- Currently Mac only, due to the lack of enough modifier keys on Windows
	if IsMetaKeyDown() and IsAltKeyDown() then
		A.add_to_exceptions(quest_id, A.EXCEPTION_TYPES.never.value)
	-- Ignore quest: Option (Mac), Ctrl-Alt (Win)
	elseif A.IS_MAC and IsAltKeyDown() or IsAltKeyDown() and IsControlKeyDown() then
		A.add_to_exceptions(quest_id, A.EXCEPTION_TYPES.ignore.value)
	-- Always track quest: Cmd (Mac), Alt (Win)
	elseif IsMetaKeyDown() or IsAltKeyDown() then
		A.add_to_exceptions(quest_id, A.EXCEPTION_TYPES.always.value)
	-- Remove quest from exceptions: Ctrl (Mac/Win)
	elseif IsControlKeyDown() then
		A.add_to_exceptions(quest_id, A.EXCEPTION_TYPES.remove.value)
	end
end

-- Check the modifiers when a quest is added or removed to/from the tracker.
-- `QuestMapQuestOptions_TrackQuest` is called when
	-- Shift-clicking a quest in the quest log;
	-- Clicking the quest checkbox in the quest log.
-- Note that this is quest log only, not in the tracker.

-- Variant 1 (like before TWW, but only in QuestMapFrame):
-- Good: Well tested pre-TWW; only one hook
-- Bad: Works only in QuestMapFrame
-- Current (11.0.0) function: https://www.townlong-yak.com/framexml/live/Blizzard_UIPanels_Game/QuestMapFrame.lua#1370
---[[
hooksecurefunc('QuestMapQuestOptions_TrackQuest', TrackQuest_modifiers_handler)
--]]

-- Variant 2 (experimental):
-- Good: Works also in tracker
-- Bad: Two hooks; not thoroughly tested; quirks with other addons?
-- Good/Bad: Quest watch limit is significant: `AddQuestWatch` is not called if over limit
-- IF HOOKING THESE FUNCTIONS, MAKE SURE THAT AQT ITSELF USES *ONLY* THE PREVIOUSLY "LOCALIZED" VERSIONS OF THESE
-- FUNCTIONS. OTHERWISE WE HAVE AN INFINITE LOOP.
--[[
hooksecurefunc(C_QuestLog, 'AddQuestWatch', TrackQuest_modifiers_handler)
hooksecurefunc(C_QuestLog, 'RemoveQuestWatch', TrackQuest_modifiers_handler)
--]]
-- Alternatively, to hooking the "watch" functions, we could listen to the QUEST_WATCH_LIST_CHANGED event.
-- We need a throttle then to avoid loops.

-- Currently preferred: Variant 1
-- This is also the only safe variant, since a modifier key may also be down while the game (not the user)
-- tracks or untracks a quest.

--[[===========================================================================
	Exclusions
===========================================================================]]--

-- Centralized confirmation messages
local CONFIRM_MSGS = {
	[true] = { -- is now
		['always'] = '%s%s is now set to Always Tracked.',
		['never'] = '%s%s is now set to Never Tracked.',
		['ignore'] = '%s%s is now set to Ignored.',
		['remove'] = '%s%s has been removed from exceptions.',
	},
	[false] = { -- is already
		['always'] = '%s%s is already set to Always Tracked.',
		['never'] = '%s%s is already set to Never Tracked.',
		['ignore'] = '%s%s is already set to Ignored.',
		['remove'] = '%s%s does not have any exception assigned.',
	}
}

function A.add_to_exceptions(scope, exc_key, target, target_text)
	A.dprint(1, '‹add_to_exceptions› called.')

	local exc_type = A.EXCEPTION_TYPES[exc_key]
	if not exc_type then
		error(format("AQT: Invalid exception key '%s' passed to add_to_exceptions.", tostring(exc_key)), 2)
	end

	local name_str = target_text or '<no name>'

	local db_target, target_name
	if scope == 'quest' then
		db_target = A.gdb.exceptions_id
		target_name = format('Quest %s "%s"', target, name_str)
	elseif scope == 'header' then
		db_target = A.gdb.exceptions_header
		target_name = format('Header "%s"', target)
	elseif scope == 'type' then
		db_target = A.gdb.exceptions_type
		target_name = format('Quest Type %s "%s"', target, name_str)
	elseif scope == 'class' then
		db_target = A.gdb.exceptions_class
		target_name = format('Quest Class %s "%s"', target, name_str)
	elseif scope == 'tag' then
		db_target = A.gdb.exceptions_tag
		target_name = format('Quest Tag %s "%s"', target, name_str)
	elseif scope == 'frequency' then
		db_target = A.gdb.exceptions_frequency
		target_name = format('Quest Frequency %s "%s"', target, name_str)
	else
		error(format('AQT: Invalid scope "%s" passed to add_to_exceptions.', tostring(scope)), 2)
	end

	local is_new = false
	local current_val = db_target[target]
	local new_val = exc_type.value

	if exc_key == 'remove' then
		if current_val ~= nil then
			db_target[target] = nil
			is_new = true
		end
	else
		if current_val ~= new_val then
			db_target[target] = new_val
			is_new = true
		end
	end

	-- Inlined confirmation message
	local msg_template = CONFIRM_MSGS[is_new][exc_key]
	print(format(msg_template, A.MSG_PRE, target_name))

	if scope == 'quest' and A.cdb.enabled then
		if exc_key == 'never' then
			C_QuestLog.RemoveQuestWatch(target)
		elseif exc_key == 'always' then
			C_QuestLog.AddQuestWatch(target)
			-- Distinguishing the QWTs is pointless since 11.0;
			-- But leave it in for the moment, maybe they'll restore the pre-11.0 quest handling
		elseif exc_key == 'remove' and C_QuestLog.GetQuestWatchType(target) == A.QWT_MANUAL then
			C_QuestLog.AddQuestWatch(target)
			A.update_quests_for_zone()
		end
	else
		A.update_quests_for_zone()
	end
end

--[[===========================================================================
	Console UI
===========================================================================]]--

local BLOCK_SEP = strrep('+', 42)

local function text_activation_status()
	return A.cdb.enabled and CLR.GOOD('Enabled') or A.cdb.enable_nextsession and CLR.HALFBAD('Disabled for this session') or A.cdb.enable_nextinstance and CLR.HALFBAD('Disabled for this instance') or CLR.BAD('Disabled')
end

function A.msg_load(msg,delay)
	if A.gdb.loadMsg then C_Timer.After(delay, function() print(A.MSG_PREFIX .. msg) end) end
end

function A.msg_confirm(msg)
	print(A.MSG_PRE .. msg)
end

local function msg_status()
	print(A.MSG_PREFIX
		.. 'Status: '
		.. text_activation_status() .. '\124r.'
		.. (A.gdb.ignoreInstances and ' Ignoring instance quests.' or '')
		.. '\nType ' .. CLR.AQT('/aqt h') .. ' for a list of commands.')
end

local function msg_invalid_input()
	print(A.MSG_PREFIX
	.. CLR.BAD('This was not a valid input.') .. ' Check for typos and missing spaces, or type '
	.. CLR.AQT('/aqt h') .. ' for help.')
end

-- I'm curious if Blizzard still uses QWT 0 somewhere outside WQs
local function QWT0_alert(qid, qtitle, watchtype)
	if not A.user_is_author then return end
	if watchtype and watchtype ~=1 then
		print(A.MSG_PREFIX, 'QWT Zero:', qid, qtitle)
		PlaySoundFile(2013855)
	end
end

-- https://warcraft.wiki.gg/wiki/API:C_QuestLog.GetInfo
local function get_questinfo_for_listing(qidx, verbose)
	local info = C_QuestLog.GetInfo(qidx)
	if info then
		info.isWQ = C_QuestLog.IsWorldQuest(info.questID)
		info.isCalling = C_QuestLog.IsQuestCalling(info.questID)
		info.type = C_QuestLog.GetQuestType(info.questID) or (C_QuestLog.GetQuestTagInfo(info.questID) or {}).tagID
		info.typeName = verbose and (C_QuestLog.GetQuestTagInfo(info.questID) or {}).tagName
		info.classificationName = verbose and tInvert(Enum.QuestClassification)[info.questClassification]
		info.watchType = C_QuestLog.GetQuestWatchType(info.questID)
		info.isImportant = C_QuestLog.IsImportantQuest(info.questID)
		-- As of Oct 16, 2026, only in Forever
		info.isElite = C_QuestLog.IsEliteQuest and C_QuestLog.IsEliteQuest(info.questID)
		info.accountQuest = C_QuestLog.IsAccountQuest(info.questID)
		info.isComplete = C_QuestLog.IsComplete(info.questID)
		info.isQuestReplayable = C_QuestLog.IsQuestReplayable(info.questID)
		info.isQuestReplayedRecently = C_QuestLog.IsQuestReplayedRecently(info.questID)
		info.isRepeatableQuest = C_QuestLog.IsRepeatableQuest(info.questID)
		info.isQuestTrivial = C_QuestLog.IsQuestTrivial(info.questID)
		info.readyForTurnIn = C_QuestLog.ReadyForTurnIn(info.questID)
		QWT0_alert(info.questID, info.title, info.watchType)
	end
	return info
	-- info.keys of C_QuestLog.GetInfo:
	-- title, questLogIndex, questID, campaignID, level, difficultyLevel, suggestedGroup, frequency, isHeader, useMinimalHeader, sortAsNormalQuest, isCollapsed, startEvent, isTask, isBounty, isStory, isScaling, isOnMap, hasLocalPOI, isHidden, isAutoComplete, overridesSortOrder, readyForTranslation, isInternalOnly, isAbandonOnDisable, headerSortKey, questClassification
end

local function msg_list_quests(verbose, showhidden)
	print(BLOCK_SEP)
	print(A.MSG_PREFIX, 'Quests in quest log:')
	if not showhidden then print 'Use "/aqt qh" to also show hidden quests.' end
	print '[L=level, T=type, C=classification, W=watched]'
	print ' '

	local tmp, filter = {}, {}
	for qidx = 1, C_QuestLog.GetNumQuestLogEntries() do
		if showhidden then
			tinsert(filter, qidx)
		else
			local info = C_QuestLog.GetInfo(qidx)
			-- Headers never have isHidden; so we have to check if the header has no visible content.
			if not info.isHidden then tinsert(tmp, { qidx = qidx, isheader = info.isHeader }) end
		end
	end
	for i, quest in ipairs(tmp) do
		if not quest.isheader or not tmp[i+1].isheader then
			tinsert(filter, quest.qidx)
		end
	end

	for _, qidx in ipairs(filter) do
		local info = get_questinfo_for_listing(qidx, verbose)
		if info.isHeader then
			print(format('%02d | [Header] %s', qidx, info.title))
		else
			print(
				format(
					'%s%02d | %s%s (%s) | %s',
					info.isHidden and '\124cff838996'
						or info.isWorldQuest and '\124cffF4A460'
						or info.isCalling and '\124cff736AFF'
						or info.watchType and '\124cff57E964'
						or '\124cff12E193',
					qidx,
					info.isHidden and '[Hidden] ' or info.isWQ and '[WQ] ' or info.isCalling and '[Calling] ' or '',
					info.title,
					info.questID,
					(info.level and 'L' .. info.level or 'L?')
					.. (info.type ~= 0 and ', T' .. info.type or '')
					.. (info.typeName and ' ' .. info.typeName or '')
					.. (info.questClassification and ', C' .. info.questClassification or '')
					.. (info.classificationName and ' ' .. info.classificationName or '')
					.. (info.isOnMap and ', OnMap' or '')
					.. (info.hasLocalPOI and ', LocalPOI' or '')
					.. (info.frequency ~= 0 and ', ' .. (tInvert(Enum.QuestFrequency)[info.frequency]) or '')
					.. (info.watchType and ', W' or '')
					.. (info.isTask and ', Task' or '')
					.. (info.isBounty and ', Bounty' or '')
					.. (info.isStory and ', Story' or '')
					.. (info.isImportant and ', Imp!' or '')
					.. (info.isElite and ', Elite' or '')
					.. (info.startEvent and ', StartEvent' or '')
					.. (info.isQuestReplayable and ', Replayable' or '')
					.. (info.isQuestReplayedRecently and ', ReplayedRecently' or '')
					.. (info.isRepeatableQuest and ', Repeatable' or '')
					.. (info.isQuestTrivial and ', Trivial' or '')
					.. (info.isComplete and ', Compl' or '')
					.. (info.readyForTurnIn and ', Ready' or '')
					.. (info.accountQuest and ', Acc' or '')
				)
			)
		end
	end
	print(BLOCK_SEP)
end

-- For quests that are not in the log, the title may not be available on the first run;
-- So, the user has to run it twice, unless we do a C_QuestLog.RequestLoadQuestByID(questID) before.
local function msg_list_exceptions()
	print(BLOCK_SEP)
	if A.table_is_empty(A.gdb.exceptions_id) then
		print(A.MSG_PREFIX .. 'You have no exceptions per quest ' .. CLR.AQT('ID') .. '.')
	else
		print(A.MSG_PREFIX .. 'Active exceptions per quest ' .. CLR.AQT('ID') .. ':')
		for id, ex in A.ordered_pairs(A.gdb.exceptions_id) do
			-- C_QuestLog.RequestLoadQuestByID(id) -- TODO: test
			local title = C_QuestLog.GetTitleForQuestID(id) or '[Quest title not (yet) available from server]'
			local xfull = ''
			for _, v in pairs(A.EXCEPTION_TYPES) do
				if v['value'] == ex then xfull = v['full'] break end
			end
			print(title .. ' (' .. id .. '): ' .. xfull)
		end
	end
	if A.table_is_empty(A.gdb.exceptions_type) then
		print(A.MSG_PREFIX .. 'You have no exceptions per quest ' .. CLR.AQT('TYPE') .. '.')
	else
		print(A.MSG_PREFIX .. 'Active exceptions per quest ' .. CLR.AQT('TYPE') .. ':')
		for ty, ex in A.ordered_pairs(A.gdb.exceptions_type) do
			local xfull = ''
			for _, v in pairs(A.EXCEPTION_TYPES) do
				if v['value'] == ex then xfull = v['full'] break end
			end
			local tyfull = ''
			for _, v in pairs(A.QUEST_TYPES) do
				if v['type'] == ty then tyfull = v['full'] break end
			end
			print(ty .. ' (' .. tyfull .. '): ' .. xfull)
		end
	end
	if A.table_is_empty(A.gdb.exceptions_header) then
		print(A.MSG_PREFIX .. 'You have no exceptions per quest ' .. CLR.AQT('HEADER') .. '.')
	else
		print(A.MSG_PREFIX .. 'Active exceptions per quest ' .. CLR.AQT('HEADER') .. ':')
		for he, ex in A.ordered_pairs(A.gdb.exceptions_header) do
			local xfull = ''
			for _, v in pairs(A.EXCEPTION_TYPES) do
				if v['value'] == ex then xfull = v['full'] break end
			end
			print('"' .. he .. '": ' .. xfull)
		end
	end
	print(BLOCK_SEP)
end

-- TODO: Add version info to help
local function msg_help()
	local lines = {
		BLOCK_SEP,
		CLR.AQT('Auto Quest Tracker') .. ' Help:',
		CLR.AQT('/autoquesttracker') .. ' or ' .. CLR.AQT('/aqt') .. ' understands these commands: ',
		CLR.AQT('on') .. ' or ' .. CLR.AQT('e') .. ': Enable AQT.',
		CLR.AQT('off') .. ' or ' .. CLR.AQT('d') .. ': Disable AQT for the current session.',
		CLR.AQT('offi') .. ' or ' .. CLR.AQT('di') .. ': Disable AQT for the current (map) instance.',
		CLR.AQT('offp') .. ' or ' .. CLR.AQT(dp) .. ': Disable AQT permanently.',
		CLR.AQT('instances') .. ' or ' .. CLR.AQT('in') .. ': Toggle auto-tracking of dungeon/raid quests.',
		CLR.AQT('loadingmessage') .. ': Toggle status message in chat after reload/login.',
		CLR.AQT('quests') .. ' or ' .. CLR.AQT('q') .. ': Show complete quest list.',
		CLR.AQT('debug') .. ': Toggle debug mode.',
		CLR.AQT('help') .. ' or ' .. CLR.AQT('h') .. ': Display this help text.',
		CLR.AQT('/aqt') .. ' without additional commands: Display status info.',
		'- Enable/disable is per char, other settings are global.',
		'- Some commands are also available via the ' .. CLR.AQT('addon compartment button') .. '. See the addon compartment button tooltip.',
		'- To learn how to assign ' .. CLR.AQT('exceptions') .. ' (special behavior) to quests or quest groups, please see the AQT Wiki at...',
		CLR.AQT('https://github.com/tflo/Auto-Quest-Tracker-MkIII/wiki/Exceptions'),
		BLOCK_SEP,
	}
	for _, l in ipairs(lines) do print(l) end
end

--[[---------------------------------------------------------------------------
	Main switch
---------------------------------------------------------------------------]]--

local function aqt_enable(on, disablemode)
	if disablemode and not A.is_integer_in_range(disablemode, 0, 2) then
		error('Arg2 (disablemode) must be nil|0|1|2', 1)
	end
	A.ef:UnregisterAllEvents()
	A.cdb.enable_nextsession, A.cdb.enable_nextinstance = nil, nil
	if on then
		-- Serves as force update if already enabled
		A.update_quests_for_zone()
		A.ef:register_zone_events()
	else
		-- Only an explicit `0` disables permanently
		if not disablemode or disablemode == 1 then
			A.cdb.enable_nextsession = true
			A.ef:RegisterEvent 'PLAYER_LOGOUT'
		elseif disablemode == 2 then
			A.cdb.enable_nextinstance = true
			A.ef:RegisterEvent 'PLAYER_ENTERING_WORLD'
		end
	end
	A.cdb.enabled = on
	A.msg_confirm(text_activation_status() .. '.')
end

--[[---------------------------------------------------------------------------
	Slash commands
---------------------------------------------------------------------------]]--

SLASH_AUTOQUESTTRACKER1 = '/autoquesttracker'
SLASH_AUTOQUESTTRACKER2 = '/aqt'
SlashCmdList['AUTOQUESTTRACKER'] = function(msg)
	local mt = {}
	for v in msg:gmatch '[^ ]+' do
		tinsert(mt, v)
	end
	-- No command, no args
	if #mt == 0 then
		msg_status()
	-- Command without args
	elseif #mt == 1 then
		-- GENERIC STUFF
		if msg == 'e' or msg == 'on' then
			aqt_enable(true)
		-- Disable for current session (default disable)
		elseif msg == 'd' or msg == 'off' then
			aqt_enable(false, nil)
		-- Permanently disable
		elseif msg == 'dp' or msg == 'offp' then
			aqt_enable(false, 0)
		-- Disable for current instance
		elseif msg == 'di' or msg == 'offi' then
			aqt_enable(false, 2)
		elseif msg == 'loadingmessage' then
			A.gdb.loadMsg = not A.gdb.loadMsg
			A.msg_confirm(
				'Loading message '
					.. (A.gdb.loadMsg and 'enabled' or 'disabled')
					.. ' for all chars.'
			)
		elseif msg == 'in' or msg == 'instances' then
			A.gdb.ignoreInstances = not A.gdb.ignoreInstances
			if A.cdb.enabled then A.update_quests_for_zone() end
			A.msg_confirm(
				'Instance quests are '
					.. (A.gdb.ignoreInstances and 'ignored' or 'treated normally')
					.. ' for all chars.'
			)
		elseif msg == 'debug' or msg == 'dm' then
			A.gdb.debug_mode = not A.gdb.debug_mode
			A.msg_confirm(
				'Debug mode'
					.. ' ('
					.. A.gdb.debug_level
					.. ') '
					.. (A.gdb.debug_mode and 'enabled' or 'disabled')
			)
		elseif msg == 'printvalues' and A.gdb.debug_mode then
			A.print_values()
		elseif msg == 'ignoreqwt' and A.gdb.debug_mode then
			A.IGNORE_QWT = not A.IGNORE_QWT
			if A.cdb.enabled then A.update_quests_for_zone() end
			A.msg_confirm(
				A.IGNORE_QWT
						and "Quests can now be removed regardless of their QuestWatchType. This screws up AQT's behavior, use only for debugging! This setting will not be saved across reloads."
					or '"IGNORE_QWT" disabled (normal behavior).'
			)
		-- PRINT LISTS
		elseif msg == 'q' or msg == 'quests' then
			msg_list_quests(true, false)
		elseif msg == 'qh' or msg == 'questshidden' then
			msg_list_quests(true, true)
		elseif msg == 'qc' or msg == 'questscompact' then
			msg_list_quests(false, false)
		elseif msg == 'x' or msg == 'exceptions' then
			msg_list_exceptions()
		-- CLEAR EXCEPTION TABLES: IDs, Types, Headers, All
		-- TODO: These need mention in the Help text
		elseif msg == 'xcleari' or msg == 'exceptionsclearid' then
			wipe(A.gdb.exceptions_id)
			if A.cdb.enabled then A.update_quests_for_zone() end
			A.msg_confirm('All exceptions per quest ID cleared.')
		elseif msg == 'xcleart' or msg == 'exceptionscleartype' then
			wipe(A.gdb.exceptions_type)
			if A.cdb.enabled then A.update_quests_for_zone() end
			A.msg_confirm('All exceptions per quest type cleared.')
		elseif msg == 'xclearh' or msg == 'exceptionsclearheader' then
			wipe(A.gdb.exceptions_header)
			if A.cdb.enabled then A.update_quests_for_zone() end
			A.msg_confirm('All exceptions per quest header cleared.')
		elseif msg == 'xclearall' or msg == 'exceptionsclearall' then
			wipe(A.gdb.exceptions_id)
			wipe(A.gdb.exceptions_type)
			wipe(A.gdb.exceptions_header)
			if A.cdb.enabled then A.update_quests_for_zone() end
			A.msg_confirm('All quest exceptions (ID & type & header) cleared.')
		elseif msg == 'notme' or msg == 'itsme' then -- Debug
			A.user_is_author = not A.user_is_author
			A.msg_confirm(user_is_author and CLR.ON("It's me.") or CLR.OFF("It's not me!"))
		elseif msg == 'h' or msg == 'help' then
			msg_help()
		else
			msg_invalid_input()
		end
	-- 1 cmd, 1 arg: Types & groups exceptions: /aqt <exception cmd> <type | group>
	elseif #mt == 2 then
		if A.EXCEPTION_TYPES[mt[1]] then
			if A.QUEST_TYPES[mt[2]] then
				A.gdb.exceptions_type[A.QUEST_TYPES[mt[2]]['type']] =
					A.EXCEPTION_TYPES[mt[1]]['value']
				A.msg_confirm(
					'Quest type "'
						.. A.QUEST_TYPES[mt[2]]['type']
						.. '" ('
						.. A.QUEST_TYPES[mt[2]]['full']
						.. ') is now '
						.. A.EXCEPTION_TYPES[mt[1]]['full']
						.. '.'
				)
				if A.cdb.enabled then A.update_quests_for_zone() end
			elseif A.QUEST_GROUPS[mt[2]] then
				for _, id in ipairs(A.QUEST_GROUPS[mt[2]]['ids']) do
					A.gdb.exceptions_id[id] = A.EXCEPTION_TYPES[mt[1]]['value']
				end
				A.msg_confirm(
					'Quest group "'
						.. A.QUEST_GROUPS[mt[2]]['full']
						.. '" ('
						.. #A.QUEST_GROUPS[mt[2]]['ids']
						.. ' quest IDs) is now '
						.. A.EXCEPTION_TYPES[mt[1]]['full']
						.. '.'
				)
				if A.cdb.enabled then A.update_quests_for_zone() end
			elseif (mt[1] == 'debug' or mt[1] == 'dm') and tonumber(mt[2]) then
				A.gdb.debug_level = max(min(floor(mt[2]), 3), 0)
				A.msg_confirm('Debug level ' .. A.gdb.debug_level)
			else
				msg_invalid_input()
			end
		else
			msg_invalid_input()
		end
	-- 1 cmd, 2+ args: Header exceptions: /aqt <exception cmd> h <quest header string>
	elseif mt[2] == 'h' and A.EXCEPTION_TYPES[mt[1]] then
		local header = A.get_questheader_from_input(mt)
		A.add_to_exceptions('header', mt[1], header, header)
	else
		msg_invalid_input()
	end
end

--[[===========================================================================
	External API
===========================================================================]]--

function _G.addon_aqt_enable(on, disablemode)
	if type(on) ~= 'boolean' then
		error('Usage: addon_aqt_enable(enable: bool[, disableMode: int])', 0)
	else
		aqt_enable(on, disablemode)
	end
end

function _G.addon_aqt_status()
	return A.cdb.enabled, A.cdb.enable_nextsession, A.cdb.enable_nextinstance
end

--[[---------------------------------------------------------------------------
	Addon Compartment (Blizz)
---------------------------------------------------------------------------]]--

local TEXT_CMD_KEY = A.IS_MAC and 'Command' or 'Control'

function _G.addon_aqt_on_addoncompartment_click(_, btn)
	if btn == 'LeftButton' then
		if A.IS_MAC and IsMetaKeyDown() or not A.IS_MAC and IsControlKeyDown() then
			msg_help()
		else
			msg_status()
		end
	elseif btn == 'RightButton' then
		aqt_enable(not AQT_CharDB.enabled)
	end
end
function _G.addon_aqt_on_addoncompartment_enter()
	GameTooltip:SetOwner(AddonCompartmentFrame)
	GameTooltip:AddDoubleLine('Auto Quest Tracker', text_activation_status())
	GameTooltip:AddLine(CLR.TT(CLR.CLICK('Left-click') .. ' to print the ' .. CLR.ACTION('status') .. '.'))
	GameTooltip:AddLine(CLR.TT(CLR.CLICK(TEXT_CMD_KEY .. '-left-click') .. ' to print the ' .. CLR.ACTION('help') .. ' text.'))
	GameTooltip:AddLine(CLR.TT(CLR.CLICK('Right-click') .. ' to ' .. CLR.ACTION('toggle') .. ' AQT for this session.'))
	GameTooltip:Show()
end

function _G.addon_aqt_on_addoncompartment_leave()
	GameTooltip:Hide()
end
