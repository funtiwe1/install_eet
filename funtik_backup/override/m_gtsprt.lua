-- ***Sprites*** --

-- Returns true if the specified object can currently bounce the given level/projectile/school/sectype/resref/opcode(s) --

function GT_Sprite_HasBounceEffects(sprite, level, projectileType, school, sectype, resref, opcodes, flags)
	local toReturn = false

	local func
	func = function(effect)
		if effect.m_effectId == 177 or effect.m_effectId == 283 then -- Use EFF file
			local CGameEffectBase = EEex_Resource_Demand(effect.m_res:get(), "eff")
			--
			if CGameEffectBase then -- sanity check
				if func(CGameEffectBase) then
					toReturn = true
					return true
				end
			end
		elseif effect.m_effectId == 0xC5 and effect.m_dWFlags == projectileType and sectype ~= 4 then -- Physical mirror (197) -> CANNOT bounce effects of Secondary Type ``MagicAttack``
			toReturn = true
			return true
		elseif effect.m_effectId == 0xC6 and GT_Utility_ArrayContains(opcodes, effect.m_dWFlags) and sectype ~= 4 then -- Reflect specified effect (198) -> CANNOT bounce effects of Secondary Type ``MagicAttack``
			toReturn = true
			return true
		elseif effect.m_effectId == 0xC7 and effect.m_effectAmount == level and sectype ~= 4 and EEex_IsBitUnset(flags, 0x2) then -- Reflect spell level (199) -> CANNOT bounce effects of Secondary Type ``MagicAttack``; CANNOT bounce EFF files with ``resist_dispel = BIT2``
			toReturn = true
			return true
		elseif effect.m_effectId == 0xC8 and effect.m_dWFlags == level and sectype ~= 4 and EEex_IsBitUnset(flags, 0x2) then -- Spell turning (200) -> CANNOT bounce effects of Secondary Type ``MagicAttack``; CANNOT bounce EFF files with ``resist_dispel = BIT2``
			toReturn = true
			return true
		elseif effect.m_effectId == 0xCA and effect.m_dWFlags == school and sectype ~= 4 then -- Reflect spell school (202) -> CANNOT bounce effects of Secondary Type ``MagicAttack``
			toReturn = true
			return true
		elseif effect.m_effectId == 0xCB and effect.m_dWFlags == sectype and sectype ~= 4 then -- Reflect spell type (203) -> CANNOT bounce effects of Secondary Type ``MagicAttack``
			toReturn = true
			return true
		elseif effect.m_effectId == 0xCF and effect.m_res:get() == resref and sectype ~= 4 then -- Reflect specified spell (207) -> CANNOT bounce effects of Secondary Type ``MagicAttack``
			toReturn = true
			return true
		elseif effect.m_effectId == 0xE3 and effect.m_dWFlags == school and sectype ~= 4 then -- Spell school turning (227) -> CANNOT bounce effects of Secondary Type ``MagicAttack``
			toReturn = true
			return true
		elseif effect.m_effectId == 0xE4 and effect.m_dWFlags == sectype and sectype ~= 4 then -- Spell type turning (228) -> CANNOT bounce effects of Secondary Type ``MagicAttack``
			toReturn = true
			return true
		end
	end

	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, func)
	if not toReturn then
		EEex_Utility_IterateCPtrList(sprite.m_equipedEffectList, func)
	end

	return toReturn
end


-- Returns true if the specified object can currently deflect the given level/projectile/school/sectype/resref/opcode(s) --

