-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Portions: Copyright (c) 2022-2026 Thomas Floeren for the added/changed code of "Mk III" (aka version 2 and later)

local MYNAME, A = ...
local CLR = A.CLR

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

--[[===========================================================================
	Core
===========================================================================]]--

local function get_questinfo(index)
	local info = C_QuestLog_GetInfo(index)
	if info then return
		info.title,
		info.isHeader,
		info.questID,
		C_QuestLog_IsWorldQuest(info.questID),
		info.isHidden,
		C_QuestLog_GetQuestType(info.questID),
		info.isOnMap,
		info.hasLocalPOI
	end
end

--[[---------------------------------------------------------------------------
	Main function
---------------------------------------------------------------------------]]--

local function auto_show_or_hide_quest(quest_idx, quest_id, show)
	local questTitle, _, id = get_questinfo(quest_idx)
	-- Check if the targeted quest is still in the log
	if id == quest_id then
		-- TODO: check if we really need this guard
-- 	if not InCombatLockdown() and id == quest_id then
		if show then
			A.dprint(1, format('Tracking: %s (%s)', questTitle, quest_id))
			C_QuestLog_AddQuestWatch(quest_id, A.QWT_AUTOMATIC)
		else
			A.dprint(2, format('Removing: %s (%s)', questTitle, quest_id))
			C_QuestLog_RemoveQuestWatch(quest_id)
		end
	end
end

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
	Zone function
---------------------------------------------------------------------------]]--

function A.update_quests_for_zone()
	local currentZone = GetRealZoneText()
	local minimapZone = GetMinimapZoneText()
	if currentZone == nil and minimapZone == nil then return end

	A.dprint(1, 'Updating quests for: ' .. currentZone .. ' or ' .. minimapZone)

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
						if A.gdb.debug_mode and A.gdb.debug_level >= 1 then
							A.dprint(0, format('Reason: %s%s%s%s%s', is_always(quest_id, questType, header) == true and 'alwaysTracked ' or '', header == currentZone and 'currZone ' or '', header == minimapZone and 'mmZone ' or '', isOnMap and 'onMap ' or '', hasLocalPOI and 'hasPOI ' or ''))
						end
					end
				elseif A.IGNORE_QWT or is_never(quest_id, questType, header) or C_QuestLog_GetQuestWatchType(quest_id) == A.QWT_AUTOMATIC then
					auto_show_or_hide_quest(quest_idx, quest_id, false)
				end
			end
		end
	end
end
