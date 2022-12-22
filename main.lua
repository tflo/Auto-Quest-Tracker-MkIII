local addonName, a = ...

AQT_GlobalDB = AQT_GlobalDB or {}
AQT_CharDB = AQT_CharDB or {}

local debug = false
local MSG_PREFIX = '|cff2196f3Auto Quest Tracker|r: '

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

local function onEvent(self, event, addon)
	if event == 'ADDON_LOADED' then
		if addon == addonName then
			f:UnregisterEvent 'ADDON_LOADED'
			a.gdb, a.cdb = AQT_GlobalDB, AQT_CharDB
			a.cdb.enabled = a.cdb.enabled == nil and true or a.cdb.enabled
			a.gdb.loadMsg = a.gdb.loadMsg == nil and true or a.gdb.loadMsg
			if a.cdb.enabled then
				registerAllEvents()
				printLoadMsg 'Enabled'
			else
				printLoadMsg 'Disabled'
			end
		end
	else
		AQT_HandleEvent()
	end
end

SLASH_AUTOQUESTTRACKER1 = '/autoquesttracker'
SLASH_AUTOQUESTTRACKER2 = '/aqt'
SlashCmdList['AUTOQUESTTRACKER'] = function(msg)
	if msg == 'on' then
		registerAllEvents()
		print(MSG_PREFIX .. 'Enabled')
		a.cdb.enabled = true
	elseif msg == 'off' then
		unregisterAllEvents()
		print(MSG_PREFIX .. 'Disabled')
		a.cdb.enabled = false
	elseif msg == 'toggleloadingmessage' then
		a.gdb.loadMsg = not a.gdb.loadMsg
		print(MSG_PREFIX .. 'Loading message ' .. (a.gdb.loadMsg and 'enabled' or 'disabled') .. ' for all chars')
	elseif msg == 'debug' then
		debug = not debug
		print(MSG_PREFIX .. 'Debug mode ' .. (debug and 'enabled' or 'disabled'))
	elseif msg == 'quests' then
		debug = true
		AQT_PrintDebugMsg 'Quests currently in quest log:'
		for questIndex = 1, C_QuestLog.GetNumQuestLogEntries() do
			local questTitle, isHeader, questId, isWorldQuest, isHidden, isCalling, isOnMap, hasLocalPOI =
				AQT_getQuestInfo(questIndex)
			if isHidden then
				print(string.format('|cff707070[Hidden] %s (%s)', questTitle, tostring(questId)))
			elseif isHeader then
				print(string.format('[Header] %s', questTitle))
			elseif isWorldQuest then
				print(string.format('|cffC107f3[World Quest] %s (%s)', questTitle, tostring(questId)))
			elseif isCalling then
				print(
					string.format(
						'[Calling quest] %s (%s) %s/%s',
						questTitle,
						tostring(questId),
						tostring(isOnMap),
						tostring(hasLocalPOI)
					)
				)
			else
				print(string.format('|cfff2cb06%s (%s)', questTitle, tostring(questId)))
			end
		end
		debug = false
	else
		print(
			MSG_PREFIX
				.. 'Status: '
				.. (a.cdb.enabled and 'Enabled' or 'Disabled')
				.. '. Available commands are: on, off, debug, quests, toggleloadingmessage'
		)
	end
end

function AQT_PrintDebugMsg(msg)
	if debug then print(MSG_PREFIX .. msg) end
end

function AQT_HandleEvent(self, event, ...)
	-- Wait 2 seconds to reduce loading congestion.
	C_Timer.After(2, function() AQT_UpdateQuestsForZone() end)
end

function AQT_UpdateQuestsForZone()
	local currentZone = GetRealZoneText()
	local minimapZone = GetMinimapZoneText()
	if currentZone == nil and minimapZone == nil then return end

	AQT_PrintDebugMsg('Updating quests for: ' .. currentZone .. ' or ' .. minimapZone)

	local questZone = nil

	for questIndex = 1, C_QuestLog.GetNumQuestLogEntries() do
		local questTitle, isHeader, questId, isWorldQuest, isHidden, isCalling, isOnMap, hasLocalPOI =
			AQT_getQuestInfo(questIndex)

		if not isWorldQuest and not isHidden then
			if isHeader then
				questZone = questTitle
			else
				if questZone == currentZone or questZone == minimapZone or isOnMap or hasLocalPOI then
					if C_QuestLog.GetQuestWatchType(questId) == nil then
						AQT_ShowOrHideQuest(questIndex, questId, true)
					end
				elseif C_QuestLog.GetQuestWatchType(questId) == 0 then
					AQT_ShowOrHideQuest(questIndex, questId, false)
				end
			end
		end
	end
end

function AQT_ShowOrHideQuest(questIndex, questId, show)
	-- Checks that the quest is still in the quest log, and that we are not in combat lockdown to avoid tainting
	local questTitle, _, id = AQT_getQuestInfo(questIndex)
	if id == questId and not (InCombatLockdown() == 1) then
		if show then
			AQT_PrintDebugMsg(string.format('Tracking: %s (%s)', questTitle, questId))
			C_QuestLog.AddQuestWatch(questId)
		else
			AQT_PrintDebugMsg(string.format('Removing: %s (%s)', questTitle, questId))
			C_QuestLog.RemoveQuestWatch(questId)
		end
	end
end

function AQT_getQuestInfo(index)
	local quest = C_QuestLog.GetInfo(index)
	return quest.title,
		quest.isHeader,
		quest.questID,
		C_QuestLog.IsWorldQuest(quest.questID),
		quest.isHidden,
		C_QuestLog.IsQuestCalling(quest.questID),
		quest.isOnMap,
		quest.hasLocalPOI
end

f:SetScript('OnEvent', onEvent)




--[[ License ===================================================================

	Copyright © 2022 Thomas Floeren

	This file is part of AutoQuestTracker.

	AutoQuestTracker is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	AutoQuestTracker is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
	or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
	more details.

	You should have received a copy of the GNU General Public License along with
	AutoQuestTracker. If not, see <https://www.gnu.org/licenses/>.

==============================================================================]]
