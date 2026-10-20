-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Portions: Copyright (c) 2022-2026 Thomas Floeren for the added/changed code of "Mk III" (aka version 2 and later)

local MYNAME, A = ...
local CLR = A.CLR

--[[===========================================================================
	Context menu for tracker and log
===========================================================================]]--

local LABEL = {
	remove = 'Auto Track',
	ignore = 'Ignore',
	always = 'Always Track',
	never = 'Never Track',
}

-- local LABEL = {
-- 	single = {
-- 		remove = 'Auto Track',
-- 		ignore = 'Ignore',
-- 		always = 'Always Track',
-- 		never = 'Never Track',
-- 	},
-- 	type = { -- NYI
-- 		remove = 'Auto track %s quests',
-- 		ignore = 'Ignore all %s quests',
-- 		always = 'Always track %s quests',
-- 		never = 'Never track %s quests',
-- 	},
-- 	header = { -- NYI
-- 		remove = 'Auto track %q quests',
-- 		ignore = 'Ignore %q quests',
-- 		always = 'Always track %q quests',
-- 		never = 'Never track %q quests',
-- 	},
-- 	-- We should remove quest groups entirely, as the hardcoding is maintenance-intensive
-- 	group = { -- NYI
-- 	},
-- }

--[[---------------------------------------------------------------------------
	Helpers for data
---------------------------------------------------------------------------]]--

local function get_header_from_quest_id(qid)
	local hidx = C_QuestLog.GetHeaderIndexForQuest(qid)
	local info = C_QuestLog.GetInfo(hidx)
	if info and info.isHeader then return info.title end
end

local function get_header_from_quest_idx(qidx)
	for idx = qidx, 1, -1 do
		local info = C_QuestLog.GetInfo(idx)
		if info and info.isHeader then return info.title end
	end
end

local function get_header_from_header_idx(hidx)
	local info = C_QuestLog.GetInfo(hidx)
	if info and info.isHeader then return info.title end
end

local function get_type_from_quest_id(qid)
	return C_QuestLog.GetQuestType(qid)
end

local function get_class_from_quest_idx(qidx)
	local info = C_QuestLog.GetInfo(qidx)
	if info then return info.questClassification end
end

local function get_class_from_quest_id(qid)
	return C_QuestInfoSystem.GetQuestClassification(qid)
end

local function get_qtagID_from_quest_id(qid)
	local info = C_QuestLog.GetQuestTagInfo(qid)
	if info then return info.tagID end
end

local function get_qtagName_from_quest_id(qid)
	local info = C_QuestLog.GetQuestTagInfo(qid)
	if info then return info.tagName end
end

local function get_qfrequency_from_quest_idx(qidx)
	local info = C_QuestLog.GetInfo(qidx)
	if info then return info.frequency end
end

---------------------------------

-- E.g. 'type', 'always', 95372
-- For headers, target is the header title, as headers have always ID 0
local function get_state(scope, exc, target)
	if scope == 'quest' then scope = 'id' end
	return A.gdb['exceptions_' .. scope][target] == A.EXCEPTION_TYPES[exc].value
end

local function get_all_states(scope, target)
	local ignore = get_state(scope, 'ignore', target)
	local always = get_state(scope, 'always', target)
	local never = get_state(scope, 'never', target)
	local auto = not(ignore or always or never)
	return { auto=auto, ignore=ignore, always=always, never=never }
end

--[[---------------------------------------------------------------------------
	Populate menu
---------------------------------------------------------------------------]]--

