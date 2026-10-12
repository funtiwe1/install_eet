-- ***AI-related stuff*** --

--[[
+---------------------------------------------------------------------------------+
| Compiled objects for use with ``EEex_Sprite_GetAllOfTypeInRange()`` and friends |
+---------------------------------------------------------------------------------+
--]]

GT_AI_ObjectType = {
	["EVILCUTOFF"] = EEex_Object_ParseString("[EVILCUTOFF]"),
	["GOODCUTOFF"] = EEex_Object_ParseString("[GOODCUTOFF]"),
	--
	["PC"] = EEex_Object_ParseString("[PC]"),
	--
	["ANYONE"] = EEex_Object_ParseString("[ANYONE]"),
}


-- The following module provides functions to calculate SHA digest --

local sha = require("gt.sha2")


-- For use with ``EEex_LuaTrigger()`` and ``EEex_LuaDecode()``

GT_AI_LuaChunks = {
	-- spells
	["GTIN500"] = {
		['resref'] = 'GTIN500',
		['opcode'] = {12},
		['targetIDS'] = {'0'},
		['extra'] = {
			{['resistCold'] = {true, true}},
		},
	},

	["GTIN100"] = {
		['resref'] = 'GTIN100',
		['opcode'] = {5},
		['targetIDS'] = {'ANIMAL'},
		['extra'] = {
			{['default'] = {false, false}},
		},
	},

	["GTIN101"] = {
		['resref'] = 'GTIN101',
		['opcode'] = {185},
		['targetIDS'] = {'HUMANOID', 'ANIMAL'},
		['extra'] = {
			{
				['largeCreature'] = {true, true},
				['incorporealCreature'] = {true, true},
				['slime'] = {true, true},
				['levitatingCreature'] = {true, true},
				['elemental'] = {true, true},
			},
		},
	},

	["GTIN201"] = {
		['resref'] = 'GTIN201',
		['opcode'] = {157},
		['targetIDS'] = {'0'},
		['extra'] = {
			{
				['incapacitated'] = {false, true},
				['largeCreature'] = {false, true},
				['incorporealCreature'] = {false, true},
				['slime'] = {false, true},
				['levitatingCreature'] = {false, true},
				['elemental'] = {false, true},
			},
		},
	},

	-- weapon attacks
	["default"] = {
		['targetIDS'] = {'0'},
		['extra'] = {
			{['mirrorImage'] = {true, true}, ['stoneSkins'] = {true, true}, ['eyeOfTheSword'] = {true, true}, ["sneakAttack"] = {true, true}},
			{['mirrorImage'] = {true, true}, ['stoneSkins'] = {true, true}, ["sneakAttack"] = {true, true}},
			{['mirrorImage'] = {true, true}, ["sneakAttack"] = {true, true}},
			{["sneakAttack"] = {true, true}},
			{['default'] = {false, false}},
		},
		['opcode'] = {-1},
	},
	["webbedPreferringWeak"] = {
		['targetIDS'] = {'0.0.MAGE', '0.0.MAGE_THIEF', '0.0.MAGE_ALL', '0.0.THIEF', '0.0.BARD_ALL', '0.0.THIEF_ALL', '0.0.SHAMAN', '0.0.DRUID', '0.0.CLERIC', '0'},
		['extra'] = {
			{['mirrorImage'] = {true, true}, ['stoneSkins'] = {true, true}, ['eyeOfTheSword'] = {true, true}, ["webbed"] = {false, false}},
			{['mirrorImage'] = {true, true}, ['stoneSkins'] = {true, true}, ["webbed"] = {false, false}},
			{['mirrorImage'] = {true, true}, ["webbed"] = {false, false}},
			{["webbed"] = {false, false}},
			{['default'] = {false, false}},
		},
		['opcode'] = {-1},
	},
}


-- extra (additional) checks (f.i.: {['mirrorImage'] = {true, true}, ['stoneSkin'] = {true, true}}) --
-- ['mirrorImage'] = true -> flag the targeted creature as such depending on source INT --
-- ['webbed'] = false -> flag the targeted creature as such regardless of source INT --
-- the second true/false flag flips the result --

