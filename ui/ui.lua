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
		A.add_quest_to_exceptions(quest_id, A.EXCEPTION_TYPES.never.value)
	-- Ignore quest: Option (Mac), Ctrl-Alt (Win)
	elseif A.IS_MAC and IsAltKeyDown() or IsAltKeyDown() and IsControlKeyDown() then
		A.add_quest_to_exceptions(quest_id, A.EXCEPTION_TYPES.ignore.value)
	-- Always track quest: Cmd (Mac), Alt (Win)
	elseif IsMetaKeyDown() or IsAltKeyDown() then
		A.add_quest_to_exceptions(quest_id, A.EXCEPTION_TYPES.always.value)
	-- Remove quest from exceptions: Ctrl (Mac/Win)
	elseif IsControlKeyDown() then
		A.add_quest_to_exceptions(quest_id, A.EXCEPTION_TYPES.remove.value)
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

local function get_questinfo_for_listing(index)
	local quest = C_QuestLog.GetInfo(index)
	if quest then return
		quest.title,
		quest.isHeader,
		quest.questID,
		C_QuestLog.IsWorldQuest(quest.questID),
		quest.isHidden,
		C_QuestLog.IsQuestCalling(quest.questID),
		C_QuestLog.GetQuestType(quest.questID),
		quest.isOnMap,
		quest.hasLocalPOI,
		C_QuestLog.GetQuestWatchType(quest.questID),
		quest.frequency,
		quest.level,
		quest.isTask,
		quest.isBounty,
		quest.isStory,
		quest.startEvent,
		C_QuestLog.IsImportantQuest(quest.questID),
		C_QuestLog.IsAccountQuest(quest.questID),
		C_QuestLog.IsComplete(quest.questID),
		C_QuestLog.IsQuestReplayable(quest.questID),
		C_QuestLog.IsQuestReplayedRecently(quest.questID),
		C_QuestLog.IsRepeatableQuest(quest.questID),
		C_QuestLog.IsQuestTrivial(quest.questID),
		C_QuestLog.ReadyForTurnIn(quest.questID)
	end
end

local function msg_list_quests()
	print(BLOCK_SEP)
	print(A.MSG_PREFIX, 'Quests currently in quest log:\n[T = type; W = watch type]')
	for questIndex = 1, C_QuestLog.GetNumQuestLogEntries() do
		local questTitle, isHeader, questId, isWorldQuest, isHidden, isCalling, questType, isOnMap, hasLocalPOI, watchType, frequency, level, isTask, isBounty, isStory, startEvent, isImportant, accountQuest, isComplete, isQuestReplayable, isQuestReplayedRecently, isRepeatableQuest, isQuestTrivial, readyForTurnIn =
			get_questinfo_for_listing(questIndex)
		if isHeader then
			print(format('%02d | [Header] %s', questIndex, questTitle))
		else
			print(
				format(
					'%s%02d | %s%s (%s) | %s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s',
					isHidden and '\124cnGRAY_FONT_COLOR:'
						or isWorldQuest and '\124cnBLUE_FONT_COLOR:'
						or isCalling and '\124cnDIM_GREEN_FONT_COLOR:'
						or '\124cnORANGE_FONT_COLOR:',
					questIndex,
					isHidden and '[Hidden] ' or isWorldQuest and '[WQ] ' or isCalling and '[Calling] ' or '',
					questTitle,
					questId,
					level,
					questType ~= 0 and ', T' .. questType or '',
					isOnMap and ', OnMap' or '',
					hasLocalPOI and ', LocalPOI' or '',
					frequency ~= 0 and ', ' .. (frequency == A.QUESTFREQUENCY_DAILY and 'Daily' or 'Weekly') or '',
					watchType and ', W' .. watchType or '',
					isTask and ', Task' or '',
					isBounty and ', Bounty' or '',
					isStory and ', Story' or '',
					startEvent and ', StartEvent' or '',
					isImportant and ', Imp!' or '',
					isQuestReplayable and ', Replayable' or '',
					isQuestReplayedRecently and ', ReplayedRecently' or '',
					isRepeatableQuest and ', Repeatable' or '',
					isQuestTrivial and ', Trivial' or '',
					isComplete and ', Compl' or '',
					readyForTurnIn and ', Ready' or '',
					accountQuest and ', Acc' or ''
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
			A.msg_confirm('Loading message ' .. (A.gdb.loadMsg and 'enabled' or 'disabled') .. ' for all chars.')
		elseif msg == 'in' or msg == 'instances' then
			A.gdb.ignoreInstances = not A.gdb.ignoreInstances
			if A.cdb.enabled then A.update_quests_for_zone() end
			A.msg_confirm('Instance quests are ' ..
			(A.gdb.ignoreInstances and 'ignored' or 'treated normally') .. ' for all chars.')
		elseif msg == 'debug' or msg == 'dm' then
			A.gdb.debug_mode = not A.gdb.debug_mode
			A.msg_confirm('Debug mode' .. ' (' .. A.gdb.debug_level .. ') ' .. (A.gdb.debug_mode and 'enabled.' or 'disabled.'))
		elseif msg == 'printvalues' and A.gdb.debug_mode then
			A.print_values()
		elseif msg == 'ignoreqwt' and A.gdb.debug_mode then
			A.IGNORE_QWT = not A.IGNORE_QWT
			if A.cdb.enabled then A.update_quests_for_zone() end
			A.msg_confirm(A.IGNORE_QWT and 'Quests can now be removed regardless of their QuestWatchType. This screws up AQT\'s behavior, use only for debugging! This setting will not be saved across reloads.' or '"IGNORE_QWT" disabled (normal behavior).')
		-- PRINT LISTS
		elseif msg == 'q' or msg == 'quests' then
			msg_list_quests()
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
				A.gdb.exceptions_type[A.QUEST_TYPES[mt[2]]['type']] = A.EXCEPTION_TYPES[mt[1]]['value']
				A.msg_confirm('Quest type "' ..
					A.QUEST_TYPES[mt[2]]['type'] ..
					'" (' .. A.QUEST_TYPES[mt[2]]['full'] .. ') is now ' .. A.EXCEPTION_TYPES[mt[1]]['full'] .. '.')
				if A.cdb.enabled then A.update_quests_for_zone() end
			elseif A.QUEST_GROUPS[mt[2]] then
				for _, id in ipairs(A.QUEST_GROUPS[mt[2]]['ids']) do
					A.gdb.exceptions_id[id] = A.EXCEPTION_TYPES[mt[1]]['value']
				end
				A.msg_confirm('Quest group "' ..
					A.QUEST_GROUPS[mt[2]]['full'] ..
					'" (' ..
					#A.QUEST_GROUPS[mt[2]]['ids'] .. ' quest IDs) is now ' .. A.EXCEPTION_TYPES[mt[1]]['full'] .. '.')
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
		A.gdb.exceptions_header[header] = A.EXCEPTION_TYPES[mt[1]]['value']
		A.msg_confirm('All quests with header "' .. header .. '" are now ' .. A.EXCEPTION_TYPES[mt[1]]['full'] .. '.')
		if A.cdb.enabled then A.update_quests_for_zone() end
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
