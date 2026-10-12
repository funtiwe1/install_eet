-- ***Utility Functions / Listeners*** --

--[[
+------------------------------------+
| check if an array contains a value |
+------------------------------------+
--]]

function GT_Utility_ArrayContains(array, value)
	for _, v in ipairs(array) do
		if v == value then
			return true
		end
	end
	return false
end


--[[
+-------------------------------------------------------+
| Get ``spellResRef`` from spellID (borrowed from Bubb) |
+-------------------------------------------------------+
--]]

function GT_Utility_DecodeSpell(spellIDS)
	local prefix
	local spellType = math.floor(spellIDS / 1000)
	--
	if spellType == 1 then
		prefix = "SPPR"
	elseif spellType == 2 then
		prefix = "SPWI"
	elseif spellType == 3 then
		prefix = "SPIN"
	elseif spellType == 4 then
		prefix = "SPCL"
	else
		prefix = "MARW"
	end
	--
	return prefix .. string.format("%03d", spellIDS % 1000)
end


-- Get ``CGameEffect`` fields --

function GT_Utility_GetEffectFields(CGameEffect)
	local toReturn = {}
	--
	toReturn["parameter1"] = CGameEffect.m_effectAmount
	toReturn["parameter2"] = CGameEffect.m_dWFlags
	toReturn["numDice"] = CGameEffect.m_numDice
	toReturn["diceSize"] = CGameEffect.m_diceSize
	--
	toReturn["effectID"] = CGameEffect.m_effectId
	toReturn["spellLevel"] = CGameEffect.m_spellLevel
	toReturn["projectileType"] = CGameEffect.m_projectileType
	toReturn["school"] = CGameEffect.m_school
	toReturn["secondaryType"] = CGameEffect.m_secondaryType
	toReturn["sourceRes"] = CGameEffect.m_sourceRes:get()
	--
	toReturn["casterLevel"] = CGameEffect.m_casterLevel
	toReturn["flags"] = CGameEffect.m_flags
	toReturn["savingThrow"] = CGameEffect.m_savingThrow
	toReturn["saveMod"] = CGameEffect.m_saveMod
	toReturn["special"] = CGameEffect.m_special
	--
	toReturn["sourceType"] = CGameEffect.m_sourceType
	toReturn["sourceFlags"] = CGameEffect.m_sourceFlags
	toReturn["slotNum"] = CGameEffect.m_slotNum
	toReturn["scriptName"] = CGameEffect.m_scriptName:get()
	--
	toReturn["duration"] = CGameEffect.m_duration
	toReturn["timing"] = CGameEffect.m_durationType
	toReturn["timeApplied"] = CGameEffect.m_effectAmount5
	--
	return toReturn
end


-- given an array of integers, return the greatest one --

function GT_Utility_FindGreatestInt(array)
	local greatest = array[1]
	for i = 2, #array do
		greatest = math.max(greatest, array[i])
	end
	return greatest
end


-- Construct ``CGameEffect`` (mainly for use with ``CProjectile:AddEffect()``) --

function GT_Utility_DecodeEffect(args)

	local effect

	EEex_RunWithStackManager({
		{ ["name"] = "itemEffect", ["struct"] = "Item_effect_st" },
		{ ["name"] = "source",     ["struct"] = "CPoint"         },
		{ ["name"] = "target",     ["struct"] = "CPoint"         }, },
		function(manager)

			itemEffect = manager:getUD("itemEffect")
			EEex_WriteUDArgs(itemEffect, args, {
				{ "effectID",         EEex_WriteFailType.ERROR        },
				{ "targetType",       EEex_WriteFailType.DEFAULT, 2   },
				{ "spellLevel",       EEex_WriteFailType.DEFAULT, 0   },
				{ "effectAmount",     EEex_WriteFailType.DEFAULT, 0   },
				{ "dwFlags",          EEex_WriteFailType.DEFAULT, 0   },
				{ "durationType",     EEex_WriteFailType.DEFAULT, 0   },
				{ "duration",         EEex_WriteFailType.DEFAULT, 0   },
				{ "probabilityUpper", EEex_WriteFailType.DEFAULT, 100 },
				{ "probabilityLower", EEex_WriteFailType.DEFAULT, 0   },
				{ "res",              EEex_WriteFailType.DEFAULT, ""  },
				{ "numDice",          EEex_WriteFailType.DEFAULT, 0   },
				{ "diceSize",         EEex_WriteFailType.DEFAULT, 0   },
				{ "savingThrow",      EEex_WriteFailType.DEFAULT, 0   },
				{ "saveMod",          EEex_WriteFailType.DEFAULT, 0   },
				{ "special",          EEex_WriteFailType.DEFAULT, 0   },
			})

			local source = manager:getUD("source")
			source.x = args["sourceX"] or -1
			source.y = args["sourceY"] or -1

			local target = manager:getUD("target")
			target.x = args["targetX"] or -1
			target.y = args["targetY"] or -1

			effect = CGameEffect.DecodeEffect(itemEffect, source, args["sourceID"] or -1, target, args["sourceTarget"] or -1)
		end)

	EEex_WriteUDArgs(effect, args, {
		{ "m_school",          EEex_WriteFailType.NOTHING },
		{ "m_minLevel",        EEex_WriteFailType.NOTHING },
		{ "m_maxLevel",        EEex_WriteFailType.NOTHING },
		{ "m_flags",           EEex_WriteFailType.NOTHING },
		{ "m_effectAmount2",   EEex_WriteFailType.NOTHING },
		{ "m_effectAmount3",   EEex_WriteFailType.NOTHING },
		{ "m_effectAmount4",   EEex_WriteFailType.NOTHING },
		{ "m_effectAmount5",   EEex_WriteFailType.NOTHING },
		{ "m_res2",            EEex_WriteFailType.NOTHING },
		{ "m_res3",            EEex_WriteFailType.NOTHING },
		{ "m_sourceType",      EEex_WriteFailType.NOTHING },
		{ "m_sourceRes",       EEex_WriteFailType.NOTHING },
		{ "m_sourceFlags",     EEex_WriteFailType.NOTHING },
		{ "m_projectileType",  EEex_WriteFailType.NOTHING },
		{ "m_slotNum",         EEex_WriteFailType.NOTHING },
		{ "m_scriptName",      EEex_WriteFailType.NOTHING },
		{ "m_casterLevel",     EEex_WriteFailType.NOTHING },
		{ "m_secondaryType",   EEex_WriteFailType.NOTHING },
	})

	return effect

end


-- Gets the distance between two points --

function GT_Utility_GetDistance(x1, y1, x2, y2)
	return math.floor((((x1 - x2) ^ 2) + ((y1 - y2) ^ 2)) ^ .5) 
end

function GT_Utility_GetIsometricDistance(x1, y1, x2, y2)
	return math.floor(((x1 - x2) ^ 2 + (4/3 * (y1 - y2)) ^ 2) ^ .5)
end


-- Converts an array to a string representation --

function GT_Utility_ArrayToString(array)
	local result = {}
	for _, value in ipairs(array) do
		table.insert(result, tostring(value)) -- Convert each value to a string
	end
	return "{" .. table.concat(result, ", ") .. "}" -- Join the values with commas
end


-- Shuffle the given array --

function GT_Utility_ShuffleArray(array)
	local shuffledArray = {}
	for i = #array, 1, -1 do
		local rand = math.random(i)
		table.insert(shuffledArray, table.remove(array, rand))
	end
	return shuffledArray
end


