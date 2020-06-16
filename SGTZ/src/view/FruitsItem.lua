local GoodsData = require("game.SGTZ.Base.GoodsData")
local Def = require("game.SGTZ.Base.Def")


local FruitsItem = class("FruitsItem", function(countdown)
	local node
	if checkint(countdown) == Def.Big_Fruits_collision_count then
		node = cc.uiloader:load("ccbResources/SGTZRes/ui/item/FruitsItemBig.csb")
	else
		node = cc.uiloader:load("ccbResources/SGTZRes/ui/item/FruitsItemSmall.csb")
	end
	return node
end)

function FruitsItem:ctor(countdown)
	self.mFruitsItem = cc.uiloader:seekCsbNodeByName(self, "FruitsItem")
	self.Image_animal_icon = cc.uiloader:seekCsbNodeByName(self.mFruitsItem, "Image_animal_icon")
	self.Image_animal_icon_bg = cc.uiloader:seekCsbNodeByName(self.mFruitsItem, "Image_animal_icon_bg")

	self.Image_bubble = cc.uiloader:seekCsbNodeByName(self, "Image_bubble")
	self.BitmapFontLabel_jiangchi = cc.uiloader:seekCsbNodeByName(self.mFruitsItem, "BitmapFontLabel_jiangchi")
	self.BitmapFontLabel_jiangchi:setLocalZOrder(4)

	self.mAnim = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/item/FruitsItem.csb")
	self.mFruitsItem:runAction(self.mAnim)

	self.mCountdown = checkint(countdown)
	self.mIsBigFruits = self.mCountdown == Def.Big_Fruits_collision_count
	self.mCount = 0
	self.mFruitsId = 1
	
	local Node_liang = cc.uiloader:seekCsbNodeByName(self, "Node_liang")
	self.mCountdownView = {}
	for i=1,self.mCountdown do
		self.mCountdownView[i] = cc.uiloader:seekCsbNodeByName(Node_liang, "Image_"..i)
	end
	self.mGaoBeiShuAnimNode = {}

	self:reset()
end

function FruitsItem:reset()
	self.mCount = 0
	self.mIsCanGetFruitsReward = true
    self.mAnim:gotoFrameAndPause(0)
    self.BitmapFontLabel_jiangchi:setVisible(false)
	self.Image_animal_icon:setVisible(true)
	self.Image_animal_icon_bg:setVisible(false)
	self.Image_bubble:setVisible(true)
    for i=1,self.mCountdown do
		if self.mCountdownView[i] then
			self.mCountdownView[i]:setVisible(false)
		end
	end
	self:removeGaoBeiShuiGuoAnim()
end

function FruitsItem:openBox()
	if not self.mOpenBoxAnimNode then
		self.mOpenBoxAnimNode = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/tx_ddz_baoguo_baozha.csb")
		self.mOpenBoxAnim = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/tx_ddz_baoguo_baozha.csb")
		self.mOpenBoxAnimNode:runAction(self.mOpenBoxAnim)
		self.mOpenBoxAnimNode:addTo(self)
		if self.mIsBigFruits then
			self.mOpenBoxAnimNode:scale(1.13)
		end
	end
    self.mAnim:gotoFrameAndPause(self.mFruitsId)
    self.mCloseBoxAnimNode:setVisible(false)
	self.Image_animal_icon:setVisible(false)
    self.BitmapFontLabel_jiangchi:setVisible(false)
	self.mOpenBoxAnimNode:setVisible(true)

	local SG_jl_7caomei_3 = cc.uiloader:seekCsbNodeByName(self.mOpenBoxAnimNode, "SG_jl_7caomei_3")
	SG_jl_7caomei_3:setTexture(self.Image_animal_icon:getTexture())
	self.mOpenBoxAnim:gotoFrameAndPlay(0,false)
	self.mOpenBoxAnim:setLastFrameCallFunc(handler(self, self.onOpenBoxAnimEndEvent))
end

function FruitsItem:onOpenBoxAnimEndEvent()
	self.Image_animal_icon:setVisible(true)
    self.BitmapFontLabel_jiangchi:setVisible(true)
	self.mOpenBoxAnimNode:setVisible(false)
end

