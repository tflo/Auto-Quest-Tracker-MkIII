-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Portions: Copyright (c) 2022-2026 Thomas Floeren for the added/changed code of "Mk III" (aka version 2 and later)

local MYNAME, A = ...


--[[===========================================================================
	Tables
===========================================================================]]--

-- Ordered pairs
-- From http://lua-users.org/wiki/SortedIteration

local function gen_ordered_index(t)
	local ordered_index = {}
	for key in pairs(t) do
		table.insert(ordered_index, key)
	end
	table.sort(ordered_index)
	return ordered_index
end

-- Let's keep the `ordered_index` tmp table out of the source table, because if the function
-- errors out before it nilifies it, it will end up inside the source table in the SV file.
-- And then, any future table.sort will not be happy.
local ordered_index
local function ordered_next(t, state)
	local key = nil
	-- print("orderedNext: state = "..tostring(state) )
	if state == nil then
		ordered_index = gen_ordered_index(t)
		key = ordered_index[1]
	else
		for i = 1, #ordered_index do
			if ordered_index[i] == state then
				key = ordered_index[i+1]
			end
		end
	end
	if key then return key, t[key] end
	ordered_index = nil
end

function A.ordered_pairs(t)
	return ordered_next, t, nil
end

--------------------------------------------------------------------------------

function A.table_is_empty(t)
	return next(t) == nil
end

function A.tabledump_first(tbl)
	if type(tbl) ~= 'table' then
		print('Not a table: ', tbl)
		return
	end

	print '{'
	for key, value in pairs(tbl) do
		local keystr = tostring(key)

		if type(key) == 'string' then keystr = format('%q', key) end

		if type(value) == 'table' then
			print(format('  [%s] = <table>,', keystr))
		elseif type(value) == 'function' then
			print(format('  [%s] = <function>,', keystr))
		elseif type(value) == 'string' then
			print(format('  [%s] = %q,', keystr, value))
		else
			print(format('  [%s] = %s,', keystr, tostring(value)))
		end
	end
	print '}'
end

A.DTD = DevTools_Dump

--[[===========================================================================
	Other
===========================================================================]]--

function A.get_questheader_from_input(t)
	local headerarray = {}
	for i = 3, #t do
		tinsert(headerarray, t[i])
	end
	return table.concat(headerarray, ' ')
end

function A.print_values()
	A.dprint(format(
		'DELAY_ZONE_CHANGE: %s; SESSION_GRACE_TIME: %s; IS_MAC: %s; QUESTFREQUENCY_DAILY: %s; QWT_AUTOMATIC: %s (%s); QWT_MANUAL: %s (%s); IGNORE_QWT: %s',
		A.DELAY_ZONE_CHANGE, A.SESSION_GRACE_TIME, tostring(A.IS_MAC), A.QUESTFREQUENCY_DAILY, A.QWT_AUTOMATIC, type(A.QWT_AUTOMATIC), A.QWT_MANUAL, type(A.QWT_MANUAL), tostring(A.IGNORE_QWT)
	))
end

function A.is_integer_in_range(value, min, max)
	if type(value) ~= 'number' then return false end
	if value ~= math.floor(value) then return false end
	if value < min or value > max then return false end
	return true
end

--[[---------------------------------------------------------------------------
	Debug
---------------------------------------------------------------------------]]--

function A.dprint(...)
	if A.gdb.debug_mode then
		local a, b = strsplit('.', GetTimePreciseSec())
		print(format('[%s.%s] %sAQT > Debug >\124r', a:sub(-3), b:sub(1, 3), A.CLR_DEBUG), ...)
	end
end

