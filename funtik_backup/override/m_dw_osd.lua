dwSystemCallMain={}
dwSystemCallMainByMenu={}
dwSystemCallBypass={}
dwSystemCallBypassByMenu={}
dwSystemCallDefault={}

dwSystemCallMain['characterScreen:OnLevelUpButtonClick']=
{
	[1]='dwStatusIsLevelling',
	[2]='dwSetOldHLACount',
	[3]='dwRecordRangerLevelOld',
	[4]='DEFAULT',
}

dwSystemCallDefault['characterScreen:OnLevelUpButtonClick']=function (arg1,arg2,arg3)
	characterScreen:OnLevelUpButtonClick()
end

dwSystemCallMain['characterScreen:OnDualClassButtonClick']=
{
	[1]='dwStatusIsDualclassing',
	[2]='dwFindClassKit2',
	[3]='DEFAULT',
}

dwSystemCallDefault['characterScreen:OnDualClassButtonClick']=function (arg1,arg2,arg3)
	characterScreen:OnDualClassButtonClick()
end

dwSystemCallMain['createCharScreen:OnAlignmentSelectButtonClick']=
{
	[1]='dwRecordChargenAlignment',
	[2]='DEFAULT',
}

dwSystemCallDefault['createCharScreen:OnAlignmentSelectButtonClick']=function (arg1,arg2,arg3)
	createCharScreen:OnAlignmentSelectButtonClick(arg1)
end

dwSystemCallMain['createCharScreen:OnGenderSelectButtonClick']=
{
	[1]='dwRecordChargenGender',
	[2]='DEFAULT',
}

dwSystemCallDefault['createCharScreen:OnGenderSelectButtonClick']=function (arg1,arg2,arg3)
	createCharScreen:OnGenderSelectButtonClick(arg1)
end

dwSystemCallMain['createCharScreen:OnAbilityReRollButtonClick']=
{
	[1]='DEFAULT',
	[2]='dwAbilityPointBuy',
}

dwSystemCallDefault['createCharScreen:OnAbilityReRollButtonClick']=function (arg1,arg2,arg3)
	createCharScreen:OnAbilityReRollButtonClick()
end

dwSystemCallMain['createCharScreen:AcceptCharacter']=
{
	[1]='dwNotInChargen',
	[2]='DEFAULT',
}

dwSystemCallBypass['createCharScreen:AcceptCharacter']=
{
	[1]={test='dwSubraceChargenBioBypassCheck',payload='dwSubraceChargenBioBypass'},
}

dwSystemCallDefault['createCharScreen:AcceptCharacter']=function (arg1,arg2,arg3)
	createCharScreen:AcceptCharacter(arg1)
end

dwSystemCallMainByMenu['createCharScreen:OnDoneButtonClick']={}

dwSystemCallMainByMenu['createCharScreen:OnDoneButtonClick']['CHARGEN_DUALCLASS']=
{
	[1]='dwStatusIsNeutral',
	[2]='DEFAULT',
}

dwSystemCallDefault['createCharScreen:OnDoneButtonClick']=function (arg1,arg2,arg3)
	createCharScreen:OnDoneButtonClick()
end

dwSystemCallMainByMenu['createCharScreen:OnDoneButtonClick']['CHARGEN_PROFICIENCIES']=
{
	[1]='dw_thief_skills_implement',
	[2]='DEFAULT',
}

dwSystemCallBypassByMenu['createCharScreen:OnDoneButtonClick']={}

dwSystemCallBypassByMenu['createCharScreen:OnDoneButtonClick']['CHARGEN_PROFICIENCIES']=
{
	[1]={test='dwHLAsAvailable',payload='dwHLAClickDoneButton'},
}

dwSystemCallMainByMenu['createCharScreen:OnDoneButtonClick']['LEVELUP_PROFICIENCIES']=
{
	[1]='dw_thief_skills_implement',
	[2]='dwStatusIsNeutral',
	[3]='DEFAULT',
}

dwSystemCallBypassByMenu['createCharScreen:OnDoneButtonClick']['LEVELUP_PROFICIENCIES']=
{
	[1]={test='dwHLAsAvailable',payload='dwHLAClickDoneButton'},
}

dwSystemCallMain['Infinity_OnPortraitLClick']=
{
	[1]='dwUpdateCurrentID',
	[2]='DEFAULT',
}

dwSystemCallDefault['Infinity_OnPortraitLClick']=function (arg1,arg2,arg3)
	Infinity_OnPortraitLClick(arg1)
end

dwSystemCallMain['Infinity_UpdateLuaStats']=
{
	[1]='DEFAULT',
	[2]='dwUpdateColors',
}

dwSystemCallDefault['Infinity_UpdateLuaStats']=function (arg1,arg2,arg3)
	Infinity_UpdateLuaStats()
end

dwSystemCallMain['startEngine:OnSoAButtonClick']=
{
	[1]='dwLevellerSoA',
	[2]='DEFAULT',
}

dwSystemCallDefault['startEngine:OnSoAButtonClick']=function (arg1,arg2,arg3)
	startEngine:OnSoAButtonClick(arg1)
end

dwSystemCallMain['startEngine:OnToBButtonClick']=
{
	[1]='dwLevellerToB',
	[2]='DEFAULT',
}

dwSystemCallBypass['startEngine:OnToBButtonClick']=
{
	[1]={test='dwDisableHoW',payload='dwShowDisableHoWMessage'},
}

dwSystemCallDefault['startEngine:OnToBButtonClick']=function (arg1,arg2,arg3)
	startEngine:OnToBButtonClick(arg1)
end

dwSystemCallMain['startEngine:OnTBPButtonClick']=
{
	[1]='dwLevellerTBP',
	[2]='DEFAULT',
}

dwSystemCallDefault['startEngine:OnTBPButtonClick']=function (arg1,arg2,arg3)
	startEngine:OnTBPButtonClick(arg1)
end

dwSystemCallMain['startEngine:OnCampaignButtonClick']=
{
	[1]='dwLevellerCampaign',
	[2]='DEFAULT',
}

dwSystemCallDefault['startEngine:OnCampaignButtonClick']=function (arg1,arg2,arg3)
	startEngine:OnCampaignButtonClick(arg1,arg2)
end

dwSystemCallMain['storeScreen:OnRentRoomButtonClick']=
{
	[1]='dwOnRentRoomButtonClick',
	[2]='DEFAULT',
}

dwSystemCallDefault['storeScreen:OnRentRoomButtonClick']=function (arg1,arg2,arg3)
	storeScreen:OnRentRoomButtonClick()
end


