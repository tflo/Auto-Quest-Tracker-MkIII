local addonName, a = ...

AQT_GlobalDB = AQT_GlobalDB or {}
AQT_CharDB = AQT_CharDB or {}

local debug = false
local MSG_PREFIX = '|cff2196f3Auto Quest Tracker|r: '
local TYPE_DUNGEON, TYPE_RAID = 81, 62

local function printLoadMsg(msg)
	if a.gdb.loadMsg then C_Timer.After(8, function() print(MSG_PREFIX .. msg) end) end
end

local f = CreateFrame 'Frame'
f:RegisterEvent 'ADDON_LOADED'

local function registerAllEvents()
	f:RegisterEvent 'ZONE_CHANGED'
	f:RegisterEvent 'ZONE_CHANGED_NEW_AREA'
end

local function unregisterAllEvents()
	f:UnregisterEvent 'ZONE_CHANGED'
	f:UnregisterEvent 'ZONE_CHANGED_NEW_AREA'
end

local function printDebugMsg(msg)
	if debug then print(MSG_PREFIX .. msg) end
end

-- Since the addition of dungeon quest exclusions, these two functions are nearly identical
-- Merge them if you don't add additional parameters for the listing
local function getQuestInfo(index)
	local quest = C_QuestLog.GetInfo(index)
	return quest.title,
		quest.isHeader,
		quest.questID,
		C_QuestLog.IsWorldQuest(quest.questID),
		quest.isHidden,
		C_QuestLog.GetQuestType(quest.questID),
		quest.isOnMap,
		quest.hasLocalPOI
end

local function getQuestInfoForListing(index)
	local quest = C_QuestLog.GetInfo(index)
	return quest.title,
		quest.isHeader,
		quest.questID,
		C_QuestLog.IsWorldQuest(quest.questID),
		quest.isHidden,
		C_QuestLog.IsQuestCalling(quest.questID),
		C_QuestLog.GetQuestType(quest.questID),
		quest.isOnMap,
		quest.hasLocalPOI
end

local function showOrHideQuest(questIndex, questId, show)
	-- Checks that the quest is still in the quest log, and that we are not in combat lockdown to avoid tainting
	local questTitle, _, id = getQuestInfo(questIndex)
	if not InCombatLockdown() and id == questId then
		if show then
			printDebugMsg(string.format('Tracking: %s (%s)', questTitle, questId))
			C_QuestLog.AddQuestWatch(questId)
		else
			printDebugMsg(string.format('Removing: %s (%s)', questTitle, questId))
			C_QuestLog.RemoveQuestWatch(questId)
		end
	end
end

local function updateQuestsForZone()
	local currentZone = GetRealZoneText()
	local minimapZone = GetMinimapZoneText()
	if currentZone == nil and minimapZone == nil then return end

	printDebugMsg('Updating quests for: ' .. currentZone .. ' or ' .. minimapZone)

	local questZone = nil

	for questIndex = 1, C_QuestLog.GetNumQuestLogEntries() do
		local questTitle, isHeader, questId, isWorldQuest, isHidden, questType, isOnMap, hasLocalPOI =
			getQuestInfo(questIndex)
		if not isWorldQuest and not isHidden and not (a.gdb.ignoreInstances and (questType == TYPE_DUNGEON or questType == TYPE_RAID)) then
			if isHeader then
				questZone = questTitle
			else
				if questZone == currentZone or questZone == minimapZone or isOnMap or hasLocalPOI then
					if C_QuestLog.GetQuestWatchType(questId) == nil then
						showOrHideQuest(questIndex, questId, true)
						printDebugMsg(format('Reason: %s %s %s %s', questZone == currentZone and 'currZone' or 'x', questZone == minimapZone and 'mmZone' or 'x', isOnMap and 'onMap' or 'x', hasLocalPOI and 'hasPOI' or 'x'))
					end
				elseif C_QuestLog.GetQuestWatchType(questId) == 0 then
					showOrHideQuest(questIndex, questId, false)
				end
			end
		end
	end
end

local function onEvent(self, event, addon)
	if event == 'ADDON_LOADED' then
		if addon == addonName then
			f:UnregisterEvent 'ADDON_LOADED'
			a.gdb, a.cdb = AQT_GlobalDB, AQT_CharDB
			a.cdb.enabled = a.cdb.enabled == nil and true or a.cdb.enabled
			a.gdb.loadMsg = a.gdb.loadMsg == nil and true or a.gdb.loadMsg
			a.gdb.ignoreInstances = a.gdb.ignoreInstances or false
			if a.cdb.enabled then
				registerAllEvents()
				printLoadMsg 'Enabled'
			else
				printLoadMsg 'Disabled'
			end
		end
	else
		C_Timer.After(2, updateQuestsForZone)
	end
end

local function aqt_enable(on)
	if on then
		updateQuestsForZone()
		registerAllEvents()
	else
		unregisterAllEvents()
	end
	a.cdb.enabled = on
	print(MSG_PREFIX .. (a.cdb.enabled and 'Enabled' or 'Disabled'))
end


SLASH_AUTOQUESTTRACKER1 = '/autoquesttracker'
SLASH_AUTOQUESTTRACKER2 = '/aqt'
SlashCmdList['AUTOQUESTTRACKER'] = function(msg)
	if msg == 'e' or msg == 'on' then
		aqt_enable(true)
	elseif msg == 'd' or msg == 'off' then
		aqt_enable(false)
	elseif msg == 'lm' or msg == 'loadingmessage' then
		a.gdb.loadMsg = not a.gdb.loadMsg
		print(MSG_PREFIX .. 'Loading message ' .. (a.gdb.loadMsg and 'enabled' or 'disabled') .. ' for all chars')
	elseif msg == 'in' or msg == 'instances' then
		a.gdb.ignoreInstances = not a.gdb.ignoreInstances
		if a.cdb.enabled then updateQuestsForZone() end
		print(
			MSG_PREFIX
				.. 'Instance quests are '
				.. (a.gdb.ignoreInstances and 'ignored' or 'treated normally')
				.. ' for all chars'
		)
	elseif msg == 'db' or msg == 'debug' then
		debug = not debug
		print(MSG_PREFIX .. 'Debug mode ' .. (debug and 'enabled' or 'disabled'))
	elseif msg == 'q' or msg == 'quests' then
		print 'Quests currently in quest log:'
		for questIndex = 1, C_QuestLog.GetNumQuestLogEntries() do
			local questTitle, isHeader, questId, isWorldQuest, isHidden, isCalling, questType, isOnMap, hasLocalPOI =
				getQuestInfoForListing(questIndex)
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
	else
		print(
			MSG_PREFIX
				.. 'Status: '
				.. (a.cdb.enabled and 'Enabled' or 'Disabled')
				.. (a.gdb.ignoreInstances and '; ignoring instance quests' or '')
				.. '. Available commands are: e or on (enable), d or off (disable), in or instances (toggle ignore instance quests), q or quests (quest list), lm or loadingmessage (toggle loading message), db or debug (toggle debug mode)'
		)
	end
end


f:SetScript('OnEvent', onEvent)

-- API

function _G.addon_aqt_enable(v)
	if type(v) ~= 'boolean' then
		error("Wrong argument type. Usage: 'addon_aqt_enable(boolean)'", 0)
	else
		aqt_enable(v)
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
