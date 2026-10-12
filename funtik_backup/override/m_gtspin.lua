-- ***Innate Abilities*** --

--[[
+------------------------------------------------------+
| cdtweaks, Last Stand innate feat for Bears and Boars |
+------------------------------------------------------+
--]]

function GTIN000(op403CGameEffect, CGameEffect, CGameSprite)
	 if CGameEffect.m_effectId == 0xD and CGameEffect.m_scriptName:get() ~= "gtAnimalBypassOp208" then  -- kill target (op13)
		if not GT_Sprite_HasBounceEffects(CGameSprite, CGameEffect.m_spellLevel, CGameEffect.m_projectileType, CGameEffect.m_school, CGameEffect.m_secondaryType, CGameEffect.m_sourceRes:get(), {13}, CGameEffect.m_flags, false) then
			if not GT_Sprite_HasImmunityEffects(CGameSprite, CGameEffect.m_spellLevel, CGameEffect.m_projectileType, CGameEffect.m_school, CGameEffect.m_secondaryType, CGameEffect.m_sourceRes:get(), {13}, CGameEffect.m_flags, CGameEffect.m_savingThrow, 0x0, false) then
				if not GT_Sprite_HasTrapEffect(CGameSprite, CGameEffect.m_spellLevel, CGameEffect.m_secondaryType, CGameEffect.m_flags, false) then
					CGameSprite:applyEffect({
            ["m_scriptName"] = "gtAnimalBypassOp208", 
						["effectID"] = CGameEffect.m_effectId, -- Kill target
						["dwFlags"] = CGameEffect.m_dWFlags,
						["effectAmount"] = CGameEffect.m_effectAmount,
						--
						["savingThrow"] = CGameEffect.m_savingThrow,
						["saveMod"] = CGameEffect.m_saveMod,
						["m_flags"] = CGameEffect.m_flags,
						--
						["durationType"] = CGameEffect.m_durationType,
						["duration"] = CGameEffect.m_duration,
						--
						["spellLevel"] = CGameEffect.m_spellLevel,
						["m_projectileType"] = CGameEffect.m_projectileType,
						["m_school"] = CGameEffect.m_school,
						["m_secondaryType"] = CGameEffect.m_secondaryType,
						["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
						--
						["m_sourceType"] = CGameEffect.m_sourceType,
						["m_sourceFlags"] = CGameEffect.m_sourceFlags,
						["m_casterLevel"] = CGameEffect.m_casterLevel,
						["m_slotNum"] = CGameEffect.m_slotNum,
						["m_maxLevel"] = CGameEffect.m_maxLevel,
						["m_minLevel"] = CGameEffect.m_minLevel,
						--
						["noSave"] = true, -- ignore immunity provided by op208
						--
						["sourceID"] = CGameEffect.m_sourceId,
						["sourceTarget"] = CGameEffect.m_sourceTarget,
					})
					--
					return true
				end
			end
		end
	end
end

-- The boar/bear will fight for (1d4/1d4+1) rounds after reaching 0 hit points. The creature will go berserk attacking friends and foes alike --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- Check creature's general / class / race / animate
	local spriteGeneralStr = GT_Resource_IDSToSymbol["general"][sprite.m_typeAI.m_General]
	local spriteRaceStr = GT_Resource_IDSToSymbol["race"][sprite.m_typeAI.m_Race]
	local spriteClassStr = GT_Resource_IDSToSymbol["class"][sprite.m_typeAI.m_Class]
	local spriteAnimateStr = GT_Resource_IDSToSymbol["animate"][sprite.m_animation.m_animation.m_animationID]
	--
	local modifier = -1
	--
	if spriteGeneralStr == "ANIMAL" then
		if spriteRaceStr == "BEAR" then
			if spriteClassStr == "BEAR_BROWN" or spriteClassStr == "BEAR_CAVE" then
				modifier = 0
			elseif spriteClassStr == "BEAR_POLAR" then
				modifier = 1
			end
		elseif spriteAnimateStr == "BOAR_ARCTIC" or spriteAnimateStr == "BOAR_WILD" then
			modifier = 1
		end
	end
	--
	local roll = modifier + Infinity_RandomNumber(1, 4) -- 1d4 / 1d4+1
	--
	if sprite:getLocalInt("gtAnimalLastStand") == 1 then
		if sprite.m_nLastDamageTaken >= sprite.m_baseStats.m_hitPoints and sprite:getLocalInt("gtAnimalRunningWild") == 0 then
			sprite:setLocalInt("gtAnimalRunningWild", 1)
			--
			local lastHitter = EEex_GameObject_Get(sprite.m_lHitter.m_Instance)
			--
			local effectCodes = {
				{["op"] = 3, ["p2"] = 1, ["dur"] = 6 * roll}, -- berserk (mode: constant)
				{["op"] = 176, ["p2"] = 5, ["p1"] = 200, ["dur"] = 6 * roll}, -- movement rate bonus (200%)
				{["op"] = 215, ["res"] = "ICSTRENI", ["p2"] = 1, ["dur"] = 2}, -- play visual effect (over target: attached)
				{["op"] = 142, ["p2"] = 4, ["dur"] = 6 * roll}, -- icon: berserk
				{["op"] = 187, ["p1"] = 0, ["effvar"] = "gtAnimalRunningWild", ["dur"] = 6 * roll, ["tmg"] = 4}, -- set local var (reset to 0 in case the animal gets resurrected)
				{["op"] = 55, ["p2"] = 2, ["dur"] = 6 * roll, ["tmg"] = 4}, -- slay creature
			}
			--
			for _, attributes in ipairs(effectCodes) do
				sprite:applyEffect({
					["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
					["effectAmount"] = attributes["p1"] or 0,
					["dwFlags"] = attributes["p2"] or 0,
					["res"] = attributes["res"] or "",
					["duration"] = attributes["dur"] or 0,
					["durationType"] = attributes["tmg"] or 0,
					["m_scriptName"] = attributes["effvar"] or "",
					["m_sourceRes"] = "GTIN000B",
					["m_sourceType"] = 1,
					["noSave"] = true,
					["sourceID"] = lastHitter.m_id,
					["sourceTarget"] = sprite.m_id,
				})
			end
		end
	end
end)

-- Apply passive trait --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual feat
	local apply = function()
		-- Mark the creature as 'feat applied'
		sprite:setLocalInt("gtAnimalLastStand", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTIN000",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 208, -- Min HP
			["effectAmount"] = 1,
			["durationType"] = 9,
			["m_sourceRes"] = "GTIN000",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 403, -- Screen effects
			["durationType"] = 9,
			["res"] = "GTIN000", -- Lua func
			["m_sourceRes"] = "GTIN000",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})

	end
	-- Check creature's general / class / race / animate
	local spriteGeneralStr = GT_Resource_IDSToSymbol["general"][sprite.m_typeAI.m_General]
	local spriteRaceStr = GT_Resource_IDSToSymbol["race"][sprite.m_typeAI.m_Race]
	local spriteClassStr = GT_Resource_IDSToSymbol["class"][sprite.m_typeAI.m_Class]
	local spriteAnimateStr = GT_Resource_IDSToSymbol["animate"][sprite.m_animation.m_animation.m_animationID]
	--
	local applyAbility = false
	--
	if spriteGeneralStr == "ANIMAL" then
		if spriteRaceStr == "BEAR" then
			if spriteClassStr == "BEAR_BROWN" or spriteClassStr == "BEAR_CAVE" or spriteClassStr == "BEAR_POLAR" then
				applyAbility = true
			end
		elseif spriteAnimateStr == "BOAR_ARCTIC" or spriteAnimateStr == "BOAR_WILD" then
			applyAbility = true
		end
	end
	--
	if sprite:getLocalInt("gtAnimalLastStand") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtAnimalLastStand", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTIN000",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

