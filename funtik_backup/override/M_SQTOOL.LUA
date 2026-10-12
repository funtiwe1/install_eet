
--SEQUENCER_MENU_VERSION:60
	function magePageInfo()
		local text = ''
		if bookMode == 1 then
			if type(SequencerMenu[contingencyResRef]) == 'function' then
			if SequencerMenuKnown == nil then	SequencerMenuKnown = 0;	end
			if SequencerMenuTotal == nil then	SequencerMenuTotal = 0;	end
				text = t("SPELLS_LABEL") .. " :" .. SequencerMenuKnown .. "/" .. SequencerMenuTotal
			end
		else
			text = Redirect_magePageInfo()
		end
		return text
	end
	function filterContingencyMageSpells()
		bookSpells = Redirect_filterContingencyMageSpells()
		if type(SequencerMenu[contingencyResRef]) == 'function' then
			SequencerMenu[contingencyResRef]()
		else
			SequencerMenu['DEFAULT']()
		end
		return bookSpells
	end
	SequencerMenu['DEFAULT'] = function()
		local temp = {}
		for k,v in pairs (bookSpells) do
			if v.level == currentSpellLevel - 1 then
				table.insert(temp, v)
			end
		end
		bookSpells = temp
	end

	function SequencerMenuSpellsKnown(multi,spelltable,abilFunc,abil,alignment,postfix,global)
		if postfix == nil then
			postfix = 'L'
		end
		local	temp = {};	local	unknown = {};	local known = 0;	local num = 0;	local mod = 0;
		if multi ~= 0 then
			if mageScreen:SpellSwappedInContingency(contingencyResRef) then
				local SwapTable = contingencySwapTable
				for k,v in pairs (SwapTable) do
					if mageScreen:SpellSwappedInContingency(v.resref) then
						for x,y in pairs (contingencySwapTable) do
							if y.level == currentSpellLevel then
								if global then
									if (Infinity_GetScriptVarInt(y.resref) == nil) or (Infinity_GetScriptVarInt(y.resref) == 0) then
										unknown[y.resref] = y
									elseif Infinity_GetScriptVarInt(y.resref) == 1 then
										known = known + 1
									end
								else
									unknown[y.resref] = y
								end
							end
						end
					end
				end
			end
		else
			if mageScreen:SpellSwappedInContingency(contingencyResRef) then
				for k,v in pairs (contingencySwapTable) do
					if v.level == currentSpellLevel then
						if global then
							if (Infinity_GetScriptVarInt(v.resref) == nil) or (Infinity_GetScriptVarInt(v.resref) == 0) then
								unknown[v.resref] = v
							elseif Infinity_GetScriptVarInt(v.resref) == 1 then
								known = known + 1
							end
						else
							unknown[v.resref] = v
						end
					end
				end
			end
		end
		local length = string.len(contingencyResRef)
		local contResBase = string.sub(contingencyResRef,1,length-1)
		if characters[id].sequencerSpells then
			for k,v in ipairs(characters[id].sequencerSpells) do
				if v.resref == contResBase then
					for x,y in ipairs(v.spells) do
						unknown[y.resref] = nil
					end
				end
			end
		end
		if characters[id].priestSpells[currentSpellLevel] ~= nil then
			for k,v in pairs (characters[id].priestSpells[currentSpellLevel]) do
				if unknown[v.resref] ~= nil then
					unknown[v.resref] = nil
					known = known + 1
				end
			end
		end
		if characters[id].mageSpells[currentSpellLevel] ~= nil then
			for k,v in pairs (characters[id].mageSpells[currentSpellLevel]) do
				if unknown[v.resref] ~= nil then
					unknown[v.resref] = nil
					known = known + 1
				end
			end
		end
		if alignment and (SequencerMenuAlignment ~= nil) then
			local alignment = characters[id].alignment
			local restrict = 0
					if alignment == (0xf000000 + 902) then alignment = 0x3
			elseif alignment == (0xf000000 + 903) then alignment = 0x5
			elseif alignment == (0xf000000 + 904) then alignment = 0x9
			elseif alignment == (0xf000000 + 1081) then alignment = 0x12
			elseif alignment == (0xf000000 + 1082) then alignment = 0x14
			elseif alignment == (0xf000000 + 1083) then alignment = 0x18
			elseif alignment == (0xf000000 + 902) then alignment = 0x22
			elseif alignment == (0xf000000 + 902) then alignment = 0x24
			elseif alignment == (0xf000000 + 902) then alignment = 0x30
			end
			for k,v in pairs (unknown) do
				restrict = SequencerMenuAlignment(v.resref)
				for i=0,7,1 do
					if restrict / 2^i > 0 and alignment / 2^i > 0 then
						unknown[v.resref] = nil
						i = 7
					else
						restrict = restrict % 2^i
						alignment = alignment % 2^i
					end
				end
			end
		end
		num = SequencerMenu[spelltable]()
		if type(SequencerMenu[abilFunc]) == 'function' then
			mod = SequencerMenu[abilFunc](abil)
		end
		for k,v in pairs (unknown) do	table.insert(temp, v);	end
		table.sort(temp,function(a,b) return a.resref < b.resref end)
		for k,v in ipairs (temp) do
			if known < num + mod then
				v.resref = v.resref .. postfix
			else
				v.resref = {}
			end
		end
		SequencerMenuKnown = known
		if num + mod > 0 then
			SequencerMenuTotal = num + mod
		else
			SequencerMenuTotal = 0
		end
		return temp
	end
