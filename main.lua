local addon_name, a = ...

AQT_GlobalDB = AQT_GlobalDB or {}
AQT_CharDB = AQT_CharDB or {}

local _
local C_TimerAfter = _G.C_Timer.After
local InCombatLockdown, GetRealZoneText, GetMinimapZoneText = _G.InCombatLockdown, _G.GetRealZoneText, _G.GetMinimapZoneText
local C_QuestLogGetInfo, C_QuestLogIsWorldQuest, C_QuestLogGetQuestType, C_QuestLogAddQuestWatch, C_QuestLogRemoveQuestWatch, C_QuestLogGetNumQuestLogEntries, C_QuestLogGetQuestWatchType, C_QuestLogGetTitleForQuestID, C_QuestLogIsQuestCalling =
	_G.C_QuestLog.GetInfo,
	_G.C_QuestLog.IsWorldQuest,
	_G.C_QuestLog.GetQuestType,
	_G.C_QuestLog.AddQuestWatch,
	_G.C_QuestLog.RemoveQuestWatch,
	_G.C_QuestLog.GetNumQuestLogEntries,
	_G.C_QuestLog.GetQuestWatchType,
	_G.C_QuestLog.GetTitleForQuestID,
	_G.C_QuestLog.IsQuestCalling
local EnumQuestWatchType = _G.Enum.QuestWatchType
local EnumQuestFrequency = _G.Enum.QuestFrequency

local debug_mode = false
local update_pending -- Serves as ignore flag during the DELAY_ZONE_CHANGE time
-- Colors for msgs
local C_AQT = '\124cff2196f3'
local C_GOOD = '\124cnDIM_GREEN_FONT_COLOR:'
local C_HALFBAD = '\124cnORANGE_FONT_COLOR:'
local C_BAD = '\124cnDIM_RED_FONT_COLOR:'
local MSG_PREFIX = C_AQT .. 'Auto Quest Tracker\124r: '
-- For addon compartment tooltip
local C_TT = '\124cnWHITE_FONT_COLOR:' -- Base color for tooltip non-header text
local C_CLICK = '\124cnORANGE_FONT_COLOR:'
local C_ACTION = '\124cnYELLOW_FONT_COLOR:'

-- § Quest types
local TYPE_DUNG = 81
local TYPE_RAID = 62
local TYPE_PROF = 267
local TYPE_PET = 102
local TYPE_PVP = 255 -- TODO: verify if this covers most of PvP or just some

local quest_types = {
	['dung'] = {
		['full'] = 'Dungeon Quests',
		['type'] = TYPE_DUNG
	},
	['raid'] = {
		['full'] = 'Raid Quests',
		['type'] = TYPE_RAID
	},
	['prof'] = {
		['full'] = 'Profession Quests',
		['type'] = TYPE_PROF
	},
	['pet'] = {
		['full'] = 'Battle Pet Quests',
		['type'] = TYPE_PET
	},
	['pvp'] = {
		['full'] = 'PvP Quests',
		['type'] = TYPE_PVP
	},
}

-- § Quest groups

local quest_groups = {
	['rtr'] = {
		['full'] = 'Replenish the Reservoir (SL)',
		['ids'] = {61981, 61982, 61983, 61984}
	},
	['ata'] = { -- From SavedInstances
		['full'] = 'Aiding the Accord',
		['ids'] = {70750, 72068, 72373, 72374, 72375, 75259, 75859, 75860, 75861, 77254}
	},
	['awa'] = {
		['full'] = 'A Worthy Ally: Loamm Niffen',
		['ids'] = {75665}
	},
	['car'] = { -- From SavedInstances
		['full'] = 'Catch and Release',
		['ids'] = {70199, 70200, 70201, 70202, 70203, 70935}
	},
	['donotuse:weeklyprof'] = { -- From SavedInstances
		['full'] = 'Profession Weeklies',
		['ids'] = {66363, 66364, 66516, 66517, 66884, 66890, 66891, 66897, 66900, 66937, 66940, 66942, 66943, 66944, 66950, 66951, 66952, 70233, 70235, 70530, 70531, 70532, 70533, 70540, 70557, 70558, 70559, 70560, 70561, 70563, 70564, 70565, 70568, 70569, 70571, 70582, 70586, 70587, 70589, 70591, 70592, 70593, 70594, 70595, 70613, 70616, 70617, 70618, 70620, 72157, 72159, 72172, 72173, 72175, 72407, 72410, 72423, 72427, 72428, 66938, 70572, 66941, 66935, 70619, 70614, 72438, 70562, 66953, 70234, 66945, 72158, 72156, 66949, 70211, 70567, 70615, 70545, 72155}
	},
	['donotuse:weeklyother'] = {-- this is a temporary collection
		['full'] = 'custom',
		['ids'] = {72727} -- A Burning Path Tru Time (TW weekly, 5 dungs)
	},
	['dr'] = { -- "The Waking Shores Tour" etc.; even numbers are the "advanced" variants
		['full'] = 'Dragonriding Races',
		['ids'] = {72481, 72482, 72483, 72484, 72485, 72486, 72487, 72488}
	}
}

 -- TODO: can/should we also add exclusions via quest header?

