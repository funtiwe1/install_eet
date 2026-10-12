-- ***Beastmaster Animal Companion*** --

--[[
+-----------------------------------------------------------------------------------------+
| Leopard: set the RANGER action bar (so as to have access to the Hide in Shadows button) |
+-----------------------------------------------------------------------------------------+
--]]

EEex_Actionbar_AddListener(function(config, state)

	local sprite = EEex_Sprite_GetSelected() -- will always return the sprite that the actionbar currently reflects
	if not sprite then
		return
	end

	if sprite.m_scriptName:get() == "gtNWNAnmlCompLeopard" then
		if state == 112 then -- Controlled (Class doesn't have a dedicated state)
			EEex_Actionbar_SetState(12) -- Ranger
		end
	end
end)

--[[
+----------------------------------------------------------------------------------------------------------------------------------------------------+
| Check if the Animal Companion has already been summoned; restore var "gtAnimalCompanion" on the summoner when the animal gets slained / unsummoned |
+----------------------------------------------------------------------------------------------------------------------------------------------------+
--]]

function GTCL300(CGameEffect, CGameSprite)
	if CGameEffect.m_effectAmount == 0 then
		if EEex_Sprite_GetLocalInt(CGameSprite, "gtNWNAnmlCompSummoned") == 1 then
			EEex_GameObject_ApplyEffect(CGameSprite,
			{
				["effectID"] = 206, -- Protection from spell
				["effectAmount"] = 487884, -- Animal Companion already summoned
				["res"] = CGameEffect.m_sourceRes:get(),
				["m_sourceRes"] = CGameEffect.m_sourceRes:get(),
				["m_sourceType"] = CGameEffect.m_sourceType,
				["sourceID"] = CGameEffect.m_sourceId,
				["sourceTarget"] = CGameEffect.m_sourceTarget,
			})
		end
	elseif CGameEffect.m_effectAmount == 1 then
		local summonerID = CGameSprite.m_lSummonedBy.m_Instance
		local summonerSprite = EEex_GameObject_Get(summonerID)
		--
		EEex_Sprite_SetLocalInt(summonerSprite, "gtNWNAnmlCompSummoned", 0)
	end
end


--[[
+----------------------------------+
| Check if the animal can level up |
+----------------------------------+
--]]

function GT_NWN_AnmlComp_CanLevelUp()
	local summonerID = EEex_LuaTrigger_Object.m_lSummonedBy.m_Instance
	local summonerSprite = EEex_GameObject_Get(summonerID)
	--
	local summonerActiveStats = EEex_Sprite_GetActiveStats(summonerSprite)
	local summonerClass = summonerSprite.m_typeAI.m_Class
	local class = GT_Resource_SymbolToIDS["class"]
	--
	if summonerActiveStats.m_nLevelDrain == 0 then
		if summonerClass == class["CLERIC_RANGER"] then
			if summonerSprite.m_baseStats.m_level2 > EEex_LuaTrigger_Object.m_baseStats.m_level1 then
				return true
			else
				return false
			end
		else
			if summonerSprite.m_baseStats.m_level1 > EEex_LuaTrigger_Object.m_baseStats.m_level1 then
				return true
			else
				return false
			end
		end
	else
		return false
	end
end

--[[
+----------------------------------------------------------------------+
| Fix "MakeGlobal()" messing up with GENERAL upon saving and reloading |
+----------------------------------------------------------------------+
--]]

function GT_NWN_AnmlComp_FixGeneral()
	if EEex_LuaAction_Object.m_scriptName:get() == "gtAnmlCompSpider" then
		EEex_LuaAction_Object:applyEffect({
			["effectID"] = 72, -- change AI type
			["durationType"] = 1,
			["dwFlags"] = 1, -- GENERAL
			["effectAmount"] = 255, -- MONSTER
			["noSave"] = true,
			["sourceID"] = EEex_LuaAction_Object.m_id,
			["sourceTarget"] = EEex_LuaAction_Object.m_id,
		})
	else
		EEex_LuaAction_Object:applyEffect({
			["effectID"] = 72, -- change AI type
			["durationType"] = 1,
			["dwFlags"] = 1, -- GENERAL
			["effectAmount"] = 2, -- ANIMAL
			["noSave"] = true,
			["sourceID"] = EEex_LuaAction_Object.m_id,
			["sourceTarget"] = EEex_LuaAction_Object.m_id,
		})
	end
end


--[[
+------------------------------------------------------------+
| Make sure innate abilities cannot be interrupted by damage |
+------------------------------------------------------------+
--]]

EEex_Sprite_AddQuickListsCheckedListener(function(sprite, resref, changeAmount)

	local m_curAction = sprite.m_curAction -- CAIAction
	local m_scriptName = sprite.m_scriptName:get()

	local actionSources = {
		[31] = true, -- Spell()
		[95] = true, -- SpellPoint()
		[476] = true, -- EEex_SpellObjectOffset()
	}

	local deathvarSources = {
		["gtNWNAnmlCompWolf"] = true,
		["gtNWNAnmlCompFalcon"] = true,
		["gtNWNAnmlCompBear"] = true,
		["gtNWNAnmlCompBoar"] = true,
		["gtNWNAnmlCompLeopard"] = true,
		["gtNWNAnmlCompSnake"] = true,
		["gtNWNAnmlCompBeetle"] = true,
		["gtNWNAnmlCompSpider"] = true,
	}

	local resrefSources = {
		["GTIN500"] = true,
		["GTIN100"] = true,
		["GTIN101"] = true,
		["GTIN201"] = true,
		["GTIN321"] = true,
	}

	if not (deathvarSources[m_scriptName] and actionSources[m_curAction.m_actionID] and resrefSources[resref] and changeAmount < 0) then
		return
	end

	-- morph current action
	if m_curAction.m_actionID == 31 then -- Spell()
		m_curAction.m_actionID = 113 -- ForceSpell()
	else
		m_curAction.m_actionID = 114 -- ForceSpellPoint()
	end

	-- restore memorization bit (make it castable at will)
	if resref == "GTIN100" then

		local spellLevelMemListArray = sprite.m_memorizedSpellsInnate
		local memList = spellLevelMemListArray:getReference(0) -- *count starts from 0*

		EEex_Utility_IterateCPtrList(memList, function(memInstance)
			local memInstanceResref = memInstance.m_spellId:get()
			if memInstanceResref == resref then
				local memFlags = memInstance.m_flags
				if EEex_IsBitUnset(memFlags, 0x0) then
					memInstance.m_flags = EEex_SetBit(memFlags, 0x0)
					return true
				end
			end
		end)
	end

end)

--[[
+-----------------------+
| Level up the creature |
+-----------------------+
--]]

function GT_NWN_AnmlComp_LevelUp()
	local summonerID = EEex_LuaAction_Object.m_lSummonedBy.m_Instance
	local summonerSprite = EEex_GameObject_Get(summonerID)
	--
	local summonerClass = summonerSprite.m_typeAI.m_Class
	local class = GT_Resource_SymbolToIDS["class"]
	--
	local summonerBaseLevel = -1
	local creatureBaseLevel = EEex_LuaAction_Object.m_baseStats.m_level1
	--
	if summonerClass == class["CLERIC_RANGER"] then
		summonerBaseLevel = summonerSprite.m_baseStats.m_level2
	else
		summonerBaseLevel = summonerSprite.m_baseStats.m_level1
	end
	-- Update creature's racial enemy
	--EEex_LuaAction_Object.m_baseStats.m_hatedRace = summonerSprite.m_baseStats.m_hatedRace
	-- Update creature's level
	EEex_LuaAction_Object:applyEffect({
		["effectID"] = 96, -- level change
		["durationType"] = 1,
		["dwFlags"] = 1, -- set
		["effectAmount"] = summonerBaseLevel,
		["noSave"] = true,
		["sourceID"] = EEex_LuaAction_Object.m_id,
		["sourceTarget"] = EEex_LuaAction_Object.m_id,
	})
	-- Update creature's saves
	local savewar = GT_Resource_2DA["savewar"]
	local effectCodes = {
		{["op"] = 33, ["p1"] = tonumber(savewar["DEATH"][string.format("%s", summonerBaseLevel)])}, -- save vs. death
		{["op"] = 34, ["p1"] = tonumber(savewar["WANDS"][string.format("%s", summonerBaseLevel)])}, -- save vs. wands
		{["op"] = 35, ["p1"] = tonumber(savewar["POLY"][string.format("%s", summonerBaseLevel)])}, -- save vs. polymorph
		{["op"] = 36, ["p1"] = tonumber(savewar["BREATH"][string.format("%s", summonerBaseLevel)])}, -- save vs. breath
		{["op"] = 37, ["p1"] = tonumber(savewar["SPELL"][string.format("%s", summonerBaseLevel)])}, -- save vs. spell
	}
	--
	for _, attributes in ipairs(effectCodes) do
		EEex_LuaAction_Object:applyEffect({
			["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
			["durationType"] = 1,
			["dwFlags"] = 1, -- set
			["effectAmount"] = attributes["p1"] or 0,
			["noSave"] = true,
			["sourceID"] = EEex_LuaAction_Object.m_id,
			["sourceTarget"] = EEex_LuaAction_Object.m_id,
		})
	end
	-- Update HP
	do
		local hpclass = GT_Resource_2DA["hpclass"]
		local hptbl = hpclass["BEAST_MASTER"]["TABLE"]
		--
		local data = EEex_Resource_Load2DA(hptbl)
		local nX, nY = data:getDimensions()
		nX = nX - 2
		nY = nY - 1
		--
		local m_maxHitPointsBase = 0
		for rowIndex = 0, nY do
			if tonumber(data:getRowLabel(rowIndex)) <= summonerBaseLevel then
				local sides = tonumber(data:getAtPoint(0, rowIndex))
				local rolls = tonumber(data:getAtPoint(1, rowIndex))
				local modifier = tonumber(data:getAtPoint(2, rowIndex))
				--
				m_maxHitPointsBase = m_maxHitPointsBase + (sides * rolls) + modifier
			end
		end
		--
		if creatureBaseLevel == 0 then
			EEex_LuaAction_Object:applyEffect({
				["effectID"] = 18, -- max HP bonus
				["durationType"] = 1,
				["dwFlags"] = 1, -- set, update current HP
				["effectAmount"] = m_maxHitPointsBase,
				["noSave"] = true,
				["sourceID"] = EEex_LuaAction_Object.m_id,
				["sourceTarget"] = EEex_LuaAction_Object.m_id,
			})
		else
			EEex_LuaAction_Object:applyEffect({
				["effectID"] = 18, -- max HP bonus
				["durationType"] = 1,
				["dwFlags"] = 4, -- set, don't update current HP
				["effectAmount"] = m_maxHitPointsBase,
				["noSave"] = true,
				["sourceID"] = EEex_LuaAction_Object.m_id,
				["sourceTarget"] = EEex_LuaAction_Object.m_id,
			})
		end
		--
		data:free()
	end
	-- Update THAC0
	local thac0 = GT_Resource_2DA["thac0"]
	EEex_LuaAction_Object:applyEffect({
		["effectID"] = 54, -- base THAC0 bonus
		["durationType"] = 1,
		["dwFlags"] = 1, -- set
		["effectAmount"] = tonumber(thac0["RANGER"][string.format("%s", summonerBaseLevel)]),
		["noSave"] = true,
		["sourceID"] = EEex_LuaAction_Object.m_id,
		["sourceTarget"] = EEex_LuaAction_Object.m_id,
	})
	-- Upgrade creature weapon
	local items = EEex_LuaAction_Object.m_equipment.m_items -- Array<CItem*,39>
	local weaponUpgrades = {
		["gtNWNAnmlCompBear"] = {"01B", "01C", "01D", "01E"},
		["gtNWNAnmlCompBeetle"] = {"02B", "02C", "02D", "02E"},
		["gtNWNAnmlCompBoar"] = {"03B", "03C", "03D", "03E"},
		["gtNWNAnmlCompFalcon"] = {"04B", "04C", "04D", "04E"},
		["gtNWNAnmlCompLeopard"] = {"05B", "05C", "05D", "05E"},
		["gtNWNAnmlCompSnake"] = {"06B", "06C", "06D", "06E"},
		["gtNWNAnmlCompSpider"] = {"07B", "07C", "07D", "07E"},
		["gtNWNAnmlCompWolf"] = {"08B", "08C", "08D", "08E"},
	}
	for i = 35, 38 do -- WEAPON[1-4]
		local item = items:get(i) -- CItem
		if item then
			local newItemResRef = item.pRes.resref:get()
			--
			if (summonerBaseLevel >= 5 and summonerBaseLevel <= 9) then
				newItemResRef = "GTPET" .. weaponUpgrades[EEex_LuaAction_Object.m_scriptName:get()][1]
			elseif (summonerBaseLevel >= 10 and summonerBaseLevel <= 14) then
				newItemResRef = "GTPET" .. weaponUpgrades[EEex_LuaAction_Object.m_scriptName:get()][2]
			elseif (summonerBaseLevel >= 15 and summonerBaseLevel <= 19) then
				newItemResRef = "GTPET" .. weaponUpgrades[EEex_LuaAction_Object.m_scriptName:get()][3]
			elseif (summonerBaseLevel >= 20) then
				newItemResRef = "GTPET" .. weaponUpgrades[EEex_LuaAction_Object.m_scriptName:get()][4]
			end
			--
			EEex_LuaAction_Object:applyEffect({
				["effectID"] = 143, -- Create item in slot
				["durationType"] = 1,
				["effectAmount"] = i, -- slot
				["res"] = newItemResRef,
				["noSave"] = true,
				["sourceID"] = EEex_LuaAction_Object.m_id,
				["sourceTarget"] = EEex_LuaAction_Object.m_id,
			})
			--
			local str = string.format('XEquipItem("%s",Myself,%d,EQUIP)', newItemResRef, i)
			GT_ExecuteResponse["parseResponseString"](EEex_LuaAction_Object, nil, str) -- "XEquipItem()" is actually instant (even if not listed in "INSTANT.IDS")... It never returns ``CGameAIBase::ACTION_NORMAL`` or ``CGameAIBase::ACTION_INTERRUPTABLE``... Feel free to use it with ``EEex_Action_ExecuteScriptFileResponseAsAIBaseInstantly()``...
		end
	end
	-- Update AC
	for i = creatureBaseLevel + 1, summonerBaseLevel do
		if i % 5 == 0 then
			EEex_LuaAction_Object:applyEffect({
				["effectID"] = 0, -- AC bonus
				["durationType"] = 1,
				["dwFlags"] = 0x0, -- increment
				["effectAmount"] = 1,
				["noSave"] = true,
				["sourceID"] = EEex_LuaAction_Object.m_id,
				["sourceTarget"] = EEex_LuaAction_Object.m_id,
			})
		end
	end
	-- Update creature's DEX / HiS / MS
	if EEex_LuaAction_Object.m_scriptName:get() == "gtNWNAnmlCompLeopard" then
		for i = creatureBaseLevel + 1, summonerBaseLevel do
			if i % 10 == 0 then
				EEex_LuaAction_Object:applyEffect({
					["effectID"] = 15, -- DEX bonus
					["durationType"] = 1,
					["dwFlags"] = 0x0, -- increment
					["effectAmount"] = 1,
					["noSave"] = true,
					["sourceID"] = EEex_LuaAction_Object.m_id,
					["sourceTarget"] = EEex_LuaAction_Object.m_id,
				})
			end
			--
			EEex_LuaAction_Object:applyEffect({
				["effectID"] = 275, -- HiS bonus
				["durationType"] = 1,
				["dwFlags"] = 0x0, -- increment
				["effectAmount"] = 5,
				["noSave"] = true,
				["sourceID"] = EEex_LuaAction_Object.m_id,
				["sourceTarget"] = EEex_LuaAction_Object.m_id,
			})
			EEex_LuaAction_Object:applyEffect({
				["effectID"] = 59, -- MS bonus
				["durationType"] = 1,
				["dwFlags"] = 0x0, -- increment
				["effectAmount"] = 5,
				["noSave"] = true,
				["sourceID"] = EEex_LuaAction_Object.m_id,
				["sourceTarget"] = EEex_LuaAction_Object.m_id,
			})
		end
	end
	-- Special abilities
	local specialAbilities = {
		["gtNWNAnmlCompBeetle"] = nil,
		["gtNWNAnmlCompBear"] = nil,
		["gtNWNAnmlCompFalcon"] = nil,
		["gtNWNAnmlCompSnake"] = "GTIN101",
		["gtNWNAnmlCompLeopard"] = nil,
		["gtNWNAnmlCompSpider"] = "GTIN201",
		["gtNWNAnmlCompWolf"] = "GTIN500",
		["gtNWNAnmlCompBoar"] = "GTIN321",
	}
	if specialAbilities[EEex_LuaAction_Object.m_scriptName:get()] then
		for i = creatureBaseLevel + 1, summonerBaseLevel do
			if i % 5 == 0 then
				EEex_LuaAction_Object:applyEffect({
					["effectID"] = 171, -- gain special ability
					["res"] = specialAbilities[EEex_LuaAction_Object.m_scriptName:get()],
					["noSave"] = true,
					["sourceID"] = EEex_LuaAction_Object.m_id,
					["sourceTarget"] = EEex_LuaAction_Object.m_id,
				})
			end
		end
	end
end

--[[
+--------------------------------------------------------------------------+
| Check if the summoner is a complete dual-class character / fallen ranger |
+--------------------------------------------------------------------------+
--]]

function GT_NWN_AnmlComp_SummonerClassCheck()
	local summonerID = EEex_LuaTrigger_Object.m_lSummonedBy.m_Instance
	local summonerSprite = EEex_GameObject_Get(summonerID)
	--
	local summonerFlags = summonerSprite.m_baseStats.m_flags
	local summonerClass = summonerSprite.m_typeAI.m_Class
	local summonerLevel1 = summonerSprite:getActiveStats().m_nLevel1
	local summonerLevel2 = summonerSprite:getActiveStats().m_nLevel2
	--
	local class = GT_Resource_SymbolToIDS["class"]
	--
	local toReturn
	--
	if EEex_IsBitUnset(summonerFlags, 10) then -- not fallen ranger
		if summonerClass == class["CLERIC_RANGER"] then
			if EEex_IsBitSet(summonerFlags, 0x8) then -- original class is ranger
				if summonerLevel1 > summonerLevel2 then
					toReturn = true
				else
					toReturn = false
				end
			else
				toReturn = true -- multiclass
			end
		else
			toReturn = true -- single class
		end
	else
		toReturn = false -- fallen ranger
	end
	--
	return not toReturn
end

--[[
+-----------------------------------------------------------------------------------+
| Make sure both the animal and its summoner are in the same area (not working...?) |
+-----------------------------------------------------------------------------------+
--]]
--[[
EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- sanity check
	if not EEex_GameObject_IsSprite(sprite) or not sprite.m_pArea then
		return
	end
	--
	local summoner = EEex_GameObject_Get(sprite.m_lSummonedBy.m_Instance) -- CGameSprite
	--
	local deathvarSources = {
		["gtAnmlCompWolf"] = true,
		["gtAnmlCompFalcon"] = true,
		["gtAnmlCompBear"] = true,
		["gtAnmlCompBoar"] = true,
		["gtAnmlCompLeopard"] = true,
		["gtAnmlCompSnake"] = true,
		["gtAnmlCompBeetle"] = true,
		["gtAnmlCompSpider"] = true,
	}
	--
	local m_scriptName = sprite.m_scriptName:get()
	--
	if deathvarSources[m_scriptName] and summoner then
		if not EEex_UDEqual(sprite.m_pArea, summoner.m_pArea) then
			sprite:applyEffect({
				["effectID"] = 186, -- move to area
				["sourceX"] = summoner.m_pos.x,
				["sourceY"] = summoner.m_pos.y,
				["targetX"] = summoner.m_pos.x,
				["targetY"] = summoner.m_pos.y,
				["res"] = summoner.m_pArea.m_resref:get(), -- ARE file
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
				["noSave"] = true,
			})
		end
	end
end)
--]]

