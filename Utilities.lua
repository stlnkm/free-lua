--*****************************************************************
--**File	:Utilities.lua
--**Author	:stlnkm(Sean Lin)
--**Date  	:2014/11/08
--**Version	:1.0.0
--*****************************************************************

function createEnum( table )
	local enum = {}
	for i,v in ipairs(table) do
		enum[v] = i
	end
	enum.count = #table
	return enum
end

function createClosure( func, ... )
	local arg1 = {...}
	return function ( ... )
		local arg2 = {...}
		local args = {}
		for i,v in ipairs(arg1) do
			table.insert(args, v)
		end
		for i,v in ipairs(arg2) do
			table.insert(args, v)
		end
		return func(unpack(args))
	end
end