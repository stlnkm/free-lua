--*****************************************************************
--**File	:PriorityQueue.lua
--**Author	:stlnkm(Sean Lin)
--**Date  	:2014/11/11
--**Version	:1.0.0
--*****************************************************************

require("Heap")

PriorityQueue = {}
PriorityQueue.__index = PriorityQueue
local DATA,LEFT,RIGHT = 1,2,3

function PriorityQueue.new( cmp, data )
	local obj = {}
	setmetatable(obj, PriorityQueue)

	obj.heap = Heap.new(cmp, data)
	return obj
end

function PriorityQueue:enqueue( value )
	self.heap:insert(value)
end

function PriorityQueue:dequeue(  )
	return self.heap:remove(1)
end