function GT_Sprite_HasImmunityEffects(sprite, level, projectileType, school, sectype, resref, opcodes, flags, savetype, immunitiesVia403)
	local toReturn = false

	local func
	func = function(effect)
		if effect.m_effectId == 177 or effect.m_effectId == 283 then -- Use EFF file
			local CGameEffectBase = EEex_Resource_Demand(effect.m_res:get(), "eff")
			--
			if CGameEffectBase then -- sanity check
				if func(CGameEffectBase) then
					toReturn = true
					return true
				end
			end
		elseif effect.m_effectId == 0x53 and effect.m_dWFlags == projectileType then -- Immunity to projectile (83) -> CAN block effects of Secondary Type ``MagicAttack``
			toReturn = true
			return true
		elseif effect.m_effectId == 0x65 and GT_Utility_ArrayContains(opcodes, effect.m_dWFlags) and EEex_IsBitUnset(savetype, 23) then -- Immunity to opcode (101)
			toReturn = true
			return true
		elseif effect.m_effectId == 0x66 and effect.m_effectAmount == level then -- Immunity to spell level (102) -> CAN block effects of Secondary Type ``MagicAttack``
			toReturn = true
			return true
		elseif effect.m_effectId == 0xC9 and effect.m_dWFlags == level and sectype ~= 4 and EEex_IsBitUnset(flags, 0x2) then -- Spell deflection (201) -> CANNOT block effects of Secondary Type ``MagicAttack``; CANNOT block EFF files with ``resist_dispel = BIT2``
			toReturn = true
			return true
		elseif effect.m_effectId == 0xCC and effect.m_dWFlags == school and sectype ~= 4 then -- Protection from spell school (204) -> CANNOT block effects of Secondary Type ``MagicAttack``
			toReturn = true
			return true
		elseif effect.m_effectId == 0xCD and effect.m_dWFlags == sectype and sectype ~= 4 then -- Protection from spell type (205) -> CANNOT block effects of Secondary Type ``MagicAttack``
			toReturn = true
			return true
		elseif effect.m_effectId == 0xCE and effect.m_res:get() == resref then -- Protection from spell (206) -> CAN block effects of Secondary Type ``MagicAttack``
			toReturn = true
			return true
		elseif effect.m_effectId == 0xDF and effect.m_dWFlags == school and sectype ~= 4 then -- Spell school deflection (223) -> CANNOT block effects of Secondary Type ``MagicAttack``
			toReturn = true
			return true
		elseif effect.m_effectId == 0xE2 and effect.m_dWFlags == sectype then -- Spell type deflection (226) -> CAN block effects of Secondary Type ``MagicAttack``
			toReturn = true
			return true
		elseif effect.m_effectId == 0x193 and effect.m_res:get() == "GTIMMUNE" and EEex_BAnd(effect.m_dWFlags, immunitiesVia403) ~= 0 then -- EEex Screen Effects (403) -> See the special cases in "misc\immunity_removal.lua"
			toReturn = true
			return true
		end
	end

	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, func)
	if not toReturn then
		EEex_Utility_IterateCPtrList(sprite.m_equipedEffectList, func)
	end

	return toReturn
end


-- Returns true if the specified object can currently trap the given level --

function GT_Sprite_HasTrapEffect(sprite, level, sectype, flags)
	local toReturn = false

	local func
	func = function(effect)
		if effect.m_effectId == 177 or effect.m_effectId == 283 then -- Use EFF file
			local CGameEffectBase = EEex_Resource_Demand(effect.m_res:get(), "eff")
			--
			if CGameEffectBase then -- sanity check
				if func(CGameEffectBase) then
					toReturn = true
					return true
				end
			end
		elseif effect.m_effectId == 0x103 and effect.m_dWFlags == level and sectype ~= 4 and EEex_IsBitUnset(flags, 0x2) then -- Spell trap (259) -> CANNOT trap effects of Secondary Type ``MagicAttack``; CANNOT trap EFF files with ``resist_dispel = BIT2``
			toReturn = true
			return true
		end
	end

	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, func)
	if not toReturn then
		EEex_Utility_IterateCPtrList(sprite.m_equipedEffectList, func)
	end

	return toReturn
end


-- Display a colored string in the combat log --