local exception_types = {
	['a'] = {
		['value'] = 1,
		['full'] = 'Always Tracked',
	},
	['n'] = {
		['value'] = -1,
		['full'] = 'Never Tracked',
	},
	['i'] = {
		['value'] = 0,
		['full'] = 'Ignored',
	},
	['r'] = {
		['value'] = nil,
		['full'] = 'Removed from Exceptions',
	}
}

-- Misc
-- Serves as delay for update after zone change events and as throttle (new zone events are ignored during the time)
local DELAY_ZONE_CHANGE = 3 -- Testwise 3; we used to use 2
-- Time between logout and login needed to consider it a new session
local SESSION_GRACE_TIME = 1200 -- 20 min

-- For the modifier click on the compartment button
local is_mac = IsMacClient()
local text_cmd_key = is_mac and 'Command' or 'Control'

local function table_is_empty(t)
	return next(t) == nil
end

local function debugprint(...)
	if a.gdb.debug_mode then print(MSG_PREFIX, 'Debug:', ...) end
end

local function msg_load(msg,delay)
	if a.gdb.loadMsg then C_TimerAfter(delay, function() print(MSG_PREFIX .. msg) end) end
end

local function msg_confirm(msg)
	print(MSG_PREFIX .. msg)
end

local function print_info_msg(msg, delay)
	if delay then
		C_TimerAfter(delay, function() print(MSG_PREFIX .. msg) end)
	else
		print(MSG_PREFIX .. msg)
	end
end

local f = CreateFrame 'Frame'
f:RegisterEvent 'ADDON_LOADED'

local function register_zone_events()
	f:RegisterEvent 'ZONE_CHANGED'
	f:RegisterEvent 'ZONE_CHANGED_NEW_AREA'
end

local function unregister_zone_events()
	f:UnregisterEvent 'ZONE_CHANGED'
	f:UnregisterEvent 'ZONE_CHANGED_NEW_AREA'
end

local function get_questinfo(index)
	local quest = C_QuestLogGetInfo(index)
	if quest then return
		quest.title,
		quest.isHeader,
		quest.questID,
		C_QuestLogIsWorldQuest(quest.questID),
		quest.isHidden,
		C_QuestLogGetQuestType(quest.questID),
		quest.isOnMap,
		quest.hasLocalPOI
	end
end

local function get_questinfo_for_listing(index)
	local quest = C_QuestLogGetInfo(index)
	if quest then return
		quest.title,
		quest.isHeader,
		quest.questID,
		C_QuestLogIsWorldQuest(quest.questID),
		quest.isHidden,
		C_QuestLogIsQuestCalling(quest.questID),
		C_QuestLogGetQuestType(quest.questID),
		quest.isOnMap,
		quest.hasLocalPOI,
		C_QuestLogGetQuestWatchType(quest.questID),
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

