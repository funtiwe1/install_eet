
function dwDisplayDifficulty()
	if(key and dw_difficulty_entries[dwDifficultyLookup[diffCategory]] and dw_difficulty_entries[dwDifficultyLookup[diffCategory]][key]) then 
		return Infinity_FetchString(dw_difficulty_entries[dwDifficultyLookup[diffCategory]][key].desc) 
	else
		return ''
	end	
end

function dwDifficultyToggleFrame()
	if dw_difficulty_entries[dwDifficultyLookup[diffCategory]][rowNumber].value==diffValue then
		return 2
	else
		return 0
	end

end

function dwDifficultyOnClick()
	if cellNumber == 2 and dw_difficulty_entries[dwDifficultyLookup[diffCategory]][key]~=diffValue then
		Infinity_PlaySound('GAM_09')
		diffValue=dw_difficulty_entries[dwDifficultyLookup[diffCategory]][key].value
		var=dw_difficulty[dwDifficultyLookup[diffCategory]].variable
		Infinity_RemoveINIEntry('Script',var)
		if diffValue>0 then
			Infinity_SetINIValue('Script',var,diffValue)
		end
	end	
end

function dwDifficultyRevert()
	for k,v in pairs (dw_difficulty) do
		Infinity_RemoveINIEntry('Script',v.variable)
	end


end


function dwDifficultyHelp()

	if diffCategory>0 then 
		val=dw_difficulty[dwDifficultyLookup[diffCategory]].desc
	else	
		val=0
	end
	return val
end

function build_dwDifficultyLookup()

	workingTable={}
	new_ind=0
	for k,v in pairs (dw_difficulty) do
		if v.active then
			new_ind=new_ind+1
			workingTable[new_ind]=k
		end
	end
	return workingTable

end