function GT_Sprite_DisplayMessage(sprite, messageStr, messageColor)

	local message = EEex_NewUD("CMessageDisplayText")

	EEex_RunWithStackManager({
		{ ["name"] = "messageStr", ["struct"] = "CString", ["constructor"] = {["args"] = {messageStr} } } },
		function(manager)
			local id = sprite.m_id
			message:Construct(
				sprite:GetName(true),
				manager:getUD("messageStr"),
				CVidPalette.RANGE_COLORS:get(sprite.m_baseStats.m_colors:get(2)),
				messageColor == nil and 0xBED7D7 or messageColor,
				-1, id, id
			)
		end
	)

	EngineGlobals.g_pBaldurChitin.m_cMessageHandler:AddMessage(message, false)

end


-- check if spellcasting is disabled via op145 --

function GT_Sprite_SpellcastingDisabled(CGameSprite, spellType)
	local toReturn = false
	--
	local func
	func = function(effect)
		if effect.m_effectId == 177 or effect.m_effectId == 283 then -- Use EFF file
			local CGameEffectBase = EEex_Resource_Demand(effect.m_res:get(), "eff")
			--
			if CGameEffectBase then -- sanity check
				if func(CGameEffectBase) then
					toReturn = true
					return true
				end
			end
		elseif effect.m_effectId == 145 then
			if effect.m_dWFlags == 0 and spellType == 1 then -- wizard
				toReturn = true
				return true
			elseif effect.m_dWFlags == 1 and spellType == 2 then -- priest
				toReturn = true
				return true
			elseif effect.m_dWFlags == 3 then -- both
				toReturn = true
				return true
			end
		end
	end
	--
	EEex_Utility_IterateCPtrList(CGameSprite.m_timedEffectList, func)
	if not toReturn then
		EEex_Utility_IterateCPtrList(CGameSprite.m_equipedEffectList, func)
	end
	--
	return toReturn
end


-- Returns ``true`` if the given sprite matched the value specified by the ``IDS Entry`` field, in the specified ``IDS File`` --