function GT_AI_ExtraCheck(source, target, extra)
	local sourceINT = source:getActiveStats().m_nINT
	--
	local aux = EEex_GetUDAux(source)
	if not aux["gt_AI_DetectableStates"] then
		aux["gt_AI_DetectableStates"] = {}
	end
	--
	local gtintmod = GT_Resource_2DA["gtintmod"]
	local dnum = tonumber(gtintmod[string.format("%s", sourceINT)]["DICE_NUM"])
	local dsize = tonumber(gtintmod[string.format("%s", sourceINT)]["DICE_SIZE"])
	--
	local m_gameTime = EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_worldTime.m_gameTime
	--
	for condition, flags in pairs(extra) do -- ['mirrorImage'] = {true, true}
		local hash = sha.sha256(condition .. tostring(flags[2]))
		--
		if flags[1] then
			--
			if not GT_EvalConditional[condition](source, target, flags[2]) then
				for _, v in ipairs(aux["gt_AI_DetectableStates"]) do
					if v.mode == 3 then
						if v.hash == hash then
							if v.id == target.m_id then
								if m_gameTime >= v.expirationTime then
									-- timer expired: target not valid
									return false
								else
									-- timer already running: target valid
									goto continue
								end
							end
						end
					end
				end
				-- timer not set: target valid
				table.insert(aux["gt_AI_DetectableStates"],
					{
						["hash"] = hash,
						["id"] = target.m_id,
						["expirationTime"] = m_gameTime + 90 * math.random(dnum, dnum * dsize), -- 90 ticks ~ 1 round
						["mode"] = 3,
					}
				)
				--
				::continue::
			else
				-- condition detected: target valid
			end
		else
			if not GT_EvalConditional[condition](source, target, flags[2]) then
				return false
			end
		end
	end
	--
	return true -- all checks passed: target valid
end


-- get (true) spell level (f.i., Secret Word is actually a level 5 spell, not 4) --

function GT_AI_GetTrueSpellLevel(pHeader, pAbility, ext)
	local toReturn = string.upper(ext) == "SPL" and pHeader.spellLevel or 0
	--
	if pAbility.effectCount > 0 then
		local currentEffectAddress = EEex_UDToPtr(pHeader) + pHeader.effectsOffset + pAbility.startingEffect * Item_effect_st.sizeof
		--
		for idx = 1, pAbility.effectCount do
			local pEffect = EEex_PtrToUD(currentEffectAddress, "Item_effect_st")
			--
			if pEffect.spellLevel > 0 then
				toReturn = pEffect.spellLevel
				break
			end
			--
			currentEffectAddress = currentEffectAddress + Item_effect_st.sizeof
		end
	end
	--
	return toReturn
end


-- check if the target can bounce the specified level/projectile/school/sectype/resref/opcode(s) --

function GT_AI_HasBounceEffects(source, target, level, projectileType, school, sectype, resref, opcodes, flags)
	local sourceINT = source:getActiveStats().m_nINT
	--
	local aux = EEex_GetUDAux(source)
	if not aux["gt_AI_DetectableStates"] then
		aux["gt_AI_DetectableStates"] = {}
	end
	--
	local m_gameTime = EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_worldTime.m_gameTime
	--
	local gtintmod = GT_Resource_2DA["gtintmod"]
	local dnum = tonumber(gtintmod[string.format("%s", sourceINT)]["DICE_NUM"])
	local dsize = tonumber(gtintmod[string.format("%s", sourceINT)]["DICE_SIZE"])
	--
	local toReturn = false
	--
	local hash = sha.sha256(tostring(level) .. tostring(projectileType) .. tostring(school) .. tostring(sectype) .. resref .. (opcodes and GT_Utility_ArrayToString(opcodes) or "nil") .. tostring(flags))
	--
	local found = GT_Sprite_HasBounceEffects(target, level, projectileType, school, sectype, resref, opcodes, flags)
	--
	if found then
		for _, v in ipairs(aux["gt_AI_DetectableStates"]) do
			if v.mode == 1 then
				if v.hash == hash then
					if v.id == target.m_id then
						if m_gameTime >= v.expirationTime then
							-- timer expired: target not valid
						else
							-- timer already running: target valid
							toReturn = true
						end
						--
						goto continue
					end
				end
			end
		end
		-- timer not set: target valid
		table.insert(aux["gt_AI_DetectableStates"],
			{
				["hash"] = hash,
				["id"] = target.m_id,
				["expirationTime"] = m_gameTime + 90 * math.random(dnum, dnum * dsize), -- 90 ticks ~ 1 round
				["mode"] = 1,
			}
		)
		--
		toReturn = true
	else
		toReturn = true -- immunity not detected: target valid
	end
	--
	::continue::
	return toReturn
