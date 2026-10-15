-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Portions: Copyright (c) 2022-2026 Thomas Floeren for the added/changed code of "Mk III" (aka version 2 and later)

local MYNAME, A = ...
local CLR = A.CLR

--[[===========================================================================
	Context menu for tracker and log
===========================================================================]]--

-- Context menu in quest log: MENU_QUEST_MAP_LOG_TITLE
-- Context menu in objective tracker: MENU_QUEST_OBJECTIVE_TRACKER

local LABEL = {
	single = {
		remove = 'Auto Track',
		ignore = 'Ignore',
		always = 'Always Track',
		never = 'Never Track',
	},
	type = { -- NYI
		remove = 'Auto track %s quests',
		ignore = 'Ignore all %s quests',
		always = 'Always track %s quests',
		never = 'Never track %s quests',
	},
	header = { -- NYI
		remove = 'Auto track %q quests',
		ignore = 'Ignore %q quests',
		always = 'Always track %q quests',
		never = 'Never track %q quests',
	},
	-- We should remove quest groups entirely, as the hardcoding is maintenance-intensive
	group = { -- NYI
	},
}

--[[---------------------------------------------------------------------------
	Handlers for always, never, ignore
---------------------------------------------------------------------------]]--

-- local function should_show_feature_x()
-- 	return true
-- end

local function on_qid(id, exception)
	A.add_quest_to_exceptions(id, A.EXCEPTION_TYPES[exception].value)
end

-- TODO: add group action
-- TODO: add header action

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

--[[---------------------------------------------------------------------------
	Menu item visibility
---------------------------------------------------------------------------]]--

local function should_show_qid_menu()
-- 	return not not qid
-- 	return  qid
	return  true
end

local function should_show_header_menu()
-- 	return not not qheader
-- 	return qheader
	return true
end

local function should_show_type_menu()
-- 	return not not qtype and not not qtype_name
	return  qtype and  qtype_name
end

local function should_show_class_menu() -- NYI
	return false
end

local function should_show_group_menu() -- NYI
	return false
end

---------------------------------

local function is_ignore(id) return A.gdb.exceptions_id[id] == 0 end
local function is_always(id) return A.gdb.exceptions_id[id] == 1 end
local function is_never(id) return A.gdb.exceptions_id[id] == -1 end

--[[---------------------------------------------------------------------------
	Populate menu
---------------------------------------------------------------------------]]--

local function populate_quest_context_menu(owner, root_description, context_data)
	-- C_QuestLog.RequestLoadQuestByID(qid) -- Seems we don't need this
	local framename = owner.GetName and owner:GetName()
	local object, qinfo, qid, qidx, hidx, qheader, qtype, qclass

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
		qheader = qinfo.header.title
		qtype = qinfo.type -- not really useful; we want C_QuestLog.GetQuestTagInfo
		qclass = qinfo.questClassification
	elseif not framename and owner.questLogIndex then -- Quest Log header
		object = 'header'
		hidx = owner.questLogIndex
	end

	-- Get missing data
	if not qidx and qid then qidx = C_QuestLog.GetLogIndexForQuestID(qid) end
	if not qid and qidx then qid = C_QuestLog.GetQuestIDForLogIndex(qidx) end
	if not qheader and qid then qheader = get_header_from_quest_id(qid) end
	if not qheader and qidx then qheader = get_header_from_quest_idx(qidx) end
	if not qheader and hidx then qheader = get_header_from_header_idx(hidx) end
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
		print('framename', framename)
		print('qid', qid)
		print('qtype:', qtype)
		print('qclass:', qclass)
		print('qheader:', qheader)
		print('context_data:', context_data)
		if IsMetaKeyDown() then A.tabledump_first(GetMouseFoci()[1]:GetParent().HeaderText) end
		if IsAltKeyDown() then A.tabledump_first(owner.ButtonText) end
		if IsControlKeyDown() then A.DTD(owner:SetHeaderText()) end
	end