function GT_Sprite_CheckIDS(sprite, IDSEntry, IDSFile, checkFallen)
	local m_EnemyAlly = sprite.m_typeAI.m_EnemyAlly
	local m_General = sprite.m_typeAI.m_General
	local m_Race = sprite.m_typeAI.m_Race
	local m_Class = sprite.m_typeAI.m_Class
	local m_Specifics = sprite.m_typeAI.m_Specifics
	local m_Gender = sprite.m_typeAI.m_Gender
	local m_Alignment = sprite.m_typeAI.m_Alignment
	local m_nKit = sprite:getActiveStats().m_nKit
	--
	if IDSEntry == 0 then -- any value is a match
		return true
	end
	--
	if not checkFallen or type(checkFallen) ~= "boolean" then
		checkFallen = false
	end
	--
	if IDSFile == 2 then -- EA
		if IDSEntry == 30 then -- GOODCUTOFF
			return m_EnemyAlly < 30
		elseif IDSEntry == 200 then -- EVILCUTOFF
			return m_EnemyAlly > 200
		else
			return m_EnemyAlly == IDSEntry
		end
	elseif IDSFile == 3 then -- GENERAL
		return m_General == IDSEntry
	elseif IDSFile == 4 then -- RACE
		return m_Race == IDSEntry
	elseif IDSFile == 5 then -- CLASS
		local m_nLevel1 = sprite:getActiveStats().m_nLevel1
		local m_nLevel2 = sprite:getActiveStats().m_nLevel2
		local m_flags = sprite.m_baseStats.m_flags
		--
		if IDSEntry == 202 then -- MAGE_ALL
			return m_Class == 1 or -- MAGE
				m_Class == 10 or -- FIGHTER_MAGE_THIEF
				m_Class == 17 or -- FIGHTER_MAGE_CLERIC
				m_Class == 19 or -- SORCERER
				(m_Class == 7 and (EEex_IsBitUnset(m_flags, 0x4) or m_nLevel1 > m_nLevel2)) or -- FIGHTER_MAGE
				(m_Class == 13 and (EEex_IsBitUnset(m_flags, 0x4) or m_nLevel2 > m_nLevel1)) or -- MAGE_THIEF
				(m_Class == 14 and (EEex_IsBitUnset(m_flags, 0x4) or m_nLevel1 > m_nLevel2)) -- CLERIC_MAGE
		elseif IDSEntry == 203 then -- FIGHTER_ALL
			return m_Class == 2 or -- FIGHTER
				m_Class == 10 or -- FIGHTER_MAGE_THIEF
				m_Class == 17 or -- FIGHTER_MAGE_CLERIC
				m_Class == 20 or -- MONK
				(m_Class == 7 and (EEex_IsBitUnset(m_flags, 0x3) or m_nLevel2 > m_nLevel1)) or -- FIGHTER_MAGE
				(m_Class == 8 and (EEex_IsBitUnset(m_flags, 0x3) or m_nLevel2 > m_nLevel1)) or -- FIGHTER_CLERIC
				(m_Class == 9 and (EEex_IsBitUnset(m_flags, 0x3) or m_nLevel2 > m_nLevel1)) or -- FIGHTER_THIEF
				(m_Class == 16 and (EEex_IsBitUnset(m_flags, 0x3) or m_nLevel2 > m_nLevel1)) -- FIGHTER_DRUID
		elseif IDSEntry == 204 then -- CLERIC_ALL
			return m_Class == 3 or -- CLERIC
				m_Class == 17 or -- FIGHTER_MAGE_CLERIC
				(m_Class == 8 and (EEex_IsBitUnset(m_flags, 0x5) or m_nLevel1 > m_nLevel2)) or -- FIGHTER_CLERIC
				(m_Class == 14 and (EEex_IsBitUnset(m_flags, 0x5) or m_nLevel2 > m_nLevel1)) or -- CLERIC_MAGE
				(m_Class == 15 and (EEex_IsBitUnset(m_flags, 0x5) or m_nLevel2 > m_nLevel1)) or -- CLERIC_THIEF
				(m_Class == 18 and (EEex_IsBitUnset(m_flags, 0x5) or m_nLevel2 > m_nLevel1)) -- CLERIC_RANGER
		elseif IDSEntry == 205 then -- THIEF_ALL
			return m_Class == 4 or -- THIEF
				m_Class == 10 or -- FIGHTER_MAGE_THIEF
				(m_Class == 9 and (EEex_IsBitUnset(m_flags, 0x6) or m_nLevel1 > m_nLevel2)) or -- FIGHTER_THIEF
				(m_Class == 13 and (EEex_IsBitUnset(m_flags, 0x6) or m_nLevel1 > m_nLevel2)) or -- MAGE_THIEF
				(m_Class == 15 and (EEex_IsBitUnset(m_flags, 0x6) or m_nLevel1 > m_nLevel2)) -- CLERIC_THIEF
		elseif IDSEntry == 206 then -- BARD_ALL
			return m_Class == 5 -- BARD
		elseif IDSEntry == 207 then -- PALADIN_ALL
			return m_Class == 6 and (not checkFallen or EEex_IsBitUnset(m_flags, 0x9)) -- PALADIN
		elseif IDSEntry == 208 then -- DRUID_ALL
			return m_Class == 11 or -- DRUID
				(m_Class == 16 and (EEex_IsBitUnset(m_flags, 0x7) or m_nLevel1 > m_nLevel2)) -- FIGHTER_DRUID
		elseif IDSEntry == 209 then -- RANGER_ALL
			return (m_Class == 12 or -- RANGER
				(m_Class == 18 and (EEex_IsBitUnset(m_flags, 0x8) or m_nLevel1 > m_nLevel2))) and -- CLERIC_RANGER
				(not checkFallen or EEex_IsBitUnset(m_flags, 10))
		else
			if IDSEntry == 6 then -- PALADIN
				return (m_Class == IDSEntry) and (not checkFallen or EEex_IsBitUnset(m_flags, 0x9))
			elseif IDSEntry == 12 then -- RANGER
				return (m_Class == IDSEntry) and (not checkFallen or EEex_IsBitUnset(m_flags, 10))
			else
				return m_Class == IDSEntry
			end
		end
	elseif IDSFile == 6 then -- SPECIFIC
		return m_Specifics == IDSEntry
	elseif IDSFile == 7 then -- GENDER
		return m_Gender == IDSEntry
	elseif IDSFile == 8 then -- ALIGN
		if IDSEntry == 0x1 then -- MASK_GOOD
			return m_Alignment == 0x11 or m_Alignment == 0x21 or m_Alignment == 0x31 -- LAWFUL_GOOD / NEUTRAL_GOOD / CHAOTIC_GOOD
		elseif IDSEntry == 0x2 then -- MASK_GENEUTRAL
			return m_Alignment == 0x21 or m_Alignment == 0x23 or m_Alignment == 0x22 -- NEUTRAL_GOOD / NEUTRAL_EVIL / NEUTRAL
		elseif IDSEntry == 0x3 then -- MASK_EVIL
			return m_Alignment == 0x13 or m_Alignment == 0x23 or m_Alignment == 0x33 -- LAWFUL_EVIL / NEUTRAL_EVIL / CHAOTIC_EVIL
		elseif IDSEntry == 0x10 then -- MASK_LAWFUL
			return m_Alignment == 0x11 or m_Alignment == 0x12 or m_Alignment == 0x13 -- LAWFUL_GOOD / LAWFUL_NEUTRAL / LAWFUL_EVIL
		elseif IDSEntry == 0x20 then -- MASK_LCNEUTRAL
			return m_Alignment == 0x12 or m_Alignment == 0x32 or m_Alignment == 0x22 -- LAWFUL_NEUTRAL / CHAOTIC_NEUTRAL / NEUTRAL
		elseif IDSEntry == 0x30 then -- MASK_CHAOTIC
			return m_Alignment == 0x31 or m_Alignment == 0x32 or m_Alignment == 0x33 -- CHAOTIC_GOOD / CHAOTIC_NEUTRAL / CHAOTIC_EVIL
		else
			return m_Alignment == IDSEntry
		end
	elseif IDSFile == 9 then -- KIT
		return m_nKit == IDSEntry
	end
	--
	return false
