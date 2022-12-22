local addon_name, a = ...

aqt_global_db = aqt_global_db or {}
aqt_char_db = aqt_char_db or {}

local debug = false
local AQT_MESSAGE_PREFIX = "|cff2196f3Auto Quest Tracker|r: "

local function print_loadmsg(msg)
	if a.gdb.loadmsg then C_Timer.After(8, function() print(AQT_MESSAGE_PREFIX .. msg) end) end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")

local function register_all_events()
	f:RegisterEvent("ZONE_CHANGED")
	f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

local function unregister_all_events()
	f:UnregisterEvent("ZONE_CHANGED")
	f:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
end

local function on_event(self, event, addon)
	if event == "ADDON_LOADED" then
		if addon == addon_name then
			f:UnregisterEvent("ADDON_LOADED")
			a.gdb, a.cdb = aqt_global_db, aqt_char_db
			a.cdb.enabled = a.cdb.enabled == nil and true or a.cdb.enabled
			a.gdb.loadmsg = a.gdb.loadmsg == nil and true or a.gdb.loadmsg
			if a.cdb.enabled then
				register_all_events()
				print_loadmsg('Enabled')
			else
				print_loadmsg('Disabled')
			end
		end
	else
		AQT_HandleEvent()
	end
end


SLASH_AUTOQUESTTRACKER1 = "/autoquesttracker"
SLASH_AUTOQUESTTRACKER2 = "/aqt"
SlashCmdList["AUTOQUESTTRACKER"] = function(msg)
	if msg == "on" then
		register_all_events()
		print(AQT_MESSAGE_PREFIX .. "Enabled")
		a.cdb.enabled = true
	elseif msg == "off" then
		unregister_all_events()
		print(AQT_MESSAGE_PREFIX .. "Disabled")
		a.cdb.enabled = false
	elseif msg == "toggleloadingmessage" then
		a.gdb.loadmsg = not a.gdb.loadmsg
		print(AQT_MESSAGE_PREFIX .. "Loading message " .. (a.gdb.loadmsg and "enabled" or "disabled") .. " for all chars")
	elseif msg == "debug" then
		debug = not debug
		print(AQT_MESSAGE_PREFIX .. "Debug mode " .. (debug and "enabled" or "disabled"))
	elseif msg == "quests" then
		debug = true
		AQT_PrintDebugMsg("Quests currently in quest log:")
		for questIndex = 1, C_QuestLog.GetNumQuestLogEntries() do
			local questTitle, isHeader, questId, isWorldQuest, isHidden, isCalling, isOnMap, hasLocalPOI = AQT_getQuestInfo(questIndex)
			if isHidden then
				print(string.format("|cff707070[Hidden] %s (%s)", questTitle, tostring(questId)))
			elseif isHeader then
				print(string.format("[Header] %s", questTitle))
			elseif isWorldQuest then
				print(string.format("|cffC107f3[Wolrd Quest] %s (%s)", questTitle, tostring(questId)))
			elseif isCalling then
				print(string.format("[Calling quest] %s (%s) %s/%s", questTitle, tostring(questId), tostring(isOnMap), tostring(hasLocalPOI)))
			else
				print(string.format("|cfff2cb06%s (%s)", questTitle, tostring(questId)))
			end
		end
		debug = false
	else
		print(AQT_MESSAGE_PREFIX .. "Status: " .. (a.cdb.enabled and "Enabled" or "Disabled") .. ". Available commands are: on, off, debug, quests, toggleloadingmessage")
	end
end

function AQT_PrintDebugMsg(msg)
	if debug then
		print(AQT_MESSAGE_PREFIX .. msg);
	end
end

function AQT_HandleEvent(self, event, ...)
	-- Wait 2 seconds to reduce loading congestion.
	C_Timer.After(2, function() AQT_UpdateQuestsForZone() end)
end

function AQT_UpdateQuestsForZone()
	local currentZone = GetRealZoneText()
	local minimapZone = GetMinimapZoneText()
	if currentZone == nil and minimapZone == nil then
		return
	end


	AQT_PrintDebugMsg("Updating quests for: " .. currentZone .. " or " .. minimapZone)

	local questZone = nil

	for questIndex = 1, C_QuestLog.GetNumQuestLogEntries() do
		local questTitle, isHeader, questId, isWorldQuest, isHidden, isCalling, isOnMap, hasLocalPOI = AQT_getQuestInfo(questIndex)

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
			AQT_PrintDebugMsg(string.format("Tracking: %s (%s)", questTitle, questId))
			C_QuestLog.AddQuestWatch(questId)
		else
			AQT_PrintDebugMsg(string.format("Removing: %s (%s)", questTitle, questId))
			C_QuestLog.RemoveQuestWatch(questId)
		end
	end
end

-- Returns:
--   Quest Title
--   Whether it's a zone header in the quest log
--	 Quest Id
--	 Whether the quest is a world quest
--	 Whether the quest is hidden in the quest log
--   Whether the quest is a calling quest
--	 Whether the quest is on the map
--	 Whether the quest has a local point of interest
function AQT_getQuestInfo(index)
	local quest = C_QuestLog.GetInfo(index)
	return quest.title, quest.isHeader, quest.questID, C_QuestLog.IsWorldQuest(quest.questID), quest.isHidden, C_QuestLog.IsQuestCalling(quest.questID), quest.isOnMap, quest.hasLocalPOI
end

f:SetScript("OnEvent", on_event)




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
