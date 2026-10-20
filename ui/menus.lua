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

local function get_class_from_quest_id(qid)
	local info = C_QuestLog.GetInfo(hidx)
	if info then return info.questClassification end
end

local function get_qtagID_from_quest_id(qid)
	local info = C_QuestLog_GetQuestTagInfo(qid)
	if info then return info.tagID end
end

local function get_qtagName_from_quest_id(qid)
	local info = C_QuestLog_GetQuestTagInfo(qid)
	if info then return info.tagName end
end

local function get_qfrequency_from_quest_id(qid)
	local info = C_QuestLog.GetInfo(hidx)
	if info then return info.frequency end
end

---------------------------------

-- E.g. 'type', 'always', 95372
-- For headers, target is the header title, as headers have always ID 0
local function get_state(scope, exc, target)
	if scope == 'quest' then scope = 'id' end
	return A.gdb['exceptions_' .. scope][target] == A.EXCEPTION_TYPES[exc].value
end

--[[---------------------------------------------------------------------------
	Populate menu
---------------------------------------------------------------------------]]--

local function populate_quest_contextmenu(owner, root_description, context_data)
	-- C_QuestLog.RequestLoadQuestByID(qid) -- Seems we don't need this
	local framename = owner.GetName and owner:GetName()
	local object, qinfo, qid, qidx, qtitle, hidx, qheader, qtype, qclass, qfrequency, qtagID, qtagName
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
	if not qclass and qid then qclass = get_class_from_quest_id(qid) end

	if not qtagID and qid then qtagID = get_qtagID_from_quest_id(qid) end
	if not qtagName and qid then qtagName = get_qtagName_from_quest_id(qid) end

	if not qfrequency and qid then qfrequency = get_qfrequency_from_quest_id(qid) end

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
		print('qtype:', qtype)
		print('qclass:', qclass)
		print('qheader:', qheader)
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
		-- Auto
		root_description:CreateRadio(
			LABEL.single.remove,
			function()
				return not (get_state('quest', 'ignore', qid) or get_state('quest', 'always', qid) or get_state('quest', 'never', qid))
			end,
			function()
				A.add_to_exceptions('quest', 'remove', qid, qtitle)
			end
		)
		-- Ignore
		root_description:CreateRadio(
			LABEL.single.ignore,
			function()
				return get_state('quest', 'ignore', qid)
			end,
			function()
				A.add_to_exceptions('quest', 'ignore', qid, qtitle)
			end
		)
		-- Always
		root_description:CreateRadio(
			LABEL.single.always,
			function()
				return get_state('quest', 'always', qid)
			end,
			function()
				A.add_to_exceptions('quest', 'always', qid, qtitle)
			end
		)
		-- Never
		root_description:CreateRadio(
			LABEL.single.never,
			function()
				return get_state('quest', 'never', qid)
			end,
			function()
				A.add_to_exceptions('quest', 'never', qid, qtitle)
			end
		)
	end

	if qheader then
		local has_any_exception =
			get_state('header', 'ignore', qheader)
			or get_state('header', 'always', qheader)
			or get_state('header', 'never', qheader)
		local menu
		if quid_menu_is_shown then
			menu = root_description:CreateButton(format('%sThis Quest Header', has_any_exception and '! ' or ''))
		else
			menu = root_description
		end
		menu:CreateTitle(format('Quests with Header %q:', qheader or '???'))

		menu:CreateRadio(
			LABEL.single.remove,
			function()
				return not has_any_exception
			end,
			function()
				A.add_to_exceptions('header', 'remove', qheader, qheader)
			end
		)

		menu:CreateRadio(
			LABEL.single.ignore,
			function()
				return get_state('header', 'ignore', qheader)
			end,
			function()
				A.add_to_exceptions('header', 'ignore', qheader, qheader)
			end
		)

		menu:CreateRadio(
			LABEL.single.always,
			function()
				return get_state('header', 'always', qheader)
			end,
			function()
				A.add_to_exceptions('header', 'always', qheader, qheader)
			end
		)

		menu:CreateRadio(
			LABEL.single.never,
			function()
				return get_state('header', 'never', qheader)
			end,
			function()
				A.add_to_exceptions('header', 'never', qheader, qheader)
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
	Menu.ModifyMenu('MENU_QUEST_OBJECTIVE_TRACKER', populate_quest_contextmenu)
	-- Quest Log quest title
	Menu.ModifyMenu('MENU_QUEST_MAP_LOG_TITLE', populate_quest_contextmenu)
	-- Quest Log header title
	Menu.ModifyMenu('MENU_QUEST_MAP_FRAME', populate_quest_contextmenu)
end