-- 	if should_show_qid_menu()
-- 		or should_show_header_menu()
	if qid or qheader then
		root_description:CreateDivider()
		root_description:CreateTitle(A.MYFULLNAME)
	end

	if qid then
		root_description:CreateTitle(format('Tracking for Quest ID %s:', qid or '???'))
		-- Auto
		root_description:CreateRadio(
			LABEL.single.remove,
			function()
				return not(is_ignore(qid) or is_always(qid) or is_never(qid))
			end,
			function()
				on_qid(qid, 'remove')
			end
		)
		-- Ignore
		root_description:CreateRadio(
			LABEL.single.ignore,
			function()
				return is_ignore(qid)
			end,
			function()
				on_qid(qid, 'ignore')
			end
		)
		-- Always
		root_description:CreateRadio(
			LABEL.single.always,
			function()
				return is_always(qid)
			end,
			function()
				on_qid(qid, 'always')
			end
		)
		-- Never
		root_description:CreateRadio(
			LABEL.single.never,
			function()
				return is_never(qid)
			end,
			function()
				on_qid(qid, 'never')
			end
		)
	end

	if qheader then
		local menu
		if qid then
			menu = root_description:CreateButton('This Quest Header')
			menu:CreateTitle(format('Tracking for Header %q:', qheader or '???'))
		else
			menu = root_description
			menu:CreateTitle(format('Tracking for Header %q:', qheader or '???'))
		end

		menu:CreateRadio(
			LABEL.single.remove,
			function()
				return not(is_ignore(qid) or is_always(qid) or is_never(qid))
			end,
			function()
				--on_qid(qid, 'remove')
			end
		)

		menu:CreateRadio(
			LABEL.single.ignore,
			function()
				return is_ignore(qid)
			end,
			function()
				--on_qid(qid, 'ignore')
			end
		)

		menu:CreateRadio(
			LABEL.single.always,
			function()
				return is_always(qid)
			end,
			function()
				--on_qid(qid, 'always')
			end
		)

		menu:CreateRadio(
			LABEL.single.never,
			function()
				return is_never(qid)
			end,
			function()
				--on_qid(qid, 'never')
			end
		)
	end

	if false then -- By type
		local submenu = root_description:CreateButton('This Quest Type')

-- 		local qtype_name =
		submenu:CreateTitle(format('Tracking for Type %s %q:', qtype or '???', qtype_name or '???'))
		submenu:CreateRadio(
			LABEL.single.remove,
			function()
				return not(is_ignore(qid) or is_always(qid) or is_never(qid))
			end,
			function()
				--on_qid(qid, 'remove')
			end
		)

		submenu:CreateRadio(
			LABEL.single.ignore,
			function()
				return is_ignore(qid)
			end,
			function()
				--on_qid(qid, 'ignore')
			end
		)

		submenu:CreateRadio(
			LABEL.single.always,
			function()
				return is_always(qid)
			end,
			function()
				--on_qid(qid, 'always')
			end
		)

		submenu:CreateRadio(
			LABEL.single.never,
			function()
				return is_never(qid)
			end,
			function()
				--on_qid(qid, 'never')
			end
		)
	end

	if false then
		local submenu = root_description:CreateButton('This Quest Class')

		qclass = qclass or C_QuestInfoSystem.GetQuestClassification(qid)
		local qclass_name = tInvert(Enum.QuestClassification)[qclass]

		submenu:CreateTitle(format('Tracking for Class %s %q:', qclass or '???', qclass_name or '???'))
		submenu:CreateRadio(
			LABEL.single.remove,
			function()
				return not(is_ignore(qid) or is_always(qid) or is_never(qid))
			end,
			function()
				--on_qid(qid, 'remove')
			end
		)

		submenu:CreateRadio(
			LABEL.single.ignore,
			function()
				return is_ignore(qid)
			end,
			function()
				--on_qid(qid, 'ignore')
			end
		)

		submenu:CreateRadio(
			LABEL.single.always,
			function()
				return is_always(qid)
			end,
			function()
				--on_qid(qid, 'always')
			end
		)

		submenu:CreateRadio(
			LABEL.single.never,
			function()
				return is_never(qid)
			end,
			function()
				--on_qid(qid, 'never')
			end
		)
	end


end

--[[---------------------------------------------------------------------------
	Register
---------------------------------------------------------------------------]]--

function A.register_menuitems()
	-- Tracker quest title
	Menu.ModifyMenu('MENU_QUEST_OBJECTIVE_TRACKER', populate_quest_context_menu)
	-- Quest Log quest title
	Menu.ModifyMenu('MENU_QUEST_MAP_LOG_TITLE', populate_quest_context_menu)
	-- Quest Log header title
	Menu.ModifyMenu('MENU_QUEST_MAP_FRAME', populate_quest_context_menu)
end
