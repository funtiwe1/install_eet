--subrStrings = {
--10. NONE_STRINGS = "",
--1.  AASIMAR = "Аасимар",
--2.  TIEFLING = "Тифлинг",
--3.  DROW = "Дроу",
--4.  WILD_ELF = "Дикий эльф",
--5.  DWARF_GOLD = "Золотой дварф",
--6.  DWARF_GRAY = "Серый дварф",
--7.  HALFLING_STRONGHEART = "Крепкий полурослик",
--8.  HALFLING_GHOSTWISE = "Скрытный полурослик",
--9.  GNOME_DEEP = "Глубинный гном",
--11. MOON_ELF = "Лунный эльф",
--}

zZsubrTitleTable = {
	['488577'] = {1, 488535},
	['488578'] = {2, 488537},
	['488579'] = {3, 488540},
	['488580'] = {4, 488542},
	['488582'] = {5, 488547},
	['488581'] = {6, 488549},
	['488583'] = {7, 488552},
	['488584'] = {8, 488554},
	['488585'] = {9, 488557},
	['488586'] = {11, 488544},
}

function subt(chr)
	--local var = Infinity_GetScriptVarInt("SUBRACE","LOCALS", char)
	--if (chr == 0) then return subrStrings.NONE_STRINGS
	--elseif (chr == 1) then return " / " .. --subrStrings.AASIMAR
	if     (chr == 1) then return Infinity_FetchString(488534) --subrStrings.AASIMAR
	elseif (chr == 2) then return Infinity_FetchString(488536) --subrStrings.TIEFLING
	elseif (chr == 3) then return Infinity_FetchString(488539) --subrStrings.DROW
	elseif (chr == 4) then return Infinity_FetchString(488541) --subrStrings.WILD_ELF
	elseif (chr == 5) then return Infinity_FetchString(488546) --subrStrings.DWARF_GOLD
	elseif (chr == 6) then return Infinity_FetchString(488548) --subrStrings.DWARF_GRAY
	elseif (chr == 7) then return Infinity_FetchString(488551) --subrStrings.HALFLING_STRONGHEART
	elseif (chr == 8) then return Infinity_FetchString(488553) --subrStrings.HALFLING_GHOSTWISE
	elseif (chr == 9) then return Infinity_FetchString(488556) --subrStrings.GNOME_DEEP
	elseif (chr == 11) then return Infinity_FetchString(488543) --subrStrings.MOON_ELF
	else return ""
	end
end

function getSubraceTitleButton(currS)
	if subt(currS) ~= "" then
		return subt(currS)
	else
		return Infinity_FetchString(488531)
	end
end

currSubrace = 10
currRace = 0
getSubrace = 0
sbSubraceData = {}
srText = ""


function zzSubraceString(char)
	local rstr = Infinity_FetchString(char.race)
	if srText == "" or char.PC ~= 1 then
		return rstr
	else
		return rstr .. " ( " .. srText .. " )"
	end
end

function createSubraceTable(race)
	sbSubraceData = {}
	if race == 1 then --human
		sbSubraceData = {
			{488560, 9550, 10},
			{488561, 488535, 1},
			{488562, 488537, 2},
		}
	end
	if race == 2 then --elf
		sbSubraceData = {
			{488563, 9552, 10},
			{488564, 488540, 3},
			{488565, 488542, 4},
			{488566, 488544, 11},
        }    
	end
	if race == 3 then --halfelf
		sbSubraceData = {
			{488575, 9555, 10},
		}
	end
	if race == 4 then --dwarf
		sbSubraceData = {
			{488567, 9551, 10},
			{488568, 488547, 5},
			{488569, 488549, 6},
		}    
	end
	if race == 5 then --halfling
		sbSubraceData = {
			{488570, 9554, 10},
			{488571, 488552, 7},
			{488572, 488554, 8},
		}    
	end
	if race == 6 then --gnome
		sbSubraceData = {
			{488573, 9553, 10},
			{488574, 488557, 9},
		}
	end
	if race == 7 then --halforc
		sbSubraceData = {
			{488576, 53191, 10},
		}
	end
