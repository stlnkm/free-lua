--*****************************************************************
--**File	:UIPageView.lua
--**Author	:stlnkm(Sean Lin)
--**Date  	:2014/11/08
--**Version	:1.0.0
--*****************************************************************
require("Utilities")

UIPageView = {}

UIPageViewDirection = createEnum{
	"kUIPageViewDirectionHorizontal",
	"kUIPageViewDirectionVertical",
}

local PageView = UIPageView
PageView.__className = "UIPageView"
PageView.__index = PageView

local DEFAULT_PRIORITY = -100
local ANIMATE_PERIOD = 0.5

function PageView.create( parent, viewSize, direction, priority, zorder, tag )
	local proxy = {}
	proxy.__index = proxy
	proxy.__newindex = proxy
	setmetatable(proxy, PageView)

	local container = CCLayer:create()
	container:setTouchEnabled(true)
	container:registerScriptTouchHandler(createClosure(PageView.ccTouch, proxy), false, priority or DEFAULT_PRIORITY, true)

	local scrollview = CCScrollView:create(viewSize, container)
	scrollview:setAnchorPoint(ccp(0, 0))
	scrollview:setContentSize(viewSize)
	if zorder then scrollview:setZOrder(zorder) end
	if tag then scrollview:setTag(tag) end
	parent:addChild(scrollview)

	proxy.parent = parent
	proxy.container = container
	proxy.scrollview = scrollview
	proxy.visible = true
	proxy.offset = {x=0, y=0}
	proxy.touchbegin = {x=0, y=0}
	proxy.pages = {}
	proxy.currPageIdx = -2
	proxy.viewSize = viewSize
	proxy.scale = {x=1, y=1}
	proxy:setDirection(direction or UIPageViewDirection.kUIPageViewDirectionHorizontal)

	return setmetatable({}, proxy)
end

function PageView:setPageInitHandler( handler )
	self.initHandler = handler
end

function PageView:setPageShowCallBack( cbfunc )
	self.onPageShow = cbfunc
end

function PageView:setPageHideCallBack( cbfunc )
	self.onPageHide = cbfunc
end

function PageView:getDirection(  )
	return self.direction
end

function PageView:setDirection( direction )
	if direction == UIPageViewDirection.kUIPageViewDirectionHorizontal then
		self.scrollview:setDirection(kCCScrollViewDirectionHorizontal)
	elseif direction == UIPageViewDirection.kUIPageViewDirectionVertical then
		self.scrollview:setDirection(kCCScrollViewDirectionVertical)
	else
		error(PageView.__className..":invalid direction:"..tostring(direction), 2)
	end
	self.direction = direction
	self:updatePagesPositionWithPos(1)
end

function PageView:getNode(  )
	return self.scrollview
end

function PageView:getParent(  )
	return self.parent
end

function PageView:setVisible( visible )
	if visible ~= self.visible then
		self.visible = visible
		self.scrollview:setVisible(visible)
	end
end

function PageView:isVisible(  )
	return self.visible
end

function PageView:setPosition( position )
	self.scrollview:setPosition(position)
end

function PageView:getPosition(  )
	return self.scrollview:getPosition()
end

function PageView:getScale(  )
	return self.scale.x, self.scale.y
end

function PageView:setScale( sx, sy )
	self.scale.x = sx or self.scale.x
	self.scale.y = sy or self.scale.y
	if sx ~= sy then
		if sx ~= nil then self.scrollview:setScaleX(sx) end
		if sy ~= nil then self.scrollview:setScaleY(sy)	end
	else self.scrollview:setScale(sx) end
end

function PageView:getPageNum(  )
	return #self.pages
end

function PageView:getCurrPageIdx(  )
	return self.currPageIdx
end

function PageView:getViewRect(  )
	local screenPos = self.scrollview:convertToWorldSpace(ccp(0, 0))
	local scaleX = self.scale.x
	local scaleY = self.scale.y
	-- local parent = self.scrollview:getParent()
	-- while parent ~= nil do
	-- 	scaleY = scaleX * parent:getScaleX()
	-- 	scaleY = scaleY * parent:getScaleY()
	-- 	parent = parent:getParent()
	-- end
	if scaleX < 0 then
		screenPos.x = screenPos.x + self.viewSize.width * scaleX
		scaleX = -scaleX
	end
	if scaleY < 0 then
		screenPos.y = screenPos.y + self.viewSize.height * scaleY
		scaleY = -scaleY
	end
	return CCRectMake(screenPos.x, screenPos.y, self.viewSize.width*scaleX, self.viewSize.height*scaleY)
end