end


-- get currently selected weapon (resref, slot, Item_Header_st, Item_ability_st) --

function GT_Sprite_GetSelectedWeapon(sprite)
	local equipment = sprite.m_equipment -- CGameSpriteEquipment
	local selectedWeapon = equipment.m_items:get(equipment.m_selectedWeapon) -- CItem
	--
	return {
		["resref"] = selectedWeapon.pRes.resref:get(),
		["slot"] = equipment.m_selectedWeapon,
		["header"] = selectedWeapon.pRes.pHeader, -- Item_Header_st
		["ability"] = EEex_Resource_GetItemAbility(selectedWeapon.pRes.pHeader, equipment.m_selectedWeaponAbility), -- Item_ability_st
		["weapon"] = selectedWeapon, -- CItem
		["launcher"] = sprite:getLauncher(selectedWeapon:getAbility(equipment.m_selectedWeaponAbility)), -- CItem
		["launcherSlot"] = select(2, EEex_Sprite_GetLauncher(sprite, selectedWeapon:getAbility(equipment.m_selectedWeaponAbility))) -- int
	}
end


--[[
+---------------------------------------------------------------------------------+
| Utility: ``damage_type`` (itm ability +0x1C) to ``op12*p2`` / AC type converter |
+---------------------------------------------------------------------------------+
| NB.: this function returns damage type as: "DMGTYPE.IDS" >> 16                  |
+---------------------------------------------------------------------------------+
--]]

