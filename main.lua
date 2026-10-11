-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Portions: Copyright (c) 2022-2026 Thomas Floeren for the added/changed code of "Mk III" (aka version 2 and later)

local MYNAME, A = ...

AQT_GlobalDB = AQT_GlobalDB or {}
AQT_CharDB = AQT_CharDB or {}

--[[===========================================================================
	Declarations
===========================================================================]]--

--[[---------------------------------------------------------------------------
	Blizz API
---------------------------------------------------------------------------]]--

local _
local C_Timer_After = C_Timer.After
local InCombatLockdown, GetRealZoneText, GetMinimapZoneText = InCombatLockdown, GetRealZoneText, GetMinimapZoneText
local C_QuestLog_GetInfo, C_QuestLog_IsWorldQuest, C_QuestLog_GetQuestType, C_QuestLog_AddQuestWatch, C_QuestLog_RemoveQuestWatch, C_QuestLog_GetNumQuestLogEntries, C_QuestLog_GetQuestWatchType, C_QuestLog_GetTitleForQuestID, C_QuestLog_IsQuestCalling =
	C_QuestLog.GetInfo,
	C_QuestLog.IsWorldQuest,
	C_QuestLog.GetQuestType,
	C_QuestLog.AddQuestWatch,
	C_QuestLog.RemoveQuestWatch,
	C_QuestLog.GetNumQuestLogEntries,
	C_QuestLog.GetQuestWatchType,
	C_QuestLog.GetTitleForQuestID,
	C_QuestLog.IsQuestCalling

--[[---------------------------------------------------------------------------
	Misc functions
---------------------------------------------------------------------------]]--

function A.table_is_empty(t)
	return next(t) == nil
end

function A.dprint(...)
	if A.gdb.debug_mode then
		local a, b = strsplit('.', GetTimePreciseSec())
		print(format('[%s.%s] %sAQT >>> Debug >>>\124r', a:sub(-3), b:sub(1, 3), A.CLR_DEBUG), ...)
	end
end

function A.msg_load(msg,delay)
	if A.gdb.loadMsg then C_Timer_After(delay, function() print(A.MSG_PREFIX .. msg) end) end
end

function A.msg_confirm(msg)
	print(A.MSG_PRE .. msg)
end

A.ef = CreateFrame 'Frame'
A.ef:RegisterEvent 'ADDON_LOADED'

function A.ef:register_zone_events()
	self:RegisterEvent 'ZONE_CHANGED'
	self:RegisterEvent 'ZONE_CHANGED_NEW_AREA'
	A.dprint 'Zone events registered.'
end

-- local function unregister_zone_events()
-- 	A.ef:UnregisterEvent 'ZONE_CHANGED'
-- 	A.ef:UnregisterEvent 'ZONE_CHANGED_NEW_AREA'
-- end

local function get_questinfo(index)
	local quest = C_QuestLog_GetInfo(index)
	if quest then return
		quest.title,
		quest.isHeader,
		quest.questID,
		C_QuestLog_IsWorldQuest(quest.questID),
		quest.isHidden,
		C_QuestLog_GetQuestType(quest.questID),
		quest.isOnMap,
		quest.hasLocalPOI
	end
end

local function get_questinfo_for_listing(index)
	local quest = C_QuestLog_GetInfo(index)
	if quest then return
		quest.title,
		quest.isHeader,
		quest.questID,
		C_QuestLog_IsWorldQuest(quest.questID),
		quest.isHidden,
		C_QuestLog_IsQuestCalling(quest.questID),
		C_QuestLog_GetQuestType(quest.questID),
		quest.isOnMap,
		quest.hasLocalPOI,
		C_QuestLog_GetQuestWatchType(quest.questID),
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
			A.dprint(format('Tracking: %s (%s)', questTitle, questId))
			C_QuestLog_AddQuestWatch(questId, A.QWT_AUTOMATIC)
		else
			A.dprint(format('Removing: %s (%s)', questTitle, questId))
			C_QuestLog_RemoveQuestWatch(questId)
		end
	end
end


--[[===========================================================================
	Exclusions
===========================================================================]]--

-- TODO: Let's find out if we can use the new (TWW) menu hooking system, instead of modified clicks!
-- https://warcraft.wiki.gg/wiki/Patch_11.0.0/API_changes#Hooking_menus

local function confirm_msg(quest_id, predicate, action)
	print(format('%sQuest %s %s%s.', A.MSG_PRE, quest_id, predicate, action))
end

local pred = {'is now ', 'is already '}

