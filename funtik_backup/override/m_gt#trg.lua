-- ***Lua Triggers*** --

-- Assume actions "MoveToPoint()" and "Attack()" are player-issued commands (as a result, do not interrupt them) --

function GT_LuaTrigger_InterruptableAction()
	if EEex_LuaTrigger_Object.m_typeAI.m_EnemyAlly > 200 then -- [EVILCUTOFF]
		return true
	else
		return not (EEex_LuaTrigger_Object.m_curAction.m_actionID == 3 or EEex_LuaTrigger_Object.m_curAction.m_actionID == 23)
	end
end


-- return true if the number of creatures of the type specified in sight of the active CRE are greater or equal to the specified number --

function GT_LuaTrigger_NumCreatureCheck(aiObjectTypeString, num)
	local creatures = EEex_Sprite_GetAllOfTypeStringInRange(EEex_LuaTrigger_Object, string.format("[%s]", aiObjectTypeString), EEex_LuaTrigger_Object:virtual_GetVisualRange(), nil, nil, nil)

	if #creatures >= num then
		return true
	else
		return math.random(num) <= #creatures -- scales with the number of expected creatures
	end

end


-- Check if the script runner is affected by effects from the specified resref --

function GT_LuaTrigger_ResRefCheck(resref)
	local toReturn = false
	--
	local func = function(effect)
		if effect.m_sourceRes:get() == resref then
			toReturn = true
			return true
		end
	end
	--
	EEex_Utility_IterateCPtrList(EEex_LuaTrigger_Object.m_timedEffectList, func)
	if not toReturn then
		-- guess we can safely ignore equipped effects, right...?
		--EEex_Utility_IterateCPtrList(EEex_LuaTrigger_Object.m_equipedEffectList, func)
	end
	--
	return toReturn
end


-- check if the active creature is in chase mode --

function GT_LuaTrigger_IsChasing()
	local str = 'InWeaponRange(EEex_Target("gtChasingTarget"))'
	local target = EEex_GameObject_Get(EEex_LuaTrigger_Object.m_targetId)
	local m_actionID = EEex_LuaTrigger_Object.m_curAction.m_actionID
	--
	return m_actionID == 134 and EEex_LuaTrigger_Object.m_followCount == 0 and target and GT_EvalConditional["parseConditionalString"](EEex_LuaTrigger_Object, target, str, "gtChasingTarget")
end


-- check if PartyAI is ON/OFF --

function GT_LuaTrigger_PartyAI()
	if EEex_LuaTrigger_Object.m_typeAI.m_EnemyAlly > 200 then -- [EVILCUTOFF]
		return true
	else
		return EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_bPartyAI == 1
	end
end


