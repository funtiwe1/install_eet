-- ***Class/Kit Abilities*** --

--[[
+----------------------------------------+
| cdtweaks, spontaneous cast for clerics |
+----------------------------------------+
--]]

-- clerics can spontaneously cast Cure/Cause Wounds spells upon pressing the Left Alt key when in "Cast Spell" mode (F7) --

function GTSPCAST(CGameEffect, CGameSprite)
	local align = GT_Resource_SymbolToIDS["align"]
	local isEvil = GT_Sprite_CheckIDS(CGameSprite, align["MASK_EVIL"], 8)
	local isGood = GT_Sprite_CheckIDS(CGameSprite, align["MASK_GOOD"], 8)
	--
	return EEex_Actionbar_GetOp214ButtonDataItr(EEex_Utility_SelectItr(3, EEex_Utility_FilterItr(
		EEex_Utility_ChainItrs(
			CGameSprite:getKnownPriestSpellsWithAbilityIterator(1, 7)
		),
		function(spellLevel, knownSpellIndex, spellResRef, spellHeader, spellAbility)
			if string.match(spellResRef:upper(), "^SPPR[1-7][0-9][0-9]$") then
				if string.match(spellResRef:sub(-2), "[0-4][0-9]") or string.match(spellResRef:sub(-2), "50") then -- NB.: Lua does not have regular expressions (that is to say, no "word boundary" matcher (\b), no alternatives (|), and also no lookahead or similar)!!!
					local spellIDS = 1 .. spellResRef:sub(-3)
					local symbol = GT_Resource_IDSToSymbol["spell"][tonumber(spellIDS)]
					--
					if symbol then -- sanity check
						if symbol == "CLERIC_CURE_LIGHT_WOUNDS" or symbol == "CLERIC_CURE_MODERATE_WOUNDS" or symbol == "CLERIC_CURE_MEDIUM_WOUNDS" or symbol == "CLERIC_CURE_SERIOUS_WOUNDS" or symbol == "CLERIC_CURE_CRITICAL_WOUNDS" then -- good only
							if isGood then
								return true
							end
						elseif symbol == "CLERIC_CAUSE_LIGHT_WOUNDS" or symbol == "CLERIC_CAUSE_MODERATE_WOUNDS" or symbol == "CLERIC_CAUSE_MEDIUM_WOUNDS" or symbol == "CLERIC_CAUSE_SERIOUS_WOUNDS" or symbol == "CLERIC_CAUSE_CRITICAL_WOUNDS" then -- evil only
							if isEvil then
								return true
							end
						end
					end
				end
			end
		end
	)))
end

-- clerics can spontaneously cast Cure/Cause Wounds spells upon pressing the Left Alt key when in "Cast Spell" mode (F7) --

EEex_Key_AddPressedListener(function(key)
	local sprite = EEex_Sprite_GetSelected()
	if not sprite then
		return
	end
	-- check for op145
	local spellcastingDisabled = GT_Sprite_SpellcastingDisabled(sprite, 0x2)
	--
	local lastState = EEex_Actionbar_GetLastState()
	local state = EEex_Actionbar_GetState()
	--
	local aux = EEex_GetUDAux(sprite)
	-- Check creature's class / flags
	local class = GT_Resource_SymbolToIDS["class"]
	-- single/multi/(complete)dual
	local isClericAll = GT_Sprite_CheckIDS(sprite, class["CLERIC_ALL"], 5)
	local canSpontaneouslyCast = isClericAll
	--
	if not spellcastingDisabled then -- op145 check...
		if canSpontaneouslyCast then
			if sprite.m_typeAI.m_EnemyAlly == 2 then -- [PC] check...
				if (lastState >= 1 and lastState <= 21) and (state == 103 or state == 113) then -- Cast Spell (F7) mode check...
					if EEex_Sprite_GetCastTimer(sprite) == -1 or sprite:getActiveStats().m_bAuraCleansing > 0 then -- aura check...
						if key == EEex_Key_GetFromName("Left Alt") then -- if the Left Alt key is pressed...
							sprite:applyEffect({
								["effectID"] = 214, -- select spell
								["dwFlags"] = 3, -- from lua
								["noSave"] = true,
								["res"] = "GTSPCAST",
								["durationType"] = 1,
								["sourceID"] = sprite.m_id,
								["sourceTarget"] = sprite.m_id,
							})
							--
							aux["gt_NWN_SpontaneousCast_Actionbar_LastState"] = lastState -- store it for later restoration
						end
					end
				end
			end
		end
	end
end)

-- check if the caster has at least 1 spell of appropriate level memorized (f.i. at least 1 spell of level 1 if it intends to spontaneously cast Cure/Cause Light Wounds). If so, decrement (unmemorize) all spells of that level by 1 --
-- restore the previous actionbar state after starting an action --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	local aux = EEex_GetUDAux(sprite)
	local m_curAction = sprite.m_curAction -- CAIAction
	--
	if aux["gt_NWN_SpontaneousCast_Actionbar_LastState"] then
		if m_curAction.m_actionID == 191 and sprite.m_bInCasting == 1 then -- SpellNoDec()
			--
			local spellResRef = m_curAction.m_string1.m_pchData:get()
			if spellResRef == "" then
				spellResRef = GT_Utility_DecodeSpell(m_curAction.m_specificID)
			end
			local spellHeader = EEex_Resource_Demand(spellResRef, "SPL")
			local spellType = spellHeader.itemType
			local spellLevel = spellHeader.spellLevel
			--
			local spellLevelMemListArray
			if spellType == 2 then -- Priest
				spellLevelMemListArray = sprite.m_memorizedSpellsPriest
			end
			--
			local alreadyDecreasedResrefs = {}
			local memList = spellLevelMemListArray:getReference(spellLevel - 1)  -- count starts from 0, that's why ``-1``
			local found = false
			--
			EEex_Utility_IterateCPtrList(memList, function(memInstance)
				local memInstanceResref = memInstance.m_spellId:get()
				if not alreadyDecreasedResrefs[memInstanceResref] then
					local memFlags = memInstance.m_flags
					if EEex_IsBitSet(memFlags, 0x0) then -- if memorized, ...
						memInstance.m_flags = EEex_UnsetBit(memFlags, 0x0) -- ... unmemorize
						alreadyDecreasedResrefs[memInstanceResref] = true
						found = true
					end
				end
			end)
			--
			if not found then
				local feedbackStrRefs = {487798, 487799, 487800, 487801, 487802}
				sprite:applyEffect({
					["effectID"] = 139, -- Display string
					["effectAmount"] = feedbackStrRefs[spellLevel],
					["sourceID"] = sprite.m_id,
					["sourceTarget"] = sprite.m_id,
				})
				-- abort action
				m_curAction.m_actionID = 0 -- NoAction()
			end
		end
		--
		if EEex_UDEqual(sprite, EEex_Sprite_GetSelected()) then
			EEex_Actionbar_SetState(aux["gt_NWN_SpontaneousCast_Actionbar_LastState"])
		end
		aux["gt_NWN_SpontaneousCast_Actionbar_LastState"] = nil
	end
end)


--[[
+---------------------------------------------------------+
| cdtweaks, NWN-ish Weapon Finesse class feat for Thieves |
+---------------------------------------------------------+
--]]

-- Apply ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- Unusually large weapons --
	local unusuallyLargeWeapons = {
		["BDBONE02"] = true, -- Ettin Club +1
	}
	-- internal function that applies the actual bonus
	local apply = function(modifier)
		-- Update tracking var
		sprite:setLocalInt("gtNWNWeaponFinesse", modifier)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTCL400",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 306, -- Main-hand THAC0 bonus
			["durationType"] = 9,
			["effectAmount"] = modifier,
			["m_sourceRes"] = "GTCL400",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 142, -- Display portrait icon
			["durationType"] = 9,
			["dwFlags"] = 251,
			["m_sourceRes"] = "GTCL400",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's equipment / stats / class
	local selectedWeapon = GT_Sprite_GetSelectedWeapon(sprite)
	local selectedWeaponTypeStr = EEex_Resource_ItemCategoryIDSToSymbol(selectedWeapon["header"].itemType)
	--
	local strmod = GT_Resource_2DA["strmod"]
	local strmodex = GT_Resource_2DA["strmodex"]
	local dexmod = GT_Resource_2DA["dexmod"]
	-- Since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteSTR = sprite.m_derivedStats.m_nSTR
	local spriteSTRExtra = sprite.m_derivedStats.m_nSTRExtra
	local spriteDEX = sprite.m_derivedStats.m_nDEX
	--
	local class = GT_Resource_SymbolToIDS["class"]
	-- compute modifier
	local curStrBonus = spriteSTR == 18 and (tonumber(strmod[string.format("%s", spriteSTR)]["TO_HIT"] + strmodex[string.format("%s", spriteSTRExtra)]["TO_HIT"])) or tonumber(strmod[string.format("%s", spriteSTR)]["TO_HIT"])
	local curDexBonus = tonumber(dexmod[string.format("%s", spriteDEX)]["MISSILE"])
	--
	local modifier = curDexBonus - curStrBonus
	-- any thief (single/multi/(complete)dual)
	local isThiefAll = GT_Sprite_CheckIDS(sprite, class["THIEF_ALL"], 5)
	-- if the thief is wielding a small blade / mace / club that scales with STR and "dexmod.2da" is better than "strmod.2da" + "strmodex.2da" ...
	local applyAbility = (selectedWeaponTypeStr == "DAGGER" or selectedWeaponTypeStr == "SMSWORD" or selectedWeaponTypeStr == "MACE")
		and not unusuallyLargeWeapons[selectedWeapon["resref"]]
		and modifier > 0
		and selectedWeapon["ability"].quickSlotType == 1 -- Location: Weapon
		and selectedWeapon["ability"].type == 1 -- Type: Melee
		and (EEex_IsBitSet(selectedWeapon["ability"].abilityFlags, 0x0) or EEex_IsBitSet(selectedWeapon["ability"].abilityFlags, 0x3))
		and isThiefAll
	--
	if sprite:getLocalInt("gtNWNWeaponFinesse") == 0 then
		if applyAbility then
			apply(modifier)
		end
	else
		if applyAbility then
			-- Check if STR/STREx/DEX have changed since the last application
			if modifier ~= sprite:getLocalInt("gtNWNWeaponFinesse") then
				apply(modifier)
			end
		else
			-- Mark the creature as 'bonus removed'
			sprite:setLocalInt("gtNWNWeaponFinesse", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL400",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

--[[
+--------------------------------------------------------+
| cdtweaks, NWN-ish Defensive Roll class feat for Rogues |
+--------------------------------------------------------+
--]]

-- Apply ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual feat
	local apply = function()
		-- Mark the creature as 'feat applied'
		sprite:setLocalInt("gtNWNDefensiveRoll", 1)
	end
	-- Check creature's class / kit / flags / levels
	local class = GT_Resource_SymbolToIDS["class"]
	--
	--local spriteKitStr = GT_Resource_IDSToSymbol["kit"][EEex_BOr(EEex_LShift(sprite.m_baseStats.m_mageSpecUpperWord, 16), sprite.m_baseStats.m_mageSpecialization)]
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteKitStr = EEex_Resource_KitIDSToSymbol(sprite.m_derivedStats.m_nKit)
	-- KIT == SHADOWDANCER => Level 5+ ; KIT != SHADOWDANCER => Level 10+
	local isThiefAll = GT_Sprite_CheckIDS(sprite, class["THIEF_ALL"], 5)
	--
	local isShadowDancer = spriteKitStr == "SHADOWDANCER"
	--
	local conditionalString = "ClassLevelGT(Myself,ROGUE,9)"
	if isShadowDancer then
		conditionalString = "ClassLevelGT(Myself,ROGUE,4)"
	end
	--
	local applyAbility = isThiefAll and GT_EvalConditional["parseConditionalString"](sprite, nil, conditionalString)
	--
	if sprite:getLocalInt("gtNWNDefensiveRoll") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtNWNDefensiveRoll", 0)
		end
	end
end)

-- If the character is struck by a potentially lethal blow, he makes a save vs. breath. If successful, he takes only half damage from the blow --

EEex_Sprite_AddAlterBaseWeaponDamageListener(function(context)
	local target = context.target -- CGameSprite
	local attacker = context.attacker -- CGameSprite
	--
	local effect = context.effect -- CGameEffect
	--
	local damageAmount = effect.m_effectAmount
	--
	local targetHP = target.m_baseStats.m_hitPoints
	local targetSaveVSBreathRoll = target.m_saveVSBreathRoll
	--
	local targetActiveStats = EEex_Sprite_GetActiveStats(target)
	--
	local dmgtype = GT_Resource_SymbolToIDS["dmgtype"]
	--
	local conditionalString = '!GlobalTimerNotExpired("gtNWNDefensiveRollTimer","LOCALS")'
	local responseString = 'SetGlobalTimer("gtNWNDefensiveRollTimer","LOCALS",2400)'
	--
	local ability = context.ability -- Item_ability_st
	--
	if target:getLocalInt("gtNWNDefensiveRoll") == 1 then
		--
		if GT_EvalConditional["parseConditionalString"](target, nil, conditionalString) then
			--
			if effect.m_effectId == 0xC and EEex_IsMaskUnset(effect.m_dWFlags, dmgtype["STUNNING"]) and effect.m_slotNum == -1 and effect.m_sourceType == 0 and effect.m_sourceRes:get() == "" then -- base weapon damage (all damage types but STUNNING)
				--
				if EEex_BAnd(targetActiveStats.m_generalState, 0x100029) == 0 then -- !(STATE_SLEEPING | STATE_STUNNED | STATE_HELPLESS | STATE_FEEBLEMINDED)
					--
					if damageAmount >= targetHP then
						--
						if targetActiveStats.m_nSaveVSBreath <= targetSaveVSBreathRoll then
							--
							effect.m_effectAmount = math.floor(damageAmount / 2)
							--
							if ability.type == 1 then -- melee
								EEex_GameObject_ApplyEffect(target,
								{
									["effectID"] = 139, -- Display string
									["effectAmount"] = 487804,
									["sourceID"] = target.m_id,
									["sourceTarget"] = target.m_id,
								})
							else -- ranged
								attacker.m_curProjectile:AddEffect(GT_Utility_DecodeEffect(
									{
										["effectID"] = 139, -- Display string
										["effectAmount"] = 487804,
										--
										["sourceX"] = attacker.m_pos.x,
										["sourceY"] = attacker.m_pos.y,
										["targetX"] = target.m_pos.x,
										["targetY"] = target.m_pos.y,
										--
										["m_projectileType"] = ability.missileType - 1,
										["m_sourceRes"] = context.weapon.cResRef:get(),
										["m_sourceType"] = 2,
										--
										["sourceID"] = attacker.m_id,
										["sourceTarget"] = target.m_id,
									}
								))
							end
							--
							GT_ExecuteResponse["parseResponseString"](target, nil, responseString)
						end
					end
				end
			end
		end
	end
end)

--[[
+--------------------------------------------------------+
| cdtweaks, NWN-ish Divine Grace class feat for Paladins |
+--------------------------------------------------------+
--]]

