
	SequencerMenu['D5SNGKN'] = function()
		local	num = 0;	local level = characters[id].level.current
		if currentSpellLevel == 1 and level > 0 then
			if level < 1 then num = 19; else num = 20 end
		elseif currentSpellLevel == 2 and level > 49 then
			if level < 50 then num = 0; else num = 1 end
		elseif currentSpellLevel == 3 and level > 49 then
			if level < 50 then num = 0; else num = 1 end
		elseif currentSpellLevel == 4 and level > 49 then
			if level < 50 then num = 0; else num = 1 end
		elseif currentSpellLevel == 5 and level > 49 then
			if level < 50 then num = 0; else num = 1 end
		elseif currentSpellLevel == 6 and level > 49 then
			if level < 50 then num = 0; else num = 1 end
		elseif currentSpellLevel == 7 and level > 49 then
			if level < 50 then num = 0; else num = 1 end
		elseif currentSpellLevel == 8 and level > 49 then
			if level < 50 then num = 0; else num = 1 end
		elseif currentSpellLevel == 9 and level > 49 then
			if level < 50 then num = 0; else num = 1 end
		end
		return num
	end	--[SEQUENCER_MENU_KNOWN_SPL_TABLE END]
SequencerMenu['D5SN87X'] = function() bookSpells = SequencerMenuSpellsKnown(0,'D5SNGKN','','0',0,'L',0); end
	SequencerMenu['QD_SPLSRCKN'] = function()
		local	num = 0;	local level = characters[id].level.current
		if currentSpellLevel == 1 and level > 0 then
			if level < 1 then num = 1; elseif level < 3 then num = 2; elseif level < 5 then num = 3; elseif level < 7 then num = 4; else num = 5 end
		elseif currentSpellLevel == 2 and level > 3 then
			if level < 4 then num = 0; elseif level < 5 then num = 1; elseif level < 7 then num = 2; elseif level < 9 then num = 3; elseif level < 11 then num = 4; else num = 5 end
		elseif currentSpellLevel == 3 and level > 5 then
			if level < 6 then num = 0; elseif level < 7 then num = 1; elseif level < 9 then num = 2; elseif level < 11 then num = 3; elseif level < 22 then num = 4; else num = 5 end
		elseif currentSpellLevel == 4 and level > 7 then
			if level < 8 then num = 0; elseif level < 9 then num = 1; elseif level < 11 then num = 2; elseif level < 13 then num = 3; elseif level < 23 then num = 4; else num = 5 end
		elseif currentSpellLevel == 5 and level > 9 then
			if level < 10 then num = 0; elseif level < 11 then num = 1; elseif level < 13 then num = 2; elseif level < 15 then num = 3; elseif level < 28 then num = 4; else num = 5 end
		elseif currentSpellLevel == 6 and level > 11 then
			if level < 12 then num = 0; elseif level < 13 then num = 1; elseif level < 15 then num = 2; elseif level < 21 then num = 3; elseif level < 30 then num = 4; else num = 5 end
		elseif currentSpellLevel == 7 and level > 13 then
			if level < 14 then num = 0; elseif level < 15 then num = 1; elseif level < 17 then num = 2; elseif level < 22 then num = 3; elseif level < 31 then num = 4; else num = 5 end
		elseif currentSpellLevel == 8 and level > 15 then
			if level < 16 then num = 0; elseif level < 17 then num = 1; elseif level < 19 then num = 2; elseif level < 23 then num = 3; elseif level < 32 then num = 4; else num = 5 end
		elseif currentSpellLevel == 9 and level > 17 then
			if level < 18 then num = 0; elseif level < 19 then num = 1; elseif level < 20 then num = 2; elseif level < 25 then num = 3; elseif level < 36 then num = 4; else num = 5 end
		end
		return num
	end	--[SEQUENCER_MENU_KNOWN_SPL_TABLE END]
