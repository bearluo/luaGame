local PopupWindow = require("script.ui.PopupWindow")
local XXLTaskInfo = class("XXLTaskInfo", PopupWindow)

local resPath = "ccbResources/DZXXLRes/image/"
local elementImgs = {"XXL_yuansu1.png", "XXL_yuansu5.png", "XXL_yuansu3.png", "XXL_yuansu2.png", "XXL_yuansu4.png", "XXL_landlord.png"}

function XXLTaskInfo:ctor(pos)
	self.super.ctor(self,"ccbResources/DZXXLRes/ui/node_xxl_guanka_dlg.csb")
	self:setMoveAnimPos(pos)
	
	self.Panel_touch = cc.uiloader:seekCsbNodeByName(self, "Panel_touch")
	self.Panel_touch:setContentSize(display.width,display.height)
	display.setImageClickNoScale(self.Panel_touch, function()
			if self.Image_start_btn:isVisible() then
				return 
			end
			self:dismiss()
		end)


	self.BitmapFontLabel_guanka_num = cc.uiloader:seekCsbNodeByName(self, "BitmapFontLabel_guanka_num")
	self.Node_element_pos = cc.uiloader:seekCsbNodeByName(self, "Node_element_pos")
	self.Panel_element_model = cc.uiloader:seekCsbNodeByName(self, "Panel_element_model"):setVisible(false)
	self.Text_bet_num = cc.uiloader:seekCsbNodeByName(self, "Text_bet_num")
	self.Node_reward_pos = cc.uiloader:seekCsbNodeByName(self, "Node_reward_pos")
	self.Panel_reward_model = cc.uiloader:seekCsbNodeByName(self, "Panel_reward_model"):setVisible(false)
	self.Image_start_btn = cc.uiloader:seekCsbNodeByName(self, "Image_start_btn"):setVisible(false)
	self.Text_1 = cc.uiloader:seekCsbNodeByName(self, "Text_1")

	display.setImageClick(self.Image_start_btn, handler(self, self.onStartClick))


	manager.popup:addPopupComponent(self, 
			handler(self, self.showAnim),
		 	handler(self, self.hideAnim),
		 	handler(self, self.removeAnim))
end

function XXLTaskInfo:setAutoClose()
	self:runAction(cc.Sequence:create(
		cc.DelayTime:create(1.5),
		cc.CallFunc:create(function()
			EventHelp.FrieEventID(EVENT_ID.EVENT_XXL_CHALLENGE_GUANKA,self.mGuanKaID)
			self:dismiss()
		end)
	))
end

function XXLTaskInfo:onStartClick()
	EventHelp.FrieEventID(EVENT_ID.EVENT_XXL_CHALLENGE_GUANKA,self.mGuanKaID)
	self:dismiss()
end

function XXLTaskInfo:showStartBtn()
	self.Image_start_btn:setVisible(true)
end

function XXLTaskInfo:onkeyBackClick()
	print("onkeyBackClick",self.Image_start_btn:isVisible())
	if self.Image_start_btn:isVisible() then
		return true
	end
	return manager.popup:closePopup()
end

function XXLTaskInfo:setConfig(config,mulConfig)
	dump(config,"setConfigsetConfig")
	local nGuanKaID = checkint(config.nGuanKaID)
	local nChip = checkint(config.nChip)
	local guanKaRemoveElement = checktable(config.GuanKaRemoveElement)
	local GuanKaRewardGoods = checktable(config.GuanKaRewardGoods)

	self.taskType = tonumber(config.taskType)
	self.mGuanKaID = nGuanKaID

	self.BitmapFontLabel_guanka_num:setString(string.format("第%d关",nGuanKaID))
	-- self.Text_bet_num:setString(string.format("（单个最少投入%d）",nChip))

	-- dump(guanKaRemoveElement,"guanKaRemoveElement")
	-- dump(GuanKaRewardGoods,"GuanKaRewardGoods")
	self:initElement(guanKaRemoveElement,mulConfig,nChip)
	self:initReward(GuanKaRewardGoods)

	if tonumber(config.taskType) == 1 then
		self.Text_1:setString("单局内消除足够数量目标")
		self.Text_bet_num:setString(string.format("（单局任务，最少投入%d）",nChip))
	else
		self.Text_1:setString("消除足够数量目标")
		self.Text_bet_num:setString(string.format("（单个最少投入%d）",nChip))
	end
