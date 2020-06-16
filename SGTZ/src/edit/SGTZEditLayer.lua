local FruitsItem = import("..view.FruitsItem")
local ColumnItem = import("..view.ColumnItem")
local SensitiveWord = require("script.public.SensitiveWord")
local MAX_ROTATION,MIN_ROTATION = 55,-55


local SGTZEditLayer = class("SGTZEditLayer", function()
	local node = cc.uiloader:load("ccbResources/SGTZRes/ui/SGTZEditLayer.csb") 
    node:setAnchorPoint(cc.p(0.5,0.5))

    -- 高度比例固定 宽度调整
    local scale = display.height / CONFIG_SCREEN_HEIGHT
    node:setContentSize(cc.size(CONFIG_SCREEN_WIDTH * scale, display.height))
	node:setPosition(display.cx,display.cy)


    ccui.Helper:doLayout(node)
    return node
end)

function SGTZEditLayer:ctor()
	self:initTB()

	self.Panel_edit = cc.uiloader:seekCsbNodeByName(self, "Panel_edit")
	-- self.Panel_edit:setTouchEnabled(false)
	self.Image_start = cc.uiloader:seekCsbNodeByName(self, "Image_start")
	self.Slider_angle = cc.uiloader:seekCsbNodeByName(self, "Slider_angle")
	self.Image_add_column = cc.uiloader:seekCsbNodeByName(self, "Image_add_column")
	self.Image_add_fruits = cc.uiloader:seekCsbNodeByName(self, "Image_add_fruits")
	self.Image_cannel = cc.uiloader:seekCsbNodeByName(self, "Image_cannel")
	self.CheckBox_del = cc.uiloader:seekCsbNodeByName(self, "CheckBox_del")
	self.Image_save = cc.uiloader:seekCsbNodeByName(self, "Image_save")


	self.Slider_angle_txt = cc.uiloader:seekCsbNodeByName(self.Slider_angle, "Text_angle")
	self.Slider_angle:addEventListener(handler(self, self.updateAngle))

	display.setImageClick(self.Image_add_fruits,handler(self,self.addFruits))
	display.setImageClick(self.Image_add_column,handler(self,self.addColumn))
	display.setImageClick(self.Image_cannel,handler(self,self.Func_onClickBtn_exit))
	display.setImageClick(self.Image_start,handler(self,self.onSimulate))
	display.setImageClick(self.Image_save,handler(self,self.onSave))
end

function SGTZEditLayer:initTB()
	self.mRecordTab = {} -- 模拟碰撞记录数据
	self.mColumnTab = {} -- 碰撞点
	self.mColumnView = {} -- 碰撞ui界面
	self.mFruitsTab = {} -- 水果
	self.mFruitsView = {} -- 水果
	self.mRewardTab = {}-- 奖励
    self.mRotation = 90 --炮台旋转角度
	self.mVelocityLen = 1500
	self.mVelocity = cc.p(0,0)
    self.mBallX,self.mBallY = 0,0
    self.mLineNum = 9--压住线条数
    self.mSingleLineNum = 500 -- 单线下注额度
    self.mFruitCardUseFlag = 0 -- 水果免费卡道具使用标记
end
function SGTZEditLayer:onEnter()
	self:updateAngle()
end

function SGTZEditLayer:updateAngle()
	local percent = self.Slider_angle:getPercent()
	local maxRotation,minRotation = 90 + MAX_ROTATION, 90 + MIN_ROTATION
	self.mRotation = minRotation + percent * (maxRotation - minRotation) / 100

	self.Slider_angle_txt:setString("角度:" .. tostring(self.mRotation - 90))

	if self:getParent() then
		self:getParent():setPaoRotation(90 - self.mRotation)
	end
end

function SGTZEditLayer:setEditSimulateFunc(func)
	self.mEditSimulateFunc = func
end

function SGTZEditLayer:getMapData()
	local map = {}
	for i,v in ipairs(self.mFruitsView) do
		table.insert(map,{"Fruits",cc.p(v:getPosition())})
	end
	for i,v in ipairs(self.mColumnView) do
		table.insert(map,{"Column",cc.p(v:getPosition())})
	end
	return map
end

function SGTZEditLayer:loadMap(tab)
	for i,v in ipairs(tab) do
		if v[1]=="angle" then
			self.mRotation = 90 - v[2]
		elseif v[1] == "Column" then
			local item = self:addColumn()
			item:setPosition(v[2])
		end
	end