function GT_Sprite_ItmDamageTypeToIDS(damageType, CDerivedStats)
	-- none / crushing
	if damageType == 0 or damageType == 2 then
		return 0x0, CDerivedStats.m_nACCrushingMod
	-- piercing
	elseif damageType == 1 then
		return 0x10, CDerivedStats.m_nACPiercingMod
	-- slashing
	elseif damageType == 3 then
		return 0x100, CDerivedStats.m_nACSlashingMod
	-- missile
	elseif damageType == 4 then
		return 0x80, CDerivedStats.m_nACMissileMod
	-- non-lethal
	elseif damageType == 5 then
		return 0x800, CDerivedStats.m_nACCrushingMod
	-- piercing/crushing (better)
	elseif damageType == 6 then
		if CDerivedStats.m_nResistPiercing > CDerivedStats.m_nResistCrushing then
			return 0x0, CDerivedStats.m_nACCrushingMod
		else
			return 0x10, CDerivedStats.m_nACPiercingMod
		end
	-- piercing/slashing (better)
	elseif damageType == 7 then
		if CDerivedStats.m_nResistPiercing > CDerivedStats.m_nResistSlashing then
			return 0x100, CDerivedStats.m_nACSlashingMod
		else
			return 0x10, CDerivedStats.m_nACPiercingMod
		end
	-- slashing/crushing (worse)
	elseif damageType == 8 then
		if CDerivedStats.m_nResistCrushing > CDerivedStats.m_nResistSlashing then
			return 0x0, CDerivedStats.m_nACCrushingMod
		else
			return 0x100, CDerivedStats.m_nACSlashingMod
		end
	end
	--
	EEex_Error("invalid damage type: " .. damageType) -- should never happen
end


-- get current critical hit / miss bonuses --

function GT_Sprite_GetCriticalModifiers(sprite, offHand)
	if offHand == nil or type(offHand) ~= "boolean" then
		offHand = false
	end
	--
	local m_cCriticalEntryList = sprite:getActiveStats().m_cCriticalEntryList
	--
	local criticalHitModifier = 0
	local criticalMissModifier = 0
	--
	local selectedWeapon = GT_Sprite_GetSelectedWeapon(sprite)
	local attackType = selectedWeapon["ability"].type
	local slot = selectedWeapon["slot"]
	--
	if selectedWeapon["launcher"] then
		local items = sprite.m_equipment.m_items -- Array<CItem*,39>
		--
		for i = 34, 38 do -- also check the magical weapon slot
			local item = items:get(i) -- CItem
			--
			if item then -- sanity check
				if EEex_UDEqual(item, selectedWeapon["launcher"]) then
					slot = i
					break
				end
			end
		end
	end
	--
	if offHand then
		local items = sprite.m_equipment.m_items -- Array<CItem*,39>
		local item = items:get(9) -- CItem
		--
		slot = 9
		attackType = -1
		--
		if item then -- sanity check
			local pHeader = item.pRes.pHeader -- Item_Header_st
			if EEex_Resource_ItemCategoryIDSToSymbol(pHeader.itemType) ~= "SHIELD" then
				attackType = item:getAbility(0).type -- Item_ability_st
			end
		end
	end
	--
	EEex_Utility_IterateCPtrList(m_cCriticalEntryList, function(entry)
		if entry.m_res:get() == "" then
			if entry.m_hitOrMiss == 0 then -- op301/341 (critical hit)
				if entry.m_attackType == 0 or entry.m_attackType == attackType then
					if entry.m_slot == -1 or entry.m_slot == slot then
						criticalHitModifier = criticalHitModifier + entry.m_bonus
					end
				end
			elseif entry.m_hitOrMiss == 1 then -- op361/362 (critical miss)
				if entry.m_attackType == 0 or entry.m_attackType == attackType then
					if entry.m_slot == -1 or entry.m_slot == slot then
						criticalMissModifier = criticalMissModifier + entry.m_bonus
					end
				end
			end
		end
	end)
	--
	return criticalHitModifier, criticalMissModifier
end


