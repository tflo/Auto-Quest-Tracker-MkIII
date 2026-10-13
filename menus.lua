-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Portions: Copyright (c) 2022-2026 Thomas Floeren for the added/changed code of "Mk III" (aka version 2 and later)

local MYNAME, A = ...

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

local function on_quest_single(id, exception)
	A.add_quest_to_exceptions(id, A.EXCEPTION_TYPES[exception].value)
end

-- TODO: add group action
-- TODO: add header action

--[[---------------------------------------------------------------------------
	Menu item visibility
---------------------------------------------------------------------------]]--

local function should_show_single()
	return true
end

local function should_show_type() -- NYI
	return true
end

local function should_show_header() -- NYI
	return true
end

local function should_show_group() -- NYI
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
	print 'context:'; dtd(context_data) --debug
	root_description:CreateDivider()
	root_description:CreateTitle(A.MYFULLNAME)

	if should_show_single() then
		-- this_quest_id is not yet updated at this point
		-- root_description:CreateTitle(format('Actions for quest %s', this_quest_id))
		local focus = GetMouseFoci()[1]
-- 		local quest_id = focus.questID or focus:GetParent().id -- log, tracker
		local quest_id = owner.questID or focus:GetParent().id -- log, tracker
		local header = owner.info and owner.info.header.title -- log only
		print('header:', header) --debug
		if IsAltKeyDown() then dtd(GetMouseFoci()) end
		local title = root_description:CreateTitle(format('Setting for quest %s:', quest_id or '???'))
-- 		dtd(owner:GetName().block)

		root_description:CreateRadio(
			LABEL.single.remove,
			function()
				return not(is_ignore(quest_id) or is_always(quest_id) or is_never(quest_id))
			end,
			function()
				on_quest_single(quest_id, 'remove')
			end
		)

		root_description:CreateRadio(
			LABEL.single.ignore,
			function()
				return is_ignore(quest_id)
			end,
			function()
				on_quest_single(quest_id, 'ignore')
			end
		)

		root_description:CreateRadio(
			LABEL.single.always,
			function()
				return is_always(quest_id)
			end,
			function()
				on_quest_single(quest_id, 'always')
			end
		)

		root_description:CreateRadio(
			LABEL.single.never,
			function()
				return is_never(quest_id)
			end,
			function()
				on_quest_single(quest_id, 'never')
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