SequencerMenu['D5XSORCX'] = function() bookSpells = SequencerMenuSpellsKnown(0,'QD_SPLSRCKN','','0',0,'W',0); end
	SequencerMenu['D5_SHMKN'] = function()
		local	num = 0;	local level = characters[id].level.current
		if currentSpellLevel == 1 and level > 0 then
			if level < 1 then num = 1; elseif level < 2 then num = 2; elseif level < 4 then num = 3; else num = 4 end
		elseif currentSpellLevel == 2 and level > 2 then
			if level < 3 then num = 0; elseif level < 4 then num = 1; elseif level < 7 then num = 2; elseif level < 10 then num = 3; else num = 4 end
		elseif currentSpellLevel == 3 and level > 4 then
			if level < 5 then num = 0; elseif level < 6 then num = 1; elseif level < 9 then num = 2; elseif level < 12 then num = 3; else num = 4 end
		elseif currentSpellLevel == 4 and level > 6 then
			if level < 7 then num = 0; elseif level < 8 then num = 1; elseif level < 11 then num = 2; elseif level < 15 then num = 3; else num = 4 end
		elseif currentSpellLevel == 5 and level > 8 then
			if level < 9 then num = 0; elseif level < 10 then num = 1; elseif level < 14 then num = 2; elseif level < 16 then num = 3; else num = 4 end
		elseif currentSpellLevel == 6 and level > 10 then
			if level < 11 then num = 0; elseif level < 12 then num = 1; elseif level < 15 then num = 2; elseif level < 18 then num = 3; else num = 4 end
		elseif currentSpellLevel == 7 and level > 12 then
			if level < 13 then num = 0; elseif level < 14 then num = 1; elseif level < 17 then num = 2; elseif level < 19 then num = 3; else num = 4 end
		end
		return num
	end	--[SEQUENCER_MENU_KNOWN_SPL_TABLE END]
SequencerMenu['D5SH01ZX'] = function() bookSpells = SequencerMenuSpellsKnown(0,'D5_SHMKN','','0',0,'W',0); end
	SequencerMenu['D5_SHMKN'] = function()
		local	num = 0;	local level = characters[id].level.current
		if currentSpellLevel == 1 and level > 0 then
			if level < 1 then num = 1; elseif level < 2 then num = 2; elseif level < 4 then num = 3; else num = 4 end
		elseif currentSpellLevel == 2 and level > 2 then
			if level < 3 then num = 0; elseif level < 4 then num = 1; elseif level < 7 then num = 2; elseif level < 10 then num = 3; else num = 4 end
		elseif currentSpellLevel == 3 and level > 4 then
			if level < 5 then num = 0; elseif level < 6 then num = 1; elseif level < 9 then num = 2; elseif level < 12 then num = 3; else num = 4 end
		elseif currentSpellLevel == 4 and level > 6 then
			if level < 7 then num = 0; elseif level < 8 then num = 1; elseif level < 11 then num = 2; elseif level < 15 then num = 3; else num = 4 end
		elseif currentSpellLevel == 5 and level > 8 then
			if level < 9 then num = 0; elseif level < 10 then num = 1; elseif level < 14 then num = 2; elseif level < 16 then num = 3; else num = 4 end
		elseif currentSpellLevel == 6 and level > 10 then
			if level < 11 then num = 0; elseif level < 12 then num = 1; elseif level < 15 then num = 2; elseif level < 18 then num = 3; else num = 4 end
		elseif currentSpellLevel == 7 and level > 12 then
			if level < 13 then num = 0; elseif level < 14 then num = 1; elseif level < 17 then num = 2; elseif level < 19 then num = 3; else num = 4 end
		end
		return num
	end	--[SEQUENCER_MENU_KNOWN_SPL_TABLE END]
SequencerMenu['D5SH01ZX'] = function() bookSpells = SequencerMenuSpellsKnown(0,'D5_SHMKN','','0',0,'W',0); end
	SequencerMenu['NPC_EE_SPLSKN'] = function()
		local	num = 0;	local level = characters[id].level.current
		if currentSpellLevel == 1 and level > 0 then
			if level < 1 then num = 1; else num = 2 end
		elseif currentSpellLevel == 2 and level > 1 then
			if level < 2 then num = 0; elseif level < 3 then num = 1; else num = 2 end
		elseif currentSpellLevel == 3 and level > 3 then
			if level < 4 then num = 0; elseif level < 5 then num = 1; else num = 2 end
		elseif currentSpellLevel == 4 and level > 5 then
			if level < 6 then num = 0; elseif level < 7 then num = 1; else num = 2 end
		elseif currentSpellLevel == 5 and level > 7 then
			if level < 8 then num = 0; elseif level < 9 then num = 1; else num = 2 end
		elseif currentSpellLevel == 6 and level > 9 then
			if level < 10 then num = 0; elseif level < 11 then num = 1; else num = 2 end
		elseif currentSpellLevel == 7 and level > 11 then
			if level < 12 then num = 0; elseif level < 13 then num = 1; else num = 2 end
		elseif currentSpellLevel == 8 and level > 13 then
			if level < 14 then num = 0; elseif level < 15 then num = 1; else num = 2 end
		elseif currentSpellLevel == 9 and level > 16 then
			if level < 17 then num = 0; elseif level < 21 then num = 1; else num = 2 end
		end
		return num
	end	--[SEQUENCER_MENU_KNOWN_SPL_TABLE END]
SequencerMenu['D5CLSPX'] = function() bookSpells = SequencerMenuSpellsKnown(0,'NPC_EE_SPLSKN','','0',0,'U',0); end
