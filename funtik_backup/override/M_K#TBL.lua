-- -- -- -- --
-- UI.MENU  --
-- -- -- -- --

--obviously theres some redundancy in this data but I dislike the idea of assuming what our frame/sequence will be.
startCampaignData = {
	
	{id = 'BG1', name = 'EET_CMP_TITLE_BG1', description = 'EET_CMP_TEXT_BG1', title = 0, bigLogo = 0, icon = 0, background = 2, button = 2, sidebar = 2, importEnabled = false, tutorialEnabled = false, forceParty = false, cheatAreasTable = cheatAreas},
	{id = 'SOD', name = 'EET_CMP_TITLE_SOD', description = 'EET_CMP_TEXT_SOD', title = 1, bigLogo = 1, icon = 1, background = 2, button = 2, sidebar = 2, importEnabled = false, tutorialEnabled = false, forceParty = false, cheatAreasTable = cheatAreas},
	{id = 'SOA', name = 'EET_CMP_TITLE_SOA', description = 'EET_CMP_TEXT_SOA', title = 2, bigLogo = 2, icon = 2, background = 2, button = 2, sidebar = 2, importEnabled = false, tutorialEnabled = false, forceParty = false, cheatAreasTable = cheatAreas},
	{id = 'TOB', name = 'EET_CMP_TITLE_TOB', description = 'EET_CMP_TEXT_TOB', title = 3, bigLogo = 3, icon = 3, background = 2, button = 2, sidebar = 2, importEnabled = false, tutorialEnabled = false, forceParty = false, cheatAreasTable = cheatAreas},
	{id = 'ID1', name = 'EET_CMP_TITLE_ID1', description = 'EET_CMP_TEXT_ID1', title = 9, bigLogo = 7, icon = 7, background = 2, button = 2, sidebar = 2, importEnabled = false, tutorialEnabled = false, forceParty = true, cheatAreasTable = cheatAreas},
	{id = 'ID2', name = 'EET_CMP_TITLE_ID2', description = 'EET_CMP_TEXT_ID2', title = 10, bigLogo = 9, icon = 9, background = 2, button = 2, sidebar = 2, importEnabled = false, tutorialEnabled = false, forceParty = true, cheatAreasTable = cheatAreas},
	{id = 'BP1', name = 'EET_CMP_TITLE_BP1', description = 'EET_CMP_TEXT_BP1', title = 4, bigLogo = 4, icon = 4, background = 2, button = 2, sidebar = 2, importEnabled = true, tutorialEnabled = false, forceParty = true, cheatAreasTable = cheatAreasArena_BP1},
	{id = 'BP2', name = 'EET_CMP_TITLE_BP2', description = 'EET_CMP_TEXT_BP2', title = 5, bigLogo = 5, icon = 5, background = 2, button = 2, sidebar = 2, importEnabled = true, tutorialEnabled = false, forceParty = true, cheatAreasTable = cheatAreasArena},
	{id = 'TUT', name = 'EET_CMP_TITLE_TUT', description = 'EET_CMP_TEXT_TUT', title = 6, bigLogo = 6, icon = 6, background = 2, button = 2, sidebar = 2, importEnabled = false, tutorialEnabled = false, forceParty = false, cheatAreasTable = cheatAreasTutorial},
}

-- class, kit, clastxtBIO: BG1, SOD, SOA, TOB, BP1, BP2, TUT, (...)
bioClassData = {
}

-- race, racetextBIO: BG1, SOD, SOA, TOB, BP1, BP2, TUT, (...)
bioRaceData = {
}

-- -- -- -- --
-- L_x.LUA  --
-- -- -- -- --

