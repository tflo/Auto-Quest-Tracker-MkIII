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

local this_quest_id = 00000

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

local function should_show_remove()
	return true
end

local function should_show_ignore()
	return true
end

local function should_show_always()
	return true
end

local function should_show_never()
	return true
end

--[[---------------------------------------------------------------------------
	Populate menu
---------------------------------------------------------------------------]]--

local function populate_quest_context_menu(owner, root_description, context_data)
	root_description:CreateDivider()
	root_description:CreateTitle(A.MYFULLNAME)

	if should_show_single() then
		-- this_quest_id is not yet updated at this point
		-- root_description:CreateTitle(format('Actions for quest %s', this_quest_id))
		root_description:CreateTitle('Setting for quest:')

		if should_show_remove() then
			root_description:CreateButton(LABEL.single.remove, function()
				on_quest_single(this_quest_id, 'remove')
			end)
		end
		if should_show_ignore() then
			root_description:CreateButton(LABEL.single.ignore, function()
				on_quest_single(this_quest_id, 'ignore')
			end)
		end
		if should_show_always() then
			root_description:CreateButton(LABEL.single.always, function()
				on_quest_single(this_quest_id, 'always')
			end)
		end
		if should_show_never() then
			root_description:CreateButton(LABEL.single.never, function()
				on_quest_single(this_quest_id, 'never')
			end)
		end
	end

-- 	this_quest_id = nil
end

--[[---------------------------------------------------------------------------
	Hackish hooks to get the quest ID
---------------------------------------------------------------------------]]--

-- So far, the only way to get the quest ID, since `context_data` of these menus is nil

function A.initialize_hooks_for_quest_id()
	-- TRACKER
	-- Quests and Campaign quests are separate
	hooksecurefunc(QuestObjectiveTracker, "OnBlockHeaderClick", function(_, block)
		this_quest_id = block and block.id
		A.dprint('tracker: quest:', this_quest_id)
	end)
	hooksecurefunc(CampaignQuestObjectiveTracker, "OnBlockHeaderClick", function(_, block)
		this_quest_id = block and block.id
		A.dprint('tracker: campaign:', this_quest_id)
	end)

	-- QUEST LOG
	hooksecurefunc('QuestMapLogTitleButton_OnClick', function(self, btn)
		this_quest_id = self.questID
		A.dprint('log:', this_quest_id)
	end)

end

--[[---------------------------------------------------------------------------
	Register
---------------------------------------------------------------------------]]--

function A.register_menuitems()
	Menu.ModifyMenu('MENU_QUEST_OBJECTIVE_TRACKER', populate_quest_context_menu)
	Menu.ModifyMenu('MENU_QUEST_MAP_LOG_TITLE', populate_quest_context_menu)
end







-- Menu:
-- https://warcraft.wiki.gg/wiki/Patch_11.0.0/API_changes#New_menu_system
-- https://warcraft.wiki.gg/wiki/Blizzard_Menu_implementation_guide
-- https://www.townlong-yak.com/framexml/live/go/Blizzard_Menu
-- Objective Tracker
-- https://www.townlong-yak.com/framexml/live/go/Blizzard_ObjectiveTracker
-- https://www.townlong-yak.com/framexml/live/Blizzard_ObjectiveTracker/Blizzard_QuestObjectiveTracker.lua
-- Quest log:
-- https://www.townlong-yak.com/framexml/live/Blizzard_UIPanels_Game/QuestMapFrame.lua
-- https://www.townlong-yak.com/framexml/live/go/QuestLog


--[=[ -- Off code

	root_description:CreateButton(dynamic_label, function() on_toggle_status_clicked(quest_id) end)

	-- [Menu Item 3] Submenu Container with a nested child action
	local sub_menu = root_description:CreateButton('Addon: Advanced Tools')

	sub_menu:CreateButton(
		'Run Diagnostic Check',
		function() on_advanced_sub_action_clicked(quest_id) end
	)

local function on_advanced_sub_action_clicked(quest_id)
	print(string.format("[AddonUI] Advanced Sub-Action triggered for Quest ID: %s", tostring(quest_id)))
end

	-- Doesn't work:
	hooksecurefunc(ObjectiveTrackerBlockMixin, "OnHeaderClick", function(_, block)
-- 			this_quest_id = block and block.id or id
			this_quest_id = self.parentModule.id
			print('tracker: BLOCK', this_quest_id)
	end)
	hooksecurefunc(ObjectiveTrackerBlockHeaderMixin, "OnClick", function(self, btn)
-- 			this_quest_id = block and block.id or id
			this_quest_id = self:GetParent().id
			print('tracker: BLOCK', this_quest_id)
	end)

--]=]
