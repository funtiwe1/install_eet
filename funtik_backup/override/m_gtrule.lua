-- ***Rule Changes*** --

--[[
+-------------------------------------------------------+
| cdtweaks, revised backstab immunity (component #2620) |
+-------------------------------------------------------+
--]]

-- Apply ability --

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	--
	local general = {
		["UNDEAD"] = true,
		["WEAPON"] = true,
		["PLANT"] = true,
	}
	local race = {
		["MIST"] = true,
		["SLIME"] = true,
		["BEHOLDER"] = true,
		["DEMONIC"] = true,
		["MEPHIT"] = true,
		["IMP"] = true,
		["ELEMENTAL"] = true,
		["SALAMANDER"] = true,
		["GENIE"] = true,
		["PLANATAR"] = true,
		["DARKPLANATAR"] = true,
		["SOLAR"] = true,
		["ANTISOLAR"] = true,
		["DRAGON"] = true,
		["SHAMBLING_MOUND"] = true,
	}
	local class = {
		["GOLEM_IRON"] = true,
		["GOLEM_STONE"] = true,
		["GOLEM_CLAY"] = true,
		["GOLEM_ICE"] = true,
	}
	-- internal function that applies the actual feat
	local apply = function()
		-- Mark the creature as 'feat applied'
		sprite:setLocalInt("gtBackstabImmunity", 1)
		--
		sprite:applyEffect({
			["effectID"] = 321, -- Remove effects by resource
			["res"] = "GTRULE03",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
		sprite:applyEffect({
			["effectID"] = 292, -- Immunity to backstab
			["dwFlags"] = 1,
			["durationType"] = 9,
			["m_sourceRes"] = "GTRULE03",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
	-- Check creature's general / race / class
	local spriteGeneralStr = GT_Resource_IDSToSymbol["general"][sprite.m_typeAI.m_General]
	local spriteRaceStr = GT_Resource_IDSToSymbol["race"][sprite.m_typeAI.m_Race]
	local spriteClassStr = GT_Resource_IDSToSymbol["class"][sprite.m_typeAI.m_Class]
	--
	local applyAbility = general[spriteGeneralStr] or race[spriteRaceStr] or class[spriteClassStr]
	--
	if sprite:getLocalInt("gtBackstabImmunity") == 0 then
		if applyAbility then
			apply()
		end
	else
		if applyAbility then
			-- do nothing
		else
			-- Mark the creature as 'bonus removed'
			sprite:setLocalInt("gtBackstabImmunity", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTRULE03",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
end)

--[[
+------------------------------------------------------------------------------------+
| cdtweaks, make infravision useful (-4 to hit in darkness (Dungeon or night areas)) |
+------------------------------------------------------------------------------------+
--]]

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) or not sprite.m_pArea then
		return
	end
	-- internal function that applies the actual penalty
	local apply = function()
		-- Mark the creature as 'condition applied'
		sprite:setLocalInt("gtMakeInfravisionUseful", 1)
		--
		local effectCodes = {
			{["op"] = 321, ["res"] = "GTRULE02"}, -- Remove effects by resource
			{["op"] = 54, ["p1"] = -4}, -- Base thac0 bonus
			{["op"] = 142, ["p2"] = 250}, -- Display portrait icon
		}
		--
		for _, attributes in ipairs(effectCodes) do
			sprite:applyEffect({
				["effectID"] = attributes["op"] or EEex_Error("opcode number not specified"),
				["effectAmount"] = attributes["p1"] or 0,
				["dwFlags"] = attributes["p2"] or 0,
				["durationType"] = 9,
				["res"] = attributes["res"] or "",
				["m_sourceRes"] = "GTRULE02",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
	--
	local playableRaces = {
		["HUMAN"] = true,
		["ELF"] = true,
		["HALF_ELF"] = true,
		["DWARF"] = true,
		["GNOME"] = true,
		["HALFLING"] = true,
		["HALFORC"] = true,
	}
	-- Check creature's race / state
	local spriteRaceStr = GT_Resource_IDSToSymbol["race"][sprite.m_typeAI.m_Race]
	local racefeat = GT_Resource_2DA["racefeat"]
	local hasInnateInfravision = racefeat[spriteRaceStr] and tonumber(racefeat[spriteRaceStr]["VALUE"]) == 1 or false
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local spriteGeneralState = sprite.m_derivedStats.m_generalState
	--
	local isDungeon = EEex_IsBitSet(sprite.m_pArea.m_header.m_areaType, 0x5)
	local isOutdoor = EEex_IsBitSet(sprite.m_pArea.m_header.m_areaType, 0x0)
	local isDayNight = EEex_IsBitSet(sprite.m_pArea.m_header.m_areaType, 0x1)
	--local isNight = EEex_Trigger_ParseConditionalString('TimeOfDay(NIGHT)')
	local m_gameTime = EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_worldTime.m_gameTime % 0x1A5E0 -- 0d108000 (FIFTEEN_DAYS)
	local isNight = m_gameTime >= 99000 or m_gameTime <= 26999
	--
	local applyCondition = playableRaces[spriteRaceStr] and not (hasInnateInfravision or EEex_IsBitSet(spriteGeneralState, 17)) and (isDungeon or (isOutdoor and isDayNight and isNight))
	--
	if sprite:getLocalInt("gtMakeInfravisionUseful") == 0 then
		if applyCondition then
			apply()
		end
	else
		if applyCondition then
			-- do nothing
		else
			-- Mark the creature as 'condition removed'
			sprite:setLocalInt("gtMakeInfravisionUseful", 0)
			--
			sprite:applyEffect({
				["effectID"] = 321, -- Remove effects by resource
				["res"] = "GTRULE02",
				["sourceID"] = sprite.m_id,
				["sourceTarget"] = sprite.m_id,
			})
		end
	end
	--
	--isNight:free()
end)

--[[
+---------------------------------------------------------------------+
| cdtweaks, alternate concentration check (fix bugged "CONCENTR.2DA") |
+---------------------------------------------------------------------+
--]]

function gtAlterConcentrationCheck(sprite, damageData)

	local curAction = sprite.m_curAction

	-- Get the spell that is currently being cast
	local spellResRef = curAction.m_string1.m_pchData:get()
	if spellResRef == "" then
		spellResRef = GT_Utility_DecodeSpell(curAction.m_specificID)
	end
	local spellLevel = EEex_Resource_Demand(spellResRef, "SPL").spellLevel

	-- Fetch components of check
	local roll = math.random(20) - 1
	local luck = sprite:getActiveStats().m_nLuck
	local con = sprite:getActiveStats().m_nCON
	local conBonus = math.floor(con / 2) - 5
	local damageTaken = damageData.damageTaken

	-- Do check
	local casterRoll = roll + conBonus
	local attackerRoll = spellLevel + damageTaken
	local disrupted = casterRoll <= attackerRoll

	-- Feedback
	if not disrupted then
		GT_Sprite_DisplayMessage(sprite,
			string.format("%s : %d > %d : [%d (1d20 - 1) + %d (%s)] > [%d (%s) + %d (%s)]",
				Infinity_FetchString(486169), casterRoll, attackerRoll, roll, conBonus, Infinity_FetchString(214029), spellLevel, Infinity_FetchString(486170), damageTaken, Infinity_FetchString(214027)),
			0x8D6140 -- Dark Muddish Brown
		)
	end

	-- Return interruption result
	return disrupted
end

--[[
+--------------------------------------------------------------------------------------+
| cdtweaks, automatically unsummon summoned creatures if the summoner dies prematurely |
+--------------------------------------------------------------------------------------+
--]]

EEex_Opcode_AddListsResolvedListener(function(sprite)
	-- Sanity check
	if not EEex_GameObject_IsSprite(sprite) then
		return
	end
	-- Check creature's gender / state / resref / animationID / ea
	local spriteGenderStr = GT_Resource_IDSToSymbol["gender"][sprite.m_typeAI.m_Gender]
	local spriteEAStr = GT_Resource_IDSToSymbol["ea"][sprite.m_typeAI.m_EnemyAlly]
	local spriteAnimateStr = GT_Resource_IDSToSymbol["animate"][sprite.m_animation.m_animation.m_animationID]
	local spriteResRef = sprite.m_resref:get()
	--
	local summonerID = sprite.m_lSummonedBy.m_Instance
	local summonerSprite = EEex_GameObject_Get(summonerID)
	-- since ``EEex_Opcode_AddListsResolvedListener`` is running after the effect lists have been evaluated, ``m_bonusStats`` has already been added to ``m_derivedStats`` by the engine
	local summonerGeneralState
	if summonerSprite then
		summonerGeneralState = summonerSprite.m_derivedStats.m_generalState
	end
	--
	local normal = spriteGenderStr == "SUMMONED" or spriteGenderStr == "SUMMONED_DEMON"
	local hardcodedResRefs = {
		["PLANGOOD"] = true,
		["PLANEVIL"] = true,
		["DEVAGOOD"] = true,
		["DEVAEVIL"] = true,
		-- the resref field is clobbered after reload
		["*LANGOOD"] = true,
		["*LANEVIL"] = true,
		["*EVAGOOD"] = true,
		["*EVAEVIL"] = true,
	}
	local celestial = spriteGenderStr == "BOTH" and hardcodedResRefs[spriteResRef] and (spriteAnimateStr == "SOLAR" or spriteAnimateStr == "DEVA_MONADIC")
	--
	if spriteEAStr ~= "FAMILIAR" and summonerSprite and EEex_IsBitSet(summonerGeneralState, 11) and (normal or celestial) then
		sprite:applyEffect({
			["effectID"] = 68, -- Unsummon creature
			["durationType"] = 1,
			["effectAmount"] = 1, -- Show text notification
			["noSave"] = true,
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end
end)