local function add_quest_to_exceptions(par1)
	A.dprint('`add_quest_to_exceptions` called.')
	local id, pr = par1, pred[1]
	-- Never track quest: Cmd-Option
	-- Currently Mac only, due to the lack of enough modifier keys on Windows
	if IsMetaKeyDown() and IsAltKeyDown() then
		if A.gdb.exceptions_id[id] ~= A.EXCEPTION_TYPES.never.value then
			A.gdb.exceptions_id[id] = A.EXCEPTION_TYPES.never.value
		else
			pr = pred[2]
		end
		confirm_msg(id, pr, A.EXCEPTION_TYPES.never.full)
		if A.cdb.enabled then C_QuestLog_RemoveQuestWatch(id) end
	-- Ignore quest: Option (Mac), Ctrl-Alt (Win)
	elseif A.IS_MAC and IsAltKeyDown() or IsAltKeyDown() and IsControlKeyDown() then
		if A.gdb.exceptions_id[id] ~= A.EXCEPTION_TYPES.ignore.value then
			A.gdb.exceptions_id[id] = A.EXCEPTION_TYPES.ignore.value
		else
			pr = pred[2]
		end
		confirm_msg(id, pr, A.EXCEPTION_TYPES.ignore.full)
	-- Always track quest: Cmd (Mac), Alt (Win)
	elseif IsMetaKeyDown() or IsAltKeyDown() then
		if A.gdb.exceptions_id[id] ~= A.EXCEPTION_TYPES.always.value then
			A.gdb.exceptions_id[id] = A.EXCEPTION_TYPES.always.value
		else
			pr = pred[2]
		end
		confirm_msg(id, pr, A.EXCEPTION_TYPES.always.full)
		if A.cdb.enabled then C_QuestLog_AddQuestWatch(id, A.QWT_AUTOMATIC) end
	-- Remove quest from exceptions: Ctrl (Mac/Win)
	elseif IsControlKeyDown() then
		if A.gdb.exceptions_id[id] then
			A.gdb.exceptions_id[id] = nil
			pr = 'removed from exceptions'
		else
			pr = 'did not have any exception assigned'
		end
		confirm_msg(id, pr, '')
		if A.cdb.enabled and C_QuestLog_GetQuestWatchType(id) == A.QWT_MANUAL then
			C_QuestLog_AddQuestWatch(id, A.QWT_AUTOMATIC)
		end
	end
end


--[[---------------------------------------------------------------------------
	Hook(s)
---------------------------------------------------------------------------]]--

-- Currently preferred: Variant 1

-- Variant 1 (like before TWW, but only in QuestMapFrame):
-- Good: Well tested pre-TWW; only one hook
-- Bad: Works only in QuestMapFrame
-- Current (11.0.0) function: https://www.townlong-yak.com/framexml/live/Blizzard_UIPanels_Game/QuestMapFrame.lua#1370
---[[
hooksecurefunc('QuestMapQuestOptions_TrackQuest', add_quest_to_exceptions)
--]]

-- Variant 2 (experimental):
-- Good: Works also in tracker
-- Bad: Two hooks; not thoroughly tested; quirks with other addons?
-- Good/Bad: Quest watch limit is significant: `AddQuestWatch` is not called if over limit
-- IF HOOKING THESE FUNCTIONS, MAKE SURE THAT AQT ITSELF USES *ONLY* THE PREVIOUSLY "LOCALIZED" VERSIONS OF THESE
-- FUNCTIONS. OTHERWISE WE HAVE AN INFINITE LOOP.
--[[
hooksecurefunc(C_QuestLog, 'AddQuestWatch', add_quest_to_exceptions)
hooksecurefunc(C_QuestLog, 'RemoveQuestWatch', add_quest_to_exceptions)
--]]
-- Alternatively, to hooking the "watch" functions, we could listen to the QUEST_WATCH_LIST_CHANGED event.
-- We need a throttle then to avoid loops.


--[[===========================================================================
	Core
===========================================================================]]--

local function is_ignored(id, ty, he)
	if A.gdb.ignoreInstances and (ty == A.TYPE_DUNG or ty == A.TYPE_RAID)
		or A.gdb.exceptions_id[id] == 0 or A.gdb.exceptions_type[ty] == 0 or A.gdb.exceptions_header[he] == 0
	then
		return true
	end
end

local function is_always(id, ty, he)
	if A.gdb.exceptions_id[id] == 1 or A.gdb.exceptions_type[ty] == 1 or A.gdb.exceptions_header[he] == 1
	then
		return true
	end
end

local function is_never(id, ty, he)
	if A.gdb.exceptions_id[id] == -1 or A.gdb.exceptions_type[ty] == -1 or A.gdb.exceptions_header[he] == -1
	then
		return true
	end
end

--[[---------------------------------------------------------------------------
	Main function
---------------------------------------------------------------------------]]--

-- It seems since 11.0.0, Blizz is (ab)using quest watch type 1 (manual) for
-- everything, e.g. also for auto-tracking after picking up a quest (which
-- should be QWT 0 (auto)).
-- It is currently impossible to set QWT 0, even explicitly.
-- Our brute-force workaround is to treat every QWT as 0.
A.IGNORE_QWT = true