-- Apply ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual bonus
	local apply = function(bonus)
		-- Update tracking var
		sprite:setLocalInt("gtNWNDivineGrace", bonus)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTCL100",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 325, -- All saving throws bonus
			["durationType"] = 9,
			["effectAmount"] = bonus,
			["m_sourceRes"] = "GTCL100",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 142, -- Display portrait icon
			["durationType"] = 9,
			["dwFlags"] = 252,
			["m_sourceRes"] = "GTCL100",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's class / kit / flags / CHR
	local spriteClassStr = GT_Resource_IDSToSymbol["class"][sprite.m_typeAI.m_Class]
	--
	local spriteFlags = sprite.m_baseStats.m_flags
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteCharisma = sprite.m_derivedStats.m_nCHR
	local spriteKitStr = EEex_Resource_KitIDSToSymbol(sprite.m_derivedStats.m_nKit)
	--
	local gtabmod = GT_Resource_2DA["gtabmod"]
	local bonus = tonumber(gtabmod[string.format("%s", spriteCharisma)]["BONUS"])
	-- The paladin adds its charisma bonus (if positive) to all saving throws (provided it is not fallen)
	local applyAbility = spriteClassStr == "PALADIN" and spriteKitStr ~= "Blackguard" and bonus and bonus > 0 and EEex_IsBitUnset(spriteFlags, 0x9)
	--
	if sprite:getLocalInt("gtNWNDivineGrace") == 0 then
		if applyAbility then
			apply(bonus)
		end
	else
		if applyAbility then
			-- Check if Charisma has changed since the last application
			if bonus ~= sprite:getLocalInt("gtNWNDivineGrace") then
				apply(bonus)
			end
		else
			-- Mark the creature as 'bonus removed'
			sprite:setLocalInt("gtNWNDivineGrace", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL100",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

--[[
+----------------------------------------------------------+
| cdtweaks, NWN-ish Dark Blessing kit feat for Blackguards |
+----------------------------------------------------------+
--]]

-- Apply ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual bonus
	local apply = function(bonus)
		-- Update tracking var
		sprite:setLocalInt("gtNWNDarkBlessing", bonus)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTCL101",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 325, -- All saving throws bonus
			["durationType"] = 9,
			["effectAmount"] = bonus,
			["m_sourceRes"] = "GTCL101",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 142, -- Display portrait icon
			["durationType"] = 9,
			["dwFlags"] = 253,
			["m_sourceRes"] = "GTCL101",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's class / kit / flags / CHR
	local spriteClassStr = GT_Resource_IDSToSymbol["class"][sprite.m_typeAI.m_Class]
	--
	local spriteFlags = sprite.m_baseStats.m_flags
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteCharisma = sprite.m_derivedStats.m_nCHR
	local spriteKitStr = EEex_Resource_KitIDSToSymbol(sprite.m_derivedStats.m_nKit)
	--
	local gtabmod = GT_Resource_2DA["gtabmod"]
	local bonus = tonumber(gtabmod[string.format("%s", spriteCharisma)]["BONUS"])
	-- The blackguard adds its charisma bonus to all saving throws (provided it is not fallen)
	local applyAbility = spriteClassStr == "PALADIN" and spriteKitStr == "Blackguard" and bonus and bonus ~= 0 and EEex_IsBitUnset(spriteFlags, 0x9)
	--
	if sprite:getLocalInt("gtNWNDarkBlessing") == 0 then
		if applyAbility then
			apply(bonus)
		end
	else
		if applyAbility then
			-- Check if Charisma has changed since the last application
			if bonus ~= sprite:getLocalInt("gtNWNDarkBlessing") then
				apply(bonus)
			end
		else
			-- Mark the creature as 'bonus removed'
			sprite:setLocalInt("gtNWNDarkBlessing", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL101",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

--[[
+--------------------------------------------------+
| cdtweaks, NWN-ish Cleave class feat for Fighters |
+--------------------------------------------------+
--]]

-- Apply Ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual feat
	local apply = function()
		-- Mark the creature as 'feat applied'
		sprite:setLocalInt("gtNWNCleave", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTCL102",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 248, -- Melee hit effect
			["durationType"] = 9,
			["res"] = "GTCL102B", -- EFF file
			["m_sourceRes"] = "GTCL102",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's class / flags
	local class = GT_Resource_SymbolToIDS["class"]
	-- any fighter class (single/multi/(complete)dual, as well as monks)
	local isFighterAll = GT_Sprite_CheckIDS(sprite, class["FIGHTER_ALL"], 5)
	--
	local applyAbility = isFighterAll
	--
	if sprite:getLocalInt("gtNWNCleave") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtNWNCleave", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL102",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- Core function --

function GTCL102(CGameEffect, CGameSprite)
	if CGameEffect.m_effectAmount == 1 then -- check if can perform Cleave
		local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
		--
		local sourceActiveStats = EEex_Sprite_GetActiveStats(sourceSprite)
		--
		local conditionalString = 'InWeaponRange(EEex_Target("gtCleaveTarget"))'
		local responseString = 'ReallyForceSpellRES("GTCL102B",EEex_Target("gtCleaveTarget"))'
		--
		local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
		--
		if EEex_IsBitSet(targetActiveStats.m_generalState, 11) then -- if STATE_DEAD (BIT11)
			local potentialTargets = {}
			if sourceSprite.m_typeAI.m_EnemyAlly > 200 then -- EVILCUTOFF
				potentialTargets = EEex_Sprite_GetAllOfTypeInRange(sourceSprite, GT_AI_ObjectType["GOODCUTOFF"], sourceSprite:virtual_GetVisualRange(), nil, nil, nil)
			elseif sourceSprite.m_typeAI.m_EnemyAlly < 30 then -- GOODCUTOFF
				potentialTargets = EEex_Sprite_GetAllOfTypeInRange(sourceSprite, GT_AI_ObjectType["EVILCUTOFF"], sourceSprite:virtual_GetVisualRange(), nil, nil, nil)
			end
			--
			for _, itrSprite in ipairs(potentialTargets) do
				local itrSpriteActiveStats = EEex_Sprite_GetActiveStats(itrSprite)
				--
				if GT_EvalConditional["parseConditionalString"](sourceSprite, itrSprite, conditionalString, "gtCleaveTarget") and EEex_IsBitUnset(itrSpriteActiveStats.m_generalState, 11) then -- if not dead
					if EEex_IsBitUnset(itrSpriteActiveStats.m_generalState, 0x4) or sourceActiveStats.m_bSeeInvisible > 0 then
						if itrSpriteActiveStats.m_bSanctuary == 0 then
							GT_ExecuteResponse["parseResponseString"](sourceSprite, itrSprite, responseString, "gtCleaveTarget")
							break
						end
					end
				end
			end
		end
	elseif CGameEffect.m_effectAmount == 2 then -- actual feat
		local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
		--
		local selectedWeapon = GT_Sprite_GetSelectedWeapon(sourceSprite)
		--
		local conditionalString = "EEex_IsImmuneToOpcode(Myself,12)"
		--
		local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
		--
		local damageTypeIDS, ACModifier = GT_Sprite_ItmDamageTypeToIDS(selectedWeapon["ability"].damageType, targetActiveStats)
		--
		if not GT_EvalConditional["parseConditionalString"](CGameSprite, nil, conditionalString) then
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 0xC, -- Damage
				["dwFlags"] = damageTypeIDS * 0x10000, -- mode: normal
				["numDice"] = selectedWeapon["ability"].damageDiceCount,
				["diceSize"] = selectedWeapon["ability"].damageDice,
				["effectAmount"] = selectedWeapon["ability"].damageDiceBonus,
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
		else
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 324, -- Immunity to resource and message
				["res"] = CGameEffect.m_sourceRes:get(),
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
		end
	end
end

--[[
+---------------------------------------------------------+
| cdtweaks, NWN-ish Sneak Attack kit feat for Blackguards |
+---------------------------------------------------------+
--]]

-- Apply ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual bonus
	local apply = function()
		-- Mark the creature as 'feat applied'
		sprite:setLocalInt("gtNWNSneakAttBlackguard", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTCL103",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 248, -- Melee hit effect
			["res"] = "GTCL103B", -- EFF file
			["durationType"] = 9,
			["m_sourceRes"] = "GTCL103",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 249, -- Ranged hit effect
			["res"] = "GTCL103B", -- EFF file
			["durationType"] = 9,
			["m_sourceRes"] = "GTCL103",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's class / kit / flags
	local spriteFlags = sprite.m_baseStats.m_flags
	local spriteClassStr = GT_Resource_IDSToSymbol["class"][sprite.m_typeAI.m_Class]
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteKitStr = EEex_Resource_KitIDSToSymbol(sprite.m_derivedStats.m_nKit)
	-- Grant the feat to Blackguards (must not be fallen)
	local applyAbility = spriteClassStr == "PALADIN" and spriteKitStr == "Blackguard" and EEex_IsBitUnset(spriteFlags, 9)
	--
	if sprite:getLocalInt("gtNWNSneakAttBlackguard") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtNWNSneakAttBlackguard", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL103",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- Core function --

function GTCL103(CGameEffect, CGameSprite)
	if CGameEffect.m_effectAmount == 1 then -- check if can perform a sneak attack
		local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
		--
		local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
		-- limit to once per round
		local conditionalString = '!GlobalTimerNotExpired("gtNWNSneakAttBlackguardTimer","LOCALS")'
		local responseString = 'SetGlobalTimer("gtNWNSneakAttBlackguardTimer","LOCALS",6)'
		--
		--local selectedWeapon = GT_Sprite_GetSelectedWeapon(CGameSprite)
		--
		if GT_EvalConditional["parseConditionalString"](sourceSprite, nil, conditionalString) then
			-- if the target is incapacitated/idle || the target is in combat with someone else
			if EEex_BAnd(targetActiveStats.m_generalState, 0x100029) ~= 0 or CGameSprite.m_targetId ~= sourceSprite.m_id then
				GT_ExecuteResponse["parseResponseString"](sourceSprite, nil, responseString)
				--
				CGameSprite:applyEffect({
					["effectID"] = 146, -- Cast spell
					["res"] = "GTCL103B", -- SPL file
					["dwFlags"] = 1, -- cast instantly / ignore level
					["sourceID"] = CGameEffect.m_sourceId,
					["sourceTarget"] = CGameEffect.m_sourceTarget,
				})
			end
		end
	elseif CGameEffect.m_effectAmount == 2 then -- actual sneak attack
		local sneakatt = GT_Resource_2DA["sneakatt"]
		--
		local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
		local sourceActiveStats = EEex_Sprite_GetActiveStats(sourceSprite)
		--
		local selectedWeapon = GT_Sprite_GetSelectedWeapon(sourceSprite)
		--
		local isUsableBySingleClassThief = EEex_IsBitUnset(selectedWeapon["header"].notUsableBy, 22)
		--
		if selectedWeapon["launcher"] then
			local pHeader = selectedWeapon["launcher"].pRes.pHeader -- Item_Header_st
			isUsableBySingleClassThief = EEex_IsBitUnset(pHeader.notUsableBy, 22)
		end
		--
		if selectedWeapon["ability"].type == 1 and sourceSprite.m_leftAttack == 1 then -- if attacking with offhand ...
			local items = sourceSprite.m_equipment.m_items -- Array<CItem*,39>
			local offHand = items:get(9) -- CItem
			--
			if offHand then
				local pHeader = offHand.pRes.pHeader -- Item_Header_st
				--
				if EEex_Resource_ItemCategoryIDSToSymbol(pHeader.itemType) ~= "SHIELD" then -- if not shield, then overwrite item ability / usability check...
					selectedWeapon["ability"] = EEex_Resource_GetItemAbility(pHeader, 0) -- Item_ability_st
					isUsableBySingleClassThief = EEex_IsBitUnset(pHeader.notUsableBy, 22)
				end
			end
		end
		--
		local damageImmunity = "EEex_IsImmuneToOpcode(Myself,12)"
		--
		local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
		--
		local damageTypeIDS, ACModifier = GT_Sprite_ItmDamageTypeToIDS(selectedWeapon["ability"].damageType, targetActiveStats)
		--
		if isUsableBySingleClassThief then
			if not GT_EvalConditional["parseConditionalString"](CGameSprite, nil, damageImmunity) then
				EEex_GameObject_ApplyEffect(CGameSprite,
				{
					["effectID"] = 0xC, -- Damage
					["dwFlags"] = damageTypeIDS * 0x10000, -- mode: normal
					["numDice"] = tonumber(sneakatt["STALKER"][string.format("%s", sourceActiveStats.m_nLevel1)]),
					["diceSize"] = 6,
					["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
					["m_sourceType"] = CGameEffect.m_sourceType,
					["sourceID"] = CGameEffect.m_sourceId,
					["sourceTarget"] = CGameEffect.m_sourceTarget,
				})
			else
				EEex_GameObject_ApplyEffect(CGameSprite,
				{
					["effectID"] = 324, -- Immunity to resource and message
					["res"] = CGameEffect.m_sourceRes:get(),
					["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
					["m_sourceType"] = CGameEffect.m_sourceType,
					["sourceID"] = CGameEffect.m_sourceId,
					["sourceTarget"] = CGameEffect.m_sourceTarget,
				})
			end
		else
			EEex_GameObject_ApplyEffect(sourceSprite,
			{
				["effectID"] = 139, -- Display string
				["effectAmount"] = 487810,
				["sourceID"] = sourceSprite.m_id,
				["sourceTarget"] = sourceSprite.m_id,
			})
		end
	end
end

--[[
+------------------------------------------------------+
| cdtweaks, NWN-ish Poison Save kit feat for Assassins |
+------------------------------------------------------+
--]]

-- Apply ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual feat
	local apply = function()
		-- Mark the creature as 'feat applied'
		sprite:setLocalInt("gtNWNPoisonSave", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTCL402",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 403, -- Screen effects
			["durationType"] = 9,
			["res"] = "GTIMMUNE", -- lua function
			["effectAmount"] = 0x84, -- BIT2 | BIT7
			["special"] = 1,
			["m_sourceRes"] = "GTCL402",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 142, -- Display portrait icon
			["durationType"] = 9,
			["dwFlags"] = 256,
			["m_sourceRes"] = "GTCL402",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's class / kit
	local class = GT_Resource_SymbolToIDS["class"]
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteKitStr = EEex_Resource_KitIDSToSymbol(sprite.m_derivedStats.m_nKit)
	-- single/multi/(complete)dual assassins
	local isThiefAll = GT_Sprite_CheckIDS(sprite, class["THIEF_ALL"], 5)
	local isAssassin = spriteKitStr == "ASSASIN" -- typo in kit.ids / kitlist.2da
	--
	local applyAbility = isThiefAll and isAssassin
	--
	if sprite:getLocalInt("gtNWNPoisonSave") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtNWNPoisonSave", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL402",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

--[[
+----------------------------------------------------------------------+
| cdtweaks, NWN-ish Planar Turning class feat for Paladins and Clerics |
+----------------------------------------------------------------------+
--]]

-- Check if turning undead --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual turning
	local turnPlanarMode = function()
		sprite:applyEffect({
			["effectID"] = 146, -- Cast spell
			["dwFlags"] = 1, -- instant / ignore level
			["res"] = "GTCL104", -- SPL file
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- turn undead lvl 21+; wis 17+, cha 17+; paladin or cleric
	local spriteWIS = sprite.m_derivedStats.m_nWIS
	local spriteCHR = sprite.m_derivedStats.m_nCHR
	--
	local class = GT_Resource_SymbolToIDS["class"]
	local isPaladinAll = GT_Sprite_CheckIDS(sprite, class["PALADIN_ALL"], 5, true)
	local isClericAll = GT_Sprite_CheckIDS(sprite, class["CLERIC_ALL"], 5)
	--
	local spriteTurnUndeadLevel = sprite.m_derivedStats.m_nTurnUndeadLevel
	-- Check if the creature is turning undead
	local turnUndeadMode = EEex_Sprite_GetModalState(sprite) == 4 and EEex_Sprite_GetModalTimer(sprite) == 0
	--
	if (isPaladinAll or isClericAll) and turnUndeadMode and spriteTurnUndeadLevel >= 21 and spriteWIS >= 17 and spriteCHR >= 17 then
		turnPlanarMode()
	end
end)

-- Core function --

function GTCL104(CGameEffect, CGameSprite)
	local parentResRef = CGameEffect.m_sourceRes:get()
	--
	local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
	--
	local align = GT_Resource_SymbolToIDS["align"]
	local isEvil = GT_Sprite_CheckIDS(sourceSprite, align["MASK_EVIL"], 8)
	--
	local sourceActiveStats = EEex_Sprite_GetActiveStats(sourceSprite)
	local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
	--
	local targetRaceStr = GT_Resource_IDSToSymbol["race"][CGameSprite.m_typeAI.m_Race]
	--
	local roll = math.random(0, 3) -- engine: ((int)((rand() & 0x7fff) << 2) >> 0xf) => generates a random number, keeps its lower 15 bits, multiplies by 2^2, divides by 2^15
	--
	local effectCodes = {}
	--
	if targetRaceStr == "DEMONIC" or targetRaceStr == "MEPHIT" or targetRaceStr == "IMP" or targetRaceStr == "ELEMENTAL" or targetRaceStr == "SALAMANDER" or targetRaceStr == "SOLAR" or targetRaceStr == "ANTISOLAR" or targetRaceStr == "DARKPLANATAR" or targetRaceStr == "PLANATAR" or targetRaceStr == "GENIE" then -- if extraplanar ...
		if sourceActiveStats.m_nTurnUndeadLevel < (targetActiveStats.m_nLevel1 + roll) + 5 then
			if sourceActiveStats.m_nTurnUndeadLevel >= (targetActiveStats.m_nLevel1 + roll) then -- turn
				effectCodes = {
					{["op"] = 174, ["res"] = "ACT_06"}, -- play sound
					{["op"] = 141, ["p2"] = 24}, -- lighting effects (invocation air)
					{["op"] = 321, ["res"] = parentResRef}, -- remove effects by resource
					{["op"] = 24, ["p2"] = 1, ["dur"] = 60}, -- panic (bypass immunity)
					{["op"] = 142, ["p2"] = 36, ["dur"] = 60}, -- icon: panic
					{["op"] = 139, ["p1"] = 487814}, -- feedback string
				}
			end
		else -- destroy or take control
			if isEvil then -- take control
				effectCodes = {
					{["op"] = 174, ["res"] = "ACT_06"}, -- play sound
					{["op"] = 141, ["p2"] = 24}, -- lighting effects (invocation air)
					{["op"] = 321, ["res"] = parentResRef}, -- remove effects by resource
					{["op"] = 241, ["p2"] = 4, ["dur"] = 60}, -- control creature (charm type: controlled)
				}
			else -- destroy
				effectCodes = {
					{["op"] = 174, ["res"] = "ACT_06"}, -- play sound
					{["op"] = 141, ["p2"] = 24}, -- lighting effects (invocation air)
					{["op"] = 13, ["p2"] = 0x4, ["tmg"] = 4}, -- kill (normal death)
				}
			end
		end
		--
		for _, attributes in ipairs(effectCodes) do
			CGameSprite:applyEffect({
				["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
				["effectAmount"] = attributes["p1"] or 0,
				["dwFlags"] = attributes["p2"] or 0,
				["res"] = attributes["res"] or "",
				["duration"] = attributes["dur"] or 0,
				["durationType"] = attributes["tmg"] or 0,
				["noSave"] = true,
				["m_sourceRes"] = parentResRef,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
		end
	end
end

--[[
+----------------------------------------------------+
| cdtweaks, NWN-ish Circle Kick class feat for Monks |
+----------------------------------------------------+
--]]

-- Apply Ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual feat
	local apply = function()
		-- Mark the creature as 'feat applied'
		sprite:setLocalInt("gtNWNCircleKick", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTCL800",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 248, -- Melee hit effect
			["dwFlags"] = 4, -- fist-only
			["durationType"] = 9,
			["res"] = "GTCL800B", -- EFF file
			["m_sourceRes"] = "GTCL800",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's class / flags
	local spriteClassStr = GT_Resource_IDSToSymbol["class"][sprite.m_typeAI.m_Class]
	--
	local applyAbility = spriteClassStr == "MONK"
	--
	if sprite:getLocalInt("gtNWNCircleKick") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtNWNCircleKick", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL800",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- Core function --

function GTCL800(CGameEffect, CGameSprite)
	if CGameEffect.m_effectAmount == 1 then -- check if can perform a circle kick
		local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
		local sourceActiveStats = EEex_Sprite_GetActiveStats(sourceSprite)
		-- limit to once per round
		local conditionalString = '!GlobalTimerNotExpired("gtNWNCircleKickTimer","LOCALS") \n InWeaponRange(EEex_Target("gtCircleKickTarget"))'
		local responseString = 'SetGlobalTimer("gtNWNCircleKickTimer","LOCALS",6) \n ReallyForceSpellRES("GTCL800B",EEex_Target("gtCircleKickTarget"))'
		--
		local potentialTargets = {}
		if sourceSprite.m_typeAI.m_EnemyAlly > 200 then -- EVILCUTOFF
			potentialTargets = EEex_Sprite_GetAllOfTypeInRange(sourceSprite, GT_AI_ObjectType["GOODCUTOFF"], sourceSprite:virtual_GetVisualRange(), nil, nil, nil)
		elseif sourceSprite.m_typeAI.m_EnemyAlly < 30 then -- GOODCUTOFF
			potentialTargets = EEex_Sprite_GetAllOfTypeInRange(sourceSprite, GT_AI_ObjectType["EVILCUTOFF"], sourceSprite:virtual_GetVisualRange(), nil, nil, nil)
		end
		--
		for _, itrSprite in ipairs(potentialTargets) do
			if itrSprite.m_id ~= CGameSprite.m_id then -- skip current target
				--EEex_LuaObject = itrSprite -- must be global (we are not confortable with global / singleton vars...)
				--sourceSprite:setStoredScriptingTarget("gt_NWN_CircleKick_Target", itrSprite)
				--
				local itrSpriteActiveStats = EEex_Sprite_GetActiveStats(itrSprite)
				--
				if GT_EvalConditional["parseConditionalString"](sourceSprite, itrSprite, conditionalString, "gtCircleKickTarget") and EEex_IsBitUnset(itrSpriteActiveStats.m_generalState, 11) then -- if not dead
					if EEex_IsBitUnset(itrSpriteActiveStats.m_generalState, 0x4) or sourceActiveStats.m_bSeeInvisible > 0 then -- if not invisible or can see through invisibility
						if itrSpriteActiveStats.m_bSanctuary == 0 then
							GT_ExecuteResponse["parseResponseString"](sourceSprite, itrSprite, responseString, "gtCircleKickTarget")
							break
						end
					end
				end
			end
		end
	elseif CGameEffect.m_effectAmount == 2 then -- actual feat
		local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
		--
		local selectedWeapon = GT_Sprite_GetSelectedWeapon(sourceSprite)
		--
		local conditionalString = "EEex_IsImmuneToOpcode(Myself,12)"
		--
		local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
		--
		local damageTypeIDS, ACModifier = GT_Sprite_ItmDamageTypeToIDS(selectedWeapon["ability"].damageType, targetActiveStats)
		--
		if not GT_EvalConditional["parseConditionalString"](CGameSprite, nil, conditionalString) then
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 0xC, -- Damage
				["dwFlags"] = damageTypeIDS * 0x10000, -- mode: normal
				["numDice"] = selectedWeapon["ability"].damageDiceCount,
				["diceSize"] = selectedWeapon["ability"].damageDice,
				["effectAmount"] = selectedWeapon["ability"].damageDiceBonus,
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
		else
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 324, -- Immunity to resource and message
				["res"] = CGameEffect.m_sourceRes:get(),
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
		end
	end
end

--[[
+----------------------------------+
| cdtweaks, NWN-ish Barbarian Rage |
+----------------------------------+
--]]

-- Terrifying Rage --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	local splstate = GT_Resource_SymbolToIDS["splstate"]
	local stats = GT_Resource_SymbolToIDS["stats"]
	local class = GT_Resource_SymbolToIDS["class"]
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteKitStr = EEex_Resource_KitIDSToSymbol(sprite.m_derivedStats.m_nKit)
	--
	local isFighterAll = GT_Sprite_CheckIDS(sprite, class["FIGHTER_ALL"], 5)
	--
	local found = false
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		if effect.m_effectId == 401 and effect.m_special == stats["GT_DUMMY_STAT"] and effect.m_scriptName:get() == "gtNWNBarbarianRageTimer" then -- dummy opcode that acts as a marker/timer
			found = true
			return true
		end
	end)
	--
	if spriteKitStr == "BARBARIAN" and isFighterAll then
		if EEex_Sprite_GetSpellState(sprite, splstate["BARBARIAN_RAGE"]) then
			if not found then
				sprite:applyEffect({
					["effectID"] = 146, -- Cast spl
					["dwFlags"] = 1, -- mode: cast instantly / ignore level
					["res"] = "GTCL152B",
					["sourceID"] = sprite.m_id,
					["sourceTarget"] = sprite.m_id,
				})
				-- set timer
				sprite:applyEffect({
					["effectID"] = 401, -- Set extended stat
					["special"] = stats["GT_DUMMY_STAT"],
					["m_scriptName"] = "gtNWNBarbarianRageTimer",
					["duration"] = 6,
					["noSave"] = true,
					["m_sourceRes"] = "GTCL152",
					["sourceID"] = sprite.m_id,
					["sourceTarget"] = sprite.m_id,
				})
			end
		end
	end
end)

-- Rage / Terrifying Rage / Thundering Rage --

function GTCL152(CGameEffect, CGameSprite)
	if CGameEffect.m_effectAmount == 1 then
		local spriteActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
		--
		local gtabmod = GT_Resource_2DA["gtabmod"]
		local conModifier = tonumber(gtabmod[string.format("%s", spriteActiveStats.m_nCON)]["BONUS"])
		--
		local splstate = GT_Resource_SymbolToIDS["splstate"]
		--
		local effectCodes = {
			{["op"] = 328, ["p2"] = splstate["BARBARIAN_RAGE"], ["spec"] = 1}, -- set spell state
			{["op"] = 282, ["p2"] = 3, ["p1"] = 1}, -- modify script state
			{["op"] = 44, ["p1"] = 4}, -- STR mod (+4)
			{["op"] = 10, ["p1"] = 4}, -- CON mod (+4)
			{["op"] = 37, ["p1"] = 2}, -- save vs. spell bonus (+2)
			{["op"] = 0, ["p1"] = -2}, -- AC bonus (-2)
			{["op"] = 341, ["res"] = "GTCL152C", ["spec"] = 1}, -- critical hit effect (melee attacks only, +2d6 extra damage)
			{["op"] = 248, ["res"] = "GTCL152D"}, -- melee hit effect (deafness, 25% chance, no save)
			{["op"] = 142, ["p2"] = 138}, -- icon: rage
			{["op"] = 206, ["res"] = CGameEffect.m_sourceRes:get(), ["p1"] = 487821}, -- protection from spell
		}
		--
		for _, attributes in ipairs(effectCodes) do
			CGameSprite:applyEffect({
				["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
				["effectAmount"] = attributes["p1"] or 0,
				["dwFlags"] = attributes["p2"] or 0,
				["special"] = attributes["spec"] or 0,
				["res"] = attributes["res"] or "",
				["duration"] = (6 * 7) + (6 * conModifier),
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameSprite.m_id,
				["sourceTarget"] = CGameSprite.m_id,
			})
		end
	elseif CGameEffect.m_effectAmount == 2 then -- Terrifying Rage
		local roll = Infinity_RandomNumber(1, 3) -- 1d3
		--
		local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
		local sourceActiveStats = EEex_Sprite_GetActiveStats(sourceSprite)
		--
		local panicImmunity = "EEex_IsImmuneToOpcode(Myself,24)"
		--
		if not GT_EvalConditional["parseConditionalString"](CGameSprite, nil, panicImmunity) then
			local effectCodes = {}
			--
			if sourceActiveStats.m_nLevel1 > 1 then
				effectCodes = {
					{["op"] = 54, ["dur"] = 6 * roll, ["p1"] = -2, ["minLvl"] = sourceActiveStats.m_nLevel1, ["maxLvl"] = sourceActiveStats.m_nLevel1}, -- base thac0 bonus (-2)
					{["op"] = 325, ["dur"] = 6 * roll, ["p1"] = -2, ["minLvl"] = sourceActiveStats.m_nLevel1, ["maxLvl"] = sourceActiveStats.m_nLevel1}, -- save vs. all bonus (-2)
					{["op"] = 139, ["p1"] = 487822, ["minLvl"] = sourceActiveStats.m_nLevel1, ["maxLvl"] = sourceActiveStats.m_nLevel1}, -- string: trembling with fear
					--
					{["op"] = 24, ["dur"] = 6 * roll, ["maxLvl"] = sourceActiveStats.m_nLevel1 - 1}, -- panic
					{["op"] = 142, ["dur"] = 6 * roll, ["p2"] = 36, ["maxLvl"] = sourceActiveStats.m_nLevel1 - 1}, -- icon: panic
					{["op"] = 139, ["p1"] = 225818, ["maxLvl"] = sourceActiveStats.m_nLevel1 - 1}, -- string: panic
				}
			else
				effectCodes = {
					{["op"] = 54, ["dur"] = 6 * roll, ["p1"] = -2, ["minLvl"] = sourceActiveStats.m_nLevel1, ["maxLvl"] = sourceActiveStats.m_nLevel1}, -- base thac0 bonus (-2)
					{["op"] = 325, ["dur"] = 6 * roll, ["p1"] = -2, ["minLvl"] = sourceActiveStats.m_nLevel1, ["maxLvl"] = sourceActiveStats.m_nLevel1}, -- save vs. all bonus (-2)
					{["op"] = 139, ["p1"] = 487822, ["minLvl"] = sourceActiveStats.m_nLevel1, ["maxLvl"] = sourceActiveStats.m_nLevel1}, -- string: trembling with fear
				}
			end
			--
			local savebonus = math.floor((sourceActiveStats.m_nLevel1 - 1) / 4) -- +1 every 4 levels, starting at 0
			if savebonus > 7 then
				savebonus = 7 -- cap at 7
			end
			--
			for _, attributes in ipairs(effectCodes) do
				CGameSprite:applyEffect({
					["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
					["effectAmount"] = attributes["p1"] or 0,
					["dwFlags"] = attributes["p2"] or 0,
					["duration"] = attributes["dur"] or 0,
					["savingThrow"] = 0x4, -- save vs. death
					["saveMod"] = -1 * savebonus,
					["m_minLevel"] = attributes["minLvl"] or 0,
					["m_maxLevel"] = attributes["maxLvl"] or 0,
					["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
					["m_sourceType"] = CGameEffect.m_sourceType,
					["sourceID"] = CGameEffect.m_sourceId,
					["sourceTarget"] = CGameEffect.m_sourceTarget,
				})
			end
		else
			CGameSprite:applyEffect({
				["effectID"] = 139, -- display string
				["effectAmount"] = 487823,
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
		end
	elseif CGameEffect.m_effectAmount == 3 then -- Thundering Rage
		local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
		--
		local selectedWeapon = GT_Sprite_GetSelectedWeapon(sourceSprite)
		--
		local items = sourceSprite.m_equipment.m_items -- Array<CItem*,39>
		--
		local offHand = items:get(9) -- CItem
		if offHand and sourceSprite.m_leftAttack == 1 then
			local pHeader = offHand.pRes.pHeader -- Item_Header_st
			--
			if EEex_Resource_ItemCategoryIDSToSymbol(pHeader.itemType) ~= "SHIELD" then -- if not shield, then overwrite item ability...
				selectedWeapon["ability"] = EEex_Resource_GetItemAbility(pHeader, 0) -- Item_ability_st
			end
		end
		--
		local damageImmunity = "EEex_IsImmuneToOpcode(Myself,12)"
		--
		local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
		--
		local damageTypeIDS, ACModifier = GT_Sprite_ItmDamageTypeToIDS(selectedWeapon["ability"].damageType, targetActiveStats)
		--
		if not GT_EvalConditional["parseConditionalString"](CGameSprite, nil, damageImmunity) then
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 0xC, -- Damage
				["dwFlags"] = damageTypeIDS * 0x10000, -- mode: normal
				["numDice"] = 2,
				["diceSize"] = 6,
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
		else
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 324, -- Immunity to resource and message
				["res"] = CGameEffect.m_sourceRes:get(),
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
		end
	end
end

--[[
+-----------------------------------------------------------------------------+
| cdtweaks, Revised Archer Kit (+X missile thac0/damage bonus with bows only) |
+-----------------------------------------------------------------------------+
--]]

-- Apply bonus --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual bonus
	local apply = function(bonus)
		-- Update tracking var
		sprite:setLocalInt("gtArcherKitBonus", bonus)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTCL122",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 167, -- Missile THAC0 bonus
			["durationType"] = 9,
			["effectAmount"] = bonus,
			["m_sourceRes"] = "GTCL122",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 286, -- Missile weapon damage bonus
			["durationType"] = 9,
			["effectAmount"] = bonus,
			["m_sourceRes"] = "GTCL122",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's equipment / class / kit / levels
	local spriteClassStr = GT_Resource_IDSToSymbol["class"][sprite.m_typeAI.m_Class]
	--
	local selectedWeapon = GT_Sprite_GetSelectedWeapon(sprite)
	local selectedWeaponTypeStr = EEex_Resource_ItemCategoryIDSToSymbol(selectedWeapon["header"].itemType)
	--
	local spriteFlags = sprite.m_baseStats.m_flags
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteLevel1 = sprite.m_derivedStats.m_nLevel1
	local spriteLevel2 = sprite.m_derivedStats.m_nLevel2
	local spriteKitStr = EEex_Resource_KitIDSToSymbol(sprite.m_derivedStats.m_nKit)
	-- any ranger (single/multi/(complete)dual, not fallen)
	local isRanger = spriteClassStr == "RANGER"
	local isClericRanger = spriteClassStr == "CLERIC_RANGER" and (EEex_IsBitUnset(spriteFlags, 0x8) or spriteLevel1 > spriteLevel2)
	local isFallenRanger = EEex_IsBitSet(spriteFlags, 10)
	--
	local bonus = 0
	--
	if isRanger then
		if spriteLevel1 <= 18 then
			bonus = math.floor(spriteLevel1 / 3)
		else
			bonus = math.floor((spriteLevel1 - 18) / 5) + (18 / 3)
		end
	elseif isClericRanger then
		if spriteLevel2 <= 18 then
			bonus = math.floor(spriteLevel2 / 3)
		else
			bonus = math.floor((spriteLevel2 - 18) / 5) + (18 / 3)
		end
	end
	-- (Bow with arrows equipped || bow with unlimited ammo equipped) && Archer kit
	local applyAbility = (selectedWeaponTypeStr == "ARROW" or selectedWeaponTypeStr == "BOW")
		and spriteKitStr == "FERALAN"
		and ((isRanger or isClericRanger) and not isFallenRanger)
		and bonus > 0
	--
	if sprite:getLocalInt("gtArcherKitBonus") == 0 then
		if applyAbility then
			apply(bonus)
		end
	else
		if applyAbility then
			-- Check if level has changed since the last application
			if bonus ~= sprite:getLocalInt("gtArcherKitBonus") then
				apply(bonus)
			end
		else
			-- Mark the creature as 'bonus removed'
			sprite:setLocalInt("gtArcherKitBonus", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL122",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

--[[
+--------------------------------------------+
| cdtweaks, Revised Archer Kit (Called Shot) |
+--------------------------------------------+
--]]

-- NWN-ish Called Shot ability (main) --

function GTCL121(CGameEffect, CGameSprite)
	-- Creatures with no arms --
	local armless = {
		{"WEAPON"}, -- GENERAL.IDS
		{"DOG", "WOLF", "ANKHEG", "BASILISK", "CARRIONCRAWLER", "SPIDER", "WYVERN", "SLIME", "BEHOLDER", "DEMILICH", "BEETLE", "BIRD", "WILL-O-WISP"}, -- RACE.IDS
		{"WOLF_WORG", "ELEMENTAL_AIR", "WIZARD_EYE"}, -- CLASS.IDS
		-- ANIMATE.IDS
		{
			"DOOM_GUARD", "DOOM_GUARD_LARGER", -- 0x6000
			"SNAKE", "DANCING_SWORD", "BLOB_MIST_CREATURE", "HAKEASHAR", "NISHRUU", "SNAKE_WATER", -- 0x7000
			"BOAR_ARCTIC", "BOAR_WILD", "BONEBAT", "WATER_WEIRD", "GT_NWN_FALCON" -- 0xE000
		},
	}
	-- Creatures with no legs --
	local legless = {
		{"WEAPON"}, -- GENERAL.IDS
		{"ANKHEG", "WYVERN", "SLIME", "BEHOLDER", "MEPHIT", "IMP", "YUANTI", "DEMILICH", "FEYR", "SALAMANDER", "BIRD", "WILL-O-WISP"}, -- RACE.IDS
		{"MEPHIT", "ELEMENTAL_AIR", "WIZARD_EYE"}, -- CLASS.IDS
		-- ANIMATE.IDS
		{
			"DOOM_GUARD", "DOOM_GUARD_LARGER", -- 0x6000
			"IMP", "SNAKE", "DANCING_SWORD", "MIST_CREATURE", "BLOB_MIST_CREATURE", "HAKEASHAR", "NISHRUU", "SNAKE_WATER", -- 0x7000
			"LEMURE", "BONEBAT", "SHADOW_SMALL", "SHADOW_LARGE", "WATER_WEIRD", "GT_NWN_FALCON" -- 0xE000
		},
	}
	--
	if CGameEffect.m_effectAmount == 0 then
		-- do nothing (AoE missile!)
	else
		local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId) -- CGameSprite
		--
		local targetGeneralStr = GT_Resource_IDSToSymbol["general"][CGameSprite.m_typeAI.m_General]
		local targetRaceStr = GT_Resource_IDSToSymbol["race"][CGameSprite.m_typeAI.m_Race]
		local targetClassStr = GT_Resource_IDSToSymbol["class"][CGameSprite.m_typeAI.m_Class]
		local targetAnimateStr = GT_Resource_IDSToSymbol["animate"][CGameSprite.m_animation.m_animation.m_animationID]
		--
		local targetIDS = {targetGeneralStr, targetRaceStr, targetClassStr, targetAnimateStr}
		-- Fetch components of check
		local roll = Infinity_RandomNumber(1, 20) -- 1d20
		--
		local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite) -- CDerivedStats
		--
		local sourceActiveStats = EEex_Sprite_GetActiveStats(sourceSprite) -- CDerivedStats
		--
		local thac0 = sourceActiveStats.m_nTHAC0 -- base thac0 (STAT 7)
		local luck = sourceActiveStats.m_nLuck -- STAT 32
		local thac0BonusRight = sourceActiveStats.m_THAC0BonusRight -- this should include the bonus from the weapon + dex + wspecial.2da + op167 (STAT 72)
		--local missileTHAC0Bonus = sourceActiveStats.m_nMissileTHAC0Bonus -- op167 (STAT 72)
		-- op178
		local thac0VsTypeBonus = GT_Sprite_Thac0VsTypeBonus(sourceSprite, CGameSprite)
		-- op219
		local attackRollPenalty = GT_Sprite_AttackRollPenalty(sourceSprite, CGameSprite)
		-- racial enemy
		local racialEnemy = GT_Sprite_GetRacialEnemyBonus(sourceSprite, CGameSprite)
		-- op120
		local conditionalString = 'WeaponEffectiveVs(EEex_Target("gtCalledShotTarget"),MAINHAND)'
		-- mainhand weapon
		local selectedWeapon = GT_Sprite_GetSelectedWeapon(sourceSprite)
		--
		local damageTypeIDS, ACModifier = GT_Sprite_ItmDamageTypeToIDS(selectedWeapon["ability"].damageType, targetActiveStats)
		--
		if GT_EvalConditional["parseConditionalString"](sourceSprite, CGameSprite, conditionalString, "gtCalledShotTarget") then
			-- compute attack roll (am I missing something...?)
			local success = false
			local modifier = luck + thac0BonusRight + thac0VsTypeBonus - attackRollPenalty + racialEnemy - 4
			--
			local criticalHitMod, criticalMissMod = GT_Sprite_GetCriticalModifiers(sourceSprite)
			--
			local m_nTimeStopCaster = EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_nTimeStopCaster
			--
			if (roll >= 20 - criticalHitMod) or EEex_BAnd(targetActiveStats.m_generalState, 0x100029) ~= 0 or m_nTimeStopCaster == sourceSprite.m_id then -- automatic hit
				success = true
				modifier = 0
			elseif roll <= 1 + criticalMissMod then -- automatic miss (critical failure)
				modifier = 0
			elseif roll + modifier >= thac0 - (targetActiveStats.m_nArmorClass + ACModifier) then
				success = true
			end
			--
			if success then
				-- display feedback message
				GT_Sprite_DisplayMessage(sourceSprite,
					string.format("%s : %d %s %d = %d : %s",
						CGameEffect.m_effectAmount == 1 and Infinity_FetchString(487825) or Infinity_FetchString(487827), roll, modifier < 0 and "-" or "+", math.abs(modifier), roll + modifier, Infinity_FetchString(225413)),
					0xBED7D7
				)
				--
				if CGameEffect.m_effectAmount == 1 then
					-- Called Shot (Arms): -2 thac0 penalty
					local found = false
					--
					do
						for index, symbolList in ipairs(armless) do
							for _, symbol in ipairs(symbolList) do
								if targetIDS[index] == symbol then
									found = true
									break
								end
							end
						end
					end
					--
					if not found then
						local effectCodes = {
							{["op"] = 54, ["p1"] = -2, ["dur"] = 24}, -- base thac0 bonus
							{["op"] = 139, ["p1"] = 214052} -- feedback string
						}
						--
						for _, attributes in ipairs(effectCodes) do
							CGameSprite:applyEffect({
								["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
								["effectAmount"] = attributes["p1"] or 0,
								["duration"] = attributes["dur"] or 0,
								--["savingThrow"] = 0x2, -- save vs. breath
								--["saveMod"] = -1 * savebonus,
								["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
								["m_sourceType"] = CGameEffect.m_sourceType,
								["sourceID"] = CGameEffect.m_sourceId,
								["sourceTarget"] = CGameEffect.m_sourceTarget,
							})
						end
					else
						CGameSprite:applyEffect({
							["effectID"] = 139, -- display string
							["effectAmount"] = 487830,
							["sourceID"] = CGameEffect.m_sourceId,
							["sourceTarget"] = CGameEffect.m_sourceTarget,
						})
					end
				elseif CGameEffect.m_effectAmount == 2 then
					-- Called Shot (Legs): -2 dex penalty, 20% movement rate penalty
					local found = false
					--
					do
						for index, symbolList in ipairs(legless) do
							for _, symbol in ipairs(symbolList) do
								if targetIDS[index] == symbol then
									found = true
									break
								end
							end
						end
					end
					--
					if not found then
						local targetDEX = CGameSprite:getActiveStats().m_nDEX
						--
						local effectCodes = {
							{["op"] = 15, ["p1"] = (targetDEX <= 1) and 0 or ((targetDEX > 2) and -2 or -1), ["dur"] = 24}, -- dex bonus
							{["op"] = 176, ["p1"] = 80, ["p2"] = 5, ["dur"] = 24}, -- movement rate bonus (mode: multiply %)
							{["op"] = 139, ["p1"] = 214024} -- feedback string
						}
						--
						for _, attributes in ipairs(effectCodes) do
							CGameSprite:applyEffect({
								["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
								["effectAmount"] = attributes["p1"] or 0,
								["dwFlags"] = attributes["p2"] or 0,
								["duration"] = attributes["dur"] or 0,
								--["savingThrow"] = 0x2, -- save vs. breath
								--["saveMod"] = -1 * savebonus,
								["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
								["m_sourceType"] = CGameEffect.m_sourceType,
								["sourceID"] = CGameEffect.m_sourceId,
								["sourceTarget"] = CGameEffect.m_sourceTarget,
							})
						end
					else
						CGameSprite:applyEffect({
							["effectID"] = 139, -- display string
							["effectAmount"] = 487830,
							["sourceID"] = CGameEffect.m_sourceId,
							["sourceTarget"] = CGameEffect.m_sourceTarget,
						})
					end
				end
			else
				-- display feedback message
				GT_Sprite_DisplayMessage(sourceSprite,
					string.format("%s : %d %s %d = %d : %s",
						CGameEffect.m_effectAmount == 1 and Infinity_FetchString(487825) or Infinity_FetchString(487827), roll, modifier < 0 and "-" or "+", math.abs(modifier), roll + modifier, Infinity_FetchString(216461)),
					0xBED7D7
				)
			end
		else
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 139, -- Display string
				["effectAmount"] = 487832,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
		end
	end
end

-- Make it castable at will. Prevent spell disruption. Check if bow equipped --

EEex_Sprite_AddQuickListsCheckedListener(function(sprite, resref, changeAmount)
	local curAction = sprite.m_curAction
	local spriteAux = EEex_GetUDAux(sprite)

	local resToAux = {
		["GTCL121B"] = "gt_NWN_CallShotArm_TargetID",
		["GTCL121C"] = "gt_NWN_CallShotLeg_TargetID",
	}

	if not (sprite:getLocalInt("gtNWNCalledShot") == 1 and curAction.m_actionID == 31 and resToAux[resref] and changeAmount < 0) then
		return
	end

	-- recast as ``ForceSpell()`` (so as to prevent spell disruption)
	curAction.m_actionID = 113

	local spellHeader = EEex_Resource_Demand(resref, "SPL")
	local spellLevelMemListArray = sprite.m_memorizedSpellsInnate
	local memList = spellLevelMemListArray:getReference(spellHeader.spellLevel - 1) -- !!!count starts from 0!!!

	-- restore memorization bit
	EEex_Utility_IterateCPtrList(memList, function(memInstance)
		local memInstanceResref = memInstance.m_spellId:get()
		if memInstanceResref == resref then
			local memFlags = memInstance.m_flags
			if EEex_IsBitUnset(memFlags, 0x0) then
				memInstance.m_flags = EEex_SetBit(memFlags, 0x0)
			end
		end
	end)

	-- make sure the creature is equipped with a bow
	local selectedWeapon = GT_Sprite_GetSelectedWeapon(sprite)
	local selectedWeaponTypeStr = EEex_Resource_ItemCategoryIDSToSymbol(selectedWeapon["header"].itemType)
	-- Bow with arrows equipped || bow with unlimited ammo equipped
	if selectedWeaponTypeStr == "ARROW" or selectedWeaponTypeStr == "BOW" then
		-- store target id
		spriteAux[resToAux[resref]] = curAction.m_acteeID.m_Instance
		-- initialize the attack frame counter
		sprite.m_attackFrame = 0
	else
		sprite:applyEffect({
			["effectID"] = 139, -- Display string
			["effectAmount"] = 487829,
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
end)

-- Cast the "real" spl (ability) when the attack frame counter is 6 --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	local spriteAux = EEex_GetUDAux(sprite)
	--
	local auxToRes = {
		["gt_NWN_CallShotArm_TargetID"] = "GTCL121D",
		["gt_NWN_CallShotLeg_TargetID"] = "GTCL121E",
	}
	-- make sure the creature is equipped with a bow
	local selectedWeapon = GT_Sprite_GetSelectedWeapon(sprite)
	local selectedWeaponTypeStr = EEex_Resource_ItemCategoryIDSToSymbol(selectedWeapon["header"].itemType)
	--
	if sprite:getLocalInt("gtNWNCalledShot") == 1 then
		if selectedWeaponTypeStr == "ARROW" or selectedWeaponTypeStr == "BOW" then
			if sprite.m_nSequence == 8 and sprite.m_attackFrame == 6 then -- SetSequence(SEQ_SHOOT)
				for aux, res in pairs(auxToRes) do
					if spriteAux[aux] then
						-- retrieve / forget target sprite
						local targetSprite = EEex_GameObject_Get(spriteAux[aux])
						spriteAux[aux] = nil
						-- make sure to use the currently selected projectile
						if targetSprite then
							sprite:applyEffect({
								["effectID"] = 408, -- projectile mutator
								["durationType"] = 10, -- ticks
								["duration"] = 1,
								["res"] = "GTCL121P",
								["sourceID"] = sprite.m_id,
								["sourceTarget"] = sprite.m_id,
							})
							targetSprite:applyEffect({
								["effectID"] = 146, -- cast spl
								["dwFlags"] = 1, -- instant / ignore level
								["res"] = res,
								["sourceID"] = sprite.m_id,
								["sourceTarget"] = targetSprite.m_id,
							})
						end
						--
						break
					end
				end
			end
		end
	end
end)

-- Make sure to use the currently selected projectile. Print a warning in case of AoE missiles --

GTCL121P = {

	["typeMutator"] = function(context)
		local actionSources = {
			[EEex_Projectile_DecodeSource.CGameAIBase_FireSpell] = true,
		}
		--
		local originatingSprite = context["originatingSprite"] -- CGameSprite
		local projectileTypeStr = GT_Resource_IDSToSymbol["missile"][context["projectileType"]] -- The projectile type about to be decoded
		--
		if not actionSources[context.decodeSource] then
			return
		end
		--
		local selectedWeapon = GT_Sprite_GetSelectedWeapon(originatingSprite)
		-- morph projectile
		if projectileTypeStr == "GT_Called_Shot" then
			return selectedWeapon["ability"].missileType
		end
	end,

	["projectileMutator"] = function(context)
		local actionSources = {
			[EEex_Projectile_DecodeSource.CGameAIBase_FireSpell] = true,
		}
		--
		if not actionSources[context.decodeSource] then
			return
		end
	end,

	["effectMutator"] = function(context)
		local actionSources = {
			[EEex_Projectile_AddEffectSource.CGameAIBase_FireSpell] = true,
		}
		--
		if not actionSources[context.addEffectSource] then
			return
		end
		--
		local effect = context["effect"] -- CGameEffect
		local projectile = context["projectile"] -- CProjectile
		local originatingSprite = context["originatingSprite"] -- CGameSprite
		--
		if EEex_Projectile_IsOfType(projectile, EEex_Projectile_Type["CProjectileArea"]) then
			if effect.m_effectId == 402 then -- invoke lua
				if effect.m_res:get() == "GTCL121" then
					-- print warning
					originatingSprite:applyEffect({
						["effectID"] = 139, -- display string
						["effectAmount"] = 487831,
						["sourceID"] = originatingSprite.m_id,
						["sourceTarget"] = originatingSprite.m_id,
					})
					-- nuke 402
					effect.m_effectAmount = 0
				end
			end
		end
	end,
}

-- Forget about ``spriteAux["gt_Aux_NWN_CallShotX_TargetID"]`` if the player manually interrupts the action --

EEex_Action_AddSpriteStartedActionListener(function(sprite, action)
	local spriteAux = EEex_GetUDAux(sprite)
	--
	local resToAux = {
		["GTCL121B"] = "gt_NWN_CallShotArm_TargetID",
		["GTCL121C"] = "gt_NWN_CallShotLeg_TargetID",
	}
	--
	if sprite:getLocalInt("gtNWNCalledShot") == 1 then
		if not (action.m_actionID == 113 and resToAux[action.m_string1.m_pchData:get()]) then
			for _, aux in pairs(resToAux) do
				if spriteAux[aux] ~= nil then
					spriteAux[aux] = nil
				end
			end
		end
	end
end)

-- NWN-ish Called Shot ability. Gain ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) or Infinity_GetCurrentScreenName() == 'CHARGEN' then
		return
	end
	-- internal function that grants the ability
	local gain = function()
		-- Mark the creature as 'feat granted'
		sprite:setLocalInt("gtNWNCalledShot", 1)
		--
		local effectCodes = {
			{["op"] = 172, ["res"] = "GTCL121B"}, -- remove spell
			{["op"] = 171, ["res"] = "GTCL121B"}, -- give spell
			{["op"] = 172, ["res"] = "GTCL121C"}, -- remove spell
			{["op"] = 171, ["res"] = "GTCL121C"}, -- give spell
		}
		--
		for _, attributes in ipairs(effectCodes) do
			sprite:applyEffect({
				["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
				["res"] = attributes["res"] or "",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
	-- Check creature's class / kit
	local class = GT_Resource_SymbolToIDS["class"]
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteKitStr = EEex_Resource_KitIDSToSymbol(sprite.m_derivedStats.m_nKit)
	-- any ranger (single/multi/(complete)dual, not fallen)
	local isRangerAll = GT_Sprite_CheckIDS(sprite, class["RANGER_ALL"], 5, true)
	--
	local gainAbility = spriteKitStr == "FERALAN" and isRangerAll
	--
	if sprite:getLocalInt("gtNWNCalledShot") == 0 then
		if gainAbility then
			gain()
		end
	else
		if gainAbility then
			-- do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtNWNCalledShot", 0)
			--
			sprite:applyEffect({
				["effectID"] = 172, -- remove spell
				["res"] = "GTCL121B",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
			sprite:applyEffect({
				["effectID"] = 172, -- remove spell
				["res"] = "GTCL121C",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

--[[
+---------------------------------------------+
| cdtweaks, Revised Archer Kit (Manyshot HLA) |
+---------------------------------------------+
--]]

-- Shoot two arrows at a time --

GTCL123P = {

	["typeMutator"] = function(context)
		local actionSources = {
			[EEex_Projectile_DecodeSource.CGameSprite_Swing] = true,
		}
		--
		if not actionSources[context.decodeSource] then
			return
		end
	end,

	["projectileMutator"] = function(context)
		local actionSources = {
			[EEex_Projectile_DecodeSource.CGameSprite_Swing] = true,
		}
		--
		if not actionSources[context.decodeSource] then
			return
		end
		--
		local originatingSprite = context["originatingSprite"] -- CGameSprite
		local sourceActiveStats = EEex_Sprite_GetActiveStats(originatingSprite) -- CDerivedStats
		--
		local targetSprite = EEex_GameObject_Get(originatingSprite.m_targetId) -- CGameSprite
		local targetActiveStats = EEex_Sprite_GetActiveStats(targetSprite) -- CDerivedStats
		--
		local selectedWeapon = GT_Sprite_GetSelectedWeapon(originatingSprite)
		local selectedWeaponTypeStr = EEex_Resource_ItemCategoryIDSToSymbol(selectedWeapon["header"].itemType)
		--
		local damageTypeIDS, ACModifier = GT_Sprite_ItmDamageTypeToIDS(selectedWeapon["ability"].damageType, targetActiveStats)
		-- Bow with arrows equipped || bow with unlimited ammo equipped
		if selectedWeaponTypeStr == "ARROW" or selectedWeaponTypeStr == "BOW" then
			--
			local projectile = context["projectile"] -- CProjectile
			-- Add main op12 (launcher + wspecial + ammo)
			do
				local damageBonus = sourceActiveStats.m_nDamageBonus -- op73
				local damageBonusRight = sourceActiveStats.m_DamageBonusRight -- wspecial.2da
				local missileDamageBonus = sourceActiveStats.m_nMissileDamageBonus -- op286 (STAT 168)
				-- op179
				local damageVsTypeBonus = GT_Sprite_DamageVsTypeBonus(originatingSprite, targetSprite)
				-- racial enemy
				local racialEnemy = GT_Sprite_GetRacialEnemyBonus(originatingSprite, targetSprite)
				--
				local modifier = damageBonus + damageBonusRight + missileDamageBonus + damageVsTypeBonus + racialEnemy
				--
				projectile:AddEffect(GT_Utility_DecodeEffect(
					{
						["effectID"] = 0xC, -- Damage
						["effectAmount"] = (selectedWeapon["ability"].damageDiceCount == 0 and selectedWeapon["ability"].damageDice == 0 and selectedWeapon["ability"].damageDiceBonus == 0) and 0 or (modifier + selectedWeapon["ability"].damageDiceBonus),
						["numDice"] = selectedWeapon["ability"].damageDiceCount,
						["diceSize"] = selectedWeapon["ability"].damageDice,
						["dwFlags"] = damageTypeIDS * 0x10000,
						--
						["sourceX"] = originatingSprite.m_pos.x,
						["sourceY"] = originatingSprite.m_pos.y,
						["targetX"] = targetSprite.m_pos.x,
						["targetY"] = targetSprite.m_pos.y,
						--
						["m_projectileType"] = selectedWeapon["ability"].missileType - 1,
						--
						["sourceID"] = originatingSprite.m_id,
						["sourceTarget"] = targetSprite.m_id,
					}
				))
			end
			-- Add on-hit effect(s) (ammo)
			do
				local currentEffectAddress = EEex_UDToPtr(selectedWeapon["header"]) + selectedWeapon["header"].effectsOffset + selectedWeapon["ability"].startingEffect * Item_effect_st.sizeof
				--
				for i = 1, selectedWeapon["ability"].effectCount do
					local pEffect = EEex_PtrToUD(currentEffectAddress, "Item_effect_st")
					--
					projectile:AddEffect(GT_Utility_DecodeEffect(
						{
							["effectID"] = pEffect.effectID,
							["targetType"] = pEffect.targetType,
							["spellLevel"] = pEffect.spellLevel,
							["effectAmount"] = pEffect.effectAmount,
							["dwFlags"] = pEffect.dwFlags,
							["durationType"] = EEex_BAnd(pEffect.durationType, 0xFF),
							["duration"] = pEffect.duration,
							["probabilityUpper"] = pEffect.probabilityUpper,
							["probabilityLower"] = pEffect.probabilityLower,
							["res"] = pEffect.res:get(),
							["numDice"] = pEffect.numDice,
							["diceSize"] = pEffect.diceSize,
							["savingThrow"] = pEffect.savingThrow,
							["saveMod"] = pEffect.saveMod,
							["special"] = pEffect.special,
							--
							["m_school"] = selectedWeapon["ability"].school,
							["m_secondaryType"] = selectedWeapon["ability"].secondaryType,
							["m_flags"] = EEex_RShift(pEffect.durationType, 8),
							["m_projectileType"] = selectedWeapon["ability"].missileType - 1,
							--
							["m_sourceRes"] = selectedWeapon["weapon"].pRes.resref:get(),
							["m_sourceType"] = 2,
							--
							["sourceX"] = originatingSprite.m_pos.x,
							["sourceY"] = originatingSprite.m_pos.y,
							["targetX"] = targetSprite.m_pos.x,
							["targetY"] = targetSprite.m_pos.y,
							--
							["sourceID"] = originatingSprite.m_id,
							["sourceTarget"] = targetSprite.m_id,
						}
					))
					--
					currentEffectAddress = currentEffectAddress + Item_effect_st.sizeof
				end
			end
			-- Add on-hit effect(s) (launcher)
			if selectedWeapon["launcher"] then
				local pHeader = selectedWeapon["launcher"].pRes.pHeader -- Item_Header_st
				--
				local pAbility
				for i = 1, pHeader.abilityCount do
					pAbility = EEex_Resource_GetCItemAbility(selectedWeapon["launcher"], i - 1) -- Item_ability_st
					if pAbility.type == 0x4 then -- Launcher
						break
					end
				end
				--
				local currentEffectAddress = EEex_UDToPtr(pHeader) + pHeader.effectsOffset + pAbility.startingEffect * Item_effect_st.sizeof
				--
				for i = 1, pAbility.effectCount do
					local pEffect = EEex_PtrToUD(currentEffectAddress, "Item_effect_st")
					--
					projectile:AddEffect(GT_Utility_DecodeEffect(
						{
							["effectID"] = pEffect.effectID,
							["targetType"] = pEffect.targetType,
							["spellLevel"] = pEffect.spellLevel,
							["effectAmount"] = pEffect.effectAmount,
							["dwFlags"] = pEffect.dwFlags,
							["durationType"] = EEex_BAnd(pEffect.durationType, 0xFF),
							["duration"] = pEffect.duration,
							["probabilityUpper"] = pEffect.probabilityUpper,
							["probabilityLower"] = pEffect.probabilityLower,
							["res"] = pEffect.res:get(),
							["numDice"] = pEffect.numDice,
							["diceSize"] = pEffect.diceSize,
							["savingThrow"] = pEffect.savingThrow,
							["saveMod"] = pEffect.saveMod,
							["special"] = pEffect.special,
							--
							["m_school"] = pAbility.school,
							["m_secondaryType"] = pAbility.secondaryType,
							["m_flags"] = EEex_RShift(pEffect.durationType, 8),
							["m_projectileType"] = pAbility.missileType - 1,
							--
							["m_sourceRes"] = selectedWeapon["launcher"].pRes.resref:get(),
							["m_sourceType"] = 2,
							--
							["sourceX"] = originatingSprite.m_pos.x,
							["sourceY"] = originatingSprite.m_pos.y,
							["targetX"] = targetSprite.m_pos.x,
							["targetY"] = targetSprite.m_pos.y,
							--
							["sourceID"] = originatingSprite.m_id,
							["sourceTarget"] = targetSprite.m_id,
						}
					))
					--
					currentEffectAddress = currentEffectAddress + Item_effect_st.sizeof
				end
			end
		end
	end,

	["effectMutator"] = function(context)
		local actionSources = {
			[EEex_Projectile_AddEffectSource.CGameSprite_Swing] = true,
		}
		--
		if not actionSources[context.addEffectSource] then
			return
		end
	end,

}

-- Apply ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual passive HLA
	local apply = function()
		-- Mark the creature as 'HLA applied'
		sprite:setLocalInt("gtNWNManyshot", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTCL123",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 408, -- EEex: Projectile Mutator
			["durationType"] = 9,
			["res"] = "GTCL123P", -- Lua
			["m_sourceRes"] = "GTCL123",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's / class / kit / levels
	local class = GT_Resource_SymbolToIDS["class"]
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteKitStr = EEex_Resource_KitIDSToSymbol(sprite.m_derivedStats.m_nKit)
	-- any ranger (single/multi/(complete)dual, not fallen)
	local isRangerAll = GT_Sprite_CheckIDS(sprite, class["RANGER_ALL"], 5, true)
	-- Level 25+ && Archer kit
	local conditionalString = "ClassLevelGT(Myself,WARRIOR,24)"
	--
	local applyAbility = spriteKitStr == "FERALAN" and isRangerAll and GT_EvalConditional["parseConditionalString"](sprite, nil, conditionalString)
	--
	if sprite:getLocalInt("gtNWNManyshot") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- Do nothing
		else
			-- Mark the creature as 'HLA removed'
			sprite:setLocalInt("gtNWNManyshot", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL123",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

--[[
+------------------------------------------------------------------------+
| cdtweaks, NWN-ish Dirty Fighting class feat for chaotic-aligned rogues |
+------------------------------------------------------------------------+
--]]

-- Apply Ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual feat
	local apply = function()
		-- Mark the creature as 'feat applied'
		sprite:setLocalInt("gtNWNDirtyFighting", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTCL403",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 248, -- Melee hit effect
			["durationType"] = 9,
			["res"] = "GTCL403B", -- EFF file
			["m_sourceRes"] = "GTCL403",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's class / flags
	local class = GT_Resource_SymbolToIDS["class"]
	local align = GT_Resource_SymbolToIDS["align"]
	-- Check if rogue class -- single/multi/(complete)dual
	local isThiefAll = GT_Sprite_CheckIDS(sprite, class["THIEF_ALL"], 5)
	-- Check if chaotic
	local isChaotic = GT_Sprite_CheckIDS(sprite, align["MASK_CHAOTIC"], 8)
	--
	local applyAbility = isThiefAll and isChaotic
	--
	if sprite:getLocalInt("gtNWNDirtyFighting") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtNWNDirtyFighting", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL403",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- Core op402 listener --

function GTCL403(CGameEffect, CGameSprite)
	local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
	--
	local sourceAux = EEex_GetUDAux(sourceSprite)
	--
	local selectedWeapon = GT_Sprite_GetSelectedWeapon(sourceSprite)
	--
	local isUsableBySingleClassThief = EEex_IsBitUnset(selectedWeapon["header"].notUsableBy, 22)
	--
	if sourceSprite.m_leftAttack == 1 then -- if off-hand attack
		local items = sourceSprite.m_equipment.m_items -- Array<CItem*,39>
		local offHand = items:get(9) -- CItem
		--
		if offHand then -- sanity check
			local pHeader = offHand.pRes.pHeader -- Item_Header_st
			--
			if EEex_Resource_ItemCategoryIDSToSymbol(pHeader.itemType) ~= "SHIELD" then -- if not shield, then overwrite item ability/usability check...
				selectedWeapon["ability"] = EEex_Resource_GetItemAbility(pHeader, 0) -- Item_ability_st
				isUsableBySingleClassThief = EEex_IsBitUnset(pHeader.notUsableBy, 22)
			end
		end
	end
	--
	local conditionalString = "EEex_IsImmuneToOpcode(Myself,12)"
	--
	local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
	--
	local resistDamageTypeTable = {
		[0x10] = targetActiveStats.m_nResistPiercing, -- piercing
		[0x0] = targetActiveStats.m_nResistCrushing, -- crushing
		[0x100] = targetActiveStats.m_nResistSlashing, -- slashing
		[0x80] = targetActiveStats.m_nResistMissile, -- missile
		[0x800] = targetActiveStats.m_nResistCrushing, -- non-lethal
	}
	--
	local damageTypeIDS, ACModifier = GT_Sprite_ItmDamageTypeToIDS(selectedWeapon["ability"].damageType, targetActiveStats)
	--
	if sourceAux["gt_NWN_DirtyFighting_FirstAttack"] then
		if isUsableBySingleClassThief then
			if resistDamageTypeTable[damageTypeIDS] < 100 and not GT_EvalConditional["parseConditionalString"](CGameSprite, nil, conditionalString) then
				-- 5% unmitigated damage
				EEex_GameObject_ApplyEffect(CGameSprite,
				{
					["effectID"] = 0xC, -- Damage
					["dwFlags"] = damageTypeIDS * 0x10000 + 3, -- mode: reduce by percentage
					--["numDice"] = 1,
					--["diceSize"] = 4,
					["effectAmount"] = 5,
					["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
					["m_sourceType"] = CGameEffect.m_sourceType,
					["sourceID"] = CGameEffect.m_sourceId,
					["sourceTarget"] = CGameEffect.m_sourceTarget,
				})
				-- the percentage mode of op12 does not provide feedback, so we have to manually display it...
				EEex_GameObject_ApplyEffect(CGameSprite,
				{
					["effectID"] = 139, -- Display string
					["effectAmount"] = 487834,
					["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
					["m_sourceType"] = CGameEffect.m_sourceType,
					["sourceID"] = CGameEffect.m_sourceId,
					["sourceTarget"] = CGameEffect.m_sourceTarget,
				})
			else
				EEex_GameObject_ApplyEffect(CGameSprite,
				{
					["effectID"] = 139, -- Immunity to resource and message
					["effectAmount"] = 487835,
					["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
					["m_sourceType"] = CGameEffect.m_sourceType,
					["sourceID"] = CGameEffect.m_sourceId,
					["sourceTarget"] = CGameEffect.m_sourceTarget,
				})
			end
		end
	end
end

-- Flag first attack in each round --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	local stats = GT_Resource_SymbolToIDS["stats"]
	--
	local found = false
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		if effect.m_effectId == 401 and effect.m_special == stats["GT_DUMMY_STAT"] and effect.m_scriptName:get() == "gtNWNDirtyFightingTimer" then -- dummy opcode that acts as a marker/timer
			found = true
			return true
		end
	end)
	--local conditionalString = EEex_Trigger_ParseConditionalString('!GlobalTimerNotExpired("gtDirtyFightingTimer","LOCALS")')
	--local responseString = EEex_Action_ParseResponseString('SetGlobalTimer("gtDirtyFightingTimer","LOCALS",6)')
	--
	local spriteAux = EEex_GetUDAux(sprite)
	--
	if sprite:getLocalInt("gtNWNDirtyFighting") == 1 then
		if sprite.m_startedSwing == 1 then
			if not found then
				-- set timer
				sprite:applyEffect({
					["effectID"] = 401, -- Set extended stat
					["special"] = stats["GT_DUMMY_STAT"],
					["noSave"] = true,
					["m_scriptName"] = "gtNWNDirtyFightingTimer",
					["duration"] = 90,
					["durationType"] = 10, -- instant/limited (ticks)
					["sourceID"] = sprite.m_id,
					["sourceTarget"] = sprite.m_id,
				})
				--
				spriteAux["gt_NWN_DirtyFighting_FirstAttack"] = true
			end
		else
			if found and spriteAux["gt_NWN_DirtyFighting_FirstAttack"] then
				spriteAux["gt_NWN_DirtyFighting_FirstAttack"] = false
			end
		end
	end
	--
	--conditionalString:free()
	--responseString:free()
end)


--[[
+---------------------------------------------------------------------------------------+
| cdtweaks, NWN-style Overwhelming/Devastating Critical class feat for Trueclass Fighters |
+---------------------------------------------------------------------------------------+
--]]

-- op402 listener --

function GTCL105(CGameEffect, CGameSprite)
	local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
	--[[
	local selectedWeapon = GT_Sprite_GetSelectedWeapon(sourceSprite)
	--
	local sourceActiveStats = EEex_Sprite_GetActiveStats(sourceSprite)
	--
	local gtabmod = GT_Resource_2DA["gtabmod"]
	--
	local savebonus = tonumber(gtabmod[string.format("%s", sourceActiveStats.m_nSTR)]["BONUS"])
	if selectedWeapon["ability"].type == 2 then -- if ranged, make it scale with Dexterity
		savebonus = tonumber(gtabmod[string.format("%s", sourceActiveStats.m_nDEX)]["BONUS"])
	end
	--]]
	local deathImmunity = "EEex_IsImmuneToOpcode(Myself,13)"
	--
	if not GT_EvalConditional["parseConditionalString"](CGameSprite, nil, deathImmunity) then
		--[[
		EEex_GameObject_ApplyEffect(sourceSprite,
		{
			["effectID"] = 139, -- Display string
			["effectAmount"] = 487838,
			["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
			["m_sourceType"] = CGameEffect.m_sourceType,
			["sourceID"] = sourceSprite.m_id,
			["sourceTarget"] = sourceSprite.m_id,
		})
		--]]
		local effectCodes = {
			{["op"] = 0xD7, ["tmg"] = 1, ["res"] = "SPBOLTGL"}, -- feedback vfx
			{["op"] = 0xD, ["tmg"] = 4, ["p2"] = 0x4} -- kill target (normal death)
		}
		--
		for _, attributes in ipairs(effectCodes) do
			CGameSprite:applyEffect({
				["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
				["dwFlags"] = attributes["p2"] or 0,
				["durationType"] = attributes["tmg"] or 0,
				["res"] = attributes["res"] or "",
				["savingThrow"] = 0x4, -- save vs. death
				--["saveMod"] = -1 * savebonus,
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
		end
	else
		EEex_GameObject_ApplyEffect(CGameSprite,
		{
			["effectID"] = 139, -- Display string
			["effectAmount"] = 487839,
			["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
			["m_sourceType"] = CGameEffect.m_sourceType,
			["sourceID"] = CGameEffect.m_sourceId,
			["sourceTarget"] = CGameEffect.m_sourceTarget,
		})
	end
end

-- Overwhelming/Devastating Critical: 3x damage --
-- Devastating Critical: 2x damage (in case target is immune to critical hits) --

EEex_Sprite_AddAlterBaseWeaponDamageListener(function(context)
	local attacker = context.attacker -- CGameSprite
	local target = context.target -- CGameSprite
	--
	local effect = context.effect -- CGameEffect
	local damageAmount = effect.m_effectAmount
	--
	local attackRoll = context.attackRoll
	local isCritical = context.isCritical
	local criticalHitMod, criticalMissMod = GT_Sprite_GetCriticalModifiers(attacker, context.isLeftHand)
	--
	local weapon = context.weapon -- CItem
	local ability = context.ability -- Item_ability_st
	local launcher = context.launcher -- CItem
	--
	local proficiencyType = weapon.pRes.pHeader.proficiencyType
	-- get launcher if needed
	if launcher then
		proficiencyType = launcher.pRes.pHeader.proficiencyType
	end
	--
	local attackerClassStr = GT_Resource_IDSToSymbol["class"][attacker.m_typeAI.m_Class]
	--
	local attackerKitStr = attacker:getActiveStats().m_nKit == 0 and "TRUECLASS" or EEex_Resource_KitIDSToSymbol(attacker:getActiveStats().m_nKit)
	local attackerLevel1 = attacker:getActiveStats().m_nLevel1
	local attackerSTR = attacker:getActiveStats().m_nSTR
	--
	local grandmastery = string.format("ProficiencyGT(Myself,%d,4)", proficiencyType)
	--
	if attackerClassStr == "FIGHTER" and (attackerKitStr == "TRUECLASS" or attackerKitStr == "MAGESCHOOL_GENERALIST") and attackerSTR >= 19 then
		if effect.m_effectId == 0xC and effect.m_slotNum == -1 and effect.m_sourceType == 0 and effect.m_sourceRes:get() == "" then -- base weapon damage
			if GT_EvalConditional["parseConditionalString"](attacker, nil, grandmastery) then
				if isCritical then
					if attackerLevel1 >= 30 then
						GT_Sprite_DisplayMessage(attacker, Infinity_FetchString(487838))
						--
						if ability.type == 1 then -- melee
							EEex_GameObject_ApplyEffect(target,
							{
								["effectID"] = 402, -- Invoke lua
								["res"] = "GTCL105",
								["sourceID"] = attacker.m_id,
								["sourceTarget"] = target.m_id,
							})
						else -- ranged
							attacker.m_curProjectile:AddEffect(GT_Utility_DecodeEffect(
								{
									["effectID"] = 402, -- Invoke lua
									["res"] = "GTCL105",
									--
									["sourceX"] = attacker.m_pos.x,
									["sourceY"] = attacker.m_pos.y,
									["targetX"] = target.m_pos.x,
									["targetY"] = target.m_pos.y,
									--
									["m_projectileType"] = ability.missileType - 1,
									["m_sourceRes"] = context.weapon.cResRef:get(),
									["m_sourceType"] = 2,
									--
									["sourceID"] = attacker.m_id,
									["sourceTarget"] = target.m_id,
								}
							))
						end
					else
						GT_Sprite_DisplayMessage(attacker, Infinity_FetchString(487836))
					end
					effect.m_effectAmount = 3 * math.floor(damageAmount / 2) -- 3x damage
				else
					-- check if critical hit averted
					if attackerLevel1 >= 30 then
						if attackRoll >= 20 - criticalHitMod then
							effect.m_effectAmount = 2 * damageAmount -- 2x damage
						end
					end
				end
			end
		end
	end
end)


--[[
+---------------------------------------------------------+
| cdtweaks, NWN-ish Self Concealment class feat for Monks |
+---------------------------------------------------------+
--]]

-- Apply ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual feat (translucency + icon)
	local apply = function(percentage)
		-- Update tracking var
		sprite:setLocalInt("gtNWNSelfConcealment", percentage)
		--
		local effectCodes = {
			{["op"] = 321, ["res"] = "GTCL801"}, -- Remove effects by resource
			{["op"] = 66, ["p1"] = math.floor((percentage / 100) * 255)}, -- Translucency
			{["op"] = 142, ["p2"] = 258}, -- Display portrait icon
		}
		--
		for _, attributes in ipairs(effectCodes) do
			sprite:applyEffect({
				["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
				["effectAmount"] = attributes["p1"] or 0,
				["dwFlags"] = attributes["p2"] or 0,
				["durationType"] = 9,
				["res"] = attributes["res"] or "",
				["m_sourceRes"] = "GTCL801",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
	-- Check creature's class / level / dexterity
	local spriteClassStr = GT_Resource_IDSToSymbol["class"][sprite.m_typeAI.m_Class]
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteLevel1 = sprite.m_derivedStats.m_nLevel1
	local spriteDEX = sprite.m_derivedStats.m_nDEX
	-- compute concealment percentage
	local percentage = math.min(math.floor((spriteLevel1 - 10) / 5) + 1, 5) * 10 -- from 10 to 50
	-- lvl 10+ monks; 16+ DEX
	local applyAbility = spriteClassStr == "MONK" and spriteLevel1 >= 10 and spriteDEX >= 16
	--
	if sprite:getLocalInt("gtNWNSelfConcealment") == 0 then
		if applyAbility then
			apply(percentage)
		end
	else
		if applyAbility then
			-- check if ``percentage`` has changed since the last application
			if sprite:getLocalInt("gtNWNSelfConcealment") ~= percentage then
				apply(percentage)
			end
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtNWNSelfConcealment", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL801",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- Core listener --

EEex_Sprite_AddBlockWeaponHitListener(function(args)
	local targetSprite = args.targetSprite -- CGameSprite
	--
	local feedbackStrrefs = {
		[10] = 487841,
		[20] = 487842,
		[30] = 487843,
		[40] = 487844,
		[50] = 487845,
	}
	--
	if math.random(100) <= targetSprite:getLocalInt("gtNWNSelfConcealment") then -- 1d100 roll
		-- display some feedback
		targetSprite:applyEffect({
			["effectID"] = 139, -- Display string
			["effectAmount"] = feedbackStrrefs[targetSprite:getLocalInt("gtNWNSelfConcealment")],
			["sourceID"] = targetSprite.m_id,
			["sourceTarget"] = targetSprite.m_id,
		})
		-- block base weapon damage + on-hit effects (if any)
		return true
	end
end)

--[[
+-----------------------------------------------------------+
| cdtweaks, NWN-ish Parry mode for Blades and Swashbucklers |
+-----------------------------------------------------------+
--]]

-- Gain ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) or Infinity_GetCurrentScreenName() == 'CHARGEN' then
		return
	end
	-- internal function that grants the ability
	local gain = function()
		-- Mark the creature as 'feat granted'
		sprite:setLocalInt("gtNWNParry", 1)
		--
		local effectCodes = {
			{["op"] = 172}, -- remove spell
			{["op"] = 171}, -- give spell
		}
		--
		for _, attributes in ipairs(effectCodes) do
			sprite:applyEffect({
				["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
				["res"] = "GTCL500",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
	-- Check creature's class / kit
	local class = GT_Resource_SymbolToIDS["class"]
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteKitStr = EEex_Resource_KitIDSToSymbol(sprite.m_derivedStats.m_nKit)
	-- any thief (swashbuckler) (single/multi/(complete)dual) or bard (blade)
	local isThiefAll = GT_Sprite_CheckIDS(sprite, class["THIEF_ALL"], 5)
	local isBardAll = GT_Sprite_CheckIDS(sprite, class["BARD_ALL"], 5)
	local isSwashbuckler = spriteKitStr == "SWASHBUCKLER"
	local isBlade = spriteKitStr == "BLADE"
	--
	local gainAbility = (isBardAll and isBlade) or (isThiefAll and isSwashbuckler)
	--
	if sprite:getLocalInt("gtNWNParry") == 0 then
		if gainAbility then
			gain()
		end
	else
		if gainAbility then
			-- do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtNWNParry", 0)
			--
			if EEex_Sprite_GetLocalInt(sprite, "gtNWNParryMode") == 1 then
				sprite:applyEffect({
					["effectID"] = 146, -- Cast spell
					["dwFlags"] = 1, -- instant/ignore level
					["res"] = "GTCL500B",
					["sourceID"] = sprite.m_id,
					["sourceTarget"] = sprite.m_id,
				})
			end
			--
			sprite:applyEffect({
				["effectID"] = 172, -- remove spell
				["res"] = "GTCL500",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- save vs. breath to parry an incoming attack; the higher DEX, the easier is to succeed --

EEex_Sprite_AddBlockWeaponHitListener(function(args)
	local toReturn = false
	--
	local attacksPerRound = {0, 1, 2, 3, 4, 5, .5, 1.5, 2.5, 3.5, 4.5}
	local attacksPerRoundHaste = {0, 2, 4, 6, 8, 10, 1, 3, 5, 7, 9}
	--
	local stats = GT_Resource_SymbolToIDS["stats"]
	--local state = GT_Resource_SymbolToIDS["state"]
	--
	local dexmod = GT_Resource_2DA["dexmod"]
	--
	local attackingWeapon = args.weapon -- CItem
	local targetSprite = args.targetSprite -- CGameSprite
	local attackingSprite = args.attackingSprite -- CGameSprite
	local attackingWeaponAbility = args.weaponAbility -- Item_ability_st
	--
	local targetActiveStats = EEex_Sprite_GetActiveStats(targetSprite)
	-- you cannot parry weapons with bare hands (only other bare hands)
	local targetSelectedWeapon = GT_Sprite_GetSelectedWeapon(targetSprite)
	--
	local aux = EEex_GetUDAux(targetSprite)
	--
	local attackingEquipment = attackingSprite.m_equipment -- CGameSpriteEquipment
	-- get # attacks
	local targetNumberOfAttacks
	if EEex_IsBitSet(targetActiveStats.m_generalState, 15) then -- if STATE_HASTED
		targetNumberOfAttacks = attacksPerRoundHaste[EEex_Sprite_GetStat(targetSprite, stats["NUMBEROFATTACKS"]) + 1]
	else
		targetNumberOfAttacks = Infinity_RandomNumber(1, 2) == 1 and math.ceil(attacksPerRound[EEex_Sprite_GetStat(targetSprite, stats["NUMBEROFATTACKS"]) + 1]) or math.floor(attacksPerRound[EEex_Sprite_GetStat(targetSprite, stats["NUMBEROFATTACKS"]) + 1])
	end
	--
	local modifier = tonumber(dexmod[string.format("%s", targetActiveStats.m_nDEX)]["AC"])
	--local roll = targetSprite.m_saveVSBreathRoll
	local roll = Infinity_RandomNumber(1, 20) -- 1d20
	local success = false
	--
	if roll == 20 then -- natural 20
		success = true
		modifier = 0
	elseif roll == 1 then -- natural 1
		modifier = 0
	else
		success = (targetActiveStats.m_nSaveVSBreath + modifier <= roll) -- [!] according to "dexmod.2da", the greater the DEX, the lower is the modifier, so we need to subtract it from the roll
	end
	--targetSprite:setStoredScriptingTarget("GT_ParryModeTarget", attackingSprite)
	--local conditionalString = EEex_Trigger_ParseConditionalString('OR(2) \n !Allegiance(Myself,GOODCUTOFF) InWeaponRange(EEex_Target("GT_ParryModeTarget") \n OR(2) \n !Allegiance(Myself,EVILCUTOFF) Range(EEex_Target("GT_ParryModeTarget"),4)') -- we intentionally let the AI cheat. In so doing, it can enter the mode without worrying about being in weapon range...
	--
	if targetSprite:getLocalInt("gtNWNParryMode") == 1 then -- parry mode ON
		--
		if targetSprite.m_curAction.m_actionID == 0 and targetSprite.m_nSequence == 7 then -- idle/ready (in particular, you cannot parry while performing a riposte attack)
			--if EEex_BAnd(targetActiveStats.m_generalState, state["CD_STATE_NOTVALID"]) == 0 then -- incapacitated creatures cannot parry
			if EEex_BAnd(targetActiveStats.m_generalState, 0x100029) == 0 then -- incapacitated creatures cannot parry
				--
				if EEex_Sprite_GetStat(targetSprite, stats["GT_NUMBER_OF_ATTACKS_PARRIED"]) < targetNumberOfAttacks then -- you can parry at most X number of attacks per round, where X is the number of attacks of the parrying creature
					--
					if attackingWeaponAbility.type == 1 and attackingWeaponAbility.range <= 2 then -- only melee attacks can be parried
						--
						if targetSelectedWeapon["slot"] ~= 10 or attackingEquipment.m_selectedWeapon == 10 then -- bare hands can only parry bare hands
							--
							if success then
								-- display feedback message
								GT_Sprite_DisplayMessage(targetSprite,
									string.format("%s : %d %s %d = %d : %s",
										Infinity_FetchString(487851), roll, modifier < 0 and "+" or "-", math.abs(modifier), roll - modifier, Infinity_FetchString(487852)),
									0x1889A1
								)
								-- increment stats["GT_NUMBER_OF_ATTACKS_PARRIED"] by 1; reset to 0 after one round
								local effectCodes = {
									{["op"] = 401, ["p1"] = 1, ["spec"] = stats["GT_NUMBER_OF_ATTACKS_PARRIED"], ["tmg"] = 1, ["effsource"] = "GTCL500C"}, -- EEex: Set Extended Stat
									{["op"] = 321, ["res"] = "GTCL500C", ["tmg"] = 4, ["dur"] = 6, ["effsource"] = "GTCL500D"}, -- Remove effects by resource
									{["op"] = 318, ["res"] = "GTCL500D", ["dur"] = 6, ["effsource"] = "GTCL500D"}, -- Protection from resource
								}
								--
								for _, attributes in ipairs(effectCodes) do
									targetSprite:applyEffect({
										["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
										["effectAmount"] = attributes["p1"] or 0,
										["special"] = attributes["spec"] or 0,
										["res"] = attributes["res"] or "",
										["durationType"] = attributes["tmg"] or 0,
										["duration"] = attributes["dur"] or 0,
										["m_sourceRes"] = attributes["effsource"] or "",
										["sourceID"] = targetSprite.m_id,
										["sourceTarget"] = targetSprite.m_id,
									})
								end
								-- initialize the attack frame counter
								targetSprite.m_attackFrame = 0
								-- store attacking ID
								aux["gt_NWN_Parry_AttackerID"] = attackingSprite.m_id
								-- cast a dummy spl that performs the attack animation via op138 (p2=0)
								attackingSprite:applyEffect({
									["effectID"] = 146, -- Cast spl
									["res"] = "GTCL500E",
									["sourceID"] = targetSprite.m_id,
									["sourceTarget"] = attackingSprite.m_id,
								})
								-- block base weapon damage + on-hit effects (if any)
								toReturn = true
							else
								GT_Sprite_DisplayMessage(targetSprite,
									string.format("%s : %d %s %d = %d : %s",
										Infinity_FetchString(487851), roll, modifier < 0 and "+" or "-", math.abs(modifier), roll - modifier, Infinity_FetchString(487853)),
									0x1889A1
								)
							end
						end
					end
				end
			end
		end
	end
	--
	--conditionalString:free()
	--
	return toReturn
end)

-- cast a spl (riposte attack) when ``m_attackFrame`` is equal to 6 (that should be approx. the value corresponding to the weapon hit...?) --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	local aux = EEex_GetUDAux(sprite)
	-- if the blade / swashbuckler gets hit while performing a riposte attack, the attack will be canceled
	if sprite:getLocalInt("gtNWNParryMode") == 1 and sprite.m_attackFrame == 6 and sprite.m_nSequence == 0 then
		local attackingSprite = EEex_GameObject_Get(aux["gt_NWN_Parry_AttackerID"])
		--
		if attackingSprite then
			attackingSprite:applyEffect({
				["effectID"] = 146, -- Cast spl
				["dwFlags"] = 1, -- mode: instant / permanent
				["res"] = "GTCL500F",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = attackingSprite.m_id,
			})
		end
	end
end)

-- automatically cancel mode if ranged weapon / polymorphed / magically created weapon --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	local selectedWeapon = GT_Sprite_GetSelectedWeapon(sprite)
	--
	if sprite:getLocalInt("gtNWNParry") == 1 then
		if EEex_Sprite_GetLocalInt(sprite, "gtNWNParryMode") == 1 then -- if in parry mode...
			if selectedWeapon["ability"].type ~= 1 or sprite.m_derivedStats.m_bPolymorphed == 1 or selectedWeapon["slot"] == 34 then
				sprite:applyEffect({
					["effectID"] = 146, -- Cast spell
					["dwFlags"] = 1, -- instant/ignore level
					["res"] = "GTCL500B",
					["sourceID"] = sprite.m_id,
					["sourceTarget"] = sprite.m_id,
				})
			end
		end
	end
end)

-- maintain SEQ_READY while in parry mode --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	if sprite:getLocalInt("gtNWNParry") == 1 then
		if EEex_Sprite_GetLocalInt(sprite, "gtNWNParryMode") == 1 and sprite.m_nSequence == 6 and sprite.m_curAction.m_actionID == 0 then
			sprite:applyEffect({
				["effectID"] = 146, -- Cast spell
				["res"] = "GTCL500G",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- make sure it cannot be disrupted. Cancel mode if no longer idle --

EEex_Action_AddSpriteStartedActionListener(function(sprite, action)
	if sprite:getLocalInt("gtNWNParry") == 1 then
		--
		local toskip = {
			["GTCL500E"] = true,
			["GTCL500G"] = true,
		}
		--
		if EEex_Sprite_GetLocalInt(sprite, "gtNWNParryMode") == 0 then
			if action.m_actionID == 31 and action.m_string1.m_pchData:get() == "GTCL500" then
				action.m_actionID = 113 -- ForceSpell()
			end
		else
			if not (action.m_actionID == 113 and toskip[action.m_string1.m_pchData:get()]) then
				sprite:applyEffect({
					["effectID"] = 146, -- Cast spell
					["dwFlags"] = 1, -- instant/ignore level
					["res"] = "GTCL500B",
					["sourceID"] = sprite.m_id,
					["sourceTarget"] = sprite.m_id,
				})
			end
		end
	end
end)

-- core op402 listener --

function GTCL500(CGameEffect, CGameSprite)
	if CGameEffect.m_effectAmount == 0 then
		-- we apply effects here due to op232's presence (which for best results requires EFF V2.0)
		local effectCodes = {
			{["op"] = 321, ["res"] = "GTCL500"}, -- remove effects by resource
			{["op"] = 232, ["p2"] = 16, ["res"] = "GTCL500B", ["tmg"] = 1}, -- cast spl on condition (condition: Die(); target: self)
			{["op"] = 142, ["p2"] = 259, ["tmg"] = 1}, -- feedback icon
		}
		--
		for _, attributes in ipairs(effectCodes) do
			CGameSprite:applyEffect({
				["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
				["dwFlags"] = attributes["p2"] or 0,
				["res"] = attributes["res"] or "",
				["durationType"] = attributes["tmg"] or 0,
				["m_sourceRes"] = "GTCL500",
				["sourceID"] = CGameSprite.m_id,
				["sourceTarget"] = CGameSprite.m_id,
			})
		end
		--
		EEex_Sprite_SetLocalInt(CGameSprite, "gtNWNParryMode", 1)
	elseif CGameEffect.m_effectAmount == 1 then
		CGameSprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTCL500",
			["sourceID"] = CGameSprite.m_id,
			["sourceTarget"] = CGameSprite.m_id,
		})
		--
		EEex_Sprite_SetLocalInt(CGameSprite, "gtNWNParryMode", 0)
	elseif CGameEffect.m_effectAmount == 2 then
		local itemflag = GT_Resource_SymbolToIDS["itemflag"]
		--
		local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
		--
		local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
		local sourceActiveStats = EEex_Sprite_GetActiveStats(sourceSprite)
		--
		local selectedWeapon = GT_Sprite_GetSelectedWeapon(sourceSprite)
		--
		local strmod = GT_Resource_2DA["strmod"]
		local strmodex = GT_Resource_2DA["strmodex"]
		--
		local strBonus = tonumber(strmod[string.format("%s", sourceActiveStats.m_nSTR)]["DAMAGE"])
		local strExtraBonus = sourceActiveStats.m_nSTR == 18 and tonumber(strmodex[string.format("%s", sourceActiveStats.m_nSTRExtra)]["DAMAGE"]) or 0
		local damageBonus = sourceActiveStats.m_nDamageBonus -- op73
		local wspecial = sourceActiveStats.m_DamageBonusRight -- wspecial.2da
		local meleeDamageBonus = sourceActiveStats.m_nMeleeDamageBonus -- op285 (STAT 167)
		-- op120
		local conditionalString = 'WeaponEffectiveVs(EEex_Target("gtParryTarget"),MAINHAND)'
		--
		if EEex_BAnd(selectedWeapon["header"].itemFlags, itemflag["TWOHANDED"]) == 0 and Infinity_RandomNumber(1, 2) == 1 then -- if single-handed and 1d2 == 1 (50% chance)
			local items = sourceSprite.m_equipment.m_items -- Array<CItem*,39>
			local offHand = items:get(9) -- CItem
			--
			if offHand then -- sanity check
				local pHeader = offHand.pRes.pHeader -- Item_Header_st
				if EEex_Resource_ItemCategoryIDSToSymbol(pHeader.itemType) ~= "SHIELD" then -- if not shield, then overwrite item resref / header / ability...
					selectedWeapon["resref"] = offHand.pRes.resref:get()
					selectedWeapon["header"] = pHeader -- Item_Header_st
					selectedWeapon["ability"] = EEex_Resource_GetItemAbility(pHeader, 0) -- Item_ability_st
					--
					wspecial = sourceActiveStats.m_DamageBonusLeft -- wspecial.2da
					--
					conditionalString = 'WeaponEffectiveVs(EEex_Target("gtParryTarget"),OFFHAND)'
				end
			end
		end
		--
		local modifier = strBonus + strExtraBonus + damageBonus + wspecial + meleeDamageBonus
		-- collect on-hit effects (if any)
		local onHitEffects = {}
		do
			local currentEffectAddress = EEex_UDToPtr(selectedWeapon["header"]) + selectedWeapon["header"].effectsOffset + selectedWeapon["ability"].startingEffect * Item_effect_st.sizeof
			--
			for idx = 1, selectedWeapon["ability"].effectCount do
				local pEffect = EEex_PtrToUD(currentEffectAddress, "Item_effect_st")
				--
				table.insert(onHitEffects, {
					["effectID"] = pEffect.effectID,
					["targetType"] = pEffect.targetType,
					["spellLevel"] = pEffect.spellLevel,
					["effectAmount"] = pEffect.effectAmount,
					["dwFlags"] = pEffect.dwFlags,
					["durationType"] = EEex_BAnd(pEffect.durationType, 0xFF),
					["m_flags"] = EEex_RShift(pEffect.durationType, 8),
					["duration"] = pEffect.duration,
					["probabilityUpper"] = pEffect.probabilityUpper,
					["probabilityLower"] = pEffect.probabilityLower,
					["res"] = pEffect.res:get(),
					["numDice"] = pEffect.numDice,
					["diceSize"] = pEffect.diceSize,
					["savingThrow"] = pEffect.savingThrow,
					["saveMod"] = pEffect.saveMod,
					["special"] = pEffect.special,
				})
				--
				currentEffectAddress = currentEffectAddress + Item_effect_st.sizeof
			end
		end
		--
		local damageTypeIDS, ACModifier = GT_Sprite_ItmDamageTypeToIDS(selectedWeapon["ability"].damageType, targetActiveStats)
		--
		if GT_EvalConditional["parseConditionalString"](sourceSprite, CGameSprite, conditionalString, "gtParryTarget") then
			-- damage type ``NONE`` requires extra care
			local mode = 0 -- normal
			if selectedWeapon["ability"].damageType == 0 and selectedWeapon["ability"].damageDiceCount > 0 then
				mode = 1 -- set HP to value
			end
			--
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 0xC, -- Damage (12)
				["dwFlags"] = damageTypeIDS * 0x10000 + mode,
				["effectAmount"] = (selectedWeapon["ability"].damageDiceCount == 0 and selectedWeapon["ability"].damageDice == 0 and selectedWeapon["ability"].damageDiceBonus == 0) and 0 or (selectedWeapon["ability"].damageDiceBonus + modifier),
				["numDice"] = selectedWeapon["ability"].damageDiceCount,
				["diceSize"] = selectedWeapon["ability"].damageDice,
				--["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				--["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
			-- apply on-hit effects (if any)
			for _, effect in ipairs(onHitEffects) do
				local array = {}
				--
				if effect["targetType"] == 1 or effect["targetType"] == 9 then -- self / original caster
					table.insert(array, sourceSprite)
				elseif effect["targetType"] == 2 then -- projectile target
					table.insert(array, CGameSprite)
				elseif effect["targetType"] == 3 or (effect["targetType"] == 6 and sourceSprite.m_typeAI.m_EnemyAlly == 2) then -- party
					for i = 0, 5 do
						local partyMember = EEex_Sprite_GetInPortrait(i) -- CGameSprite
						if partyMember and EEex_BAnd(partyMember:getActiveStats().m_generalState, 0x800) == 0 then -- skip if STATE_DEAD
							table.insert(array, partyMember)
						end
					end
				elseif effect["targetType"] == 4 then -- everyone
					local everyone = EEex_Area_GetAllOfTypeInRange(sourceSprite.m_pArea, sourceSprite.m_pos.x, sourceSprite.m_pos.y, GT_AI_ObjectType["ANYONE"], 0x7FFF, false, nil, nil)
					--
					for _, itrSprite in ipairs(everyone) do
						if EEex_BAnd(itrSprite:getActiveStats().m_generalState, 0x800) == 0 then -- skip if STATE_DEAD
							table.insert(array, itrSprite)
						end
					end
				elseif effect["targetType"] == 5 then -- everyone but party
					local everyone = EEex_Area_GetAllOfTypeInRange(sourceSprite.m_pArea, sourceSprite.m_pos.x, sourceSprite.m_pos.y, GT_AI_ObjectType["ANYONE"], 0x7FFF, false, nil, nil)
					--
					for _, itrSprite in ipairs(everyone) do
						if itrSprite.m_typeAI.m_EnemyAlly ~= 2 then
							if EEex_BAnd(itrSprite:getActiveStats().m_generalState, 0x800) == 0 then -- skip if STATE_DEAD
								table.insert(array, itrSprite)
							end
						end
					end
				elseif effect["targetType"] == 6 then -- caster group
					local casterGroup = EEex_Area_GetAllOfTypeStringInRange(sourceSprite.m_pArea, sourceSprite.m_pos.x, sourceSprite.m_pos.y, string.format("[0.0.0.0.%d]", sourceSprite.m_typeAI.m_Specifics), 0x7FFF, false, nil, nil)
					--
					for _, itrSprite in ipairs(casterGroup) do
						if EEex_BAnd(itrSprite:getActiveStats().m_generalState, 0x800) == 0 then -- skip if STATE_DEAD
							table.insert(array, itrSprite)
						end
					end
				elseif effect["targetType"] == 7 then -- target group
					local targetGroup = EEex_Area_GetAllOfTypeStringInRange(sourceSprite.m_pArea, sourceSprite.m_pos.x, sourceSprite.m_pos.y, string.format("[0.0.0.0.%d]", CGameSprite.m_typeAI.m_Specifics), 0x7FFF, false, nil, nil)
					--
					for _, itrSprite in ipairs(targetGroup) do
						if EEex_BAnd(itrSprite:getActiveStats().m_generalState, 0x800) == 0 then -- skip if STATE_DEAD
							table.insert(array, itrSprite)
						end
					end
				elseif effect["targetType"] == 8 then -- everyone but self
					local everyone = EEex_Area_GetAllOfTypeInRange(sourceSprite.m_pArea, sourceSprite.m_pos.x, sourceSprite.m_pos.y, GT_AI_ObjectType["ANYONE"], 0x7FFF, false, nil, nil)
					--
					for _, itrSprite in ipairs(everyone) do
						if itrSprite.m_id ~= sourceSprite.m_id then
							if EEex_BAnd(itrSprite:getActiveStats().m_generalState, 0x800) == 0 then -- skip if STATE_DEAD
								table.insert(array, itrSprite)
							end
						end
					end
				end
				--
				for _, object in ipairs(array) do
					EEex_GameObject_ApplyEffect(object,
					{
						["effectID"] = effect["effectID"],
						["spellLevel"] = effect["spellLevel"],
						["effectAmount"] = effect["effectAmount"],
						["dwFlags"] = effect["dwFlags"],
						["durationType"] = effect["durationType"],
						["m_flags"] = effect["m_flags"],
						["duration"] = effect["duration"],
						["probabilityUpper"] = effect["probabilityUpper"],
						["probabilityLower"] = effect["probabilityLower"],
						["res"] = effect["res"],
						["numDice"] = effect["numDice"],
						["diceSize"] = effect["diceSize"],
						["savingThrow"] = effect["savingThrow"],
						["saveMod"] = effect["saveMod"],
						["special"] = effect["special"],
						--
						["m_school"] = selectedWeapon["ability"].school,
						["m_secondaryType"] = selectedWeapon["ability"].secondaryType,
						--
						["m_sourceRes"] = selectedWeapon["resref"],
						["m_sourceType"] = 2,
						["sourceID"] = CGameEffect.m_sourceId,
						["sourceTarget"] = CGameEffect.m_sourceTarget,
					})
				end
			end
		else
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 139, -- Display string
				["effectAmount"] = 487832,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
		end
	end
end

--[[
+---------------------------------------------------------+
| cdtweaks, NWN-ish Trackless Step class feat for Rangers |
+---------------------------------------------------------+
--]]

-- Apply ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- sanity check
	if not EEex_GameObject_IsSprite(sprite) or not sprite.m_pArea then
		return
	end
	-- internal function that applies the actual bonus
	local apply = function()
		-- Mark the creature as 'bonus applied'
		sprite:setLocalInt("gtNWNTracklessStep", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTCL106",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 59, -- Move silently bonus
			["durationType"] = 9,
			["dwFlags"] = 2, -- Percentage Modifier
			["effectAmount"] = 25, -- +25%
			["m_sourceRes"] = "GTCL106",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 275, -- Hide in shadows bonus
			["durationType"] = 9,
			["dwFlags"] = 2, -- Percentage Modifier
			["effectAmount"] = 25, -- +25%
			["m_sourceRes"] = "GTCL106",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 142, -- Display portrait icon
			["durationType"] = 9,
			["dwFlags"] = 260,
			["m_sourceRes"] = "GTCL106",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's area / class / equipment
	local items = sprite.m_equipment.m_items -- Array<CItem*,39>
	--
	local armor = items:get(1) -- CItem (index from "slots.ids")
	local armorTypeStr
	local armorAnimation
	--
	if armor then -- if the character is equipped with an armor...
		local pHeader = armor.pRes.pHeader -- Item_Header_st
		armorTypeStr = EEex_Resource_ItemCategoryIDSToSymbol(pHeader.itemType)
		armorAnimation = EEex_CastUD(pHeader.animationType, "CResRef"):get()
	end
	--
	local class = GT_Resource_SymbolToIDS["class"]
	--
	local isForest = EEex_IsBitSet(sprite.m_pArea.m_header.m_areaType, 0x4)
	local isOutdoor = EEex_IsBitSet(sprite.m_pArea.m_header.m_areaType, 0x0)
	--
	local isRangerAll = GT_Sprite_CheckIDS(sprite, class["RANGER_ALL"], 5, true)
	--
	local applyAbility = (isForest and isOutdoor)
		and isRangerAll
		and (not armor or (armorTypeStr == "ARMOR" and armorAnimation ~= "3A" and armorAnimation ~= "4A")) -- light armor / no armor
	--
	if sprite:getLocalInt("gtNWNTracklessStep") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'bonus removed'
			sprite:setLocalInt("gtNWNTracklessStep", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL106",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

--[[
+------------------------------------------------------+
| cdtweaks, NWN-ish Nature Sense class feat for Druids |
+------------------------------------------------------+
--]]

-- Apply ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- sanity check
	if not EEex_GameObject_IsSprite(sprite) or not sprite.m_pArea then
		return
	end
	-- internal function that applies the actual bonus
	local apply = function()
		-- Mark the creature as 'bonus applied'
		sprite:setLocalInt("gtNWNNatureSense", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTCL600",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 54, -- Base thac0 bonus
			["durationType"] = 9,
			["effectAmount"] = 2, -- +2
			["m_sourceRes"] = "GTCL600",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 142, -- Display portrait icon
			["durationType"] = 9,
			["dwFlags"] = 261,
			["m_sourceRes"] = "GTCL600",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's area / class
	local class = GT_Resource_SymbolToIDS["class"]
	--
	local isForest = EEex_IsBitSet(sprite.m_pArea.m_header.m_areaType, 0x4)
	local isOutdoor = EEex_IsBitSet(sprite.m_pArea.m_header.m_areaType, 0x0)
	-- any druid (single/multi/(complete)dual)
	local isDruidAll = GT_Sprite_CheckIDS(sprite, class["DRUID_ALL"], 5)
	--
	local applyAbility = (isForest and isOutdoor) and isDruidAll
	--
	if sprite:getLocalInt("gtNWNNatureSense") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'bonus removed'
			sprite:setLocalInt("gtNWNNatureSense", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL600",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

--[[
+----------------------------------------------------------------------+
| cdtweaks, NWN-ish Uncanny Dodge class feat for Barbarians and Rogues |
+----------------------------------------------------------------------+
--]]

-- Apply ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual feat
	local apply = function()
		-- Mark the creature as 'feat applied'
		sprite:setLocalInt("gtNWNUncannyDodge", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTCL107",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 403, -- Screen effects
			["durationType"] = 9,
			["res"] = "GTCL107", -- Lua func
			["m_sourceRes"] = "GTCL107",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's class / kit / flags / levels
	local class = GT_Resource_SymbolToIDS["class"]
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteKitStr = EEex_Resource_KitIDSToSymbol(sprite.m_derivedStats.m_nKit)
	-- KIT=BARBARIAN || CLASS=THIEF
	local isThiefAll = GT_Sprite_CheckIDS(sprite, class["THIEF_ALL"], 5)
	local isFighterAll = GT_Sprite_CheckIDS(sprite, class["FIGHTER_ALL"], 5)
	local isBarbarian = spriteKitStr == "BARBARIAN"
	--
	local applyAbility = isThiefAll or (isBarbarian and isFighterAll)
	--
	if sprite:getLocalInt("gtNWNUncannyDodge") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtNWNUncannyDodge", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL107",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- op403 listener --

function GTCL107(op403CGameEffect, CGameEffect, CGameSprite)
	local id = CGameEffect.m_sourceId
	local object = EEex_GameObject_Get(id)
	--
	local objectSources = {
		[CGameObjectType.TRIGGER] = true,
		[CGameObjectType.DOOR] = true,
		[CGameObjectType.CONTAINER] = true,
	}
	--
	if object and objectSources[object.m_objectType] then
		CGameEffect.m_saveMod = CGameEffect.m_saveMod + 2
	end
end

--[[
+---------------------------------------------------------+
| cdtweaks, Spell Penetration class feat for Spellcasters |
+---------------------------------------------------------+
--]]

-- Apply ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual feat
	local apply = function()
		-- Mark the creature as 'feat applied'
		sprite:setLocalInt("gtNWNSpellPenetration", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTCL118",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 408, -- EEex: Projectile Mutator
			["durationType"] = 9,
			["res"] = "GTCL118P", -- Lua func
			["m_sourceRes"] = "GTCL118",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's class / levels
	local class = GT_Resource_SymbolToIDS["class"]
	-- Spellcaster classes (all but rangers, paladins, bards)
	local isMageAll = GT_Sprite_CheckIDS(sprite, class["MAGE_ALL"], 5)
	local isDruidAll = GT_Sprite_CheckIDS(sprite, class["DRUID_ALL"], 5)
	local isClericAll = GT_Sprite_CheckIDS(sprite, class["CLERIC_ALL"], 5)
	local isShaman = GT_Sprite_CheckIDS(sprite, class["SHAMAN"], 5)
	--
	local applyAbility = isMageAll or isDruidAll or isClericAll or isShaman
	--
	if sprite:getLocalInt("gtNWNSpellPenetration") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- Do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtNWNSpellPenetration", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL118",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- op402 listener (alter target's mr roll) --

function GTCL118(CGameEffect, CGameSprite)
	local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
	--
	if EEex_Sprite_GetStat(CGameSprite, 18) < 100 then -- skip if mr >= 100
		if CGameSprite.m_id ~= sourceSprite.m_id then -- skip if caster
			-- Compute modifier based on caster level (cap at 30...?)
			local modifier = EEex_Sprite_GetCasterLevelForSpell(sourceSprite, CGameEffect.m_res2:get(), true)
			if modifier > 30 then
				modifier = 30
			end
			-- alter roll
			CGameSprite.m_magicResistRoll = CGameSprite.m_magicResistRoll + modifier
		end
	end
end

-- op408 listener --

GTCL118P = {

	["typeMutator"] = function(context)
		local actionSources = {
			[EEex_Projectile_DecodeSource.CGameSprite_Spell] = true,
			[EEex_Projectile_DecodeSource.CGameSprite_SpellPoint] = true,
			[EEex_Projectile_DecodeSource.CGameAIBase_ForceSpell] = true,
			[EEex_Projectile_DecodeSource.CGameAIBase_ForceSpellPoint] = true,
		}
		--
		if not actionSources[context.decodeSource] then
			return
		end
	end,

	["projectileMutator"] = function(context)
		local actionSources = {
			[EEex_Projectile_DecodeSource.CGameSprite_Spell] = true,
			[EEex_Projectile_DecodeSource.CGameSprite_SpellPoint] = true,
			[EEex_Projectile_DecodeSource.CGameAIBase_ForceSpell] = true,
			[EEex_Projectile_DecodeSource.CGameAIBase_ForceSpellPoint] = true,
		}
		--
		if not actionSources[context.decodeSource] then
			return
		end
		--
		local originatingSprite = context["originatingSprite"] -- CGameSprite
		-- get spell resref
		local spellResRef = originatingSprite.m_curAction.m_string1.m_pchData:get()
		if spellResRef == "" then
			spellResRef = GT_Utility_DecodeSpell(originatingSprite.m_curAction.m_specificID)
		end
		local pHeader = EEex_Resource_Demand(spellResRef, "spl")
		--
		if not (pHeader.itemType == 1 or pHeader.itemType == 2) then
			return
		end
		--
		local projectile = context["projectile"] -- CProjectile
		--
		projectile:AddEffect(GT_Utility_DecodeEffect(
			{
				["effectID"] = 402, -- EEex: Invoke Lua
				["res"] = "GTCL118", -- lua func
				["m_res2"] = spellResRef,
				["sourceX"] = originatingSprite.m_pos.x,
				["sourceY"] = originatingSprite.m_pos.y,
				["sourceID"] = originatingSprite.m_id,
			}
		))
	end,

	["effectMutator"] = function(context)
		local actionSources = {
			[EEex_Projectile_AddEffectSource.CGameSprite_Spell] = true,
			[EEex_Projectile_AddEffectSource.CGameSprite_SpellPoint] = true,
			[EEex_Projectile_AddEffectSource.CGameAIBase_ForceSpell] = true,
			[EEex_Projectile_AddEffectSource.CGameAIBase_ForceSpellPoint] = true,
		}
		--
		if not actionSources[context.addEffectSource] then
			return
		end
	end,
}

--[[
+---------------------------------------------------------+
| cdtweaks, NWN-ish Woodland Stride class feat for Druids |
+---------------------------------------------------------+
--]]

-- Apply Ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual feat
	local apply = function()
		-- Mark the creature as 'feat applied'
		sprite:setLocalInt("gtNWNWoodlandStride", 1)
		--
		local effectCodes = {
			{["op"] = 321, ["res"] = "GTCL643"}, -- Remove effects by resource
			--
			{["op"] = 403, ["p1"] = 0xE000000, ["res"] = "GTIMMUNE"}, -- screen effects (entangle, web, grease)
			{["op"] = 101, ["p2"] = 154}, -- immunity to effect
			{["op"] = 101, ["p2"] = 157}, -- immunity to effect
			{["op"] = 101, ["p2"] = 158}, -- immunity to effect
			--
			{["op"] = 142, ["p2"] = 262} -- icon
		}
		--
		for _, attributes in ipairs(effectCodes) do
			sprite:applyEffect({
				["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
				["effectAmount"] = attributes["p1"] or 0,
				["dwFlags"] = attributes["p2"] or 0,
				["res"] = attributes["res"] or "",
				["durationType"] = 9,
				["m_sourceRes"] = "GTCL643",
				["m_sourceType"] = 1,
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
	-- Check creature's class / flags
	local class = GT_Resource_SymbolToIDS["class"]
	-- any lvl 2+ druid (single/multi/(complete)dual)
	local isDruidAll = GT_Sprite_CheckIDS(sprite, class["DRUID_ALL"], 5)
	--
	local string = "ClassLevelGT(Myself,PRIEST,1)"
	--
	local applyAbility = isDruidAll and GT_EvalConditional["parseConditionalString"](sprite, nil, string)
	--
	if sprite:getLocalInt("gtNWNWoodlandStride") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtNWNWoodlandStride", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL643",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

--[[
+----------------------------------------------------------+
| cdtweaks, NWN-ish Bane of Enemies class feat for Rangers |
+----------------------------------------------------------+
--]]

-- Apply Ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual feat
	local apply = function(raceID)
		-- Mark the creature as 'feat applied'
		sprite:setLocalInt("gtNWNBaneOfEnemies", raceID)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTCL108",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 248, -- Melee hit effect
			["durationType"] = 9,
			["res"] = "GTCL108", -- EFF file
			["m_sourceRes"] = "GTCL108",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 249, -- Ranged hit effect
			["durationType"] = 9,
			["res"] = "GTCL108", -- EFF file
			["m_sourceRes"] = "GTCL108",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 178, -- THAC0 vs. type bonus
			["durationType"] = 9,
			["dwFlags"] = 4, -- RACE.IDS
			["effectAmount"] = raceID,
			["special"] = 2, -- +2
			["m_sourceRes"] = "GTCL108",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's class / flags
	local class = GT_Resource_SymbolToIDS["class"]
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local m_nHatedRace = sprite.m_derivedStats.m_nHatedRace
	-- any lvl 21+ ranger (single/multi/(complete)dual, not fallen)
	local isRangerAll = GT_Sprite_CheckIDS(sprite, class["RANGER_ALL"], 5, true)
	--
	local applyAbility = isRangerAll and GT_EvalConditional["parseConditionalString"](sprite, nil, "ClassLevelGT(Myself,WARRIOR,20)") and m_nHatedRace > 0
	--
	if sprite:getLocalInt("gtNWNBaneOfEnemies") == 0 then
		if applyAbility then
			apply(m_nHatedRace)
		end
	else
		if applyAbility then
			-- check if ``m_nHatedRace`` has changed since the last application
			if m_nHatedRace ~= sprite:getLocalInt("gtNWNBaneOfEnemies") then
				apply(m_nHatedRace)
			end
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtNWNBaneOfEnemies", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL108",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- op402 listener (2d6 extra damage) --

function GTCL108(CGameEffect, CGameSprite)
	local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId) -- CGameSprite
	--
	local selectedWeapon = GT_Sprite_GetSelectedWeapon(sourceSprite)
	--
	if selectedWeapon["ability"].type == 1 and sourceSprite.m_leftAttack == 1 then -- if attacking with offhand...
		local items = sourceSprite.m_equipment.m_items -- Array<CItem*,39>
		local offHand = items:get(9) -- CItem
		--
		if offHand then
			local pHeader = offHand.pRes.pHeader -- Item_Header_st
			local itemTypeStr = EEex_Resource_ItemCategoryIDSToSymbol(pHeader.itemType)
			--
			if itemTypeStr ~= "SHIELD" then -- if not shield, then overwrite item ability...
				selectedWeapon["ability"] = EEex_Resource_GetItemAbility(pHeader, 0) -- Item_ability_st
			end
		end
	end
	--
	local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
	local targetRaceID = CGameSprite.m_typeAI.m_Race
	--
	local damageTypeIDS, ACModifier = GT_Sprite_ItmDamageTypeToIDS(selectedWeapon["ability"].damageType, targetActiveStats)
	--
	if targetRaceID == sourceSprite:getLocalInt("gtNWNBaneOfEnemies") then -- race check
		EEex_GameObject_ApplyEffect(CGameSprite,
		{
			["effectID"] = 0xC, -- Damage
			["dwFlags"] = damageTypeIDS * 0x10000, -- mode: normal
			["numDice"] = 2,
			["diceSize"] = 6,
			["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
			["m_sourceType"] = CGameEffect.m_sourceType,
			["sourceID"] = CGameEffect.m_sourceId,
			["sourceTarget"] = CGameEffect.m_sourceTarget,
		})
	end
end

--[[
+-------------------------------------------------------------+
| cdtweaks: NWN-ish Animal Companion kit feat for beastmaster |
+-------------------------------------------------------------+
--]]

-- Give/remove feat --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) or Infinity_GetCurrentScreenName() == 'CHARGEN' then
		return
	end
	-- internal function that grants the actual feat
	local gain = function()
		-- Mark the creature as 'feat granted'
		sprite:setLocalInt("gtNWNAnimalCompanion", 1)
		--
		sprite:applyEffect({
			["effectID"] = 172, -- Remove spell
			["res"] = "GTCL300",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 171, -- Give spell
			["res"] = "GTCL300",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's class / kit / flags
	local class = GT_Resource_SymbolToIDS["class"]
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteKitStr = EEex_Resource_KitIDSToSymbol(sprite.m_derivedStats.m_nKit)
	-- Check if beastmaster -- single/multi/(complete)dual
	local isRangerAll = GT_Sprite_CheckIDS(sprite, class["RANGER_ALL"], 5, true)
	local isBeastmaster = spriteKitStr == "BEASTMASTER"
	--
	local gainAbility = isRangerAll and isBeastmaster
	--
	if sprite:getLocalInt("gtNWNAnimalCompanion") == 0 then
		if gainAbility then
			gain()
		end
	else
		if gainAbility then
			-- do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtNWNAnimalCompanion", 0)
			--
			sprite:applyEffect({
				["effectID"] = 172, -- Remove spell
				["res"] = "GTCL300",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

--[[
+---------------------------------------------------------------------+
| cdtweaks, NWN-ish Opportunist class feat for chaotic-aligned Rogues |
+---------------------------------------------------------------------+
--]]

-- Apply Ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual feat
	local apply = function()
		-- Mark the creature as 'feat applied'
		sprite:setLocalInt("gtNWNOpportunist", 1)
		--
		local effectCodes = {
			{["op"] = 321, ["res"] = "GTCL404"}, -- Remove effects by resource
			{["op"] = 73, ["p1"] = 2}, -- Attack damage bonus
			{["op"] = 278, ["p1"] = 2}, -- THAC0 bonus
			{["op"] = 142, ["p2"] = 263}, -- Display portrait icon
		}
		--
		for _, attributes in ipairs(effectCodes) do
			sprite:applyEffect({
				["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
				["effectAmount"] = attributes["p1"] or 0,
				["dwFlags"] = attributes["p2"] or 0,
				["durationType"] = 9,
				["res"] = attributes["res"] or "",
				["m_sourceRes"] = "GTCL404",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
	-- Check creature's class / flags
	local align = GT_Resource_SymbolToIDS["align"]
	local class = GT_Resource_SymbolToIDS["class"]
	--
	local attackerSelectedWeapon = GT_Sprite_GetSelectedWeapon(sprite) -- Item_ability_st
	local attackerIsChaotic = GT_Sprite_CheckIDS(sprite, align["MASK_CHAOTIC"], 8)
	local attackerIsThiefAll = GT_Sprite_CheckIDS(sprite, class["THIEF_ALL"], 5)
	local targetSprite = EEex_GameObject_Get(sprite.m_targetId) -- CGameSprite
	--
	local targetClassStr, targetSelectedWeapon
	if targetSprite then
		targetClassStr = GT_Resource_IDSToSymbol["class"][targetSprite.m_typeAI.m_Class]
		targetSelectedWeapon = GT_Sprite_GetSelectedWeapon(targetSprite) -- Item_ability_st
	end
	--
	local applyAbility = targetSprite and
		(attackerIsThiefAll and attackerIsChaotic and attackerSelectedWeapon["ability"].type == 1 and attackerSelectedWeapon["slot"] ~= 10) and
		(targetSelectedWeapon["ability"].type ~= 1 or (targetClassStr ~= "MONK" and targetSelectedWeapon["slot"] == 10))
	--
	if sprite:getLocalInt("gtNWNOpportunist") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtNWNOpportunist", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCL404",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)