end

function XXLTaskInfo:initElement(guanKaRemoveElement,mulConfig,nChip)
	if not mulConfig then
		return 
	end
	self.Node_element_pos:removeAllChildren()

	local addElementView = {}
	for i,v in ipairs(guanKaRemoveElement) do
		local nNum = checkint(v.nNum)
		if nNum > 0 then
			local nType = checkint(v.nType) + 1
			local removeNum = center.task:getXXLGuankaRemoveNumByType(nType)
			local view = self.Panel_element_model:clone():setVisible(true)
			local Image_element_icon = cc.uiloader:seekCsbNodeByName(view, "Image_element_icon")
			local Text_remove_num = cc.uiloader:seekCsbNodeByName(view, "Text_remove_num")
			local Image_complete = cc.uiloader:seekCsbNodeByName(view, "Image_complete")

			local imageName = "XXL_yuansu0.png"
			if center.roomList:isXXLGameModel() then
				imageName = "XXL_yuansu0_n.png"
			end

			if nType == #elementImgs then
				Image_element_icon:loadTexture(resPath .. imageName)
			else
				Image_element_icon:loadTexture(resPath .. elementImgs[nType])
			end

			-- if removeNum >= nNum then
			-- 	Text_remove_num:setString("")
			-- 	Image_complete:setVisible(true)
			-- else
			-- 	Text_remove_num:setString(nNum-removeNum)
			-- 	Image_complete:setVisible(false)
			-- end
			local sumValue = 0
    		local eliminateValue = 0
    		local surplusValue = 0
    		if v.nType == 5 then
    			sumValue = v.nNum
    		else
    			sumValue = v.nNum * nChip
    		end
    		local eliminateValue = center.task:getXXLGuankaRemoveNumByType(v.nType+1)
    		local surplusValue = sumValue - eliminateValue
    		if surplusValue > 0 then
    			local tmp = ""
    			if self.taskType == 2 then
    				tmp = "x"
    			end
    			if v.nType == 5 then
    				Text_remove_num:setString(tmp .. surplusValue)
    			else
    				local num = math.ceil(surplusValue / mulConfig[v.nType])
    				Text_remove_num:setString(tmp .. num)
    			end
    			Image_complete:setVisible(false)
		   	else
		    	Text_remove_num:setString("")
		    	Image_complete:setVisible(true)
		    end

			table.insert(addElementView,view)
		end
	end

	local itemWidth = self.Panel_element_model:getContentSize().width
	local offsetW = 15
	local itemNum = #addElementView
	local startX = -((itemWidth + offsetW) * itemNum - offsetW)/2

	for i,view in ipairs(addElementView) do
		view:addTo(self.Node_element_pos)
		view:setPosition(cc.p(startX+itemWidth/2,0))
		startX = startX + itemWidth + offsetW
	end
end