-- Check if the attacker can perform an attack of opportunity. If so, return 4 (bonus to hit and damage) --

function GT_Sprite_GetAttackOfOpportunityBonus(attacker, target)
	local toReturn = 0
	--
	local attackerSelectedWeapon = GT_Sprite_GetSelectedWeapon(attacker)
	local targetSelectedWeapon = GT_Sprite_GetSelectedWeapon(target)
	--
	local attackerClassIDS = attacker.m_typeAI.m_Class
	local targetClassIDS = target.m_typeAI.m_Class
	--
	local attackerAbilityNotRanged = attackerSelectedWeapon["ability"].type == 1
	local attackerNotUsingFists = attackerSelectedWeapon["slot"] ~= 10 or attackerClassIDS == 20
	--
	local targetAbilityNotRanged = targetSelectedWeapon["ability"].type == 1
	local targetNotUsingFists = targetSelectedWeapon["slot"] ~= 10 or targetClassIDS == 20
	-- (attacker not using non-monk fists and attacker not using ranged ability) and (target using non-monk fists or target using ranged weapon)
	if attackerAbilityNotRanged and attackerNotUsingFists then
		if not (targetAbilityNotRanged and targetNotUsingFists) then
			toReturn = 4
		end
	end
	--
	return toReturn
end


-- op219 --

function GT_Sprite_AttackRollPenalty(attacker, target)
	local toReturn = 0
	--
	EEex_Utility_IterateCPtrList(target:getActiveStats().m_cProtectionList, function(selectiveBonus)
		if GT_Sprite_CheckIDS(attacker, selectiveBonus.m_type.m_EnemyAlly, 2) then
			if GT_Sprite_CheckIDS(attacker, selectiveBonus.m_type.m_General, 3) then
				if GT_Sprite_CheckIDS(attacker, selectiveBonus.m_type.m_Race, 4) then
					if GT_Sprite_CheckIDS(attacker, selectiveBonus.m_type.m_Class, 5) then
						if GT_Sprite_CheckIDS(attacker, selectiveBonus.m_type.m_Specifics, 6) then
							if GT_Sprite_CheckIDS(attacker, selectiveBonus.m_type.m_Gender, 7) then
								if GT_Sprite_CheckIDS(attacker, selectiveBonus.m_type.m_Alignment, 8) then
									toReturn = toReturn + selectiveBonus.m_bonus
									return true -- https://gibberlings3.github.io/iesdp/opcodes/bgee.htm#op219
								end
							end
						end
					end
				end
			end
		end
	end)
	--
	return toReturn
end


-- racial enemy bonus to thac0 and damage --

function GT_Sprite_GetRacialEnemyBonus(attacker, target)
	local toReturn = 0
	--
	if attacker:getActiveStats().m_nHatedRace > 0 then
		if GT_Sprite_CheckIDS(target, attacker:getActiveStats().m_nHatedRace, 4) then
			toReturn = 4
		end
	end
	--
	return toReturn
end


-- Check if the target is invisible. If so, then the attacker gets a malus of -4 to thac0 (unless it can see invisible sprites) --

function GT_Sprite_InvisibleTargetPenalty(attacker, target)
	local toReturn = 0
	--
	if EEex_IsBitSet(target:getActiveStats().m_generalState, 0x4) or EEex_IsBitSet(target:getActiveStats().m_generalState, 22) then
		if attacker:getActiveStats().m_bSeeInvisible == 0 then
			toReturn = 4
		end
	end
	--
	return toReturn
end


-- Check if the attacker is striking from invisibility --

