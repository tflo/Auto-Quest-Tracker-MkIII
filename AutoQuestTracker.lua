local AutoQuestTrackerFrame = CreateFrame("Frame")

AutoQuestTrackerFrame:RegisterEvent("ZONE_CHANGED")
AutoQuestTrackerFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

local debug = false
local AQT_MESSAGE_PREFIX = "|cff2196f3Auto Quest Tracker: |r"

SLASH_AUTOQUESTTRACKER1 = "/autoquesttracker"
SLASH_AUTOQUESTTRACKER2 = "/aqt"
SlashCmdList["AUTOQUESTTRACKER"] = function(msg)
	if msg == "debug" then
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
		print(AQT_MESSAGE_PREFIX .. "Command not recognized. Available commands are: debug, quests")
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

AutoQuestTrackerFrame:SetScript("OnEvent", AQT_HandleEvent)