local function auto_show_or_hide_quest(questIndex, questId, show)
	-- Check if quest is still in the log, and if we are not in combat (tainting)
	local questTitle, _, id = get_questinfo(questIndex)
	if not InCombatLockdown() and id == questId then
		if show then
			debugprint(string.format('Tracking: %s (%s)', questTitle, questId))
			C_QuestLogAddQuestWatch(questId, EnumQuestWatchType.Automatic)
		else
			debugprint(string.format('Removing: %s (%s)', questTitle, questId))
			C_QuestLogRemoveQuestWatch(questId)
		end
	end
end


--[[---------------------------------------------------------------------------
	§ Exclusions
---------------------------------------------------------------------------]]--

local last_hook_call = 0

local function add_quest_to_exclusions(par1, par2)
	local id = par2 or par1
	-- local is_watched = QuestUtils_IsQuestWatched(id)
	debugprint('AQT: Hook was called with', par2 and 'QuestObjectiveTracker_UntrackQuest' or 'QuestMapQuestOptions_TrackQuest')
	-- This is to avoid calling our hook 2 times; see below.
	-- if par2 or not is_watched then
	local now = GetTime()
	if now - last_hook_call > 0.15 then
		last_hook_call = now
		-- TODO: Find a way to do this on Windows (eg cycling thru 0 and -1 with ALt-Ctrl)
		-- Never
		if IsMetaKeyDown() and IsAltKeyDown() then
			if a.gdb.exceptions_id[id] ~= -1 then
				print(MSG_PREFIX .. 'Quest', id, 'is now NEVER tracked on all toons.')
				a.gdb.exceptions_id[id] = -1
			else
				print(MSG_PREFIX .. 'Quest', id, 'is already NEVER tracked.')
			end
			if a.cdb.enabled then C_QuestLogRemoveQuestWatch(id) end
		-- Ignore
		elseif is_mac and IsAltKeyDown() or IsAltKeyDown() and IsControlKeyDown() then
			if a.gdb.exceptions_id[id] ~= 0 then
				print(MSG_PREFIX .. 'Quest', id, 'is now IGNORED on all toons.')
				a.gdb.exceptions_id[id] = 0
			else
				print(MSG_PREFIX .. 'Quest', id, 'is already IGNORED.')
			end
		-- Always
		elseif IsMetaKeyDown() or IsAltKeyDown() then
			if a.gdb.exceptions_id[id] ~= 1 then
				print(MSG_PREFIX .. 'Quest', id, 'is now ALWAYS tracked on all toons.')
				a.gdb.exceptions_id[id] = 1
			else
				print(MSG_PREFIX .. 'Quest', id, 'is already ALWAYS tracked.')
			end
			if a.cdb.enabled then C_QuestLogAddQuestWatch(id, EnumQuestWatchType.Automatic) end
		-- Remove from exceptions
		elseif IsControlKeyDown() then
			if a.gdb.exceptions_id[id] then
				print(MSG_PREFIX .. 'Removed quest', id, 'from exceptions.')
				a.gdb.exceptions_id[id] = nil
			else
				print(MSG_PREFIX .. 'Quest', id, 'is not on the exceptions list.')
			end
			if a.cdb.enabled and C_QuestLogGetQuestWatchType(id) == EnumQuestWatchType.Manual then
				C_QuestLogAddQuestWatch(id, EnumQuestWatchType.Automatic)
			end
		end
	end
end

hooksecurefunc('QuestObjectiveTracker_UntrackQuest', add_quest_to_exclusions) -- 2 parameters
hooksecurefunc('QuestMapQuestOptions_TrackQuest', add_quest_to_exclusions) -- 1 parameter
-- NOTE on `QuestMapQuestOptions_TrackQuest`: If the quest is already tracked, it calls `QuestObjectiveTracker_UntrackQuest`. See bear://x-callback-url/open-note?id=63F42C3E-5174-4487-A05C-96F761408B1F

local function is_ignored(id, ty, he)
	if a.gdb.ignoreInstances and (ty == TYPE_DUNG or ty == TYPE_RAID)
		or a.gdb.exceptions_id[id] == 0 or a.gdb.exceptions_type[ty] == 0 or a.gdb.exceptions_header[he] == 0
	then
		return true
	end
end

local function is_always(id, ty, he)
	if a.gdb.exceptions_id[id] == 1 or a.gdb.exceptions_type[ty] == 1 or a.gdb.exceptions_header[he] == 1
	then
		return true
	end
