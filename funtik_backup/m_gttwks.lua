-- ***Misc Tweaks*** --

--[[
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| cdtweaks: hide op215 and hardcoded animations played by opcodes 153, 155, 156, 201, 204, 205, 223, 226, 259, 197, 198, 200, 202, 203, 207, 227, 228, 299 from invisible enemies |
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
--]]

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- sanity check
	if 1==1	then 
		return 
	end
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	local func
	func = function(effect)
		if effect.m_effectId == 0xB1 or effect.m_effectId == 0x11B then -- Use EFF file
			local CGameEffectBase = EEex_Resource_Demand(effect.m_res:get(), "eff")
			--
			if CGameEffectBase then -- sanity check
				if func(CGameEffectBase) then
					return true
				end
			end
		elseif effect.m_effectId == 0xD7 or effect.m_effectId == 0x99 or effect.m_effectId == 0x9B or effect.m_effectId == 0x9C then
			return true
		end
		--
		return false
	end
	--
	local effectList = {sprite.m_timedEffectList, sprite.m_equipedEffectList}
	-- Check creature's state
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteGeneralState = sprite.m_derivedStats.m_generalState
	--
	local applyCondition = EEex_IsBitSet(spriteGeneralState, 0x4) and sprite.m_typeAI.m_EnemyAlly > 200 -- STATE_INVISIBLE && EVILCUTOFF
	--
	if applyCondition then
		-- Play visual effect (215), Sanctuary (153), Minor globe overlay (155), Protection from normal missiles overlay (156)
		for _, list in ipairs(effectList) do
			EEex_Utility_IterateCPtrList(list, function(effect)
				local found = func(effect)
				-- hide visual effects
				if found then
					if effect.m_res3:get() ~= "GTHIDVFX" then
						--Infinity_DisplayString("hiding vfx...")
						--
						effect.m_res2:set(effect.m_res:get()) -- store for later restoration
						if not (effect.m_effectId == 177 or effect.m_effectId == 283) then
							effect.m_dWFlags = effect.m_effectId == 215 and effect.m_dWFlags or 1 -- custom overlay
						end
						effect.m_res:set("") -- null overlay
						effect.m_res3:set("GTHIDVFX")
					end
				end
			end)
		end
		-- Spell Deflection/Reflection/Trap
		sprite:applyEffect({
			["effectID"] = 0x141, -- Remove effects by resource (321)
			["noSave"] = true, -- just in case...?
			["res"] = "GTHIDVFX",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		EEex_GameObject_ApplyEffect(sprite,
		{
			["effectID"] = 0x123, -- Disable visual effects (291)
			["noSave"] = true, -- just in case...?
			["dwFlags"] = 1,
			["durationType"] = 9,
			["m_sourceRes"] = "GTHIDVFX",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	else
		-- Play visual effect (215), Sanctuary (153), Minor globe overlay (155), Protection from normal missiles overlay (156)
		for _, list in ipairs(effectList) do
			EEex_Utility_IterateCPtrList(list, function(effect)
				local found = func(effect)
				-- restore visual effects
				if found then
					if effect.m_res3:get() == "GTHIDVFX" then
						--Infinity_DisplayString("restoring vfx...")
						--
						if effect.m_effectId ~= 215 and effect.m_effectId ~= 177 and effect.m_effectId ~= 283 then
							effect.m_dWFlags = effect.m_res2:get() == "" and 0 or 1
						end
						effect.m_res:set(effect.m_res2:get())
						effect.m_res2:set("")
						effect.m_res3:set("")
					end
				end
			end)
		end
		--
		sprite:applyEffect({
			["effectID"] = 0x141, -- Remove effects by resource (321)
			["noSave"] = true, -- just in case...?
			["res"] = "GTHIDVFX",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
end)


--[[
+--------------------------------------+
| cdtweaks, Revised Troll Regeneration |
+--------------------------------------+
--]]

-- flag regenerating trolls as such --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	local spriteRaceStr = GT_Resource_IDSToSymbol["race"][sprite.m_typeAI.m_Race]
	--
	local func
	func = function(effect)
		local m_sourceType = effect.m_sourceType
		local m_sourceRes = effect.m_sourceRes:get()
		local tocheck = false
		--
		if m_sourceType == 2 then
			local pHeader = EEex_Resource_Demand(m_sourceRes, "itm")
			--
			if EEex_IsBitUnset(pHeader.itemFlags, 0x2) then
				tocheck = true
			end
		else
			if m_sourceRes == "" then
				tocheck = true
			end
		end
		--
		if tocheck then
			if effect.m_effectId == 177 or effect.m_effectId == 283 then -- Use EFF file
				local CGameEffectBase = EEex_Resource_Demand(effect.m_res:get(), "eff")
				--
				if CGameEffectBase then -- sanity check
					local result = func(CGameEffectBase)
					if result then
						return true
					end
				end
			elseif effect.m_effectId == 98 then -- Regeneration
				return true
			end
		end
	end
	--
	if (spriteRaceStr == "TROLL" or spriteRaceStr == "SNOW_TROLL") then
		local effectList = {sprite.m_timedEffectList, sprite.m_equipedEffectList}
		--
		local found = false
		for _, list in ipairs(effectList) do
			EEex_Utility_IterateCPtrList(list, function(effect)
				if func(effect) then
					effect.m_sourceRes:set("GTTRLREG")
					found = true
				end
			end)
		end
		--
		if found then
			local effectCodes = {
				{["op"] = 321, ["res"] = "GTTRLREG"}, -- remove effects by resource
				{["op"] = 321, ["res"] = "GTTRLRG1"}, -- remove effects by resource
				{["op"] = 142, ["p2"] = 56}, -- icon: regenerating
				{["op"] = 403, ["res"] = "GTTRLRG1"}, -- screen effects
			}
			--
			for _, attributes in ipairs(effectCodes) do
				sprite:applyEffect({
					["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
					["dwFlags"] = attributes["p2"] or 0,
					["res"] = attributes["res"] or "",
					["durationType"] = 9,
					["m_sourceRes"] = "GTTRLRG1",
					["noSave"] = true,
					["sourceID"] = sprite.m_id,
					["sourceTarget"] = sprite.m_id,
				})
			end
		end
	end
end)

-- +1d6 hp/round (regardless of haste/slow) --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteGeneralState = sprite.m_derivedStats.m_generalState
	--
	local aux = EEex_GetUDAux(sprite)
	--
	local stats = GT_Resource_SymbolToIDS["stats"]
	--
	local timerRunning = false
	local found = false
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		if effect.m_effectId == 401 and effect.m_special == stats["GT_DUMMY_STAT"] and effect.m_scriptName:get() == "gtTrollRegTimer" then -- dummy opcode that acts as a marker/timer
			timerRunning = true
		elseif effect.m_effectId == 403 and effect.m_res:get() == "GTTRLRG1" then
			found = true
		end
	end)
	--
	if found then
		if not timerRunning then
			-- skip if hit by fire/acid OR if in coma
			if not aux["gt_PnP_IsTrollRegHalted"] and not (EEex_IsBitSet(spriteGeneralState, 0x0) and sprite.m_derivedStats.m_nResistSlashing == 100) then
				sprite:applyEffect({
					["effectID"] = 17, -- cur hp bonus
					["numDice"] = 1,
					["diceSize"] = 6,
					["sourceID"] = sprite.m_id,
					["sourceTarget"] = sprite.m_id,
				})
			end
			-- set timer
			sprite:applyEffect({
				["effectID"] = 401, -- set extended stat
				["special"] = stats["GT_DUMMY_STAT"],
				["m_scriptName"] = "gtTrollRegTimer",
				["duration"] = 90, -- 90 ticks ~ 1 round
				["durationType"] = 10, -- instant/limited (ticks)
				["noSave"] = true,
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
			--
			aux["gt_PnP_IsTrollRegHalted"] = nil
		end
	end
end)

-- op403 listener: any time they take fire or acid damage their regeneration is halted for one round (not cumulative) --

function GTTRLRG1(op403CGameEffect, CGameEffect, CGameSprite)
	local dmgtype = GT_Resource_SymbolToIDS["dmgtype"]
	--
	local fields
	local found = false
	local forceApplyViaOp177 = false
	--
	if CGameEffect.m_effectId == 0xC then -- damage
		if EEex_IsMaskSet(CGameEffect.m_dWFlags, dmgtype["FIRE"]) or EEex_IsMaskSet(CGameEffect.m_dWFlags, dmgtype["ACID"]) then
			found = true
			fields = GT_Utility_GetEffectFields(CGameEffect)
		end
	elseif CGameEffect.m_effectId == 0xB1 and CGameEffect.m_effectAmount4 ~= 0 then -- https://github.com/Gibberlings3/iesdp/pull/193
		if GT_Sprite_CheckIDS(CGameSprite, CGameEffect.m_effectAmount, CGameEffect.m_dWFlags) then
			local CGameEffectBase = EEex_Resource_Demand(CGameEffect.m_res:get(), "eff")
			-- sanity check
			if CGameEffectBase then
				if CGameEffectBase.m_effectId == 0xC then
					if EEex_IsMaskSet(CGameEffectBase.m_dWFlags, dmgtype["FIRE"]) or EEex_IsMaskSet(CGameEffectBase.m_dWFlags, dmgtype["ACID"]) then
						found = true
						forceApplyViaOp177 = true
						fields = GT_Utility_GetEffectFields(CGameEffectBase)
					end
				end
			end
		end
	end
	--
	if found then
		-- op403 "sees" effects after they have passed their probability roll, but before any saving throws have been made against said effect / other immunity mechanisms have taken place
		-- opcodes applied here *should* use the same roll for saves and mr checks...
		-- make sure it is *not* reflected/deflected/trapped
		if not GT_Sprite_HasBounceEffects(CGameSprite, fields["spellLevel"], fields["projectileType"], fields["school"], fields["secondaryType"], fields["sourceRes"], {402, 12}, fields["flags"]) or forceApplyViaOp177 then
			if not GT_Sprite_HasImmunityEffects(CGameSprite, fields["spellLevel"], fields["projectileType"], fields["school"], fields["secondaryType"], fields["sourceRes"], {402, 12}, fields["flags"], fields["savingThrow"], 0x0) or forceApplyViaOp177 then
				if not GT_Sprite_HasTrapEffect(CGameSprite, fields["spellLevel"], fields["secondaryType"], fields["flags"]) or forceApplyViaOp177 then
					--
					CGameSprite:applyEffect({
						["effectID"] = 402, -- invoke lua
						["res"] = "GTTRLRG2", -- lua func
						--
						["durationType"] = CGameEffect.m_durationType,
						["duration"] = CGameEffect.m_duration,
						--
						["m_flags"] = fields["flags"],
						["savingThrow"] = EEex_IsBitSet(fields["special"], 0x8) and 0 or fields["savingThrow"], -- ignore save check if the save for half flag is set
						["saveMod"] = fields["saveMod"],
						--
						["spellLevel"] = fields["spellLevel"],
						["m_projectileType"] = fields["projectileType"],
						["m_school"] = fields["school"],
						["m_secondaryType"] = fields["secondaryType"],
						["m_sourceRes"] = fields["sourceRes"],
						--
						["m_sourceType"] = fields["sourceType"],
						["m_sourceFlags"] = fields["sourceFlags"],
						["m_casterLevel"] = fields["casterLevel"],
						["m_slotNum"] = fields["slotNum"],
						--
						["sourceID"] = CGameEffect.m_sourceId,
						["sourceTarget"] = CGameEffect.m_sourceTarget,
					})
				end
			end
		end
	end
end

-- op402 listener --

function GTTRLRG2(CGameEffect, CGameSprite)
	local aux = EEex_GetUDAux(CGameSprite)
	--
	aux["gt_PnP_IsTrollRegHalted"] = true
	--
	CGameEffect.m_done = true
end


--[[
+---------------------------------------------------------------------+
| cdtweaks, Give Every Class/Kit Four Weapon Slots                    |
+---------------------------------------------------------------------+
| Press and Hold ``Left Ctrl`` to access the extra quick weapon slots |
+---------------------------------------------------------------------+
--]]

local GT_Tweaks_GiveEveryClassKitFourWeaponSlots = {
	[1] = 2, -- Mage / Sorcerer
	[3] = 2, -- Cleric
	[4] = 2, -- Thief
	[5] = 2, -- Bard
	[6] = 3, -- Paladin
	[7] = 2, -- Fighter Mage
	[8] = 2, -- Fighter Cleric
	[9] = 2, -- Fighter Thief
	[10] = 2, -- Fighter Mage Thief
	[11] = 2, -- Druid
	[12] = 3, -- Ranger
	[13] = 2, -- Mage Thief
	[14] = 2, -- Cleric Mage
	[15] = 2, -- Cleric Thief
	[16] = 2, -- Fighter Druid
	[17] = 2, -- Fighter Mage Cleric
	[18] = 2, -- Cleric Ranger
	[20] = 3, -- Monk
	[21] = 2, -- Shaman
}

EEex_Key_AddPressedListener(function(key)

	local sprite = EEex_Sprite_GetSelected() -- CGameSprite
	if not sprite then
		return
	end

	local state = EEex_Actionbar_GetState()

	if sprite.m_typeAI.m_EnemyAlly == 2 then -- if [PC]
		if key == EEex_Key_GetFromName("Left Ctrl") then
			if GT_Tweaks_GiveEveryClassKitFourWeaponSlots[state] == 2 then
				-- replace weapon 1 and 2 with 3 and 4
				for i = 0, 11 do
					if buttonArray:GetButtonType(i) == EEex_Actionbar_ButtonType.QUICK_WEAPON_1 then
						EEex_Actionbar_SetButton(i, EEex_Actionbar_ButtonType.QUICK_WEAPON_3)
					end
					if buttonArray:GetButtonType(i) == EEex_Actionbar_ButtonType.QUICK_WEAPON_2 then
						EEex_Actionbar_SetButton(i, EEex_Actionbar_ButtonType.QUICK_WEAPON_4)
					end
				end
			elseif GT_Tweaks_GiveEveryClassKitFourWeaponSlots[state] == 3 then
				-- replace weapon 3 with 4
				for i = 0, 11 do
					if buttonArray:GetButtonType(i) == EEex_Actionbar_ButtonType.QUICK_WEAPON_3 then
						EEex_Actionbar_SetButton(i, EEex_Actionbar_ButtonType.QUICK_WEAPON_4)
					end
				end
			end
		end
	end

end)

EEex_Key_AddReleasedListener(function(key)

	local sprite = EEex_Sprite_GetSelected() -- CGameSprite
	if not sprite then
		return
	end

	local state = EEex_Actionbar_GetState()

	if sprite.m_typeAI.m_EnemyAlly == 2 then -- if [PC]
		if key == EEex_Key_GetFromName("Left Ctrl") then
			if GT_Tweaks_GiveEveryClassKitFourWeaponSlots[state] == 2 then
				-- replace weapon 3 and 4 with 1 and 2
				for i = 0, 11 do
					if buttonArray:GetButtonType(i) == EEex_Actionbar_ButtonType.QUICK_WEAPON_3 then
						EEex_Actionbar_SetButton(i, EEex_Actionbar_ButtonType.QUICK_WEAPON_1)
					end
					if buttonArray:GetButtonType(i) == EEex_Actionbar_ButtonType.QUICK_WEAPON_4 then
						EEex_Actionbar_SetButton(i, EEex_Actionbar_ButtonType.QUICK_WEAPON_2)
					end
				end
			elseif GT_Tweaks_GiveEveryClassKitFourWeaponSlots[state] == 3 then
				-- replace weapon 4 with 3
				for i = 0, 11 do
					if buttonArray:GetButtonType(i) == EEex_Actionbar_ButtonType.QUICK_WEAPON_4 then
						EEex_Actionbar_SetButton(i, EEex_Actionbar_ButtonType.QUICK_WEAPON_3)
					end
				end
			end
		end
	end

end)


--[[
+----------------------------------------+
| cdtweaks, more sensible cowled wizards |
+----------------------------------------+
--]]

-- set a GLOBAL var when a PC casts a wizard spell and is in Athkatla --

GTCOWENF = {

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
		local areaSources = {
			["AR0020"] = true, -- City Gates
			["AR0300"] = true, -- The Docks
			["AR0400"] = true, -- Slums
			["AR0500"] = true, -- Bridge District
			["AR0700"] = true, -- Waukeen's Promenade
			["AR0900"] = true, -- Temple District
			["AR1000"] = true, -- Government District
		}
		--
		if not actionSources[context.decodeSource] then
			return
		end
		--
		local originatingSprite = context["originatingSprite"] -- CGameSprite
		--
		--local areaCheck = EEex_Trigger_ParseConditionalString('OR(7) \n AreaCheck("AR0020") AreaCheck("AR0300") AreaCheck("AR0400") AreaCheck("AR0500") AreaCheck("AR0700") AreaCheck("AR0900") AreaCheck("AR1000")')
		--
		local spellResRef = originatingSprite.m_curAction.m_string1.m_pchData:get()
		if spellResRef == "" then
			spellResRef = GT_Utility_DecodeSpell(originatingSprite.m_curAction.m_specificID)
		end
		--
		local spellHeader = EEex_Resource_Demand(spellResRef, "SPL")
		--
		if spellHeader.itemType == 1 and areaSources[originatingSprite.m_pArea.m_resref:get()] then -- if wizard spell and in Athkatla ...
			EEex_GameState_SetGlobalInt("gtCowledWizardsTriggered", 1)
		end
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

--

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual condition
	local apply = function()
		-- Mark the creature as 'condition applied'
		sprite:setLocalInt("gtMoreSensibleCowlies", 1)
		--
		local effectCodes = {
			{["op"] = 321}, -- Remove effects by resource
			{["op"] = 408}, -- Projectile mutator
		}
		--
		for _, attributes in ipairs(effectCodes) do
			sprite:applyEffect({
				["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
				["durationType"] = 9,
				["res"] = "GTCOWENF",
				["m_sourceRes"] = "GTCOWENF",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
	-- Check creature's EA
	local applyCondition = sprite.m_typeAI.m_EnemyAlly == 2 -- PC
	--
	if sprite:getLocalInt("gtMoreSensibleCowlies") == 0 then
		if applyCondition then
			apply()
		end
	else
		if applyCondition then
			-- do nothing
		else
			-- Mark the creature as 'condition removed'
			sprite:setLocalInt("gtMoreSensibleCowlies", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTCOWENF",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

--[[
+-------------------------------------------------------------------------------------------------------+
| cdtweaks: whenever a stoneskinned creature gets hit, inform the player about the number of skins left |
+-------------------------------------------------------------------------------------------------------+
--]]

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual condition
	local apply = function()
		-- Mark the creature as 'condition applied'
		sprite:setLocalInt("gtDisplayStoneskinsLeft", 1)
		--
		local effectCodes = {
			{["op"] = 0x141}, -- Remove effects by resource (321)
			{["op"] = 0xE8}, -- Cast spell on condition (232)
		}
		--
		for _, attributes in ipairs(effectCodes) do
			sprite:applyEffect({
				["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
				["durationType"] = 1,
				["res"] = "GTSTNSKN",
				["m_sourceRes"] = "GTSTNSKN",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
	-- Check if the creature is stoneskinned
	local applyCondition = sprite.m_derivedStats.m_nStoneSkins > 0 -- at least one skin
	--
	if sprite:getLocalInt("gtDisplayStoneskinsLeft") == 0 then
		if applyCondition then
			apply()
		end
	else
		if applyCondition then
			-- do nothing
		else
			-- Mark the creature as 'condition removed'
			sprite:setLocalInt("gtDisplayStoneskinsLeft", 0)
			--
			sprite:applyEffect({
				["effectID"] = 0x141, -- Remove effects by resource (321)
				["res"] = "GTSTNSKN",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- op402 listener --

function GTSTNSKN(CGameEffect, CGameSprite)
	local m_lHitter = EEex_GameObject_Get(CGameSprite.m_lHitter.m_Instance) -- CGameSprite
	--
	local func
	local skins = {}
	--
	func = function(effect)
		if effect.m_effectId == 177 or effect.m_effectId == 283 then -- Use EFF file
			local CGameEffectBase = EEex_Resource_Demand(effect.m_res:get(), "eff")
			--
			if CGameEffectBase then
				func(CGameEffectBase)
			end
		elseif effect.m_effectId == 0xDA then -- Stoneskin effect (218)
			table.insert(skins, effect.m_effectAmount)
		end
	end
	-- sanity check
	if m_lHitter ~= nil then
		-- ignore non-weapon attacks
		if m_lHitter.m_targetId == CGameSprite.m_id then
			EEex_Utility_IterateCPtrList(CGameSprite.m_timedEffectList, func)
			EEex_Utility_IterateCPtrList(CGameSprite.m_equipedEffectList, func)
			--
			GT_Sprite_DisplayMessage(CGameSprite,
				string.format("%s : %d %s",
					Infinity_FetchString(483377), GT_Utility_FindGreatestInt(skins), Infinity_FetchString(483378)),
				0x808080 -- Grey
			)
		end
	end
end

--[[
+-------------------------------------------------------------------------------------------+
| cdtweaks, More Sensible Fireshield                                                        |
+-------------------------------------------------------------------------------------------+
| Fixes two things:                                                                         |
| 1. Fireshield-like spells will no longer bounce back and forth ad infinitum               |
| 2. Only true melee attacks will trigger these spells (no longer ranged attacks or poison) |
+-------------------------------------------------------------------------------------------+
--]]

-- equipped effects (run me as soon as the game launches) --

EEex_GameState_AddInitializedListener(function()
	local stats = GT_Resource_SymbolToIDS["stats"]
	--
	local func
	func = function(effect)
		if effect.m_effectId == 177 or effect.m_effectId == 283 then -- Use EFF file
			local CGameEffectBase = EEex_Resource_Demand(effect.m_res:get(), "eff")
			--
			if CGameEffectBase then -- sanity check
				func(CGameEffectBase)
			end
		elseif effect.m_effectId == 232 then -- Cast spell on condition
			if effect.m_effectAmount == 1 and effect.m_dWFlags == 0 then -- Target: LastHitter / Condition: HitBy([ANYONE])
				effect.m_effectId = 401 -- Set extended stat
				effect.m_effectAmount = 1
				effect.m_dWFlags = 1 -- mode: set
				effect.m_special = stats["GT_FAKE_CONTINGENCY"]
			end
		end
	end
	--
	local itmFileList = Infinity_GetFilesOfType("itm")
	-- for some unknown reason, we need two nested loops in order to get the resref...
	for _, temp in ipairs(itmFileList) do
		for _, resref in pairs(temp) do
			local pHeader = EEex_Resource_Demand(resref, "itm")
			--
			if pHeader then
				if pHeader.equipedEffectCount > 0 then
					local currentEffectAddress = EEex_UDToPtr(pHeader) + pHeader.effectsOffset + pHeader.equipedStartingEffect * Item_effect_st.sizeof
					--
					for i = 1, pHeader.equipedEffectCount do
						local pEffect = EEex_PtrToUD(currentEffectAddress, "Item_effect_st")
						--
						if pEffect.effectID == 232 then -- Cast spell on condition
							if pEffect.effectAmount == 1 and pEffect.dwFlags == 0 then -- Target: LastHitter / Condition: HitBy([ANYONE])
								pEffect.effectID = 401 -- Set extended stat
								pEffect.effectAmount = 1
								pEffect.dwFlags = 1 -- mode: set
								pEffect.special = stats["GT_FAKE_CONTINGENCY"]
							end
						elseif pEffect.effectID == 177 or pEffect.effectID == 283 then -- Use EFF file
							local CGameEffectBase = EEex_Resource_Demand(pEffect.res:get(), "eff")
							--
							if CGameEffectBase then
								func(CGameEffectBase)
							end
						end
						--
						currentEffectAddress = currentEffectAddress + Item_effect_st.sizeof
					end
				end
			end
		end
	end
end)

-- timed/limited effects --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	local stats = GT_Resource_SymbolToIDS["stats"]
	--
	local fireShield = {}
	--
	local func
	func = function(effect)
		if effect.m_effectId == 177 or effect.m_effectId == 283 then -- Use EFF file
			local CGameEffectBase = EEex_Resource_Demand(effect.m_res:get(), "eff")
			--
			if CGameEffectBase then -- sanity check
				return func(CGameEffectBase)
			end
		elseif effect.m_effectId == 232 then -- Cast spell on condition
			if effect.m_effectAmount == 1 and effect.m_dWFlags == 0 then -- Target: LastHitter / Condition: HitBy([ANYONE])
				return effect.m_res:get(), effect.m_res2:get(), effect.m_res3:get()
			end
		end
		--
		return nil, nil, nil
	end
	--
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		local m_res, m_res2, m_res3 = func(effect)
		--
		if m_res or m_res2 or m_res3 then
			table.insert(fireShield, {m_res, m_res2, m_res3, GT_Utility_GetEffectFields(effect)})
			-- Absolute timing mode, instantly marked for removal
			effect.m_durationType = 0x1000
			effect.m_duration = 0
		end
	end)
	--
	if next(fireShield) then
		-- force the engine to reevaluate the effect list after the change
		sprite.m_newEffect = true
		-- apply op401
		for _, v in ipairs(fireShield) do
			sprite:applyEffect({
				["effectID"] = 401, -- set extended stat
				["dwFlags"] = 1, -- mode: set
				["effectAmount"] = 1,
				["special"] = stats["GT_FAKE_CONTINGENCY"],
				--
				["res"] = v[1] or "",
				["m_res2"] = v[2] or "",
				["m_res3"] = v[3] or "",
				--
				["noSave"] = true,
				--
				["duration"] = v[4]["duration"],
				["durationType"] = v[4]["timing"],
				--
				["numDice"] = v[4]["numDice"],
				["diceSize"] = v[4]["diceSize"],
				--
				["spellLevel"] = v[4]["spellLevel"],
				["m_projectileType"] = v[4]["projectileType"],
				["m_school"] = v[4]["school"],
				["m_secondaryType"] = v[4]["secondaryType"],
				["m_sourceRes"] = v[4]["sourceRes"],
				--
				["m_sourceType"] = v[4]["sourceType"],
				["m_sourceFlags"] = v[4]["sourceFlags"],
				["m_scriptName"] = v[4]["scriptName"],
				["m_slotNum"] = v[4]["slotNum"],
				["m_casterLevel"] = v[4]["casterLevel"],
				["m_flags"] = v[4]["flags"],
				--
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- main --

EEex_Sprite_AddBlockWeaponHitListener(function(args)
	local stats = GT_Resource_SymbolToIDS["stats"]
	--
	local weapon = args.weapon -- CItem
	local weaponAbility = args.weaponAbility -- Item_ability_st
	local targetSprite = args.targetSprite -- CGameSprite
	local attackingSprite = args.attackingSprite -- CGameSprite
	-- check for Fireshield-like spells
	local effectList = {targetSprite.m_equipedEffectList, targetSprite.m_timedEffectList} -- CGameEffectList
	local fireShield = {}
	--
	local func
	func = function(effect)
		if effect.m_effectId == 177 or effect.m_effectId == 283 then -- Use EFF file
			local CGameEffectBase = EEex_Resource_Demand(effect.m_res:get(), "eff")
			--
			if CGameEffectBase then -- sanity check
				return func(CGameEffectBase)
			end
		elseif effect.m_effectId == 401 and effect.m_dWFlags == 1 and effect.m_effectAmount == 1 and effect.m_special == stats["GT_FAKE_CONTINGENCY"] then
			return effect.m_res:get(), effect.m_res2:get(), effect.m_res3:get()
		end
		--
		return nil, nil, nil
	end
	--
	for _, list in ipairs(effectList) do
		EEex_Utility_IterateCPtrList(list, function(effect)
			local m_res, m_res2, m_res3 = func(effect)
			--
			if m_res or m_res2 or m_res3 then
				table.insert(fireShield, {m_res, m_res2, m_res3})
			end
		end)
	end
	--
	if weaponAbility.type == 1 and weaponAbility.range <= 2 then -- melee weapons only
		-- apply retaliation damage
		for _, v in ipairs(fireShield) do
			for _, res in ipairs(v) do
				if res ~= "" then
					attackingSprite:applyEffect({
						["effectID"] = 146, -- Cast spl
						["dwFlags"] = 1, -- mode: cast instantly / ignore level
						["res"] = res,
						["sourceID"] = targetSprite.m_id,
						["sourceTarget"] = attackingSprite.m_id,
					})
				end
			end
		end
	end
end)

--[[
+---------------------------------------------------------------------------------------------------------------------------------------------------------+
| cdtweaks, Blade Barrier vs. Time Stop                                                                                                                   |
+---------------------------------------------------------------------------------------------------------------------------------------------------------+
| As currently implemented, Blade Barrier and similar spells interact very oddly with time stop effects.                                                  |
| Freeze two characters in melee range, one with a Blade Barrier (or Globe of Blades, or Circle of Bones, or any mod spell that uses the same mechanics), |
| and the spell triggers several times to no immediate effect...                                                                                          |
| until stopped time wears off. Then all of those suspended triggers hit at once, for a potential massive burst of damage.                                |
+---------------------------------------------------------------------------------------------------------------------------------------------------------+
--]]

-- equipped effects (run me as soon as the game launches) --

EEex_GameState_AddInitializedListener(function()
	local stats = GT_Resource_SymbolToIDS["stats"]
	--
	local func
	func = function(effect)
		if effect.m_effectId == 177 or effect.m_effectId == 283 then -- Use EFF file
			local CGameEffectBase = EEex_Resource_Demand(effect.m_res:get(), "eff")
			--
			if CGameEffectBase then -- sanity check
				func(CGameEffectBase)
			end
		elseif effect.m_effectId == 232 then -- Cast spell on condition
			if effect.m_effectAmount == 0 and effect.m_dWFlags == 8 then -- Target: Myself / Condition: PersonalSpaceDistance([ANYONE],4)
				effect.m_effectId = 401 -- Set extended stat
				effect.m_effectAmount = 2
				effect.m_dWFlags = 1 -- mode: set
				effect.m_special = stats["GT_FAKE_CONTINGENCY"]
			end
		end
	end
	--
	local itmFileList = Infinity_GetFilesOfType("itm")
	-- for some unknown reason, we need two nested loops in order to get the resref...
	for _, temp in ipairs(itmFileList) do
		for _, resref in pairs(temp) do
			local pHeader = EEex_Resource_Demand(resref, "itm")
			--
			if pHeader then
				if pHeader.equipedEffectCount > 0 then
					local currentEffectAddress = EEex_UDToPtr(pHeader) + pHeader.effectsOffset + pHeader.equipedStartingEffect * Item_effect_st.sizeof
					--
					for i = 1, pHeader.equipedEffectCount do
						local pEffect = EEex_PtrToUD(currentEffectAddress, "Item_effect_st")
						--
						if pEffect.effectID == 232 then -- Cast spell on condition
							if pEffect.effectAmount == 0 and pEffect.dwFlags == 8 then -- Target: Myself / Condition: PersonalSpaceDistance([ANYONE],4)
								pEffect.effectID = 401 -- Set extended stat
								pEffect.effectAmount = 2
								pEffect.dwFlags = 1 -- mode: set
								pEffect.special = stats["GT_FAKE_CONTINGENCY"]
							end
						elseif pEffect.effectID == 177 or pEffect.effectID == 283 then -- Use EFF file
							local CGameEffectBase = EEex_Resource_Demand(pEffect.res:get(), "eff")
							--
							if CGameEffectBase then
								func(CGameEffectBase)
							end
						end
						--
						currentEffectAddress = currentEffectAddress + Item_effect_st.sizeof
					end
				end
			end
		end
	end
end)

-- timed/limited effects --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	local stats = GT_Resource_SymbolToIDS["stats"]
	--
	local bladeBarrier = {}
	--
	local func
	func = function(effect)
		if effect.m_effectId == 177 or effect.m_effectId == 283 then -- Use EFF file
			local CGameEffectBase = EEex_Resource_Demand(effect.m_res:get(), "eff")
			--
			if CGameEffectBase then -- sanity check
				return func(CGameEffectBase)
			end
		elseif effect.m_effectId == 232 then -- Cast spell on condition
			if effect.m_effectAmount == 0 and effect.m_dWFlags == 8 then -- Target: Myself / Condition: PersonalSpaceDistance([ANYONE],4)
				return effect.m_res:get(), effect.m_res2:get(), effect.m_res3:get()
			end
		end
		--
		return nil, nil, nil
	end
	--
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		local m_res, m_res2, m_res3 = func(effect)
		--
		if m_res or m_res2 or m_res3 then
			table.insert(bladeBarrier, {m_res, m_res2, m_res3, GT_Utility_GetEffectFields(effect)})
			-- Absolute timing mode, instantly marked for removal
			effect.m_durationType = 0x1000
			effect.m_duration = 0
		end
	end)
	--
	if next(bladeBarrier) then
		-- force the engine to reevaluate the effect list after the change
		sprite.m_newEffect = true
		-- apply op401
		for _, v in ipairs(bladeBarrier) do
			sprite:applyEffect({
				["effectID"] = 401, -- set extended stat
				["dwFlags"] = 1, -- mode: set
				["effectAmount"] = 2,
				["special"] = stats["GT_FAKE_CONTINGENCY"],
				--
				["res"] = v[1] or "",
				["m_res2"] = v[2] or "",
				["m_res3"] = v[3] or "",
				--
				["noSave"] = true,
				--
				["duration"] = v[4]["duration"],
				["durationType"] = v[4]["timing"],
				--
				["numDice"] = v[4]["numDice"],
				["diceSize"] = v[4]["diceSize"],
				--
				["spellLevel"] = v[4]["spellLevel"],
				["m_projectileType"] = v[4]["projectileType"],
				["m_school"] = v[4]["school"],
				["m_secondaryType"] = v[4]["secondaryType"],
				["m_sourceRes"] = v[4]["sourceRes"],
				--
				["m_sourceType"] = v[4]["sourceType"],
				["m_sourceFlags"] = v[4]["sourceFlags"],
				["m_scriptName"] = v[4]["scriptName"],
				["m_slotNum"] = v[4]["slotNum"],
				["m_casterLevel"] = v[4]["casterLevel"],
				["m_flags"] = v[4]["flags"],
				--
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

-- main --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	local stats = GT_Resource_SymbolToIDS["stats"]
	--
	local m_nTimeStopCaster = EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_nTimeStopCaster
	--local isImmuneToTimeStop = m_nTimeStopCaster == sprite.m_id or sprite.m_derivedStats.m_bImmuneToTimeStop > 0 -- N.B.: the caster is always immune to its own time stop
	-- check for Blade Barrier &c.
	local effectList = {sprite.m_equipedEffectList, sprite.m_timedEffectList} -- CGameEffectList
	local bladeBarrier = {}
	--
	local timerRunning = false
	--
	local func
	func = function(effect)
		if effect.m_effectId == 177 or effect.m_effectId == 283 then -- Use EFF file
			local CGameEffectBase = EEex_Resource_Demand(effect.m_res:get(), "eff")
			--
			if CGameEffectBase then -- sanity check
				return func(CGameEffectBase)
			end
		elseif effect.m_effectId == 401 and effect.m_dWFlags == 1 and effect.m_effectAmount == 2 and effect.m_special == stats["GT_FAKE_CONTINGENCY"] then
			return effect.m_res:get(), effect.m_res2:get(), effect.m_res3:get()
		end
		--
		return nil, nil, nil
	end
	--
	for _, list in ipairs(effectList) do
		EEex_Utility_IterateCPtrList(list, function(effect)
			local m_res, m_res2, m_res3 = func(effect)
			--
			if m_res or m_res2 or m_res3 then
				table.insert(bladeBarrier, {m_res, m_res2, m_res3})
			elseif effect.m_effectId == 401 and effect.m_special == stats["GT_DUMMY_STAT"] and effect.m_scriptName:get() == "gtBladeBarrierTimer" then -- dummy opcode that acts as a marker/timer
				timerRunning = true
			end
		end)
	end
	--
	if next(bladeBarrier) then
		if not timerRunning then
			if m_nTimeStopCaster == -1 then
				-- cast subspell(s)
				for _, v in ipairs(bladeBarrier) do
					for _, res in ipairs(v) do
						if res ~= "" then
							sprite:applyEffect({
								["effectID"] = 146, -- Cast spl
								["dwFlags"] = 1, -- mode: cast instantly / ignore level
								["res"] = res,
								["sourceID"] = sprite.m_id,
								["sourceTarget"] = sprite.m_id,
							})
						end
					end
				end
				-- set timer
				sprite:applyEffect({
					["effectID"] = 401, -- Set extended stat
					["special"] = stats["GT_DUMMY_STAT"],
					["m_scriptName"] = "gtBladeBarrierTimer",
					["duration"] = 100,
					["durationType"] = 10, -- instant/limited (ticks)
					["sourceID"] = sprite.m_id,
					["sourceTarget"] = sprite.m_id,
				})
			end
		end
	end
end)

--[[
+-------------------------------------------------------+
| cdtweaks: automatically change FPS during playthrough |
+-------------------------------------------------------+
--]]

-- When in cutscene, lock FPS to 30 --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	if sprite.m_inCutScene == 1 then
		if EEex_CChitin.TIMER_UPDATES_PER_SECOND ~= 30 then
			EEex_CChitin.TIMER_UPDATES_PER_SECOND = 30
		end
	end
end)

-- When in combat, lock FPS to 30. Otherwise, set to 60 --

function GT_LuaAction_DynamicFPSChange()
	-- [Bubb] Each area has its own combat counter. You can check the global script runner's area in this way...
	local globalScriptRunnerId = EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_nAIIndex
	local globalScriptRunner = EEex_GameObject_Get(globalScriptRunnerId) -- CGameSprite
	local globalScriptRunnerArea = globalScriptRunner.m_pArea -- CGameArea
	--local globalScriptRunnerAreaResref = globalScriptRunnerArea and globalScriptRunnerArea.m_resref:get() or "nil"
	--Infinity_DisplayString(string.format("Global script runner area resref: \"%s\"", globalScriptRunnerAreaResref))
	--
	if globalScriptRunnerArea then
		if globalScriptRunnerArea.m_nBattleSongCounter > 0 then
			if EEex_CChitin.TIMER_UPDATES_PER_SECOND ~= 30 then
				EEex_CChitin.TIMER_UPDATES_PER_SECOND = 30
			end
		else
			if EEex_CChitin.TIMER_UPDATES_PER_SECOND ~= 60 then
				EEex_CChitin.TIMER_UPDATES_PER_SECOND = 60
			end
		end
	end
end

--[[
+--------------------------------------+
| cdtweaks, more sensible Morentherene |
+--------------------------------------+
--]]

-- [SoD] make sure op146*p2=1 and &c. do not set global var "BD_GREEN_DRAGON_AWAKE" --

GTMORENT = {

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
		local areaSources = {
			["BD7210"] = true, -- Wyrm Cave
		}
		--
		if not actionSources[context.decodeSource] then
			return
		end
		--
		local originatingSprite = context["originatingSprite"] -- CGameSprite
		--
		if EEex_GameState_GetGlobalInt("BD_GREEN_DRAGON_AWAKE") == 0 and areaSources[originatingSprite.m_pArea.m_resref:get()] then -- if wizard/priest/innate spell and in Wyrm Cave ...
			EEex_GameState_SetGlobalInt("BD_GREEN_DRAGON_AWAKE", 1)
		end
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

--

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- internal function that applies the actual condition
	local apply = function()
		-- Mark the creature as 'condition applied'
		sprite:setLocalInt("gtMoreSensibleMorentherene", 1)
		--
		local effectCodes = {
			{["op"] = 321}, -- Remove effects by resource
			{["op"] = 408}, -- Projectile mutator
		}
		--
		for _, attributes in ipairs(effectCodes) do
			sprite:applyEffect({
				["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
				["durationType"] = 9,
				["res"] = "GTMORENT",
				["m_sourceRes"] = "GTMORENT",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
	-- Check creature's EA
	local applyCondition = sprite.m_typeAI.m_EnemyAlly < 30 -- GOODCUTOFF
	--
	if sprite:getLocalInt("gtMoreSensibleMorentherene") == 0 then
		if applyCondition then
			apply()
		end
	else
		if applyCondition then
			-- do nothing
		else
			-- Mark the creature as 'condition removed'
			sprite:setLocalInt("gtMoreSensibleMorentherene", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTMORENT",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)


