-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Portions: Copyright (c) 2022-2026 Thomas Floeren for the added/changed code of "Mk III" (aka version 2 and later)

local MYNAME, A = ...
local CLR = A.CLR

local ef = CreateFrame('Frame', MYNAME .. '_eventframe')

--[[===========================================================================
	Helpers
===========================================================================]]--

local function register_events(...)
	local events = { ... }
	for _, event in ipairs(events) do
		ef:RegisterEvent(event)
	end
end

local function unregister_events(...)
	if ... == nil or ... == 'all' then
		ef:UnregisterAllEvents()
		A.dprint(1, 'Unregistered all events.')
		return
	end
	local events = { ... }
	for _, event in ipairs(events) do
		ef:UnregisterEvent(event)
	end
	A.dprint(1, 'Unregistered', ...)
end

local function register_zone_events()
	register_events('ZONE_CHANGED', 'ZONE_CHANGED_NEW_AREA')
end

A.register_events = register_events
A.register_zone_events = register_zone_events
A.unregister_events = unregister_events

--[[===========================================================================
	Handlers
===========================================================================]]--

local function ADDON_LOADED(addon)
	if addon == MYNAME then
		ef:UnregisterEvent('ADDON_LOADED')
		A.gdb, A.cdb = AQT_GlobalDB, AQT_CharDB
		A.cdb.enabled = A.cdb.enabled == nil and true or A.cdb.enabled
		A.gdb.loadMsg = A.gdb.loadMsg == nil and true or A.gdb.loadMsg
		A.gdb.ignoreInstances = A.gdb.ignoreInstances or false
		A.gdb.debug_mode = A.gdb.debug_mode or false
		A.gdb.debug_level = A.gdb.debug_level or 1
		A.cdb.time_logout = A.cdb.time_logout or 0

		A.gdb.exceptions_id = A.gdb.exceptions_id or {}
		A.gdb.exceptions_type = A.gdb.exceptions_type or {}
		A.gdb.exceptions_header = A.gdb.exceptions_header or {}
		A.gdb.exceptions_class = A.gdb.exceptions_class or {}
		A.gdb.exceptions_tag = A.gdb.exceptions_tag or {}
		A.gdb.exceptions_frequency = A.gdb.exceptions_frequency or {}

		A.register_menuitems()

		if A.cdb.enabled then
			register_zone_events()
			A.msg_load(CLR.GOOD('Enabled'), 8)
		else
			if not A.cdb.enable_nextsession and not A.cdb.enable_nextinstance then
				A.msg_load(CLR.BAD('Disabled.'), 8)
			else
				register_events('PLAYER_ENTERING_WORLD')
			end
		end
	end
end

local function PLAYER_LOGIN()
	ef:UnregisterEvent('PLAYER_LOGIN')
	A.user_is_author = tf6 and tf6.user_is_tflo
end

local function PLAYER_ENTERING_WORLD(is_login, is_reload)
	if not is_reload then
		if is_login then
			if A.cdb.enable_nextsession and time() - A.cdb.time_logout > A.SESSION_GRACE_TIME then
				register_zone_events()
				A.cdb.enabled = true
				A.cdb.enable_nextsession = nil
				A.msg_load(CLR.GOOD('Re-enabled because of new session'), 6)
			end
		-- TODO: check for instance 'world' here, as we actually only want continent changes
		elseif A.cdb.enable_nextinstance then
			register_zone_events()
			A.cdb.enabled = true
			A.cdb.enable_nextinstance = nil
			A.msg_load(CLR.GOOD('Re-enabled because of new (map) instance'), 6)
		end
	end
	if A.cdb.enable_nextsession or A.cdb.enable_nextinstance then
		A.msg_load(CLR.HALFBAD() .. 'Disabled for this ' .. (A.cdb.enable_nextsession and 'session.' or 'instance'), 6)
		if A.cdb.enable_nextsession then register_events('PLAYER_LOGOUT') end
		if not A.cdb.enable_nextinstance then unregister_events('PLAYER_ENTERING_WORLD') end
	end
end

local function PLAYER_LOGOUT()
	A.cdb.time_logout = time()
end

local ZONE_CHANGED do
	local pending
	function ZONE_CHANGED()
		if pending then return end
		pending = true
		C_Timer.After(A.DELAY_ZONE_CHANGE, function()
			A.update_quests_for_zone()
			pending = nil
		end)
	end
end

local event_handlers = {
	['ADDON_LOADED'] = ADDON_LOADED,
	['PLAYER_LOGIN'] = PLAYER_LOGIN,
	['PLAYER_ENTERING_WORLD'] = PLAYER_ENTERING_WORLD,
	['PLAYER_LOGOUT'] = PLAYER_LOGOUT,
	['ZONE_CHANGED'] = ZONE_CHANGED,
	['ZONE_CHANGED_NEW_AREA'] = ZONE_CHANGED,
}

--[[===========================================================================
	Register and script
===========================================================================]]--

register_events('ADDON_LOADED', 'PLAYER_LOGIN')

ef:SetScript('OnEvent', function(_, event, ...)
	event_handlers[event](...) -- Function-less events should throw an error
end)