end

local function is_never(id, ty, he)
	if a.gdb.exceptions_id[id] == -1 or a.gdb.exceptions_type[ty] == -1 or a.gdb.exceptions_header[he] == -1
	then
		return true
	end
end

--[[---------------------------------------------------------------------------
	§ Core function
---------------------------------------------------------------------------]]--

local function update_quests_for_zone()
	local currentZone = GetRealZoneText()
	local minimapZone = GetMinimapZoneText()
	if currentZone == nil and minimapZone == nil then return end

	debugprint('Updating quests for: ' .. currentZone .. ' or ' .. minimapZone)

	local header = nil

	for questIndex = 1, C_QuestLogGetNumQuestLogEntries() do
		local questTitle, isHeader, questId, isWorldQuest, isHidden, questType, isOnMap, hasLocalPOI =
			get_questinfo(questIndex)
		if not isWorldQuest and not isHidden then
			if isHeader then
				header = questTitle
			elseif is_ignored(questId, questType, header) then
				-- Nop
			else
				if is_always(questId, questType, header) or (header == currentZone or header == minimapZone or isOnMap or hasLocalPOI) and not is_never(questId, questType) then
					if C_QuestLogGetQuestWatchType(questId) == nil then
						auto_show_or_hide_quest(questIndex, questId, true)
						debugprint(format('Reason: %s %s %s %s', header == currentZone and 'currZone' or '', header == minimapZone and 'mmZone' or '', isOnMap and 'onMap' or '', hasLocalPOI and 'hasPOI' or ''))
					end
				elseif is_never(questId, questType, header) or C_QuestLogGetQuestWatchType(questId) == 0 then
					auto_show_or_hide_quest(questIndex, questId, false)
				end
			end
		end
	end
end


--[[---------------------------------------------------------------------------
	§ Doing stuff at events
---------------------------------------------------------------------------]]--

local function onEvent(self, event, ...)
	if event == 'ADDON_LOADED' then
		if ... == addon_name then
			f:UnregisterEvent 'ADDON_LOADED'
			a.gdb, a.cdb = AQT_GlobalDB, AQT_CharDB
			a.cdb.enabled = a.cdb.enabled == nil and true or a.cdb.enabled
			a.gdb.loadMsg = a.gdb.loadMsg == nil and true or a.gdb.loadMsg
			a.gdb.ignoreInstances = a.gdb.ignoreInstances or false
			a.gdb.debug_mode = a.gdb.debug_mode or false
			a.cdb.time_logout = a.cdb.time_logout or 0
			a.gdb.exceptions_id = a.gdb.exceptions_id or {}
			a.gdb.exceptions_type = a.gdb.exceptions_type or {}
			a.gdb.exceptions_header = a.gdb.exceptions_header or {}
			if a.cdb.enabled then
				register_zone_events()
				msg_load(C_GOOD .. 'Enabled.', 8)
			else
				if not a.cdb.enable_nextsession and not a.cdb.enable_nextinstance then
					msg_load(C_BAD .. 'Disabled.', 8)
				else
					f:RegisterEvent 'PLAYER_ENTERING_WORLD'
				end
			end
		end
	elseif event == 'PLAYER_ENTERING_WORLD' then
		local is_login, is_reload = ...
		if not is_reload then
			if is_login then
				if a.cdb.enable_nextsession and time() - a.cdb.time_logout > SESSION_GRACE_TIME then
					register_zone_events()
					a.cdb.enabled = true
					a.cdb.enable_nextsession = nil
					msg_load(C_GOOD .. 'Re-enabled because of new session.', 6)
				end
			elseif a.cdb.enable_nextinstance then
				register_zone_events()
				a.cdb.enabled = true
				a.cdb.enable_nextinstance = nil
				msg_load(C_GOOD .. 'Re-enabled because of new (map) instance.', 6)
			end
		end
		if a.cdb.enable_nextsession or a.cdb.enable_nextinstance then
			msg_load(C_HALFBAD .. 'Disabled for this ' .. (a.cdb.enable_nextsession and 'session.' or 'instance.'), 6)
			if a.cdb.enable_nextsession then f:RegisterEvent 'PLAYER_LOGOUT' end
			if not a.cdb.enable_nextinstance then f:UnregisterEvent 'PLAYER_ENTERING_WORLD' end
		end
	elseif event == 'PLAYER_LOGOUT' then
		a.cdb.time_logout = time()
	else -- The ZONE events
		if update_pending then return end
		update_pending = true
		C_TimerAfter(DELAY_ZONE_CHANGE, function()
			update_quests_for_zone()
			update_pending = nil
		end)
	end