function XXLTaskInfo:initReward(GuanKaRewardGoods)
	self.Node_reward_pos:removeAllChildren()

	local addElementView = {}

	for i,v in ipairs(GuanKaRewardGoods) do
		local nNum = checkint(v.nNum)
		local nGoodsID = checkint(v.nGoodsID)
		if nNum > 0 then
			local view = self.Panel_reward_model:clone():setVisible(true)
			local Node_reward_icon_pos = cc.uiloader:seekCsbNodeByName(view, "Node_reward_icon_pos")
			local Text_reward_num = cc.uiloader:seekCsbNodeByName(view, "Text_reward_num")
			local goodInfo = center.good:getGoodsInfo(nGoodsID)
			if goodInfo then
				print("nPacketPicID",goodInfo.nPacketPicID)
				self:getGoodsIcon(goodInfo.nPacketPicID,Node_reward_icon_pos)
			end
			Text_reward_num:setString("x"..nNum)
			table.insert(addElementView,view)
		end
	end

	local itemWidth = self.Panel_reward_model:getContentSize().width
	local offsetW = 15
	local itemNum = #addElementView
	local startX = -((itemWidth + offsetW) * itemNum - offsetW)/2

	for i,view in ipairs(addElementView) do
		view:addTo(self.Node_reward_pos)
		view:setPosition(cc.p(startX+itemWidth/2,0))
		startX = startX + itemWidth + offsetW
	end
end

-- 获取的商品图片
function XXLTaskInfo:getGoodsIcon(nPacketPicID, spriteNode)
	local function linster(bSuccess,sprite)
		if tolua.isnull(spriteNode) then
			return
		end
        if bSuccess then
            spriteNode:removeAllChildren()
            sprite:setContentSize(cc.size(150,150))
            sprite:setPosition(cc.p(60,60))
            sprite:addTo(spriteNode)
		end
	end
	filefunc.openPic(nPacketPicID,linster)
end

function XXLTaskInfo:setMoveAnimPos(pos)
	-- dump(pos,"setMoveAnimPos")
	self.mMovePos = pos
end

local PopAnimTag = 6666
function XXLTaskInfo:showAnim()
	self:setVisible(false)
	self:setScale(0.01)

	-- dump(self.mMovePos,"showAnim")
	if self.mMovePos then
		self:setPosition(self.mMovePos)
		local action = cca.seq( {
			cca.show(),
			cca.spawn( {
				cca.scaleTo(0.15, 1),
				cc.MoveTo:create(0.15, cc.p(display.cx, display.cy))
			})
		})
		action:setTag(PopAnimTag)
		self:stopAllActionsByTag(PopAnimTag)
		self:runAction(action)
	else
		local action = cca.seq( {
			cca.show(),
			cca.spawn( {
				cca.scaleTo(0.15, 1),
				cc.MoveTo:create(0.15, cc.p(display.cx, display.cy))
			})
		})
		action:setTag(PopAnimTag)
		self:stopAllActionsByTag(PopAnimTag)
		self:runAction(action)
	end
end

function XXLTaskInfo:hideAnim()
	if self.mMovePos then
		self:setPosition(cc.p(display.cx, display.cy))
		local action = cca.seq({
			cca.spawn( {
				cca.scaleTo(0.1, 0.05),
				cc.MoveTo:create(0.1, self.mMovePos)
			}),
			cca.hide()
		})
		action:setTag(PopAnimTag)
		self:stopAllActionsByTag(PopAnimTag)
		self:runAction(action)
	else
		local action = cca.seq({cca.scaleTo(0.1, 0.05),cca.hide()})
		action:setTag(PopAnimTag)
		self:stopAllActionsByTag(PopAnimTag)
		self:runAction(action)
	end
end

function XXLTaskInfo:removeAnim()
	if self.mMovePos then
		self:setPosition(cc.p(display.cx, display.cy))
		local action = cca.seq({
			cca.spawn( {
				cca.scaleTo(0.1, 0.05),
				cc.MoveTo:create(0.1, self.mMovePos)
			}),
			cca.removeSelf()
		})
		action:setTag(PopAnimTag)
		self:stopAllActionsByTag(PopAnimTag)
		self:runAction(action)
	else
		local action = cca.seq({cca.scaleTo(0.1, 0.05),cca.removeSelf()})
		action:setTag(PopAnimTag)
		self:stopAllActionsByTag(PopAnimTag)
		self:runAction(action)
	end
end

return XXLTaskInfo