local function populate_quest_contextmenu(owner, root_description, context_data)
	-- C_QuestLog.RequestLoadQuestByID(qid) -- Seems we don't need this
	local framename = owner.GetName and owner:GetName()
	local object, qinfo, qid, qidx, qtitle, hidx, qheader, qtype, qclass, qfrequency, qtag, qtagName
	local quid_menu_is_shown

	-- First, leverage the available data from the object itself
	if framename == 'ObjectiveTrackerFrame' then -- Tracker quest title
		object = 'tracker'
		qinfo = GetMouseFoci()[1]:GetParent()
		qid = qinfo.id
	elseif not framename and type(owner.info) == 'table' then -- Quest Log quest title
		object = 'log'
		qinfo = owner.info
		qid = qinfo.questID
		qidx = qinfo.questLogIndex
		qtitle = qinfo.title
		qheader = qinfo.header.title
		qtype = qinfo.type
		qclass = qinfo.questClassification
		qfrequency = qinfo.frequency
	elseif not framename and owner.questLogIndex then -- Quest Log header
		object = 'header'
		hidx = owner.questLogIndex
	end

	-- Get missing data
	if not qidx and qid then qidx = C_QuestLog.GetLogIndexForQuestID(qid) end

	if not qid and qidx then qid = C_QuestLog.GetQuestIDForLogIndex(qidx) end

	if not qtitle and qidx then qtitle = C_QuestLog.GetTitleForLogIndex(qidx) end
	if not qtitle and qid then qtitle = C_QuestLog.GetTitleForQuestID(qidx) end

	if not qheader and qid then qheader = get_header_from_quest_id(qid) end
	if not qheader and qidx then qheader = get_header_from_quest_idx(qidx) end
	if not qheader and hidx then qheader = get_header_from_header_idx(hidx) end

	if not qtype and qid then qtype = get_type_from_quest_id(qid) end

	if not qclass and qidx then qclass = get_class_from_quest_idx(qidx) end
	if not qclass and qid then qclass = get_class_from_quest_id(qid) end

	if not qtag and qid then qtag = get_qtagID_from_quest_id(qid) end

	if not qfrequency and qidx then qfrequency = get_qfrequency_from_quest_idx(qidx) end

	-- Get type
	if qid then
		local taginfo = C_QuestLog.GetQuestTagInfo(qid)
		local qtype_name
		if taginfo then
			qtype = qtype or taginfo.tagID
			qtype_name = taginfo.tagName
		end
	end

	if A.gdb.debug_mode then
		-- Trying to find out if the different ID sources always deliver the same ID
		if object == 'tracker' then
			local poi_qid = qinfo.poiQuestID -- poi ID == quest ID ?
			if qid ~= poi_qid then
				A.dprint(0, 'Tracker ‹qid› ~= ‹poiQuestID›!', qid, poi_qid)
				PlaySoundFile(2924351)
			end
		elseif object == 'log' then
			local entry_qid = owner.questID -- alternative ID source from top-level owner
			if qid ~= entry_qid then
				A.dprint(0, 'Log ‹qid› ~= ‹owner.questID›!', qid, entry_qid)
				PlaySoundFile(2924351)
			end
		end
		print('framename:', framename)
		print('qid:', qid)
		print('qtitle:', qtitle)
		print('qheader:', qheader)
		print('qtype:', qtype)
		print('qclass:', qclass)
		print('qtag:', qtag)
		print('qtagName:', qtagName)
		print('qfrequency:', qfrequency)
		print('context_data:', context_data)
		if IsMetaKeyDown() then A.tabledump_first(GetMouseFoci()[1]:GetParent().HeaderText) end
		if IsAltKeyDown() then A.tabledump_first(owner.ButtonText) end
		if IsControlKeyDown() then A.DTD(owner:SetHeaderText()) end
	end

	if qid or qheader then
		root_description:CreateDivider()
		root_description:CreateTitle(A.MYFULLNAME)
	end

	if qid then
		quid_menu_is_shown = true
		root_description:CreateTitle(format('Tracking for Quest ID %s:', qid or '???'))
		local state = get_all_states('quest', qid)
		-- Auto
		root_description:CreateRadio(
			LABEL.remove,
			function()
				return state.auto
			end,
			function()
				A.add_to_exceptions('quest', 'remove', qid, qtitle)
			end
		)
		-- Ignore
		root_description:CreateRadio(
			LABEL.ignore,
			function()
				return state.ignore
			end,
			function()
				A.add_to_exceptions('quest', 'ignore', qid, qtitle)
			end
		)
		-- Always
		root_description:CreateRadio(
			LABEL.always,
			function()
				return state.always
			end,
			function()
				A.add_to_exceptions('quest', 'always', qid, qtitle)
			end
		)
		-- Never
		root_description:CreateRadio(
			LABEL.never,
			function()
				return state.never
			end,
			function()
				A.add_to_exceptions('quest', 'never', qid, qtitle)
			end
		)
	end

	if qheader then
		local menu
		local state = get_all_states('header', qheader)
		-- The first menu is in any case either the quest ID or the header menu, depending on
		-- what is clicked.
		-- So the header menu is either the 1st one (expanded), or the first *sub* menu.
		-- All subsequent menus are always sub menus.
		if quid_menu_is_shown then
			menu = root_description:CreateButton(format('%sThis Quest Header', not state.auto and '! ' or ''))
		else
			menu = root_description
		end
		menu:CreateTitle(format('Quests with Header %q:', qheader or '???'))

		-- Header
		menu:CreateRadio(
			LABEL.remove,
			function()
				return state.auto
			end,
			function()
				A.add_to_exceptions('header', 'remove', qheader, qheader)
			end
		)
		menu:CreateRadio(
			LABEL.ignore,
			function()
				return state.ignore
			end,
			function()
				A.add_to_exceptions('header', 'ignore', qheader, qheader)
			end
		)
		menu:CreateRadio(
			LABEL.always,
			function()
				return state.always
			end,
			function()
				A.add_to_exceptions('header', 'always', qheader, qheader)
			end
		)
		menu:CreateRadio(
			LABEL.never,
			function()
				return state.never
			end,
			function()
				A.add_to_exceptions('header', 'never', qheader, qheader)
			end
		)
	end

	-- Menu is always submenu from here on

	if qtype and qtype ~= A.NORMAL.type then -- By type
		local state = get_all_states('type', qtype)
		local menu = root_description:CreateButton(format('%sThis Quest Type', not state.auto and '! ' or ''))
		local qtype_name = A.QUEST_TYPE_NAMES[qtype]
		menu:CreateTitle(format('Tracking for Type %s %q:', qtype or '???', qtype_name or '???'))

		-- Type
		menu:CreateRadio(
			LABEL.remove,
			function()
				return state.auto
			end,
			function()
				A.add_to_exceptions('type', 'remove', qtype, nil)
			end
		)
		menu:CreateRadio(
			LABEL.ignore,
			function()
				return state.ignore
			end,
			function()
				A.add_to_exceptions('type', 'ignore', qtype, nil)
			end
		)
		menu:CreateRadio(
			LABEL.always,
			function()
				return state.always
			end,
			function()
				A.add_to_exceptions('type', 'always', qtype, nil)
			end
		)
		menu:CreateRadio(
			LABEL.never,
			function()
				return state.never
			end,
			function()
				A.add_to_exceptions('type', 'never', qtype, nil)
			end
		)
	end

	if qtag and qtag ~= A.NORMAL.class then
		local state = get_all_states('tag', qtag)
		local menu = root_description:CreateButton(format('%sThis Quest Tag', not state.auto and '! ' or ''))
		local qtag_name = get_qtagName_from_quest_id(qid)
		menu:CreateTitle(format('Tracking for Tag %s %q:', qtag or '???', qtag_name or '???'))

		-- Tag
		menu:CreateRadio(
			LABEL.remove,
			function()
				return state.auto
			end,
			function()
				A.add_to_exceptions('tag', 'remove', qtag, qtag_name)
			end
		)
		menu:CreateRadio(
			LABEL.ignore,
			function()
				return state.ignore
			end,
			function()
				A.add_to_exceptions('tag', 'ignore', qtag, qtag_name)
			end
		)
		menu:CreateRadio(
			LABEL.always,
			function()
				return state.always
			end,
			function()
				A.add_to_exceptions('tag', 'always', qtag, qtag_name)
			end
		)
		menu:CreateRadio(
			LABEL.never,
			function()
				return state.never
			end,
			function()
				A.add_to_exceptions('tag', 'never', qtag, qtag_name)
			end
		)
	end

	if qfrequency and qfrequency ~= A.NORMAL.frequency then
		local state = get_all_states('frequency', qfrequency)
		local menu = root_description:CreateButton(format('%sThis Quest Frequency', not state.auto and '! ' or ''))
		local qfrequency_name = tInvert(Enum.QuestFrequency)[qfrequency]
		menu:CreateTitle(format('Tracking for Frequency %s %q:', qfrequency or '???', qfrequency_name or '???'))

		-- Tag
		menu:CreateRadio(
			LABEL.remove,
			function()
				return state.auto
			end,
			function()
				A.add_to_exceptions('frequency', 'remove', qfrequency, qfrequency_name)
			end
		)
		menu:CreateRadio(
			LABEL.ignore,
			function()
				return state.ignore
			end,
			function()
				A.add_to_exceptions('frequency', 'ignore', qfrequency, qfrequency_name)
			end
		)
		menu:CreateRadio(
			LABEL.always,
			function()
				return state.always
			end,
			function()
				A.add_to_exceptions('frequency', 'always', qfrequency, qfrequency_name)
			end
		)
		menu:CreateRadio(
			LABEL.never,
			function()
				return state.never
			end,
			function()
				A.add_to_exceptions('frequency', 'never', qfrequency, qfrequency_name)
			end
		)
	end

	if qclass and qclass ~= A.NORMAL.class then
		local state = get_all_states('class', qclass)
		local menu = root_description:CreateButton(format('%sThis Quest Class', not state.auto and '! ' or ''))
		local qclass_name = tInvert(Enum.QuestClassification)[qclass]
		menu:CreateTitle(format('Tracking for Class %s %q:', qclass or '???', qclass_name or '???'))

		-- Class
		menu:CreateRadio(
			LABEL.remove,
			function()
				return state.auto
			end,
			function()
				A.add_to_exceptions('class', 'remove', qclass, qclass_name)
			end
		)
		menu:CreateRadio(
			LABEL.ignore,
			function()
				return state.ignore
			end,
			function()
				A.add_to_exceptions('class', 'ignore', qclass, qclass_name)
			end
		)
		menu:CreateRadio(
			LABEL.always,
			function()
				return state.always
			end,
			function()
				A.add_to_exceptions('class', 'always', qclass, qclass_name)
			end
		)
		menu:CreateRadio(
			LABEL.never,
			function()
				return state.never
			end,
			function()
				A.add_to_exceptions('class', 'never', qclass, qclass_name)
			end
		)
	end


end

--[[---------------------------------------------------------------------------
	Register
---------------------------------------------------------------------------]]--

function A.register_menuitems()
	-- Tracker quest title
	Menu.ModifyMenu('MENU_QUEST_OBJECTIVE_TRACKER', populate_quest_contextmenu)
	-- Quest Log quest title
	Menu.ModifyMenu('MENU_QUEST_MAP_LOG_TITLE', populate_quest_contextmenu)
	-- Quest Log header title
	Menu.ModifyMenu('MENU_QUEST_MAP_FRAME', populate_quest_contextmenu)
end
