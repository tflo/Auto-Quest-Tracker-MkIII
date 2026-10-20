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
local C_QuestLog_GetQuestTagInfo = C_QuestLog.GetQuestTagInfo
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
		local tagInfo = C_QuestLog_GetQuestTagInfo(info.questID)
		info.tagID = tagInfo and tagInfo.tagID
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

-- local function is_ignore(id, ty, he)
-- 	if A.gdb.ignoreInstances and (ty == A.TYPE_DUNG or ty == A.TYPE_RAID)
-- 		or A.gdb.exceptions_id[id] == 0 or A.gdb.exceptions_type[ty] == 0 or A.gdb.exceptions_header[he] == 0
-- 	then
-- 		return true
-- 	end
-- end
--
-- local function is_always(id, ty, he)
-- 	if A.gdb.exceptions_id[id] == 1 or A.gdb.exceptions_type[ty] == 1 or A.gdb.exceptions_header[he] == 1
-- 	then
-- 		return true
-- 	end
-- end
--
-- local function is_never(id, ty, he)
-- 	if A.gdb.exceptions_id[id] == -1 or A.gdb.exceptions_type[ty] == -1 or A.gdb.exceptions_header[he] == -1
-- 	then
-- 		return true
-- 	end
-- end

--[[---------------------------------------------------------------------------
	Zone function
---------------------------------------------------------------------------]]--

do
	local header, currentZone, minimapZone

	local function get_quest_action(info, header)
		-- 1. Single quest ID (absolute priority)
		if A.gdb.exceptions_id[info.questID] == 1 then return 'always' end
		if A.gdb.exceptions_id[info.questID] == -1 then return 'never' end
		if A.gdb.exceptions_id[info.questID] == 0 then return 'ignore' end

		-- 2. Special settings (instances); might be removed
		if A.gdb.ignoreInstances and (info.type == A.TYPE_DUNG or info.type == A.TYPE_RAID) then
			return 'ignore'
		end

		-- 3. Header
		if A.gdb.exceptions_header[header] == 1 then return 'always' end
		if A.gdb.exceptions_header[header] == -1 then return 'never' end
		if A.gdb.exceptions_header[header] == 0 then return 'ignore' end

		-- 4. Type if non-zero
		if info.type and info.type ~= A.NORMAL.type then
			if A.gdb.exceptions_type[info.type] == 1 then return 'always' end
			if A.gdb.exceptions_type[info.type] == -1 then return 'never' end
			if A.gdb.exceptions_type[info.type] == 0 then return 'ignore' end
		end

		-- 5. TagID if it exists
		if info.tagID then
			if A.gdb.exceptions_tag[info.tagID] == 1 then return 'always' end
			if A.gdb.exceptions_tag[info.tagID] == -1 then return 'never' end
			if A.gdb.exceptions_tag[info.tagID] == 0 then return 'ignore' end
		end

		-- 6. Frequency if non-zero ("Default")
		if info.frequency and info.frequency ~= A.NORMAL.frequency then
			if A.gdb.exceptions_frequency[info.frequency] == 1 then return 'always' end
			if A.gdb.exceptions_frequency[info.frequency] == -1 then return 'never' end
			if A.gdb.exceptions_frequency[info.frequency] == 0 then return 'ignore' end
		end

		-- 7. Classification if non-7 ("Normal")
		if info.questClassification and info.questClassification ~= A.NORMAL.class then
			if A.gdb.exceptions_class[info.questClassification] == 1 then return 'always' end
			if A.gdb.exceptions_class[info.questClassification] == -1 then return 'never' end
			if A.gdb.exceptions_class[info.questClassification] == 0 then return 'ignore' end
		end

		return 'auto'
	end

	local function auto_show_or_hide_quest(qidx)
		local info = get_questinfo(qidx)
		if info.isWQ or info.isHidden then return end

		if info.isHeader then
			header = info.title
			return
		end

		local action = get_quest_action(info, header)
		if action == 'ignore' then return end

		local show = false
		if action == 'always' then
			show = true
		elseif action == 'never' then
			show = false
		else -- auto
			if
				header == currentZone
				or header == minimapZone
				or info.isOnMap
				or info.hasLocalPOI
			then
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
