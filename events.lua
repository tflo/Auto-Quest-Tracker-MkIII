-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Portions: Copyright (c) 2022-2026 Thomas Floeren for the added/changed code of "Mk III" (aka version 2 and later)

local MYNAME, A = ...

--[[---------------------------------------------------------------------------
	Doing stuff at events
---------------------------------------------------------------------------]]--


local update_pending -- Ignore flag during the A.DELAY_ZONE_CHANGE time

local function on_event(_, event, ...)
	if event == 'ADDON_LOADED' then
		if ... == MYNAME then
			A.ef:UnregisterEvent 'ADDON_LOADED'
			A.gdb, A.cdb = AQT_GlobalDB, AQT_CharDB
			A.cdb.enabled = A.cdb.enabled == nil and true or A.cdb.enabled
			A.gdb.loadMsg = A.gdb.loadMsg == nil and true or A.gdb.loadMsg
			A.gdb.ignoreInstances = A.gdb.ignoreInstances or false
			A.gdb.debug_mode = A.gdb.debug_mode or false
			A.cdb.time_logout = A.cdb.time_logout or 0
			A.gdb.exceptions_id = A.gdb.exceptions_id or {}
			A.gdb.exceptions_type = A.gdb.exceptions_type or {}
			A.gdb.exceptions_header = A.gdb.exceptions_header or {}

			A.register_menuitems()

			if A.cdb.enabled then
				A.ef:register_zone_events()
				A.msg_load(A.CLR_GOOD .. 'Enabled.', 8)
			else
				if not A.cdb.enable_nextsession and not A.cdb.enable_nextinstance then
					A.msg_load(A.CLR_BAD .. 'Disabled.', 8)
				else
					A.ef:RegisterEvent 'PLAYER_ENTERING_WORLD'
				end
			end
		end
	elseif event == 'PLAYER_ENTERING_WORLD' then
		local is_login, is_reload = ...
		if not is_reload then
			if is_login then
				if A.cdb.enable_nextsession and time() - A.cdb.time_logout > A.SESSION_GRACE_TIME then
					A.ef:register_zone_events()
					A.cdb.enabled = true
					A.cdb.enable_nextsession = nil
					A.msg_load(A.CLR_GOOD .. 'Re-enabled because of new session.', 6)
				end
			-- TODO: check for instance 'world' here, as we actually only want continent changes
			elseif A.cdb.enable_nextinstance then
				A.ef:register_zone_events()
				A.cdb.enabled = true
				A.cdb.enable_nextinstance = nil
				A.msg_load(A.CLR_GOOD .. 'Re-enabled because of new (map) instance.', 6)
			end
		end
		if A.cdb.enable_nextsession or A.cdb.enable_nextinstance then
			A.msg_load(A.CLR_HALFBAD .. 'Disabled for this ' .. (A.cdb.enable_nextsession and 'session.' or 'instance.'), 6)
			if A.cdb.enable_nextsession then A.ef:RegisterEvent 'PLAYER_LOGOUT' end
			if not A.cdb.enable_nextinstance then A.ef:UnregisterEvent 'PLAYER_ENTERING_WORLD' end
		end
	elseif event == 'PLAYER_LOGOUT' then
		A.cdb.time_logout = time()
	else -- The ZONE events
		if update_pending then return end
		update_pending = true
		C_Timer.After(A.DELAY_ZONE_CHANGE, function()
			A.update_quests_for_zone()
			update_pending = nil
		end)
	end
end

A.ef = CreateFrame 'Frame'
A.ef:RegisterEvent 'ADDON_LOADED'

function A.ef:register_zone_events()
	self:RegisterEvent 'ZONE_CHANGED'
	self:RegisterEvent 'ZONE_CHANGED_NEW_AREA'
	A.dprint 'Zone events registered.'
end

-- local function unregister_zone_events()
-- 	A.ef:UnregisterEvent 'ZONE_CHANGED'
-- 	A.ef:UnregisterEvent 'ZONE_CHANGED_NEW_AREA'
-- end


A.ef:SetScript('OnEvent', on_event)