function GT_Sprite_StrikingFromInvisibilityBonus(attacker, target)
	local toReturn = 0
	--
	local m_nBackstabDamageMultiplier = attacker:getActiveStats().m_nBackstabDamageMultiplier
	local m_generalState = attacker:getActiveStats().m_generalState
	local selectedWeapon = GT_Sprite_GetSelectedWeapon(attacker)
	--
	local dexmod = GT_Resource_2DA["dexmod"]
	local targetACDexBonus = tonumber(dexmod[string.format("%s", target:getActiveStats().m_nDEX)]["AC"])
	--
	if EEex_IsBitSet(m_generalState, 0x4) then -- if STATE_INVISIBLE
		if selectedWeapon["ability"].type == 1 then -- if melee weapon
			if m_nBackstabDamageMultiplier >= 2 and targetACDexBonus < 0 then -- https://gibberlings3.github.io/iesdp/opcodes/bgee.htm#op20
				toReturn = 4 - targetACDexBonus
			else
				toReturn = 4
			end
		end
	end
	--
	return toReturn
end


-- op178 --

function GT_Sprite_Thac0VsTypeBonus(attacker, target)
	local toReturn = 0
	--
	EEex_Utility_IterateCPtrList(attacker:getActiveStats().m_cToHitBonusList, function(selectiveBonus)
		if GT_Sprite_CheckIDS(target, selectiveBonus.m_type.m_EnemyAlly, 2) then
			if GT_Sprite_CheckIDS(target, selectiveBonus.m_type.m_General, 3) then
				if GT_Sprite_CheckIDS(target, selectiveBonus.m_type.m_Race, 4) then
					if GT_Sprite_CheckIDS(target, selectiveBonus.m_type.m_Class, 5) then
						if GT_Sprite_CheckIDS(target, selectiveBonus.m_type.m_Specifics, 6) then
							if GT_Sprite_CheckIDS(target, selectiveBonus.m_type.m_Gender, 7) then
								if GT_Sprite_CheckIDS(target, selectiveBonus.m_type.m_Alignment, 8) then
									toReturn = toReturn + selectiveBonus.m_bonus
									return true -- https://gibberlings3.github.io/iesdp/opcodes/bgee.htm#op178
								end
							end
						end
					end
				end
			end
		end
	end)
	--
	return toReturn
end


-- op179 --

function GT_Sprite_DamageVsTypeBonus(attacker, target)
	local toReturn = 0
	--
	EEex_Utility_IterateCPtrList(attacker:getActiveStats().m_cDamageBonusList, function(selectiveBonus)
		if GT_Sprite_CheckIDS(target, selectiveBonus.m_type.m_EnemyAlly, 2) then
			if GT_Sprite_CheckIDS(target, selectiveBonus.m_type.m_General, 3) then
				if GT_Sprite_CheckIDS(target, selectiveBonus.m_type.m_Race, 4) then
					if GT_Sprite_CheckIDS(target, selectiveBonus.m_type.m_Class, 5) then
						if GT_Sprite_CheckIDS(target, selectiveBonus.m_type.m_Specifics, 6) then
							if GT_Sprite_CheckIDS(target, selectiveBonus.m_type.m_Gender, 7) then
								if GT_Sprite_CheckIDS(target, selectiveBonus.m_type.m_Alignment, 8) then
									toReturn = toReturn + selectiveBonus.m_bonus
									return true -- https://gibberlings3.github.io/iesdp/opcodes/bgee.htm#op179
								end
							end
						end
					end
				end
			end
		end
	end)
	--
	return toReturn
end


-- Sort ``CGameArea::GetAllInRange()`` output by (isometric) distance --

function GT_Sprite_SortByIsometricDistance(array)
	local temp = {}
	local sourceX = EEex_LuaDecode_Object.m_pos.x
	local sourceY = EEex_LuaDecode_Object.m_pos.y
	--
	for _, v in ipairs(array) do
		local distance = GT_Utility_GetIsometricDistance(sourceX, sourceY, v.m_pos.x, v.m_pos.y)
		temp[v] = distance
	end
	-- Create a table of keys
	local toReturn = {}
	for k in pairs(temp) do table.insert(toReturn, k) end
	-- Sort the keys based on the values in the table
	table.sort(toReturn, function(a, b) return temp[a] < temp[b] end)
	--
	return toReturn
end