function A.update_quests_for_zone()
	local currentZone = GetRealZoneText()
	local minimapZone = GetMinimapZoneText()
	if currentZone == nil and minimapZone == nil then return end

	A.dprint('Updating quests for: ' .. currentZone .. ' or ' .. minimapZone)

	local header = nil

	for questIndex = 1, C_QuestLog_GetNumQuestLogEntries() do
		local questTitle, isHeader, questId, isWorldQuest, isHidden, questType, isOnMap, hasLocalPOI =
			get_questinfo(questIndex)
		if not isWorldQuest and not isHidden then
			if isHeader then
				header = questTitle
			elseif is_ignored(questId, questType, header) then
				-- Nop
			else
				if is_always(questId, questType, header) or (header == currentZone or header == minimapZone or isOnMap or hasLocalPOI) and not is_never(questId, questType) then
					if C_QuestLog_GetQuestWatchType(questId) == nil then
						auto_show_or_hide_quest(questIndex, questId, true)
						if A.gdb.debug_mode then
							A.dprint(format('Reason: %s%s%s%s%s', is_always(questId, questType, header) == true and 'alwaysTracked ' or '', header == currentZone and 'currZone ' or '', header == minimapZone and 'mmZone ' or '', isOnMap and 'onMap ' or '', hasLocalPOI and 'hasPOI ' or ''))
						end
					end
				elseif A.IGNORE_QWT or is_never(questId, questType, header) or C_QuestLog_GetQuestWatchType(questId) == A.QWT_AUTOMATIC then
					auto_show_or_hide_quest(questIndex, questId, false)
				end
			end
		end
	end
end


--[[---------------------------------------------------------------------------
	Doing stuff at events
---------------------------------------------------------------------------]]--

local update_pending -- Ignore flag during the A.DELAY_ZONE_CHANGE time

local function onEvent(_, event, ...)
	if event == 'ADDON_LOADED' then
		if ... == MYNAME then
			A.ef:UnregisterEvent 'ADDON_LOADED'
			A.gdb, A.cdb = AQT_GlobalDB, AQT_CharDB
			A.cdb.enabled = A.cdb.enabled == nil and true or A.cdb.enabled
			A.gdb.loadMsg = A.gdb.loadMsg == nil and true or A.gdb.loadMsg
			A.gdb.ignoreInstances = A.gdb.ignoreInstances or false
			A.gdb.debug_mode = A.gdb.debug_mode or false
			A.cdb.time_logout = A.cdb.time_logout or 0
			A.gdb.exceptions_id = A.gdb.exceptions_id or {}
			A.gdb.exceptions_type = A.gdb.exceptions_type or {}
			A.gdb.exceptions_header = A.gdb.exceptions_header or {}
			if A.cdb.enabled then
				A.ef:register_zone_events()
				A.msg_load(A.CLR_GOOD .. 'Enabled.', 8)
			else
				if not A.cdb.enable_nextsession and not A.cdb.enable_nextinstance then
					A.msg_load(A.CLR_BAD .. 'Disabled.', 8)
				else
					A.ef:RegisterEvent 'PLAYER_ENTERING_WORLD'
				end
			end
		end
	elseif event == 'PLAYER_ENTERING_WORLD' then
		local is_login, is_reload = ...
		if not is_reload then
			if is_login then
				if A.cdb.enable_nextsession and time() - A.cdb.time_logout > A.SESSION_GRACE_TIME then
					A.ef:register_zone_events()
					A.cdb.enabled = true
					A.cdb.enable_nextsession = nil
					A.msg_load(A.CLR_GOOD .. 'Re-enabled because of new session.', 6)
				end
			elseif A.cdb.enable_nextinstance then
				A.ef:register_zone_events()
				A.cdb.enabled = true
				A.cdb.enable_nextinstance = nil
				A.msg_load(A.CLR_GOOD .. 'Re-enabled because of new (map) instance.', 6)
			end
		end
		if A.cdb.enable_nextsession or A.cdb.enable_nextinstance then
			A.msg_load(A.CLR_HALFBAD .. 'Disabled for this ' .. (A.cdb.enable_nextsession and 'session.' or 'instance.'), 6)
			if A.cdb.enable_nextsession then A.ef:RegisterEvent 'PLAYER_LOGOUT' end
			if not A.cdb.enable_nextinstance then A.ef:UnregisterEvent 'PLAYER_ENTERING_WORLD' end
		end
	elseif event == 'PLAYER_LOGOUT' then
		A.cdb.time_logout = time()
	else -- The ZONE events
		if update_pending then return end
		update_pending = true
		C_Timer_After(A.DELAY_ZONE_CHANGE, function()
			A.update_quests_for_zone()
			update_pending = nil
		end)
	end
end

A.ef:SetScript('OnEvent', onEvent)

-- TODO:
-- Context menu for tracker and log
-- Possiblity to add/remove by ID via slash command
-- Do something when user reaches the tracking limit

-- TODO, maybe:
-- Option to track only when completed or not completed; could be a "Track conditionally" with submenu
-- Another possible conditional tracking: ALways/Never track in current zone/continent
-- LDB button for quick access to enable/disable, plus status indicator; plus number of always/never/ignore quests
-- Save a snaphot of what is tracked when the user activates AQT. Optionally restore this when the user deactivates AQT.
