local PopupWindow = require("script.ui.PopupWindow")
local XXLTaskPass = class("XXLTaskPass", PopupWindow)

local resPath = "ccbResources/DZXXLRes/image/"
local elementImgs = {"XXL_yuansu1.png", "XXL_yuansu5.png", "XXL_yuansu3.png", "XXL_yuansu2.png", "XXL_yuansu4.png", "XXL_landlord.png"}

function XXLTaskPass:ctor()
	self.super.ctor(self,"ccbResources/DZXXLRes/ui/node_xxl_guanka_pass_dlg.csb")

	local actionTimeLine = cc.uiloader:csbAniload("ccbResources/DZXXLRes/ui/node_xxl_guanka_pass_dlg.csb")
	-- actionTimeLine:gotoFrameAndPlay(0, false)
	actionTimeLine:play("animation0",false);
	actionTimeLine:setAnimationEndCallFunc("animation0",function()
			actionTimeLine:play("animation1",true);
		end)
	self:runAction(actionTimeLine)

	self.Node_reward_pos = cc.uiloader:seekCsbNodeByName(self, "Node_reward_pos")
	self.Panel_reward_model = cc.uiloader:seekCsbNodeByName(self, "Panel_reward_model"):setVisible(false)
	self.Image_start_btn = cc.uiloader:seekCsbNodeByName(self, "Image_start_btn")

	display.setImageClick(self.Image_start_btn, handler(self, self.onStartClick))
end

function XXLTaskPass:onStartClick()
	center.task:sendXXLGuankaReward(self.mGuanKaID)
	self:dismiss()
end

function XXLTaskPass:setAutoClose()
	self:runAction(cc.Sequence:create(
			cc.DelayTime:create(1.5),
			cc.CallFunc:create(function()
				center.task:sendXXLGuankaReward(self.mGuanKaID)
				self:dismiss()
			end)
		))
end

function XXLTaskPass:setConfig(config)
	local nGuanKaID = checkint(config.nGuanKaID)
	local GuanKaRewardGoods = checktable(config.GuanKaRewardGoods)

	self.mGuanKaID = nGuanKaID

	dump(GuanKaRewardGoods,"GuanKaRewardGoods")
	self:initReward(GuanKaRewardGoods)
end

function XXLTaskPass:initReward(GuanKaRewardGoods)
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
function XXLTaskPass:getGoodsIcon(nPacketPicID, spriteNode)
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

return XXLTaskPass