--strings used by UI.MENU file
eetStrings = {

	EET_CMP_TEXT_BG1 = "\"He who fights with monsters should look to it that he himself does not become a monster... when you gaze long into the abyss the abyss also gazes into you...\" -Friedrich Nietzsche.\n\nFor as long as you can remember, your view of the world has been limited to the heavily fortified walls of Candlekeep. Your foster father, Gorion, has done everything in his power to protect you and keep you out of harm's way.\n\nAll of that is about to change. Forced to leave your home under mysterious circumstances, you find yourself drawn into a conflict that has the Sword Coast on the brink of war. An iron shortage of unknown origin threatens to plunge the city of Baldur's Gate into conflict with Amn. Meanwhile, there is something else at work, far more sinister than you can even begin to fathom...",
	EET_CMP_TEXT_SOD = "\"Fate leads him who follows it, and drags him who resist.\" -Plutarch\n\nThe threat of war looms over the city of Baldur's Gate. A crusade marches from the north, seizing supplies, forcing locals into military service, and disrupting trade along the Sword Coast. A charismatic warrior known as the Shining Lady leads this army, her background shrouded in mystery. Rumors whisper that she follows a divine agenda. Could the gods truly guide this Shining Lady?\n\nThe farther you travel from the city, the more you realize how many forces have a stake in the outcome of this conflict. Baldur's Gate has put its faith in you, but you must determine whose interests you truly serve before you face the Shining Lady among the ruins of Dragonspear Castle...",
	EET_CMP_TEXT_SOA = "\"The Lord of Murder shall perish, but in his doom he shall spawn a score of mortal progeny. Chaos shall be sown from their passage...\" -So sayeth the Wise Alaundo\n\nKidnapped. Imprisoned. Tortured. The wizard Irenicus holds you captive in his stronghold, attempting to strip you of the powers that are your birthright.\n\nCan you resist the evil within you, forge a legend of heroic proportions, and ultimately destroy the dark essence that haunts your dreams? Or will you embrace your monstrous nature, carve a swath of destruction across the realms, and ascend to godhood as the new Lord of Murder?",
	EET_CMP_TEXT_TOB = "\"There is no peace for a child of Bhaal. You've learned this lesson time and again. As all who are close to you suffer; because, of your tainted blood.\"\n\nWelcome to Baldur's Gate II: Throne of Bhaal, the expansion pack to Baldur's Gate II: Shadows of Amn, and the final chapter in the Baldur's Gate series. The time of the prophecy has come.",
	EET_CMP_TEXT_BP1 = "\"Come one, come all! Feast your eyes upon most marvelous martial magnificence that the Underdark has to offer!\" -Baeloth the Entertainer\n\nDeep within the Underdark where few dare to tread, the mad drow Baeloth has used his extensive mastery of magic to force a duergar colony into creating an entertainment complex of his own design. He has invited guests from across the realms, from Maztica to Menzoberranzan, and they will readily attend - Baeloth is known to be an excellent showman.",
	EET_CMP_TEXT_BP2 = "\"Come one, come all! To the greatest show this side of the Astral plane!\" -Dennaton\n\nWelcome to Black Pits II: Gladiators of Thay, a follow-up to Baeloth's Black Pits. Explore the tactical depth of high-level Dungeons & Dragons combat. Turn your captors against each other while you dodge traps and battle for your life against Demi-Liches, Mind Flayers, and the legendary Githyanki.",
	EET_CMP_TEXT_TUT = "\"Hello, child. Shall we continue your lessons?\" -Tutor\n\nWelcome to the Ducal Palace, the tutorial area for Baldur's Gate: Enhanced Edition. This is a simple walk-through of some of the basic skills you will need to play and enjoy the game. Once the tutorial area has loaded, an NPC (non-player character) will guide you through fighting monsters, casting spells, the use of thieving abilities, and some of the more common interactions you will experience in the game world.",
	EET_CMP_TITLE_BG1 = "Baldur's Gate",
	EET_CMP_TITLE_SOD = "Siege of Dragonspear",
	EET_CMP_TITLE_SOA = "Shadows of Amn",
	EET_CMP_TITLE_TOB = "Throne of Bhaal",
	EET_CMP_TITLE_ID1 = "Долина Ледяного Ветра",
	EET_CMP_TEXT_ID1 = "Добро пожаловать в Долину Ледяного Ветра - tipun",
	EET_CMP_TITLE_ID2 = "Долина Ледяного Ветра II",
	EET_CMP_TEXT_ID2 = "Добро пожаловать в Долину Ледяного Ветра II - tipun",
	EET_CMP_TITLE_BP1 = "The Black Pits",
	EET_CMP_TITLE_BP2 = "Gladiators of Thay",
	EET_CMP_TITLE_TUT = "Tutorial",
	EET_WARNING_TITLE = "WARNING",
	EET_WARNING_TEXT = "Baldur's Gate: Enhanced Edition Trilogy mod installation has not been finished yet.\n\nAFTER installing all other mods please run \"setup-EET_end.exe\" to finalise the installation.\n\nIf you're unsure what to do please check the readme file included in the mod package.",
	EET_CHAPTER = "Chapter ",
}
