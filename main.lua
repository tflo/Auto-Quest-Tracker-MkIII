local addon_name, a = ...

AQT_GlobalDB = AQT_GlobalDB or {}
AQT_CharDB = AQT_CharDB or {}

local C_TimerAfter = _G.C_Timer.After
local InCombatLockdown, GetRealZoneText, GetMinimapZoneText = _G.InCombatLockdown, _G.GetRealZoneText, _G.GetMinimapZoneText
local C_QuestLogGetInfo, C_QuestLogIsWorldQuest, C_QuestLogGetQuestType, C_QuestLogAddQuestWatch, C_QuestLogRemoveQuestWatch, C_QuestLogGetNumQuestLogEntries, C_QuestLogGetQuestWatchType =
	_G.C_QuestLog.GetInfo,
	_G.C_QuestLog.IsWorldQuest,
	_G.C_QuestLog.GetQuestType,
	_G.C_QuestLog.AddQuestWatch,
	_G.C_QuestLog.RemoveQuestWatch,
	_G.C_QuestLog.GetNumQuestLogEntries,
	_G.C_QuestLog.GetQuestWatchType

local debug_mode, debug_mode_extra = false, true
local update_pending -- Serves as ignore flag during the DELAY_ZONE_CHANGE time
-- Colors and msgs
local C_AQT = '\124cff2196f3'
local C_GOOD = '\124cnDIM_GREEN_FONT_COLOR:'
local C_HALFBAD = '\124cnORANGE_FONT_COLOR:'
local C_BAD = '\124cnDIM_RED_FONT_COLOR:'
local MSG_PREFIX = C_AQT .. 'Auto Quest Tracker\124r: '
-- Misc
local TYPE_DUNGEON, TYPE_RAID = 81, 62
-- Serves as delay for update after zone change events and as throttle (new zone events are ignored during the time)
local DELAY_ZONE_CHANGE = 3 -- Testwise 3; we used to use 2
-- Time between logout and login needed to consider it a new session
local SESSION_GRACE_TIME = 360

-- For the modifier click on the compartment button
local is_mac = IsMacClient()

local function msg_debug(msg)
	if debug_mode or debug_mode_extra then print(MSG_PREFIX .. msg) end
end

local function msg_debug_extra(msg)
	if debug_mode_extra then print(MSG_PREFIX .. 'Debug: ' .. msg) end
end

local function msg_load(msg,delay)
	if a.gdb.loadMsg then C_TimerAfter(delay, function() print(MSG_PREFIX .. msg) end) end
end

local function msg_confirm(msg)
	print(MSG_PREFIX .. msg)
end

local function print_info_msg(msg, delay)
	if delay then
		C_TimerAfter(delay, function() print(MSG_PREFIX .. msg) end)
	else
		print(MSG_PREFIX .. msg)
	end
end

local f = CreateFrame 'Frame'
f:RegisterEvent 'ADDON_LOADED'

local function register_zone_events()
	f:RegisterEvent 'ZONE_CHANGED'
	f:RegisterEvent 'ZONE_CHANGED_NEW_AREA'
end

local function unregister_zone_events()
	f:UnregisterEvent 'ZONE_CHANGED'
	f:UnregisterEvent 'ZONE_CHANGED_NEW_AREA'
end

-- Since the addition of dungeon quest exclusions, these two functions are nearly identical
-- Merge them if you don't add additional parameters for the listing
local function get_questinfo(index)
	local quest = C_QuestLogGetInfo(index)
	return quest.title,
		quest.isHeader,
		quest.questID,
		C_QuestLogIsWorldQuest(quest.questID),
		quest.isHidden,
		C_QuestLogGetQuestType(quest.questID),
		quest.isOnMap,
		quest.hasLocalPOI
end

local function get_questinfo_for_listing(index)
	local quest = C_QuestLogGetInfo(index)
	return quest.title,
		quest.isHeader,
		quest.questID,
		C_QuestLogIsWorldQuest(quest.questID),
		quest.isHidden,
		C_QuestLog.IsQuestCalling(quest.questID),
		C_QuestLogGetQuestType(quest.questID),
		quest.isOnMap,
		quest.hasLocalPOI