function PageView:removeFromParentAndCleanup( cleanup )
	self.scrollview:removeFromParentAndCleanup(cleanup)
end

function PageView:destroy(  )
	self.scrollview:removeFromParentAndCleanup(cleanup)
	self.container = nil
	self.parent = nil
	self.viewSize = nil
	self.pages = nil
end

function PageView:updatePagesPositionWithPos( pos )
	if self.direction == UIPageViewDirection.kUIPageViewDirectionHorizontal then
		for i = pos,#self.pages do
			local pt = ccp(self.viewSize.width*(i-1), 0)
			self.pages[i]:setPosition(pt)
		end
		local size = CCSizeMake(self.viewSize.width*#self.pages, self.viewSize.height)
		self.scrollview:setContentSize(size)
	elseif self.direction == UIPageViewDirection.kUIPageViewDirectionVertical then
		for i = 1,math.min(pos, #self.pages) do
			local pt = ccp(0, self.viewSize.height*(#self.pages-i))
			self.pages[i]:setPosition(pt)
		end
		local size = CCSizeMake(self.viewSize.width, self.viewSize.height*#self.pages)
		self.scrollview:setContentSize(size)
	else
		error(PageView.__className..":invalid direction:"..tostring(direction), 2)
	end
end

function PageView:insertPage( idx, page )
	assert(idx >= 1 and idx <= #self.pages+1, 2)
	page = page or CCNode:create()
	page:setAnchorPoint(ccp(0, 0))
	page:setContentSize(self.viewSize)
	self.container:addChild(page)
	table.insert(self.pages, idx, page)
	self:updatePagesPositionWithPos(idx)
	return page
end

function PageView:addPage( page )
	return self:insertPage(#self.pages+1, page)
end

function PageView:removePage( idx )
	assert(idx >= 1 and idx <= #self.pages)
	if idx >= self.currPageIdx-1 and idx <= self.currPageIdx+1 then
		self:showPage(idx+1)
	end
	local page = self.pages[idx]
	page:removeFromParentAndCleanup(true)
	table.remove(self.pages, idx)
	self:updatePagesPositionWithPos(idx)
end

function PageView:clearAllPages(  )
	if self.onPageHide ~= nil then
		self.onPageHide(self.currPageIdx)
	end
	for i = 1, #self.pages do
		local page = self.pages[i]
		page:removeFromParentAndCleanup(true)
	end
	self.pages = {}
	self.currPageIdx = -2
	self.offset.x = 0
	self.offset.y = 0
	self:updatePagesPositionWithPos(1)
end

function PageView:calcPageOffset( idx )
	if self.direction == UIPageViewDirection.kUIPageViewDirectionHorizontal then
		return ccp(-self.viewSize.width*(idx-1), 0)
	elseif self.direction == UIPageViewDirection.kUIPageViewDirectionVertical then
		return ccp(0, -self.viewSize.height*(#self.pages-idx))
	else
		error(PageView.__className..":invalid direction:"..tostring(self.direction), 2)
	end
end

function PageView:showPage( idx, animated )
	assert(idx >= 1 and idx <= #self.pages, 2)
	local tps --time per step
	if self.initHandler == nil then tps = math.min(ANIMATE_PERIOD, 0.1*math.abs(idx-self.currPageIdx))
	elseif idx == self.currPageIdx then tps = 0.1
	else tps = math.min(ANIMATE_PERIOD/math.min(10, math.abs(idx-self.currPageIdx)), 0.1) end
	print(PageView.__className..":show page tps:", tps)

	local function _showPage( nextidx, cbComplete )
		if nextidx ~= self.currPageIdx and self.initHandler ~= nil then
			local l = {self.currPageIdx-2, self.currPageIdx-1, self.currPageIdx, self.currPageIdx+1, self.currPageIdx+2}
			local r = {nextidx-2, nextidx-1, nextidx, nextidx+1, nextidx+2}
			for i = 1, 5 do
				for j = 1, 5 do
					if l[i] == r[j] then l[i],r[j] = nil,nil; break end
				end
			end
			for i = 1, 5 do
				if l[i] ~= nil and l[i] >= 1 and l[i] <= #self.pages then
					local page = self.pages[l[i]]
					page:removeAllChildrenWithCleanup(true)
				end
			end
			for i = 1, 5 do
				if r[i] ~= nil and r[i] >= 1 and r[i] <= #self.pages then
					local page = self.pages[r[i]]
					self.initHandler(r[i], page)
				end
			end
		end
		local offset = self:calcPageOffset(nextidx)
		-- print("page view page offset:", nextidx, offset.x, offset.y)
		if cbComplete ~= nil then
			self.scrollview:setContentOffsetInDuration(offset, tps)
			local delay = CCDelayTime:create(tps)
			local callback = CCCallFunc:create(cbComplete)
			self.scrollview:runAction(CCSequence:createWithTwoActions(delay, callback))
		else
			self.scrollview:setContentOffset(offset)
		end
		self.currPageIdx = nextidx
		if self.direction == UIPageViewDirection.kUIPageViewDirectionHorizontal then
			self.offset.x = offset.x
		elseif self.direction == UIPageViewDirection.kUIPageViewDirectionVertical then
			self.offset.y = offset.y
		end
	end --_showPage

	local diffPage = idx ~= self.currPageIdx
	if self.onPageHide ~= nil and diffPage then
		print(PageView.__className..":will hide page:", self.currPageIdx)
		self.onPageHide(self.currPageIdx)
	end
	animated = animated or false
	if animated then
		local step
		if self.initHandler == nil then step = idx - self.currPageIdx
		elseif idx == self.currPageIdx then step = 0
		elseif idx > self.currPageIdx then step = idx-self.currPageIdx > 10 and 10 or 1
		elseif idx < self.currPageIdx then step = idx-self.currPageIdx < -10 and -10 or -1 end
		print(PageView.__className..":show page step:", step)

		local function onShowOnePageCompleted(  )
			if self.currPageIdx == idx then
				self.animated = false
				-- local offset = self:calcPageOffset(idx)
				-- self.scrollview:setContentOffset(offset)
				if self.onPageShow ~= nil and diffPage then
					print(PageView.__className..":show page with animation:", idx)
					self.onPageShow(self.currPageIdx)
				end
			else
				local nextPageIdx = self.currPageIdx+step
				if step > 0 then nextPageIdx = math.min(idx, nextPageIdx)
				elseif step < 0 then nextPageIdx = math.max(idx, nextPageIdx) end
				_showPage(nextPageIdx, onShowOnePageCompleted)
			end
		end --onShowOnePageCompleted

		local nextPageIdx = self.currPageIdx+step
		if step > 0 then nextPageIdx = math.min(idx, nextPageIdx)
		elseif step < 0 then nextPageIdx = math.max(idx, nextPageIdx) end
		self.animated = true
		_showPage(nextPageIdx, onShowOnePageCompleted)
	else
		_showPage(idx)
		if self.onPageShow ~= nil and diffPage then
			print(PageView.__className..":show page without animation:", idx)
			self.onPageShow(self.currPageIdx)
		end
	end
end

function PageView:ccTouch( event, x, y )
	if event == "began" then
		-- print(PageView.__className.."touch began")
		return self:ccTouchBegan(x, y)
	elseif event == "moved" then
		-- print(PageView.__className.."touch moved")
		self:ccTouchMoved(x, y)
	elseif event == "ended" then
		-- print(PageView.__className.."touch ended")
		self:ccTouchEnded(x, y)
	elseif event == "cancelled" then
		-- print(PageView.__className.."touch cancelled")
		self:ccTouchCancelled(x, y)
	end
end

function PageView:ccTouchBegan( x, y )
	if #self.pages == 0 then
		return false
	end
	if not self.visible then
		return false
	end
	if self.animated then
		print(PageView.__className..":touch began:animated")
		return false
	end
	if not self.parent:isVisible() then
		return false
	end
	local ancestor = self.parent:getParent()
	while ancestor do
		if not ancestor:isVisible() then
			return false
		end
		ancestor = ancestor:getParent()
	end
	-- local boundbox = self.scrollview:boundingBox()
	-- if not boundbox:containsPoint(ccp(x, y)) then
	-- 	return false
	-- end
	local frameRect = self:getViewRect()
	if not frameRect:containsPoint(ccp(x, y)) then
		return false
	end
	self.touchbegin.x = x
	self.touchbegin.y = y
	self.touched = true
	-- print(PageView.__className.."touch began:", x, y)
	return true
end

function PageView:calcPointOffset( begpt, endpt )
	-- print(PageView.__className..":touch points:", begpt.x, begpt.y, endpt.x, endpt.y)
	if self.direction == UIPageViewDirection.kUIPageViewDirectionHorizontal then
		return {x=endpt.x-begpt.x, y=0}
	elseif self.direction == UIPageViewDirection.kUIPageViewDirectionVertical then
		return {x=0, y=endpt.y-begpt.y}
	else
		error(PageView.__className..":invalid direction:"..tostring(self.direction), 2)
	end
end

function PageView:checkOffsetOf( offset )
	if self.direction == UIPageViewDirection.kUIPageViewDirectionHorizontal then
		return not (self.currPageIdx == 1 and offset.x >= self.viewSize.width*self.scale.x/2) and
			not (self.currPageIdx == #self.pages and offset.x <= -self.viewSize.width*self.scale.x/2)
	elseif self.direction == UIPageViewDirection.kUIPageViewDirectionVertical then
		return not (self.currPageIdx == 1 and offset.y <= -self.viewSize.height*self.scale.y/2) and
			not (self.currPageIdx == #self.pages and offset.y >= self.viewSize.height*self.scale.y/2)
	else
		error(PageView.__className..":invalid direction:"..tostring(direction), 2)
	end
end

function PageView:ccTouchMoved( x, y )
	if not self.touched then return end
	local frameRect = self:getViewRect()
	if not frameRect:containsPoint(ccp(x, y)) then
		return
	end
	local offset = self:calcPointOffset(self.touchbegin, {x=x, y=y})
	if self:checkOffsetOf(offset) then
		offset.x = self.offset.x + offset.x
		offset.y = self.offset.y + offset.y
		self.scrollview:setContentOffset(ccp(offset.x, offset.y))
	end
	-- print(PageView.__className..":touch move:", x, y)
end

function PageView:ccTouchEnded( x, y )
	if not self.touched then return end
	-- print(PageView.__className..":touch end:", x, y)
	local offset = self:calcPointOffset(self.touchbegin, {x=x, y=y})
	local nextPageIdx = self.currPageIdx
	if self.direction == UIPageViewDirection.kUIPageViewDirectionHorizontal then
		if offset.x >= self.viewSize.width*self.scale.x/2 then
			nextPageIdx = nextPageIdx - 1
		elseif offset.x <= -self.viewSize.width*self.scale.x/2 then
			nextPageIdx = nextPageIdx + 1
		end
	elseif self.direction == UIPageViewDirection.kUIPageViewDirectionVertical then
		if offset.y >= self.viewSize.height*self.scale.y/2 then
			nextPageIdx = nextPageIdx + 1
		elseif offset.y <= -self.viewSize.height*self.scale.y/2 then
			nextPageIdx = nextPageIdx - 1
		end
	else
		error(PageView.__className..":invalid direction:"..tostring(direction), 2)
	end
	nextPageIdx = math.max(1, math.min(#self.pages, nextPageIdx))
	self:showPage(nextPageIdx, true)
	self.touched = false
end

function PageView:ccTouchCancelled( x, y )
	if not self.touched then return end
	print(PageView.__className..":touch cancelled:", self.currPageIdx, x, y)
	self:showPage(self.currPageIdx, true)
	self.touched = false
end

function testUIPageView( parent )
	local pv1, pv2
	local function initPage( idx, page )
		print("init page view:"..idx)
		local r = math.random(0, 255)
		local g = math.random(0, 255)
		local b = math.random(0, 255)
		local layer = CCLayerColor:create(ccc4(r, g, b, 255))
		layer:setContentSize(page:getContentSize())
		page:addChild(layer)
		local label = CCLabelTTF:create("PAGE "..idx, "宋体", 32)
		local size = page:getContentSize()
		label:setPosition(ccp(size.width/2, size.height/2))
		page:addChild(label)
	end

	local function onPageHide( idx )
		print("page hide:", idx)
	end

	local function onPageShow( idx )
		print("page show:", idx)
		-- if idx == 70 then
		-- 	pv2:showPage(1, true)
		-- end
	end

	math.randomseed(os.time())
	local function test1(  )
		pv1 = UIPageView.create(parent, CCSizeMake(200, 200), UIPageViewDirection.kUIPageViewDirectionVertical)
		pv1:setPosition(ccp(100, 100))
		pv1:setPageInitHandler(initPage)
		pv1:setPageShowCallBack(onPageShow)
		pv1:setPageHideCallBack(onPageHide)
		for i = 1, 200 do
			pv1:addPage()
		end
		pv1:setScale(0.5, 0.5)
		pv1:removePage(5)
		pv1:showPage(69)
	end
	local function test2(  )
		pv2 = UIPageView.create(parent, CCSizeMake(200, 200))
		pv2:setPosition(ccp(300, 100))
		pv2:setPageShowCallBack(onPageShow)
		pv2:setPageHideCallBack(onPageHide)
		for i = 1, 200 do
	    	local page = pv2:addPage()
	    	initPage(i, page)
		end
		pv2:setScale(0.5, 0.5)
		pv2:removePage(5)
		pv2:showPage(69, true)
	end
	test1()
	test2()
end

return UIPageView