end


-- check if the target is immune to the specified level/projectile/school/sectype/resref/opcode(s) --

function GT_AI_HasImmunityEffects(source, target, level, projectileType, school, sectype, resref, opcodes, flags, savetype, immunitiesVia403)
	local sourceINT = source:getActiveStats().m_nINT
	--
	local aux = EEex_GetUDAux(source)
	if not aux["gt_AI_DetectableStates"] then
		aux["gt_AI_DetectableStates"] = {}
	end
	--
	local m_gameTime = EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_worldTime.m_gameTime
	--
	local gtintmod = GT_Resource_2DA["gtintmod"]
	local dnum = tonumber(gtintmod[string.format("%s", sourceINT)]["DICE_NUM"])
	local dsize = tonumber(gtintmod[string.format("%s", sourceINT)]["DICE_SIZE"])
	--
	local toReturn = false
	--
	local hash = sha.sha256(tostring(level) .. tostring(projectileType) .. tostring(school) .. tostring(sectype) .. resref .. (opcodes and GT_Utility_ArrayToString(opcodes) or "nil") .. tostring(flags) .. tostring(savetype) .. tostring(immunitiesVia403))
	--
	local found = GT_Sprite_HasImmunityEffects(target, level, projectileType, school, sectype, resref, opcodes, flags, savetype, immunitiesVia403)
	--
	if found then
		for _, v in ipairs(aux["gt_AI_DetectableStates"]) do
			if v.mode == 0 then
				if v.hash == hash then
					if v.id == target.m_id then
						if m_gameTime >= v.expirationTime then
							-- timer expired: target not valid
						else
							-- timer already running: target valid
							toReturn = true
						end
						--
						goto continue
					end
				end
			end
		end
		-- timer not set: target valid
		table.insert(aux["gt_AI_DetectableStates"],
			{
				["hash"] = hash,
				["id"] = target.m_id,
				["expirationTime"] = m_gameTime + 90 * math.random(dnum, dnum * dsize), -- 90 ticks ~ 1 round
				["mode"] = 0,
			}
		)
		--
		toReturn = true
	else
		toReturn = true -- immunity not detected: target valid
	end
	--
	::continue::
	return toReturn
end


-- check if the target can trap the specified level --

function GT_AI_HasTrapEffect(source, target, level, sectype, flags)
	local sourceINT = source:getActiveStats().m_nINT
	--
	local aux = EEex_GetUDAux(source)
	if not aux["gt_AI_DetectableStates"] then
		aux["gt_AI_DetectableStates"] = {}
	end
	--
	local m_gameTime = EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_worldTime.m_gameTime
	--
	local gtintmod = GT_Resource_2DA["gtintmod"]
	local dnum = tonumber(gtintmod[string.format("%s", sourceINT)]["DICE_NUM"])
	local dsize = tonumber(gtintmod[string.format("%s", sourceINT)]["DICE_SIZE"])
	--
	local toReturn = false
	--
	local hash = sha.sha256(tostring(level) .. tostring(sectype) .. tostring(flags))
	--
	local found = GT_Sprite_HasTrapEffect(target, level, sectype, flags)
	--
	if found then
		for _, v in ipairs(aux["gt_AI_DetectableStates"]) do
			if v.mode == 2 then
				if v.hash == hash then
					if v.id == target.m_id then
						if m_gameTime >= v.expirationTime then
							-- timer expired: target not valid
						else
							-- timer already running: target valid
							toReturn = true
						end
						--
						goto continue
					end
				end
			end
		end
		-- timer not set: target valid
		table.insert(aux["gt_AI_DetectableStates"],
			{
				["hash"] = hash,
				["id"] = target.m_id,
				["expirationTime"] = m_gameTime + 90 * math.random(dnum, dnum * dsize), -- 90 ticks ~ 1 round
				["mode"] = 2,
			}
		)
		--
		toReturn = true
	else
		toReturn = true -- immunity not detected: target valid
	end
	--
	::continue::
	return toReturn
end


