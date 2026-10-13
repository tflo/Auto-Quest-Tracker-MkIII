-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Portions: Copyright (c) 2022-2026 Thomas Floeren for the added/changed code of "Mk III" (aka version 2 and later)

local MYNAME, A = ...

local InCombatLockdown = InCombatLockdown
local GetRealZoneText = GetRealZoneText
local GetMinimapZoneText = GetMinimapZoneText

local C_QuestLog_GetInfo = C_QuestLog.GetInfo
local C_QuestLog_IsWorldQuest = C_QuestLog.IsWorldQuest
local C_QuestLog_GetQuestType = C_QuestLog.GetQuestType
local C_QuestLog_AddQuestWatch = C_QuestLog.AddQuestWatch
local C_QuestLog_RemoveQuestWatch = C_QuestLog.RemoveQuestWatch
local C_QuestLog_GetNumQuestLogEntries = C_QuestLog.GetNumQuestLogEntries
local C_QuestLog_GetQuestWatchType = C_QuestLog.GetQuestWatchType
-- local C_QuestLog_GetTitleForQuestID = C_QuestLog.GetTitleForQuestID
-- local C_QuestLog_IsQuestCalling = C_QuestLog.IsQuestCalling

--[=[

https://warcraft.wiki.gg/wiki/Category:API_systems/QuestLog

--]=]

--[[---------------------------------------------------------------------------
	Main function
---------------------------------------------------------------------------]]--

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

local function auto_show_or_hide_quest(quest_idx, quest_id, show)
	local questTitle, _, id = get_questinfo(quest_idx)
	-- Check if the targeted quest is still in the log
	-- TODO: check if we really can't do this in combat
	if id == quest_id then
-- 	if not InCombatLockdown() and id == quest_id then
		if show then
			A.dprint(format('Tracking: %s (%s)', questTitle, quest_id))
			C_QuestLog_AddQuestWatch(quest_id, A.QWT_AUTOMATIC)
		else
			A.dprint(format('Removing: %s (%s)', questTitle, quest_id))
			C_QuestLog_RemoveQuestWatch(quest_id)
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

local predicate = {'is now ', 'is already '}

function A.add_quest_to_exceptions(quest_id, exc_type)
	A.dprint('`A.add_quest_to_exceptions` called.')
	local pred = predicate[1]
	-- Never track quest: Cmd-Option
	-- Currently Mac only, due to the lack of enough modifier keys on Windows
	if exc_type == A.EXCEPTION_TYPES.never.value then
		if A.gdb.exceptions_id[quest_id] ~= A.EXCEPTION_TYPES.never.value then
			A.gdb.exceptions_id[quest_id] = A.EXCEPTION_TYPES.never.value
		else
			pred = predicate[2]
		end
		confirm_msg(quest_id, pred, A.EXCEPTION_TYPES.never.full)
		if A.cdb.enabled then C_QuestLog_RemoveQuestWatch(quest_id) end
	-- Ignore quest: Option (Mac), Ctrl-Alt (Win)
	elseif exc_type == A.EXCEPTION_TYPES.ignore.value then
		if A.gdb.exceptions_id[quest_id] ~= A.EXCEPTION_TYPES.ignore.value then
			A.gdb.exceptions_id[quest_id] = A.EXCEPTION_TYPES.ignore.value
		else
			pred = predicate[2]
		end
		confirm_msg(quest_id, pred, A.EXCEPTION_TYPES.ignore.full)
	-- Always track quest: Cmd (Mac), Alt (Win)
	elseif exc_type == A.EXCEPTION_TYPES.always.value then
		if A.gdb.exceptions_id[quest_id] ~= A.EXCEPTION_TYPES.always.value then
			A.gdb.exceptions_id[quest_id] = A.EXCEPTION_TYPES.always.value
		else
			pred = predicate[2]
		end
		confirm_msg(quest_id, pred, A.EXCEPTION_TYPES.always.full)
		if A.cdb.enabled then C_QuestLog_AddQuestWatch(quest_id, A.QWT_AUTOMATIC) end
	-- Remove quest from exceptions: Ctrl (Mac/Win)
	elseif exc_type == A.EXCEPTION_TYPES.remove.value then
		if A.gdb.exceptions_id[quest_id] then
			A.gdb.exceptions_id[quest_id] = nil
			pred = 'removed from exceptions'
		else
			pred = 'did not have any exception assigned'
		end
		confirm_msg(quest_id, pred, '')
		if A.cdb.enabled and C_QuestLog_GetQuestWatchType(quest_id) == A.QWT_MANUAL then
			C_QuestLog_AddQuestWatch(quest_id, A.QWT_AUTOMATIC)
		end
	end
end

--[[===========================================================================
	Core
===========================================================================]]--

local function is_ignore(id, ty, he)
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

	for quest_idx = 1, C_QuestLog_GetNumQuestLogEntries() do
		local questTitle, isHeader, quest_id, isWorldQuest, isHidden, questType, isOnMap, hasLocalPOI =
			get_questinfo(quest_idx)
		if not isWorldQuest and not isHidden then
			if isHeader then
				header = questTitle
			elseif is_ignore(quest_id, questType, header) then
				-- Nop
			else
				if is_always(quest_id, questType, header) or (header == currentZone or header == minimapZone or isOnMap or hasLocalPOI) and not is_never(quest_id, questType) then
					if C_QuestLog_GetQuestWatchType(quest_id) == nil then
						auto_show_or_hide_quest(quest_idx, quest_id, true)
						if A.gdb.debug_mode then
							A.dprint(format('Reason: %s%s%s%s%s', is_always(quest_id, questType, header) == true and 'alwaysTracked ' or '', header == currentZone and 'currZone ' or '', header == minimapZone and 'mmZone ' or '', isOnMap and 'onMap ' or '', hasLocalPOI and 'hasPOI ' or ''))
						end
					end
				elseif A.IGNORE_QWT or is_never(quest_id, questType, header) or C_QuestLog_GetQuestWatchType(quest_id) == A.QWT_AUTOMATIC then
					auto_show_or_hide_quest(quest_idx, quest_id, false)
				end
			end
		end
	end
end
