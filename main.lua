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

local function get_questinfo(qidx)
	local info = C_QuestLog_GetInfo(qidx)
	if info then
		info.isWQ = C_QuestLog_IsWorldQuest(info.questID)
		info.type = C_QuestLog_GetQuestType(info.questID)
	end
	return info
	-- info.keys of C_QuestLog.GetInfo:
	-- title, questLogIndex, questID, campaignID, level, difficultyLevel, suggestedGroup, frequency, isHeader, useMinimalHeader, sortAsNormalQuest, isCollapsed, startEvent, isTask, isBounty, isStory, isScaling, isOnMap, hasLocalPOI, isHidden, isAutoComplete, overridesSortOrder, readyForTranslation, isInternalOnly, isAbandonOnDisable, headerSortKey, questClassification
end

--[[---------------------------------------------------------------------------
	Main function
---------------------------------------------------------------------------]]--

-- local function auto_show_or_hide_quest(qidx, qid, show)
-- 	local info = get_questinfo(qidx)
-- 	-- Check if the targeted quest is still in the log
-- 	if info.questID == qid then
-- 		-- TODO: check if we really need this guard
-- -- 	if not InCombatLockdown() and info.questID == qid then
-- 		if show then
-- 			A.dprint(1, format('Tracking: %s (%s)', info.title, qid))
-- 			C_QuestLog_AddQuestWatch(qid)
-- 		else
-- 			A.dprint(2, format('Removing: %s (%s)', info.title, qid))
-- 			C_QuestLog_RemoveQuestWatch(qid)
-- 		end
-- 	end
-- end

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

do
	local header, currentZone, minimapZone

	local function auto_show_or_hide_quest(qidx)
		local info = get_questinfo(qidx)
		if info.isWQ or info.isHidden then return end
		local show = false

		if info.isHeader then
			header = info.title
			return
		elseif is_ignore(info.questID, info.type, header) then
			return
		else
			if is_always(info.questID, info.type, header) or (header == currentZone or header == minimapZone or info.isOnMap or info.hasLocalPOI) and not is_never(info.questID, info.type) then
				show = true
			end
		end

		if show then
			if C_QuestLog_GetQuestWatchType(info.questID) ~= nil then return end
			C_QuestLog_AddQuestWatch(info.questID)
		else
			if C_QuestLog_GetQuestWatchType(info.questID) == nil then return end
			C_QuestLog_RemoveQuestWatch(info.questID)
		end
	end

	function A.update_quests_for_zone()
		currentZone = GetRealZoneText()
		minimapZone = GetMinimapZoneText()
		header = nil
		if currentZone == nil and minimapZone == nil then return end

		for idx = 1, C_QuestLog_GetNumQuestLogEntries() do
			auto_show_or_hide_quest(idx)
		end
	end
end
