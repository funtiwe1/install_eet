



function iscsvright
try
csv = read(mods.csv)
csv_old = read(mods_old.csv)
catch
	say problem with csv, csv_old
end

if csv_old equal csv
	say csv file not changed!
	say you sure?
	while true  
		promt
		if promt = Y 
			return true
		else if promt = N
			return false
	end
else
	say new csv file. Are you sure?
	while true  
		promt
		if promt = Y 
			return true
		else if promt = N
			return false
end



function check_csv
try
csv = read(mods.csv)
catch
	say problem with csv
end

flag_empty = 0
flag_double = 0
arr = array[order][name]
foreach row in csv
	if row[order] is empty
		say empty order at mod {row[name]}
		flag_empty = 1
		continue
	end
	if row[order] in arr
		arr[row[order]] = arr[row[order]] + ',' + row[name]
		say equal order in mods arr[row[name]] with row[order] prioopity
		flag_double= 1
	else
		arr[row[order]] = row[name]

if flag_empty or flag_double 
	say there are doubles or empty orders
	return false
else
	return true