end
sbSubraceDataEx = {}
function createSubraceTableEx()
	sbSubraceDataEx = {}
	sbSubraceDataEx = {
		{488561, 488535, 1},
		{488562, 488537, 2},
		{488564, 488540, 3},
		{488565, 488542, 4},
		{488568, 488547, 5},
		{488569, 488549, 6},
		{488571, 488552, 7},
		{488572, 488554, 8},
		{488574, 488557, 9},
		{0, 0, 10},
		{488566, 488544, 11},
		}
end
createSubraceTableEx()

function getRaceSubraceTitle(sbr)
	if sbr == 1 then
		return Infinity_FetchString(488532)
	else
		return t("RACE_TITLE")
	end
end

function getSubraceTitle(row)
	local text = sbSubraceData[row][1]
	return Infinity_FetchString(text)
end

function getSubraceDescription(row)
	local text = sbSubraceData[row][2]
	return Infinity_FetchString(text)
end

function onSubraceButton(buttonNum)
	--local gl = sbSubraceData[buttonNum][3]
	C:SetGlobal("Pl_SUBRACE","GLOBAL",buttonNum)
end

function SubRaceOrGeneralHelp(sbr)
	if sbr == nil then
		return Infinity_FetchString(270676)
	else
		return Infinity_FetchString(sbSubraceData[sbr][2])
	end
end

function zzSubrClaickable()
	local race = chargen.races[currentChargenRace]
	if race then
		return true
	else
		return false
	end
end

function SubRaceAndRaceOrGeneralHelp(sbr)
	local race = chargen.races[currentChargenRace]
	if race then
		if (sbr > 0 and sbr ~= 10) then
			return Infinity_FetchString(race.desc) .. '\n\n________________________\n\n' .. Infinity_FetchString(sbSubraceDataEx[sbr][2])
		else
			return Infinity_FetchString(race.desc)
		end
	else
		return Infinity_FetchString(17237)
	end
end

zZraceStrings = {
	{nil, 1096, 1},
	{nil, 1097, 2},
	{nil, 1098, 3},
	{nil, 1100, 4},
	{nil, 1101, 5},
	{nil, 1099, 6},
	{nil, 53212, 7},
}
--nil race subrace idx
zZsubraceStrings = {
	{nil, 1, 488577, 1},
	{nil, 1, 488578, 2},
	{nil, 2, 488579, 3},
	{nil, 2, 488580, 4},
	{nil, 4, 488582, 5},
	{nil, 4, 488581, 6},
	{nil, 5, 488583, 7},
	{nil, 5, 488584, 8},
	{nil, 6, 488585, 9},
	{nil, 0, -1, 10},
	{nil, 2, 488586, 11},
}
function zzCreateCharInfo(info)
	local rc = 0
	local str, stra, strb = ''
	local x, y = 0, 0
	if currentChargenRace ~= nil and currSubrace > 0 and currSubrace ~= 10 then
		for k, v in pairs(zZraceStrings) do
			if currentChargenRace == v[3] then
				rc = v[3]
				str = Infinity_FetchString(v[2])
				break
			end
		end
		if rc > 0 then
			x, y = string.find(info, str, 1, true)
			if x ~= nil then
				stra = string.sub(info, 1, y)
				strb = string.sub(info, y + 1)
				for k, v in pairs(zZsubraceStrings) do
					if rc == v[2] and currSubrace == v[4] then
						info = stra .. ' ( ' .. Infinity_FetchString(v[3]) .. ' )' .. strb
					end
				end
			end
		end
	end
	return info
end






function zZrandomSubrace()
	local subr = math.random(1,2)
	if subr == 2 then
		createSubraceTable(chargen.races[currentChargenRace].id)
		currChargenSubrace = math.random(1, #sbSubraceData)
		currSubrace = sbSubraceData[currChargenSubrace][3]
		onSubraceButton(currSubrace)
	end
end
