end

f:SetScript('OnEvent', onEvent)


--[[===========================================================================
	§ UI
===========================================================================]]--

local function text_activation_status()
	return a.cdb.enabled and C_GOOD .. 'Enabled' or a.cdb.enable_nextsession and C_HALFBAD .. 'Disabled for this session' or a.cdb.enable_nextinstance and C_HALFBAD .. 'Disabled for this instance.' or C_BAD .. 'Disabled'
end

local function msg_status()
	print(MSG_PREFIX
		.. 'Status: '
		.. text_activation_status() .. '\124r.'
		.. (a.gdb.ignoreInstances and ' Ignoring instance quests.' or '')
		.. '\nType ' .. C_AQT .. '/aqt h\124r for a list of commands.')
end

local function msg_invalid_input()
	print(MSG_PREFIX
	.. 'This was not a valid input. Check for typos and spaces, or type '
	.. C_AQT .. '/aqt h\124r for help.')
end

local function msg_list_quests()
	print(MSG_PREFIX, 'Quests currently in quest log:\n[T = type; W = watch type]')
	for questIndex = 1, C_QuestLogGetNumQuestLogEntries() do
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
					isOnMap and ', OnMap ' or '',
					hasLocalPOI and ', LocalPOI' or '',
					frequency ~= 0 and ', ' .. (frequency == EnumQuestFrequency.Daily and 'Daily' or 'Weekly') or '',
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
end

local function msg_list_exceptions()
	if table_is_empty(a.gdb.exceptions_id) then
		print(MSG_PREFIX .. 'You have no quest exceptions.')
	else
		print(MSG_PREFIX .. 'List of quest ID exceptions:')
		for id, ex in pairs(a.gdb.exceptions_id) do
			local title = C_QuestLogGetTitleForQuestID(id) or '[Quest title not yet available from server]'
			local xfull = ''
			for k, v in pairs(exception_types) do
				if v['value'] == ex then xfull = v['full'] break end
			end
			print(title .. ' (' .. id .. '): ' .. xfull)
		end
	end
	if table_is_empty(a.gdb.exceptions_type) then
		print(MSG_PREFIX .. 'You have no quest type exceptions.')
	else
		print(MSG_PREFIX .. 'List of quest type exceptions:')
		for ty, ex in pairs(a.gdb.exceptions_type) do
			local xfull = ''
			for k, v in pairs(exception_types) do
				if v['value'] == ex then xfull = v['full'] break end
			end
			local tyfull = ''
			for k, v in pairs(quest_types) do
				if v['type'] == ty then tyfull = v['full'] break end
			end
			print(ty .. ' (' .. tyfull .. '): ' .. xfull)
		end
	end
end

-- TODO: Add version info to help
local function msg_help()
	print(MSG_PREFIX .. 'Help: \n'.. C_AQT .. '/autoquesttracker ' .. '\124ror ' .. C_AQT .. '/aqt ' .. '\124runderstands these commands: ')
	print(C_AQT .. 'on ' .. '\124ror ' .. C_AQT .. 'e' .. '\124r: Enable AQT.')
	print(C_AQT .. 'off ' .. '\124ror ' .. C_AQT .. 'd' .. '\124r: Disable AQT for the current session.')
	print(C_AQT .. 'offi ' .. '\124ror ' .. C_AQT .. 'di' .. '\124r: Disable AQT for the current (map) instance.')
	print(C_AQT .. 'offp ' .. '\124ror ' .. C_AQT .. 'dp' .. '\124r: Disable AQT permanently.')
	print(C_AQT .. 'instances ' .. '\124ror ' .. C_AQT .. 'in' .. '\124r: Toggle auto-tracking of dungeon/raid quests.')
	print(C_AQT .. 'loadingmessage' .. '\124r: Toggle status message in chat after reload/login.')
	print(C_AQT .. 'quests ' .. '\124ror ' .. C_AQT .. 'q' .. '\124r: Show complete quest list.')
	print(C_AQT .. 'debug' .. '\124r: Toggle debug mode.')
	print(C_AQT .. 'help ' .. '\124ror ' .. C_AQT .. 'h' .. '\124r: Display this help text.')
	print(C_AQT .. '/aqt ' .. '\124rwithout additional commands: Display status info.')
	print('Enable/disable is per char, other settings are global.')
	print('Some commands are also available via the addon compartment button. See the addon compartment button tooltip.')