end

function SGTZEditLayer:onSimulate()
	if self.mEditSimulateFunc then
		-- self:loadMap(SGTZEditLayer.testTab)
		local map = self:getMapData()
		self.mEditSimulateFunc(map,self.mRotation)
	end
end
	
function SGTZEditLayer:newDragTouch(size,view)
	local node = display.newNode()
	node:setContentSize(size)
	node:setTouchEnabled(true)
	node:setPosition(-size.width/2, -size.height/2)
	node:addTo(view)
	-- node:addNodeEventListener(cc.NODE_TOUCH_EVENT, function (event)
	-- 			print("111111111")
	--    --      	local boundingBox = self.target_:getCascadeBoundingBox()

	-- 			-- if "began" == event.name and not cc.rectContainsPoint(boundingBox, cc.p(event.x, event.y)) then
	-- 			-- 	printInfo("DraggableProtocol - touch didn't in viewRect")
	-- 			-- 	return false
	-- 			-- end

	-- 			if "began" == event.name then
	-- 				return true
	-- 			elseif "moved" == event.name then
	-- 				local posX, posY = view:getPosition()
	-- 				view:setPosition(
	-- 					posX + event.x - event.prevX,
	-- 					posY + event.y - event.prevY)
	-- 			elseif "ended" == event.name then
	-- 			end
	--     	end)

	-- 判断父节点是否显示
	local function checkAllParntShow(root)
		local rootParent = root:getParent()
		if rootParent then
			if rootParent:isVisible() then
				local isShow = checkAllParntShow(rootParent)
				if isShow then
					return isShow
				end
			else
				return false
			end
		else
			return true
		end
	end
	local function onTouchBegan(touch, event)
        local target = event:getCurrentTarget()

        if not target:isVisible() or not checkAllParntShow(target) then
            return false
        end   

        if self.CheckBox_del:isSelected() and self:removeObj(view) then
        	return false
        end
        	

        local locationInNode = target:convertToNodeSpace(touch:getLocation())
        local s = target:getContentSize()
        local rect = cc.rect(0, 0, s.width, s.height)
        
        if cc.rectContainsPoint(rect, locationInNode) then
            return true
        end
        return false
    end

    local function onTouchMoved(touch, event)
		local posX, posY = view:getPosition()
		local curv = touch:getLocation()
		local prev = touch:getPreviousLocation()
		if prev then
			view:setPosition(
				posX + curv.x - prev.x,
				posY + curv.y - prev.y)
		end
    end

    local function onTouchEnded(touch, event)
    end
    local listener1 = cc.EventListenerTouchOneByOne:create()
    listener1:setSwallowTouches(true)
    listener1:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener1:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener1:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener1, node)
end

function SGTZEditLayer:addFruits()
	local fruitsItem = FruitsItem.new()
	local size = fruitsItem:getCollisionSize()
	self:newDragTouch(size,fruitsItem)
	fruitsItem:setPosition(display.cx, display.cy)
	fruitsItem:addTo(self.Panel_edit)
	table.insert(self.mFruitsView,fruitsItem)
	return fruitsItem
end


function SGTZEditLayer:addColumn()
	local columnItem = ColumnItem.new()
	local size = columnItem:getCollisionSize()
	self:newDragTouch(size,columnItem)
	columnItem:setPosition(display.cx, display.cy)
	columnItem:addTo(self.Panel_edit)
	table.insert(self.mColumnView,columnItem)
	return columnItem
end

function SGTZEditLayer:removeObj(obj)
	for i,v in ipairs(self.mFruitsView) do
		if v == obj then
			table.remove(self.mFruitsView,i)
			v:removeSelf()
			return true
		end
	end
	for i,v in ipairs(self.mColumnView) do
		if v == obj then
			table.remove(self.mColumnView,i)
			v:removeSelf()
			return true
		end
	end
end

function SGTZEditLayer:Func_onClickBtn_exit()
	self:getParent():Func_onClickBtn_exit()
end


function SGTZEditLayer:onSave()
	local map = self:getMapData()
	local path = cc.FileUtils:getInstance():getWritablePath().."SGTZ_" .. os.time() .. ".lua"
	
	io.writefile(path, SensitiveWord:serialize(map))
end

return SGTZEditLayer