end

local function show_or_hide_quest(questIndex, questId, show)
	-- Checks that the quest is still in the quest log, and that we are not in combat lockdown to avoid tainting
	local questTitle, _, id = get_questinfo(questIndex)
	if not InCombatLockdown() and id == questId then
		if show then
			msg_debug(string.format('Tracking: %s (%s)', questTitle, questId))
			C_QuestLogAddQuestWatch(questId)
		else
			msg_debug(string.format('Removing: %s (%s)', questTitle, questId))
			C_QuestLogRemoveQuestWatch(questId)
		end
	end
end


--[[---------------------------------------------------------------------------
  Core function
---------------------------------------------------------------------------]]--

local function update_quests_for_zone()
	local currentZone = GetRealZoneText()
	local minimapZone = GetMinimapZoneText()
	if currentZone == nil and minimapZone == nil then return end

	msg_debug('Updating quests for: ' .. currentZone .. ' or ' .. minimapZone)

	local questZone = nil

	for questIndex = 1, C_QuestLogGetNumQuestLogEntries() do
		local questTitle, isHeader, questId, isWorldQuest, isHidden, questType, isOnMap, hasLocalPOI =
			get_questinfo(questIndex)
		if not isWorldQuest and not isHidden and not (a.gdb.ignoreInstances and (questType == TYPE_DUNGEON or questType == TYPE_RAID)) then
			if isHeader then
				questZone = questTitle
			else
				if questZone == currentZone or questZone == minimapZone or isOnMap or hasLocalPOI then
					if C_QuestLogGetQuestWatchType(questId) == nil then
						show_or_hide_quest(questIndex, questId, true)
						msg_debug(format('Reason: %s %s %s %s', questZone == currentZone and 'currZone' or '', questZone == minimapZone and 'mmZone' or '', isOnMap and 'onMap' or '', hasLocalPOI and 'hasPOI' or ''))
					end
				elseif C_QuestLogGetQuestWatchType(questId) == 0 then
					show_or_hide_quest(questIndex, questId, false)
				end
			end
		end
	end
end


--[[---------------------------------------------------------------------------
  Doing stuff at events
---------------------------------------------------------------------------]]--

local function onEvent(self, event, ...)
	if event == 'ADDON_LOADED' then
		if ... == addon_name then
			f:UnregisterEvent 'ADDON_LOADED'
			a.gdb, a.cdb = AQT_GlobalDB, AQT_CharDB
			a.cdb.enabled = a.cdb.enabled == nil and true or a.cdb.enabled
			a.gdb.loadMsg = a.gdb.loadMsg == nil and true or a.gdb.loadMsg
			a.gdb.ignoreInstances = a.gdb.ignoreInstances or false
			if a.cdb.enabled then
				register_zone_events()
				msg_load(C_GOOD .. 'Enabled.', 8)
			else
				if not a.cdb.enable_nextsession and not a.cdb.enable_nextinstance then
					msg_load(C_BAD .. 'Disabled.', 8)
				else
					f:RegisterEvent 'PLAYER_ENTERING_WORLD'
				end
			end
		end
	elseif event == 'PLAYER_ENTERING_WORLD' then
		local is_login, is_reload = ...
		if not is_reload then
			if is_login then
				if a.cdb.enable_nextsession and time() - a.cdb.time_logout > SESSION_GRACE_TIME then
					register_zone_events()
					a.cdb.enabled = true
					a.cdb.enable_nextsession = nil
					msg_load(C_GOOD .. 'Re-enabled because of new session.', 6)
				end
			elseif a.cdb.enable_nextinstance then
				register_zone_events()
				a.cdb.enabled = true
				a.cdb.enable_nextinstance = nil
				msg_load(C_GOOD .. 'Re-enabled because of new (map) instance.', 6)
			end
		end
		if a.cdb.enable_nextsession or a.cdb.enable_nextinstance then
			msg_load(C_HALFBAD .. 'Disabled for this ' .. (a.cdb.enable_nextsession and 'session.' or 'instance.'), 6)
			if a.cdb.enable_nextsession then f:RegisterEvent 'PLAYER_LOGOUT' end
			if not a.cdb.enable_nextinstance then f:UnregisterEvent 'PLAYER_ENTERING_WORLD' end
		end
	elseif event == 'PLAYER_LOGOUT' then
		a.cdb.time_logout = time()
	else -- The ZONE events
		if update_pending then return end
		update_pending = true
		C_TimerAfter(DELAY_ZONE_CHANGE, function()
			update_quests_for_zone()
			update_pending = nil
		end)
	end