function FruitsItem:closeBox()
	if not self.mCloseBoxAnimNode then
		self.mCloseBoxAnimNode = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/tx_ddz_baoguo_chuxian.csb")
		self.mCloseBoxAnim = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/tx_ddz_baoguo_chuxian.csb")
		self.mCloseBoxAnimNode:runAction(self.mCloseBoxAnim)
		self.mCloseBoxAnimNode:addTo(self)
		self.mCloseBoxAnimNode:setPositionY(10)
		if self.mIsBigFruits then
			self.mCloseBoxAnimNode:scale(1.13)
		end
	end
    self.mAnim:gotoFrameAndPause(self.mFruitsId)
	self.Image_animal_icon:setVisible(false)
    self.BitmapFontLabel_jiangchi:setVisible(false)
	self.mCloseBoxAnimNode:setVisible(true)

	local SG_jl_7caomei_17 = cc.uiloader:seekCsbNodeByName(self.mCloseBoxAnimNode, "SG_jl_7caomei_17")
	SG_jl_7caomei_17:setTexture(self.Image_animal_icon:getTexture())
	self.mCloseBoxAnim:gotoFrameAndPlay(0,false)
	-- self.mCloseBoxAnim:setLastFrameCallFunc(handler(self, self.onOpenBoxAnimEndEvent))
end

function FruitsItem:setAnimalIcon(id,num)
	print("setAnimalIcon",id)
	self.mFruitsId = id
	num = checkint(num)
	-- self.Image_animal_icon:loadTexture(path)

    if GoodsData.isFreeFruits(id) then
    	self.BitmapFontLabel_jiangchi:setString("免费" .. tostring(num) .. "次")
    else
    	self.BitmapFontLabel_jiangchi:setString(tostring(num/10).."倍")
    end

    if self.mFruitsId > 3 then
    	self:addGaoBeiShuiGuoAnim()
    end
end

function FruitsItem:onCollision(callback)
	print("FruitsItem onCollision",self.mCount)
	self.mCount = self.mCount + 1
	if self.mCountdownView[self.mCount] then
		self.mCountdownView[self.mCount]:setVisible(true)
	end
	if self.mCountdown == self.mCount then
		self.mIsCanGetFruitsReward = false
		self.Image_animal_icon:setVisible(false)
		self.Image_animal_icon_bg:setVisible(true)
		self:playCollisionAnim()
		if type(callback) == "function" then
			self:performWithDelay(function()
					callback()
				end, 0.9)
		end
	else
		self:playCollisionAnim()
	end
end

function FruitsItem:isComplete()
	return self.mCountdown == self.mCount
end

function FruitsItem:isCanGetFruitsReward()
	return self.mIsCanGetFruitsReward
end

function FruitsItem:getFruitsId()
	return self.mFruitsId
end

function FruitsItem:getAnimalIconToWorldSpace()
	return self.Image_animal_icon:convertToWorldSpaceAR(cc.p(0,-20))
end

function FruitsItem:getCollisionSize()
	return self.Image_animal_icon:getContentSize()
end

function FruitsItem:playCollisionAnim()
	if not self.mCollisionAnimNode then
		self.mCollisionAnimNode = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/tx_ddz_baoguo_zhuangji.csb")
		self.mCollisionAnim = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/tx_ddz_baoguo_zhuangji.csb")
		self.mCollisionAnimNode:runAction(self.mCollisionAnim)
		self.mCollisionAnimNode:addTo(self)
		if self.mIsBigFruits then
			self.mCollisionAnimNode:scale(1.13)
		end
	end
	self.mCollisionAnimNode:setVisible(true)

	-- local SG_sg1_11 = cc.uiloader:seekCsbNodeByName(self.mCollisionAnimNode, "SG_sg1_11")
	-- local path = GoodsData.getFruitsImagePathByID(self.mFruitsId)
	-- if path then
	-- 	SG_sg1_11:setTexture(path)
	-- end
	self.mCollisionAnim:gotoFrameAndPlay(0,false)
	self.mCollisionAnim:setLastFrameCallFunc(handler(self, self.onAnimEndEvent))
end

function FruitsItem:onAnimEndEvent()
	self.mCollisionAnimNode:setVisible(false)
end

function FruitsItem:addGaoBeiShuiGuoAnim()
	local animNode = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/Node_sgdz_gaobeishuiguo_bg.csb")
	local anim = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_gaobeishuiguo_bg.csb")
	animNode:runAction(anim)
	animNode:setLocalZOrder(-1)
	animNode:addTo(self)
	anim:gotoFrameAndPlay(0,true)
	table.insert(self.mGaoBeiShuAnimNode,animNode)

	local animNode = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/Node_sgdz_gaobeishuiguo_xin.csb")
	local anim = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_gaobeishuiguo_xin.csb")
	animNode:runAction(anim)
	animNode:setLocalZOrder(1000)
	animNode:addTo(self)
	anim:gotoFrameAndPlay(0,true)
	table.insert(self.mGaoBeiShuAnimNode,animNode)
end

function FruitsItem:removeGaoBeiShuiGuoAnim()
	for i,v in ipairs(self.mGaoBeiShuAnimNode) do
		v:removeSelf()
	end
	self.mGaoBeiShuAnimNode = {}
end
	

return FruitsItem