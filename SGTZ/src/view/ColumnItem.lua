local ColumnItem = class("ColumnItem", function()
	local node = cc.uiloader:load("ccbResources/SGTZRes/ui/item/ColumnItem.csb")
	return node
end)

function ColumnItem:ctor(goodsType)
	self.Image_animal_icon = cc.uiloader:seekCsbNodeByName(self, "Image_animal_icon")
	self.mGoodsType = goodsType
	if self.mGoodsType == GOODSTYPE_TREASURE then
		self.Image_animal_icon:setTexture("ccbResources/SGTZRes/image/icon/SG_fuka.png")
	end
	-- self.mAnim = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/item/ColumnItem.csb")
	-- self:runAction(self.mAnim)
end

function ColumnItem:onCollision(callback)
	self:playCollisionAnim()
	if type(callback) == "function" then
		callback()
	end
end

function ColumnItem:getCollisionSize()
	return self.Image_animal_icon:getContentSize()
end

function ColumnItem:playCollisionAnim()
	if not self.mCollisionAnimNode then
		self.mCollisionAnimNode = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/Node_sgdz_jinbipengzhuang.csb")
		self.mCollisionAnim = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_jinbipengzhuang.csb")
		self.mCollisionAnimNode:runAction(self.mCollisionAnim)
		self.mCollisionAnimNode:addTo(self)
		local Image_animal_icon = cc.uiloader:seekCsbNodeByName(self.mCollisionAnimNode, "Image_animal_icon")
		if self.mGoodsType == GOODSTYPE_TREASURE then
			Image_animal_icon:setTexture("ccbResources/SGTZRes/image/icon/SG_fuka.png")
		end
		self.Image_animal_icon:setVisible(false)
	end
	self.mCollisionAnim:gotoFrameAndPlay(0,false)
end

return ColumnItem