end

local function get_questheader_from_input(t)
	local headerarray = {}
	for i = 3, #t do
		tinsert(headerarray, t[i])
	end
	return table.concat(headerarray, ' ')
end

--[[---------------------------------------------------------------------------
	§ Main switch
---------------------------------------------------------------------------]]--

local function aqt_enable(on, disablemode)
	f:UnregisterAllEvents()
	a.cdb.enable_nextsession, a.cdb.enable_nextinstance = nil, nil
	if on then
		update_quests_for_zone()
		register_zone_events()
	else
		if not disablemode or disablemode == 1 then
			a.cdb.enable_nextsession = true
			f:RegisterEvent 'PLAYER_LOGOUT'
		elseif disablemode == 2 then
			a.cdb.enable_nextinstance = true
			f:RegisterEvent 'PLAYER_ENTERING_WORLD'
		end
	end
	a.cdb.enabled = on
	msg_confirm(text_activation_status() .. '.')
end

--[[---------------------------------------------------------------------------
	§ Slash commands
---------------------------------------------------------------------------]]--

SLASH_AUTOQUESTTRACKER1 = '/autoquesttracker'
SLASH_AUTOQUESTTRACKER2 = '/aqt'
SlashCmdList['AUTOQUESTTRACKER'] = function(msg)
	local mt = {}
	for v in msg:gmatch '[^ ]+' do
		tinsert(mt, v)
	end
	if #mt == 0 then
		msg_status()
	elseif #mt == 1 then
		if msg == 'e' or msg == 'on' then
			aqt_enable(true)
			-- Disable for current session (default)
		elseif msg == 'd' or msg == 'off' then
			aqt_enable(false, nil)
			-- Permanently disable
		elseif msg == 'dp' or msg == 'offp' then
			aqt_enable(false, 0)
			-- Disable for current instance
		elseif msg == 'di' or msg == 'offi' then
			aqt_enable(false, 2)
		elseif msg == 'loadingmessage' then
			a.gdb.loadMsg = not a.gdb.loadMsg
			msg_confirm('Loading message ' .. (a.gdb.loadMsg and 'enabled' or 'disabled') .. ' for all chars.')
		elseif msg == 'in' or msg == 'instances' then
			a.gdb.ignoreInstances = not a.gdb.ignoreInstances
			if a.cdb.enabled then update_quests_for_zone() end
			msg_confirm('Instance quests are ' ..
			(a.gdb.ignoreInstances and 'ignored' or 'treated normally') .. ' for all chars.')
		elseif msg == 'debug' then
			a.gdb.debug_mode = not a.gdb.debug_mode
			msg_confirm('Debug mode ' .. (a.gdb.debug_mode and 'enabled.' or 'disabled.'))
		elseif msg == 'q' or msg == 'quests' then
			msg_list_quests()
		elseif msg == 'x' or msg == 'exceptions' then
			msg_list_exceptions()
		elseif msg == 'xcleari' or msg == 'exceptionsclearid' then
			wipe(a.gdb.exceptions_id)
			if a.cdb.enabled then update_quests_for_zone() end
			msg_confirm('All quest ID exceptions cleared.')
		elseif msg == 'xcleart' or msg == 'exceptionscleartype' then
			wipe(a.gdb.exceptions_type)
			if a.cdb.enabled then update_quests_for_zone() end
			msg_confirm('All quest type exceptions cleared.')
		elseif msg == 'xclearall' or msg == 'exceptionsclearall' then
			wipe(a.gdb.exceptions_id)
			wipe(a.gdb.exceptions_type)
			if a.cdb.enabled then update_quests_for_zone() end
			msg_confirm('All quest exceptions (ID & type) cleared.')
		elseif msg == 'h' or msg == 'help' then
			msg_help()
		else
			msg_invalid_input()
		end
	elseif #mt == 2 then -- assuming we have a cmd like a, i, n, or r, plus an arg
		if exception_types[mt[1]] then
			if quest_types[mt[2]] then
				a.gdb.exceptions_type[quest_types[mt[2]]['type']] = exception_types[mt[1]]['value']
				msg_confirm('Quest type "' ..
					quest_types[mt[2]]['type'] ..
					'" (' .. quest_types[mt[2]]['full'] .. ') is now ' .. exception_types[mt[1]]['full'] .. '.')
				if a.cdb.enabled then update_quests_for_zone() end
			elseif quest_groups[mt[2]] then
				for _, id in ipairs(quest_groups[mt[2]]['ids']) do
					a.gdb.exceptions_id[id] = exception_types[mt[1]]['value']
				end
				msg_confirm('Quest group "' ..
					quest_groups[mt[2]]['full'] ..
					'" (' ..
					#quest_groups[mt[2]]['ids'] .. ' quest IDs) is now ' .. exception_types[mt[1]]['full'] .. '.')
				if a.cdb.enabled then update_quests_for_zone() end
			else
				msg_invalid_input()
			end
		else
			msg_invalid_input()
		end
	-- Header exceptions format: /aqt <exception cmd> h <quest header>
	elseif mt[2] == 'h' and exception_types[mt[1]] then
		local header = get_questheader_from_input(mt)
		a.gdb.exceptions_header[header] = exception_types[mt[1]]['value']
		msg_confirm('All quests with header "' .. header .. '" are now ' .. exception_types[mt[1]]['full'] .. '.')
		if a.cdb.enabled then update_quests_for_zone() end
	else
		msg_invalid_input()
	end
end

--[[===========================================================================
	§ API
===========================================================================]]--

function _G.addon_aqt_enable(v)
	if type(v) ~= 'boolean' then
		error("Wrong argument type. Usage: 'addon_aqt_enable(boolean)'", 0)
	else
		aqt_enable(v)
	end
end

function _G.addon_aqt_on_addoncompartment_click(_, btn)
	if btn == 'LeftButton' then
		if is_mac and IsMetaKeyDown() or not is_mac and IsControlKeyDown() then
			msg_help()
		else
			msg_status()
		end
	elseif btn == 'RightButton' then
		aqt_enable(not AQT_CharDB.enabled)
	end
end
function _G.addon_aqt_on_addoncompartment_enter()
---@diagnostic disable-next-line: missing-parameter
	GameTooltip:SetOwner(AddonCompartmentFrame)
	GameTooltip:AddDoubleLine('Auto Quest Tracker', text_activation_status())
	GameTooltip:AddLine(C_CLICK .. 'Left-click ' .. C_TT .. 'to print ' .. C_ACTION .. 'status\124r.')
	GameTooltip:AddLine(C_CLICK .. text_cmd_key .. '-left-click ' .. C_TT .. 'to print ' .. C_ACTION .. 'help\124r text.')
	GameTooltip:AddLine(C_CLICK .. 'Right-click ' .. C_TT .. 'to ' .. C_ACTION .. 'toggle\124r AQT for this session.')
	GameTooltip:Show()
end

function _G.addon_aqt_on_addoncompartment_leave()
	GameTooltip:Hide()
end


--[[ License ===================================================================

	Portions: Copyright © 2022–2023 Thomas Floeren for the added code of "Mk III" (v2.0)

	This file is part of Auto Quest Tracker Mk III.

	Auto Quest Tracker Mk III is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	Auto Quest Tracker Mk III is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
	or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
	more details.

	You should have received a copy of the GNU General Public License along with
	Auto Quest Tracker Mk III. If not, see <https://www.gnu.org/licenses/>.

==============================================================================]]
