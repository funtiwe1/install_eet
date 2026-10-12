function dwSystemCall(fn,menu,arg1,arg2,arg3)

	local bypasslist=nil
	if dwSystemCallBypass[fn] then
		bypasslist=dwSystemCallBypass[fn]
	elseif dwSystemCallBypassByMenu[fn] and dwSystemCallBypassByMenu[fn][menu] then
		bypasslist=dwSystemCallBypassByMenu[fn][menu]
	else
		bypasslist=nil
	end
	local proceed=true
	if bypasslist then
		for k,v in ipairs (bypasslist) do
			if proceed then
				test=_G[v.test]
				if (type(test)=='function') then
					match=test()
				else
					match=test
				end
				if match then
					_G[v.payload]()
					proceed=false
				end
			end
		end
	end
	if proceed then
		local actionlist=nil
		if dwSystemCallMain[fn] then
			actionlist=dwSystemCallMain[fn]
		else
			actionlist=dwSystemCallMainByMenu[fn][menu]
		end
		for k,v in ipairs (actionlist) do
			if v=='DEFAULT' then
				dwSystemCallDefault[fn](arg1,arg2,arg3)
			elseif type(_G[v])=='function' then
				_G[v](arg1,arg2,arg3)
			else
				print('Not running function '..v..' as it is not installed')
			end
		end
	end
end