end

f:SetScript('OnEvent', onEvent)


--[[===========================================================================
  UI
===========================================================================]]--

local function msg_activation_status()
	return a.cdb.enabled and C_GOOD .. 'Enabled.' or a.cdb.enable_nextsession and C_HALFBAD .. 'Disabled for this session.' or a.cdb.enable_nextinstance and C_HALFBAD .. 'Disabled for this instance.' or C_BAD .. 'Disabled.'
end

local function msg_help()
	print(MSG_PREFIX .. 'Help: \n'.. C_AQT .. '/autoquesttracker ' .. '\124ror ' .. C_AQT .. '/aqt ' .. '\124runderstands these commands: ')
	print(C_AQT .. 'on ' .. '\124ror ' .. C_AQT .. 'e' .. '\124r: Enable AQT.')
	print(C_AQT .. 'off ' .. '\124ror ' .. C_AQT .. 'd' .. '\124r: Disable AQT for the current session.')
	print(C_AQT .. 'offi ' .. '\124ror ' .. C_AQT .. 'di' .. '\124r: Disable AQT for the current (map) instance.')
	print(C_AQT .. 'offp ' .. '\124ror ' .. C_AQT .. 'dp' .. '\124r: Disable AQT permanently.')
	print(C_AQT .. 'instances ' .. '\124ror ' .. C_AQT .. 'in' .. '\124r: Toggle auto-tracking of dungeon/raid quests.')
	print(C_AQT .. 'loadingmessage' .. '\124r: Toggle status message in chat after reload/login.')
	print(C_AQT .. 'quests ' .. '\124ror ' .. C_AQT .. 'q' .. '\124r: Show complete quest list.')
	print(C_AQT .. 'debug' .. '\124r: Toggle debug mode (resets at reload).')
	print(C_AQT .. 'help ' .. '\124ror ' .. C_AQT .. 'h' .. '\124r: Display this help text.')
	print(C_AQT .. '/aqt ' .. '\124rwithout additional commands: Display status info.')
	print('Enable/disable is per char, other settings are global.')
end


--[[---------------------------------------------------------------------------
  Main switch
---------------------------------------------------------------------------]]--

local function aqt_enable(on, disablemode)
	f:UnregisterAllEvents()
	a.cdb.enable_nextsession, a.cdb.enable_nextinstance = nil, nil
	if on then
		update_quests_for_zone()
		register_zone_events()
	else
		if not disablemode or disablemode == 1 then
			a.cdb.enable_nextsession = true
			f:RegisterEvent 'PLAYER_LOGOUT'
		elseif disablemode == 2 then
			a.cdb.enable_nextinstance = true
			f:RegisterEvent 'PLAYER_ENTERING_WORLD'
		end
	end
	a.cdb.enabled = on
	msg_confirm(msg_activation_status())
end

--[[---------------------------------------------------------------------------
  Slash commands
---------------------------------------------------------------------------]]--

