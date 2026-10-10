-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Portions: Copyright (c) 2022-2026 Thomas Floeren for the added/changed code of "Mk III" (aka version 2 and later)

local MYNAME, A = ...



--[[---------------------------------------------------------------------------
	Tables
---------------------------------------------------------------------------]]--

A.QUEST_TYPES = {
	['dung'] = {
		['full'] = 'Dungeon Quests',
		['type'] = TYPE_DUNG
	},
	['raid'] = {
		['full'] = 'Raid Quests',
		['type'] = TYPE_RAID
	},
	['prof'] = {
		['full'] = 'Profession Quests',
		['type'] = TYPE_PROF
	},
	['pet'] = {
		['full'] = 'Battle Pet Quests',
		['type'] = TYPE_PET
	},
	['pvp'] = {
		['full'] = 'PvP Quests',
		['type'] = TYPE_PVP
	},
}

A.QUEST_GROUPS = {
	['ws'] = {
		['full'] = 'The Call of the Worldsoul',
		['ids'] = {82482, 82516, 82483, 82453, 82489, 82659, 87417, 91052, 87419, 82490, 82491, 82492, 82493, 82494, 82496, 82497, 82498, 82499, 82500, 82501, 82502, 82503, 82504, 82505, 82506, 82507, 82508, 82509, 82510, 89514, 87424, 82511, 82512, 89492, 87423, 82488, 91855, 82487, 82486, 82485, 82452, 87422, 82495, 89502}
	},
	['st'] = {
		['full'] = 'The Severed Threads',
		['ids'] = {80670, 80671, 80672}
	},
	['lkf'] = {
		['full'] = 'Lesser Keyflame',
		['ids'] = {76169, 76394, 76600, 76733, 76997, 78656, 78915, 78933, 78972, 79158, 79173, 79216, 79346, 80004, 80562, 81574, 81632}
	},
	['sa'] = {
		['full'] = 'Special Assignments',
		['ids'] = {82355, 81647, 81649, 81650, 81691, 83229, 82852, 82787, 82414, 82531, 85487, 85488, 89294, 89293}
	},
	['si'] = {
		['full'] = 'Siren Isle weekly',
		['ids'] = {84852, 84680, 83932, 84432, 84248, 84222, 84851, 83753, 84299, 84619, 83827, 84001, 84850, 85589, 84430, 85051, 84627}
	},
	['kw'] = {
		['full'] = 'K\'aresh Warrants',
		['ids'] = {90122, 90123, 90124, 90125, 90126, 90127}
	},
	['nf'] = {
		['full'] = 'Nightfall dailies',
		['ids'] = {87475, 87477, 87480, 88711, 88916, 88945}
	},
	['ata'] = {
		['full'] = 'DF: Aiding the Accord',
		['ids'] = {70750, 72068, 72373, 72374, 72375, 75259, 75859, 75860, 75861, 77254, 77976, 78446, 78447, 78861, 80385, 80386, 80388, 80389}
	},
	['awa'] = {
		['full'] = 'DF: A Worthy Ally',
		['ids'] = {75665, 78444}
	},
	['car'] = {
		['full'] = 'DF: Catch and Release',
		['ids'] = {70199, 70200, 70201, 70202, 70203, 70935}
	},
	['dr'] = { -- "The Waking Shores Tour" etc.; even numbers are the "advanced" variants; 78113 is Challenge Tour; 77815: Stone Race Tour
		['full'] = 'DF: Dragonriding Races',
		['ids'] = {72481, 72482, 72483, 72484, 72485, 72486, 72487, 72488, 78113, 77815}
	},
	['rtr'] = {
		['full'] = 'SL: Replenish the Reservoir',
		['ids'] = {61981, 61982, 61983, 61984}
	},
}

A.EXCEPTION_TYPES = {
	['always'] = {
		['value'] = 1,
		['full'] = C_ALW .. 'Always Tracked\124r',
	},
	['never'] = {
		['value'] = -1,
		['full'] = C_NEV .. 'Never Tracked\124r',
	},
	['ignore'] = {
		['value'] = 0,
		['full'] = C_IGN .. 'Ignored\124r',
	},
	['removed'] = {
		['value'] = nil,
		['full'] = 'Removed from Exceptions',
	}
}