--[[
+--------------------------------------------------+
| cdtweaks, NWN Good Aim racial feat for Halflings |
+--------------------------------------------------+
--]]

-- Apply ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual bonus
	local apply = function()
		-- Mark the creature as 'bonus applied'
		sprite:setLocalInt("gtNWNGoodAim", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTIN001",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 167, -- Missile THAC0 bonus
			["effectAmount"] = 1,
			["durationType"] = 9,
			["m_sourceRes"] = "GTIN001",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 142, -- Display portrait icon
			["durationType"] = 9,
			["dwFlags"] = 254,
			["m_sourceRes"] = "GTIN001",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's equipment / race
	local selectedWeapon = GT_Sprite_GetSelectedWeapon(sprite)
	local selectedWeaponTypeStr = EEex_Resource_ItemCategoryIDSToSymbol(selectedWeapon["header"].itemType)
	--
	local spriteRaceStr = GT_Resource_IDSToSymbol["race"][sprite.m_typeAI.m_Race]
	-- This feat grants a +1 thac0 bonus with throwing weapons (throwing daggers, throwing axes, darts, throwing hammers)
	local applyAbility = (selectedWeaponTypeStr == "DAGGER" or selectedWeaponTypeStr == "AXE" or selectedWeaponTypeStr == "HAMMER" or selectedWeaponTypeStr == "DART")
		and selectedWeapon["ability"].type == 2 -- Ranged
		and spriteRaceStr == "HALFLING"
	--
	if sprite:getLocalInt("gtNWNGoodAim") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'bonus removed'
			sprite:setLocalInt("gtNWNGoodAim", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTIN001",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

--[[
+------------------------------------------------------+
| cdtweaks, NWN-ish Fearless racial feat for Halflings |
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
		sprite:setLocalInt("gtNWNFearless", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTIN002",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 403, -- Screen effects
			["durationType"] = 9,
			["res"] = "GTIMMUNE", -- lua function
			["effectAmount"] = 0x40, -- BIT6
			["special"] = 1,
			["m_sourceRes"] = "GTIN002",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 142, -- Display portrait icon
			["durationType"] = 9,
			["dwFlags"] = 255,
			["m_sourceRes"] = "GTIN002",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's race
	local spriteRaceStr = GT_Resource_IDSToSymbol["race"][sprite.m_typeAI.m_Race]
	--
	local applyAbility = spriteRaceStr == "HALFLING"
	--
	if sprite:getLocalInt("gtNWNFearless") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'feat removed'
			sprite:setLocalInt("gtNWNFearless", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTIN002",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- cdtweaks, Blind Fight innate feat for Berserkers --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual bonus
	local apply = function()
		-- Mark the creature as 'bonus applied'
		sprite:setLocalInt("gtNWNBlindFight", 1)
		--
		local effectCodes = {
			{["op"] = 321, ["res"] = "GTIN003"}, -- Remove effects by resource
			{["op"] = 284, ["p1"] = 4}, -- Melee THAC0 bonus (+4)
			{["op"] = 0, ["p1"] = 4}, -- AC bonus (+4)
			{["op"] = 142, ["p2"] = 257}, -- Display portrait icon
		}
		--
		for _, attributes in ipairs(effectCodes) do
			sprite:applyEffect({
				["effectID"] = attributes["op"] or -1,
				["effectAmount"] = attributes["p1"] or 0,
				["dwFlags"] = attributes["p2"] or 0,
				["durationType"] = 9,
				["res"] = attributes["res"] or "",
				["m_sourceRes"] = "GTIN003",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
	-- Check creature's kit / state
	local class = GT_Resource_SymbolToIDS["class"]
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteKitStr = EEex_Resource_KitIDSToSymbol(sprite.m_derivedStats.m_nKit)
	local spriteGeneralState = sprite.m_derivedStats.m_generalState
	-- any fighter class (single/multi/(complete)dual)
	local isFighterAll = GT_Sprite_CheckIDS(sprite, class["FIGHTER_ALL"], 5)
	-- berserkers
	local applyAbility = EEex_IsBitSet(spriteGeneralState, 0x12) -- STATE_BLIND
		and spriteKitStr == "BERSERKER"
		and isFighterAll
	--
	if sprite:getLocalInt("gtNWNBlindFight") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'bonus removed'
			sprite:setLocalInt("gtNWNBlindFight", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTIN003",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

--[[
+------------------------------------------------------------------+
| Bear (Hug): hit creature suffers extra damage from critical hits |
+------------------------------------------------------------------+
--]]

function GTIN141(CGameEffect, CGameSprite)
	local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
	local sourceActiveStats = EEex_Sprite_GetActiveStats(sourceSprite)
	local sourceClassStr = GT_Resource_IDSToSymbol["class"][sourceSprite.m_typeAI.m_Class]
	--
	local selectedWeapon = GT_Sprite_GetSelectedWeapon(sourceSprite)
	--
	local conditionalString = "EEex_IsImmuneToOpcode(Myself,12)"
	--
	local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
	--
	local damageTypeIDS, ACModifier = GT_Sprite_ItmDamageTypeToIDS(selectedWeapon["ability"].damageType, targetActiveStats)
	--
	local levelModifier = math.floor(sourceActiveStats.m_nLevel1 / 5) -- +1 every 5 levels
	--
	local diceSize
	local numDice
	if sourceClassStr == "BEAR_BLACK" then
		numDice = 2
		diceSize = 4
	elseif sourceClassStr == "BEAR_BROWN" then
		numDice = 2
		diceSize = 6
	elseif sourceClassStr == "BEAR_CAVE" then
		numDice = 2
		diceSize = 8
	elseif sourceClassStr == "BEAR_POLAR" then
		numDice = 3
		diceSize = 6
	end
	--
	if not GT_EvalConditional["parseConditionalString"](CGameSprite, nil, conditionalString) then
		EEex_GameObject_ApplyEffect(CGameSprite,
		{
			["effectID"] = 0xC, -- Damage
			["dwFlags"] = damageTypeIDS * 0x10000, -- mode: normal
			["numDice"] = numDice + levelModifier,
			["diceSize"] = diceSize,
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

--[[
+------------------------------------------------------------------------------------------------------------------+
| Bombardier Beetle Cloud: targeted creature is either stunned for 2d4 rounds or deafened for 2d6 rounds (no save) |
+------------------------------------------------------------------------------------------------------------------+
--]]

function GTIN191(CGameEffect, CGameSprite)
	local stunDuration = math.random(4) + math.random(4) -- 2d4
	local deafDuration = math.random(6) + math.random(6) -- 2d6
	--
	local stunImmunity = "EEex_IsImmuneToOpcode(Myself,45)"
	local deafImmunity = "EEex_IsImmuneToOpcode(Myself,80)"
	--
	if not GT_EvalConditional["parseConditionalString"](CGameSprite, nil, stunImmunity) then
		if math.random(5) == 1 then -- 20% chance
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 45, -- Stun
				["duration"] = 6 * stunDuration,
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 139, -- Display String
				["effectAmount"] = 226050,
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
		end
	end
	--
	if not GT_EvalConditional["parseConditionalString"](CGameSprite, nil, deafImmunity) then
		if math.random(5) == 1 then -- 20% chance
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 80, -- Deafness
				["duration"] = 6 * deafDuration,
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 142, -- Icon
				["duration"] = 6 * deafDuration,
				["dwFlags"] = 112,
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 139, -- Display String
				["effectAmount"] = 487870,
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
		end
	end
end

--[[
+---------------------------------------------------------------------------------------------------------+
| Animal Ferocity: The creature using this ability becomes ferocious for 5 rounds (+1 round per 5 levels) |
+---------------------------------------------------------------------------------------------------------+
| Specs:                                                                                                  |
| - +1d6 STR                                                                                              |
| - +1d6 CON                                                                                              |
| - immunity to confusion, charm, and feeblemind                                                          |
+---------------------------------------------------------------------------------------------------------+
--]]

function GTIN321(CGameEffect, CGameSprite)
	local spriteActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
	--
	local levelModifier = math.floor(spriteActiveStats.m_nLevel1 / 5) -- +1 round every 5 levels
	--
	local berserkImmunity = "EEex_IsImmuneToOpcode(Myself,3)"
	--
	if not GT_EvalConditional["parseConditionalString"](CGameSprite, nil, berserkImmunity) then
		local effectCodes = {
			--{["op"] = 3}, -- berserk (mode: normal)
			{["op"] = 44, ["p1"] = math.random(6)}, -- STR mod (+1d6)
			{["op"] = 10, ["p1"] = math.random(6)}, -- CON mod (+1d6)
			--{["op"] = 317, ["p2"] = 2}, -- Haste (movement rate only)
			{["op"] = 101, ["p2"] = 5}, -- immunity to effect
			{["op"] = 101, ["p2"] = 76}, -- immunity to effect
			{["op"] = 101, ["p2"] = 128}, -- immunity to effect
			{["op"] = 403, ["p1"] = 0x208002, ["res"] = "GTIMMUNE"}, -- screen effects (confusion, charm, feeblemind)
			--{["op"] = 142, ["p2"] = 4} -- icon: Berserk
			{["op"] = 215, ["res"] = "ICSTRENI", ["p2"] = 1, ["dur"] = 2}, -- vfx
			{["op"] = 206, ["res"] = CGameEffect.m_sourceRes:get(), ["p1"] = 487873}, -- protection from spell
		}
		--
		for _, attributes in ipairs(effectCodes) do
			CGameSprite:applyEffect({
				["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
				["effectAmount"] = attributes["p1"] or 0,
				["dwFlags"] = attributes["p2"] or 0,
				["res"] = attributes["res"] or "",
				["duration"] = attributes["dur"] or ((6 * 5) + (6 * levelModifier)),
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameSprite.m_id,
				["sourceTarget"] = CGameSprite.m_id,
			})
		end
	end
end

--[[
+---------------------------------------------------------------------------------------+
| Hawk (blind): targeted creature is blinded for 1d10 rounds (save vs. breath to avoid) |
+---------------------------------------------------------------------------------------+
--]]

function GTIN221(CGameEffect, CGameSprite)
	local blindDuration = math.random(10) -- 1d10
	--
	local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId) -- CGameSprite
	--
	local blindImmunity = "EEex_IsImmuneToOpcode(Myself,74)"
	--
	local levelModifier = math.floor(sourceSprite:getActiveStats().m_nLevel1 / 5) -- +1 every 5 levels
	--
	if not GT_EvalConditional["parseConditionalString"](CGameSprite, nil, blindImmunity) then
		EEex_GameObject_ApplyEffect(CGameSprite,
		{
			["effectID"] = 74, -- Duration
			["duration"] = 6 * blindDuration,
			["savingThrow"] = 0x2, -- breath
			["saveMod"] = -1 * levelModifier,
			["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
			["m_sourceType"] = CGameEffect.m_sourceType,
			["sourceID"] = CGameEffect.m_sourceId,
			["sourceTarget"] = CGameEffect.m_sourceTarget,
		})
		EEex_GameObject_ApplyEffect(CGameSprite,
		{
			["effectID"] = 139, -- Display string
			["effectAmount"] = 231786,
			["savingThrow"] = 0x2, -- breath
			["saveMod"] = -1 * levelModifier,
			["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
			["m_sourceType"] = CGameEffect.m_sourceType,
			["sourceID"] = CGameEffect.m_sourceId,
			["sourceTarget"] = CGameEffect.m_sourceTarget,
		})
	end
end

--[[
+--------------------------------------------------------------------------------------------------+
| Leopard: Can perform sneak attacks as if it was an assassin of the same level (see sneakatt.2da) |
+--------------------------------------------------------------------------------------------------+
--]]

function GTIN200(CGameEffect, CGameSprite)
	if CGameEffect.m_effectAmount == 1 then -- check if can perform a sneak attack
		local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
		--
		local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
		-- limit to once per round
		local conditionalString = '!GlobalTimerNotExpired("gtLeopardSneakattTimer","LOCALS")'
		local responseString = 'SetGlobalTimer("gtLeopardSneakattTimer","LOCALS",6)'
		--
		--local selectedWeapon = GT_Sprite_GetSelectedWeapon(CGameSprite)
		--
		if GT_EvalConditional["parseConditionalString"](sourceSprite, nil, conditionalString) then
			-- if the target is incapacitated || the target is in combat with someone else
			if EEex_BAnd(targetActiveStats.m_generalState, 0x100029) ~= 0 or CGameSprite.m_targetId ~= sourceSprite.m_id then
				GT_ExecuteResponse["parseResponseString"](sourceSprite, nil, responseString)
				--
				CGameSprite:applyEffect({
					["effectID"] = 146, -- Cast spell
					["res"] = "GTIN200", -- SPL file
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
		local string = "EEex_IsImmuneToOpcode(Myself,12)"
		--
		local targetActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
		--
		local damageTypeIDS, ACModifier = GT_Sprite_ItmDamageTypeToIDS(selectedWeapon["ability"].damageType, targetActiveStats)
		--
		if not GT_EvalConditional["parseConditionalString"](CGameSprite, nil, string) then
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 0xC, -- Damage
				["dwFlags"] = damageTypeIDS * 0x10000, -- mode: normal
				["numDice"] = tonumber(sneakatt["ASSASIN"][string.format("%s", sourceActiveStats.m_nLevel1)]), -- typo in KIT.IDS / KITLIST.2DA
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
+-------------------------------------------------------------------------------------------+
| Snake Gaze (charm): targeted animal is charmed for 2d6 rounds (save vs. petrify to avoid) |
+-------------------------------------------------------------------------------------------+
--]]

function GTIN100(CGameEffect, CGameSprite)
	local charmDuration = math.random(6) + math.random(6) -- 2d6
	--
	local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId) -- CGameSprite
	--
	local charmImmunity = "EEex_IsImmuneToOpcode(Myself,5)"
	--
	local levelModifier = math.floor(sourceSprite:getActiveStats().m_nLevel1 / 5) -- +1 every 5 levels
	--
	if not GT_EvalConditional["parseConditionalString"](CGameSprite, nil, charmImmunity) then
		EEex_GameObject_ApplyEffect(CGameSprite,
		{
			["effectID"] = 5, -- Charm
			["duration"] = 6 * charmDuration,
			["dwFlags"] = 1, -- Charm type: Charmed (hostile)
			["effectAmount"] = 2, -- Creature type: ANIMAL
			["savingThrow"] = 0x1, -- spell
			["saveMod"] = -1 * levelModifier,
			["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
			["m_sourceType"] = CGameEffect.m_sourceType,
			["sourceID"] = CGameEffect.m_sourceId,
			["sourceTarget"] = CGameEffect.m_sourceTarget,
		})
		EEex_GameObject_ApplyEffect(CGameSprite,
		{
			["effectID"] = 174, -- Play (expiry) sound
			["durationType"] = 4,
			["duration"] = 6 * charmDuration,
			["res"] = "EFF_E04",
			["savingThrow"] = 0x1, -- spell
			["saveMod"] = -1 * levelModifier,
			["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
			["m_sourceType"] = CGameEffect.m_sourceType,
			["sourceID"] = CGameEffect.m_sourceId,
			["sourceTarget"] = CGameEffect.m_sourceTarget,
		})
	end
end

--[[
+------------------------------------------------------------------------------------+
| Snake Grasp: targeted creature is constricted for 5 rounds (+1 round per 5 levels) |
+------------------------------------------------------------------------------------+
--]]

-- main op402 listener --

function GTIN101(CGameEffect, CGameSprite)
	local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId)
	--local sourceAux = EEex_GetUDAux(sourceSprite)
	--
	if CGameEffect.m_effectAmount == 0 then
		local sourceActiveStats = EEex_Sprite_GetActiveStats(sourceSprite)
		--
		local levelModifier = math.floor(sourceActiveStats.m_nLevel1 / 5) -- +1 round every 5 levels
		--
		local holdImmunity = "EEex_IsImmuneToOpcode(Myself,185)"
		--
		if not GT_EvalConditional["parseConditionalString"](CGameSprite, nil, holdImmunity) then
			-- store targeted creature (sprite)
			--sourceAux["gt_Aux_SnakeGrasp_CoiledVictim"] = CGameSprite
			-- store targeted creature (id): this is because ``aux`` does not survive reloads, so if we save and reload the game while grasping a creature, the coiled victim will be lost
			sourceSprite:setLocalInt("gtSnakeGraspCoiledVictimID", CGameSprite.m_id)
			-- free the coiled victim upon death
			do
				local effectCodes = {
					--{["op"] = 0xE8, ["p2"] = 16}, -- cast spell on condition (232), cond: Die()
					{["op"] = 0x92, ["p2"] = 1, ["tmg"] = 4}, -- cast spell (146), mode: instant/ignore level (nuke aux upon expiration)
				}
				--
				for _, attributes in ipairs(effectCodes) do
					sourceSprite:applyEffect({
						["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
						["dwFlags"] = attributes["p2"] or 0,
						["res"] = "GTIN101B",
						["durationType"] = attributes["tmg"] or 0,
						["duration"] = (6 * 5) + (6 * levelModifier),
						["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
						["m_sourceType"] = CGameEffect.m_sourceType,
						["sourceID"] = sourceSprite.m_id,
						["sourceTarget"] = sourceSprite.m_id,
					})
				end
			end
			-- actual grasp (not dispellable by Free Action &c.)
			-- nuke aux upon target death
			do
				local effectCodes = {
					--{["op"] = 0xE8, ["p2"] = 16, ["res"] = "GTIN101B", ["spec"] = 0x2}, -- cast spell on condition (232), cond: Die(), spec: Fire subspell as effect source (the creature that casts the spell) instead of effect host (the creature the effect is attached to)
					{["op"] = 0xB9, ["p2"] = 2}, -- hold II (185)
					{["op"] = 0xCE, ["res"] = "GTIN101", ["p1"] = 487879}, -- protection from spell (206), string: already constricted
				}
				--
				for _, attributes in ipairs(effectCodes) do
					CGameSprite:applyEffect({
						["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
						["dwFlags"] = attributes["p2"] or 0,
						["effectAmount"] = attributes["p1"] or 0,
						["res"] = attributes["res"] or "",
						["special"] = attributes["spec"] or 0,
						["duration"] = (6 * 5) + (6 * levelModifier),
						["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
						["m_sourceType"] = CGameEffect.m_sourceType,
						["sourceID"] = CGameEffect.m_sourceId,
						["sourceTarget"] = CGameEffect.m_sourceTarget,
					})
				end
			end
		else
			CGameSprite:applyEffect({
				["effectID"] = 324,
				["res"] = CGameEffect.m_sourceRes:get(),
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
		end
	else
		local victim = EEex_GameObject_Get(sourceSprite:getLocalInt("gtSnakeGraspCoiledVictimID")) -- CGameSprite
		--
		sourceSprite:applyEffect({
			["effectID"] = 321, -- remove effects by resource
			["res"] = "GTIN101",
			["noSave"] = true,
			["sourceID"] = sourceSprite.m_id,
			["sourceTarget"] = sourceSprite.m_id,
		})
		--
		if victim then
			victim:applyEffect({
				["effectID"] = 321, -- remove effects by resource
				["res"] = "GTIN101",
				["noSave"] = true,
				["sourceID"] = victim.m_id,
				["sourceTarget"] = victim.m_id,
			})
			victim:applyEffect({
				["effectID"] = 139, -- feedback string
				["effectAmount"] = 487880,
				["noSave"] = true,
				["sourceID"] = victim.m_id,
				["sourceTarget"] = victim.m_id,
			})
			--
			sourceSprite:setLocalInt("gtSnakeGraspCoiledVictimID", -1)
		end
	end
end

-- make sure to nuke the aux upon death (we do not trust op232). This is because auxiliary values are not cleared upon death --
-- also, make sure to clear delayed op146 on the snake upon victim's death --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	--local aux = EEex_GetUDAux(sprite)
	local victim = EEex_GameObject_Get(sprite:getLocalInt("gtSnakeGraspCoiledVictimID")) -- CGameSprite
	--
	if victim then
		local found = false
		EEex_Utility_IterateCPtrList(victim.m_timedEffectList, function(effect)
			if effect.m_effectId == 185 and effect.m_sourceId == sprite.m_id and effect.m_sourceRes:get() == "GTIN101" then
				found = true
				return true
			end
		end)
		--
		if not found then
			sprite:applyEffect({
				["effectID"] = 146, -- cast spell
				["dwFlags"] = 1, -- instant/ignore level
				["res"] = "GTIN101B",
				["noSave"] = true,
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- free the coiled victim upon getting petrified/frozen/stunned/mazed/imprisoned/... --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) or not sprite.m_pArea then
		return
	end
	--
	--local aux = EEex_GetUDAux(sprite)
	local victim = EEex_GameObject_Get(sprite:getLocalInt("gtSnakeGraspCoiledVictimID")) -- CGameSprite
	--
	local isMazed = false
	--
	local func
	func = function(effect)
		if effect.m_effectId == 177 or effect.m_effectId == 283 then -- Use EFF file
			local CGameEffectBase = EEex_Resource_Demand(effect.m_res:get(), "eff")
			--
			if CGameEffectBase then -- sanity check
				if func(CGameEffectBase) then
					isMazed = true
					return true
				end
			end
		elseif effect.m_effectId == 0xD5 then -- Maze (213)
			isMazed = true
			return true
		end
	end
	--
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, func)
	--
	if victim then
		local conditionalString = 'Range(EEex_Target("gtCoiledVictim"),4)'
		--
		if EEex_BAnd(sprite.m_derivedStats.m_generalState, 0x80102FEF) ~= 0 or not EEex_UDEqual(sprite.m_pArea, victim.m_pArea) or isMazed or not GT_EvalConditional["parseConditionalString"](sprite, victim, conditionalString, "gtCoiledVictim") then
			sprite:applyEffect({
				["effectID"] = 146, -- cast spell
				["dwFlags"] = 1, -- instant/ignore level
				["res"] = "GTIN101B",
				["noSave"] = true,
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- free the coiled victim upon a successful open doors roll --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	local stats = GT_Resource_SymbolToIDS["stats"]
	--
	local constricted = false
	local id = -1
	local timerRunning = false
	--
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		if effect.m_effectId == 185 and effect.m_sourceRes:get() == "GTIN101" then
			constricted = true
			id = effect.m_sourceId
		elseif effect.m_effectId == 401 and effect.m_special == stats["GT_DUMMY_STAT"] and effect.m_scriptName:get() == "gtSnakeGraspTimer" then -- dummy opcode that acts as a marker/timer
			timerRunning = true
		end
	end)
	--
	if constricted then
		if EEex_GameObject_Get(id) then -- sanity check
			local src = EEex_GameObject_Get(id) -- CGameSprite (snake)
			--
			if not timerRunning then
				-- fetch components of check
				local strmod = GT_Resource_2DA["strmod"]
				local strmodex = GT_Resource_2DA["strmodex"]
				--
				local strBonus = tonumber(strmod[tostring(sprite.m_derivedStats.m_nSTR)]["BEND_BARS_LIFT_GATES"])
				local strExtraBonus = sprite.m_derivedStats.m_nSTR == 18 and tonumber(strmodex[tostring(sprite.m_derivedStats.m_nSTRExtra)]["BEND_BARS_LIFT_GATES"]) or 0
				--
				local roll = math.random(tonumber(strmod["19"]["BEND_BARS_LIFT_GATES"]))
				--
				if strBonus + strExtraBonus >= roll then
					src:applyEffect({
						["effectID"] = 146, -- cast spell
						["dwFlags"] = 1, -- instant/ignore level
						["res"] = "GTIN101B",
						["noSave"] = true,
						["sourceID"] = src.m_id,
						["sourceTarget"] = src.m_id,
					})
				else
					-- set timer (+1d6 crushing damage)
					sprite:applyEffect({
						["effectID"] = 401, -- Set extended stat
						["special"] = stats["GT_DUMMY_STAT"],
						["m_scriptName"] = "gtSnakeGraspTimer",
						["duration"] = 6,
						["noSave"] = true,
						["m_sourceRes"] = "GTIN101",
						["sourceID"] = src.m_id,
						["sourceTarget"] = sprite.m_id,
					})
					sprite:applyEffect({
						["effectID"] = 12, -- Damage
						["numDice"] = 1,
						["diceSize"] = 6,
						["sourceID"] = src.m_id,
						["sourceTarget"] = sprite.m_id,
					})
				end
			end
		else
			sprite:applyEffect({
				["effectID"] = 146, -- cast spell
				["dwFlags"] = 1, -- instant/ignore level
				["res"] = "GTIN101B",
				["noSave"] = true,
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- free the coiled victim upon attacking/casting/moving/... --

EEex_Action_AddSpriteStartedActionListener(function(sprite, action)
	--local aux = EEex_GetUDAux(sprite)
	local victim = EEex_GameObject_Get(sprite:getLocalInt("gtSnakeGraspCoiledVictimID")) -- CGameSprite
	--
	local actionSources = {
		[31] = true, -- Spell()
		[95] = true, -- SpellPoint()
		[191] = true, -- SpellNoDec()
		[192] = true, -- SpellPointNoDec()
		[113] = true, -- ForceSpell()
		[114] = true, -- ForceSpellPoint()
		[181] = true, -- ReallyForceSpell()
		[318] = true, -- ForceSpellRange()
		[319] = true, -- ForceSpellPointRange()
		[337] = true, -- ReallyForceSpellPoint()
		[476] = true, -- EEex_SpellObjectOffset()
		[477] = true, -- EEex_SpellObjectOffsetNoDec()
		[478] = true, -- EEex_ForceSpellObjectOffset()
		[479] = true, -- EEex_ReallyForceSpellObjectOffset()
		--
		[3] = true, -- Attack()
		[94] = true, -- GroupAttack()
		[98] = true, -- AttackNoSound()
		[105] = true, -- AttackOneRound()
		[134] = true, -- AttackReevaluate()
	}
	--
	if victim then
		if actionSources[action.m_actionID] then
			sprite:applyEffect({
				["effectID"] = 146, -- cast spell
				["dwFlags"] = 1, -- instant/ignore level
				["res"] = "GTIN101B",
				["noSave"] = true,
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		else
			sprite:applyEffect({
				["effectID"] = 0x16E, -- Apply spell on movement
				["res"] = "GTIN101B",
				["duration"] = 1,
				["noSave"] = true,
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- Anyone who attempts to free a captive by hacking at the constrictor has a 20% chance of striking the victim instead --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	local attackerAux = EEex_GetUDAux(sprite)
	--
	local actionSources = {
		[3] = true, -- Attack()
		[94] = true, -- GroupAttack()
		[98] = true, -- AttackNoSound()
		[105] = true, -- AttackOneRound()
		[134] = true, -- AttackReevaluate()
	}
	--
	local m_curAction = sprite.m_curAction -- CAIAction
	--
	if sprite.m_startedSwing == 1 then
		if actionSources[m_curAction.m_actionID] and not attackerAux["gt_SnakeGrasp_StrikeVictim"] then
			attackerAux["gt_SnakeGrasp_StrikeVictim"] = {}
			--
			local target = EEex_GameObject_Get(sprite.m_targetId) -- CGameSprite
			-- if the targeted creature is not dead...
			if target and EEex_IsBitUnset(target.m_derivedStats.m_generalState, 11) then
				--local targetAux = EEex_GetUDAux(target)
				local victim = EEex_GameObject_Get(target:getLocalInt("gtSnakeGraspCoiledVictimID")) -- CGameSprite
				--
				local roll = math.random(20) -- 1d20
				--
				local conditionalString = 'InWeaponRange(EEex_Target("gtCoiledVictim"))'
				--
				if victim and roll <= 4 and GT_EvalConditional["parseConditionalString"](sprite, victim, conditionalString, "gtCoiledVictim") then -- 20% chance + InWeaponRange()
					-- store original ``m_actionID`` and ``m_acteeID``
					-- NB.: this is because we recall some weirdness with ``AttackReevaluate()`` and how it stores its target!
					attackerAux["gt_SnakeGrasp_StrikeVictim"] = {
						["actionID"] = m_curAction.m_actionID,
						["instance"] = m_curAction.m_acteeID.m_Instance,
					}
					--
					m_curAction.m_actionID = 105 -- ``AttackOneRound()``
					m_curAction.m_acteeID.m_Instance = victim.m_id
				end
			end
		end
	elseif attackerAux["gt_SnakeGrasp_StrikeVictim"] then
		-- restore original action if needed
		if actionSources[m_curAction.m_actionID] and attackerAux["gt_SnakeGrasp_StrikeVictim"]["actionID"] then
			m_curAction.m_actionID = attackerAux["gt_SnakeGrasp_StrikeVictim"]["actionID"]
		end
		if actionSources[m_curAction.m_actionID] and attackerAux["gt_SnakeGrasp_StrikeVictim"]["instance"] then
			m_curAction.m_acteeID.m_Instance = attackerAux["gt_SnakeGrasp_StrikeVictim"]["instance"]
		end
		--
		attackerAux["gt_SnakeGrasp_StrikeVictim"] = nil
	end
end)


--[[
+----------------------------------------------------------------------------------------------------------------------+
| Snakes fear fire and will retreat from open flames, suffering a -1 morale modifier when flames are used against them |
+----------------------------------------------------------------------------------------------------------------------+
--]]

function GTIN102(op403CGameEffect, CGameEffect, CGameSprite)
	local dmgtype = GT_Resource_SymbolToIDS["dmgtype"]
	--
	local spriteActiveStats = EEex_Sprite_GetActiveStats(CGameSprite)
	--
	--local immunityToDamage = EEex_Trigger_ParseConditionalString("EEex_IsImmuneToOpcode(Myself,12)")
	--
	if CGameEffect.m_effectId == 0xC and EEex_IsMaskSet(CGameEffect.m_dWFlags, dmgtype["FIRE"]) then -- Damage (FIRE)
		if spriteActiveStats.m_nResistFire < 100 then -- only apply if the target is not immune to fire
			-- op403 "sees" effects after they have passed their probability roll, but before any saving throws have been made against said effect / other immunity mechanisms have taken place
			-- opcodes applied here *should* use the same roll for saves and mr checks...
			-- moreover, the morale modifier penalty *should* not be bounced back...
			if not GT_Sprite_HasBounceEffects(CGameSprite, CGameEffect.m_spellLevel, CGameEffect.m_projectileType, CGameEffect.m_school, CGameEffect.m_secondaryType, CGameEffect.m_sourceRes:get(), {12, 23, 146, 24}, CGameEffect.m_flags, false) then
				if not GT_Sprite_HasImmunityEffects(CGameSprite, CGameEffect.m_spellLevel, CGameEffect.m_projectileType, CGameEffect.m_school, CGameEffect.m_secondaryType, CGameEffect.m_sourceRes:get(), {12, 23, 146, 24}, CGameEffect.m_flags, CGameEffect.m_savingThrow, 0x0, false) then
					if not GT_Sprite_HasTrapEffect(CGameSprite, CGameEffect.m_spellLevel, CGameEffect.m_secondaryType, CGameEffect.m_flags, false) then
						CGameSprite:applyEffect({
							["effectID"] = 146, -- cast spell
							["dwFlags"] = 1, -- instant/ignore level
							--
							["savingThrow"] = EEex_IsBitSet(CGameEffect.m_special, 0x8) and 0 or CGameEffect.m_savingThrow, -- ignore save check if the save for half flag is set
							["saveMod"] = CGameEffect.m_saveMod,
							["m_flags"] = CGameEffect.m_flags,
							--
							["durationType"] = CGameEffect.m_durationType,
							["duration"] = CGameEffect.m_duration,
							--
							["spellLevel"] = CGameEffect.m_spellLevel,
							["m_projectileType"] = CGameEffect.m_projectileType,
							["m_school"] = CGameEffect.m_school,
							["m_secondaryType"] = CGameEffect.m_secondaryType,
							["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
							--
							["m_sourceType"] = CGameEffect.m_sourceType,
							["m_sourceFlags"] = CGameEffect.m_sourceFlags,
							["m_casterLevel"] = CGameEffect.m_casterLevel,
							["m_slotNum"] = CGameEffect.m_slotNum,
							--
							["res"] = "GTIN102",
							--
							["sourceID"] = CGameEffect.m_sourceId,
							["sourceTarget"] = CGameEffect.m_sourceTarget,
						})
					end
				end
			end
		end
	end
end


--[[
+--------------------------------------------------------------------------------------------+
| Web Tangle (spider): targeted creature is webbed for 2d6 rounds (save vs. breath to avoid) |
+--------------------------------------------------------------------------------------------+
--]]

function GTIN201(CGameEffect, CGameSprite)
	local webDuration = math.random(6) + math.random(6) -- 2d6
	--
	local sourceSprite = EEex_GameObject_Get(CGameEffect.m_sourceId) -- CGameSprite
	--
	local webImmunity = "EEex_IsImmuneToOpcode(Myself,157)"
	--
	local levelModifier = math.floor(sourceSprite:getActiveStats().m_nLevel1 / 5) -- +1 every 5 levels
	--
	if not GT_EvalConditional["parseConditionalString"](CGameSprite, nil, webImmunity) then
		EEex_GameObject_ApplyEffect(CGameSprite,
		{
			["effectID"] = 157, -- Web overlay
			["duration"] = 6 * webDuration,
			["savingThrow"] = 0x2, -- breath
			["saveMod"] = -1 * levelModifier,
			["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
			["m_sourceType"] = CGameEffect.m_sourceType,
			["sourceID"] = CGameEffect.m_sourceId,
			["sourceTarget"] = CGameEffect.m_sourceTarget,
		})
		EEex_GameObject_ApplyEffect(CGameSprite,
		{
			["effectID"] = 142, -- Display portrait icon
			["dwFlags"] = 129, -- webbed
			["duration"] = 6 * webDuration,
			["savingThrow"] = 0x2, -- breath
			["saveMod"] = -1 * levelModifier,
			["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
			["m_sourceType"] = CGameEffect.m_sourceType,
			["sourceID"] = CGameEffect.m_sourceId,
			["sourceTarget"] = CGameEffect.m_sourceTarget,
		})
		EEex_GameObject_ApplyEffect(CGameSprite,
		{
			["effectID"] = 174, -- Play sound
			["res"] = "CRE_M02",
			["savingThrow"] = 0x2, -- breath
			["saveMod"] = -1 * levelModifier,
			["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
			["m_sourceType"] = CGameEffect.m_sourceType,
			["sourceID"] = CGameEffect.m_sourceId,
			["sourceTarget"] = CGameEffect.m_sourceTarget,
		})
	end
end