SLASH_AUTOQUESTTRACKER1 = '/autoquesttracker'
SLASH_AUTOQUESTTRACKER2 = '/aqt'
SlashCmdList['AUTOQUESTTRACKER'] = function(msg)
	if msg == 'e' or msg == 'on' then
		aqt_enable(true)
	-- Disable for current session (default)
	elseif msg == 'd' or msg == 'off' then
		aqt_enable(false, nil)
	-- Permanently disable
	elseif msg == 'dp' or msg == 'offp' then
		aqt_enable(false, 0)
	-- Disable for current instance
	elseif msg == 'di' or msg == 'offi' then
		aqt_enable(false, 2)
	elseif msg == 'loadingmessage' then
		a.gdb.loadMsg = not a.gdb.loadMsg
		msg_confirm(MSG_PREFIX .. 'Loading message ' .. (a.gdb.loadMsg and 'enabled' or 'disabled') .. ' for all chars.')
	elseif msg == 'in' or msg == 'instances' then
		a.gdb.ignoreInstances = not a.gdb.ignoreInstances
		if a.cdb.enabled then update_quests_for_zone() end
		msg_confirm(
			MSG_PREFIX
				.. 'Instance quests are '
				.. (a.gdb.ignoreInstances and 'ignored' or 'treated normally')
				.. ' for all chars.'
		)
	elseif msg == 'debug' then
		debug_mode = not debug_mode
		msg_confirm(MSG_PREFIX .. 'Debug mode ' .. (debug_mode and 'enabled.' or 'disabled.'))
	elseif msg == 'q' or msg == 'quests' then
		print 'Quests currently in quest log:'
		for questIndex = 1, C_QuestLogGetNumQuestLogEntries() do
			local questTitle, isHeader, questId, isWorldQuest, isHidden, isCalling, questType, isOnMap, hasLocalPOI =
				get_questinfo_for_listing(questIndex)
			if isHeader then
				print(format('%02d| [Header] %s', questIndex, questTitle))
			else
				print(
					format(
						'%s%02d| %s%s (%s) - Type %s%s%s',
						isHidden and '|cnGRAY_FONT_COLOR:'
							or isWorldQuest and '|cnBLUE_FONT_COLOR:'
							or isCalling and '|cnDIM_GREEN_FONT_COLOR:'
							or '|cnORANGE_FONT_COLOR:',
						questIndex,
						isHidden and '[Hidden] ' or isWorldQuest and '[WQ] ' or isCalling and '[Calling] ' or '',
						questTitle,
						tostring(questId),
						tostring(questType),
						isOnMap and ', on map ' or '',
						hasLocalPOI and ', local POI' or ''
					)
				)
			end
		end
	elseif msg == 'h' or msg == 'help' then
		msg_help()
	else
		print(MSG_PREFIX
			.. 'Status: '
			.. msg_activation_status() .. '\124r'
			.. (a.gdb.ignoreInstances and ' Ignoring instance quests.' or '')
			.. '\nType ' .. C_AQT .. '/aqt help ' .. '\124ror ' .. C_AQT .. '/aqt h ' .. '\124rfor a list of commands.')
	end
end


--[[===========================================================================
API
===========================================================================]]--

function _G.addon_aqt_enable(v)
	if type(v) ~= 'boolean' then
		error("Wrong argument type. Usage: 'addon_aqt_enable(boolean)'", 0)
	else
		aqt_enable(v)
	end
end

function _G.addon_aqt_on_addoncompartment_click()
	if is_mac and IsMetaKeyDown() or not is_mac and IsControlKeyDown() then
		aqt_enable(not AQT_CharDB.enabled)
	elseif IsShiftKeyDown() then
		msg_help()
	else
		print(MSG_PREFIX .. 'Status: ' .. msg_activation_status() .. '\124r' .. (a.gdb.ignoreInstances and ' Ignoring instance quests.' or '') .. '\n\124cnYELLOW_FONT_COLOR:' .. (is_mac and 'Command-' or 'Control-') .. '\124rclick the button to toggle ' .. C_AQT .. 'AQT' .. '\124r, \124cnYELLOW_FONT_COLOR:Shift-\124rclick for a list of available slash commands.')
	end

end


--[[ License ===================================================================

	Portions: Copyright © 2022 Thomas Floeren for the added code of "Mk III" (v2.0)

	This file is part of Auto Quest Tracker Mk III.

	Auto Quest Tracker Mk III is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	Auto Quest Tracker Mk III is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
	or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
	more details.

	You should have received a copy of the GNU General Public License along with
	Auto Quest Tracker Mk III. If not, see <https://www.gnu.org/licenses/>.

==============================================================================]]
