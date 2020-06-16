local PopupWindow = require("script.ui.PopupWindow")
local SGTZRewardTip=class("SGTZRewardTip",PopupWindow)

function SGTZRewardTip:ctor()
	self.super.ctor(self,"ccbResources/SGTZRes/ui/dialog/SGTZRewardTip.csb")
	self:initView()
end

function SGTZRewardTip:initView()
	--//关闭按钮
	local closebtn = cc.uiloader:seekCsbNodeByName(self, "btn_close")
	display.setImageClick(closebtn,handler(self,self.Func_onClickClosebtn))

	--立即领取按钮
	local btn_get = cc.uiloader:seekCsbNodeByName(self, "btn_get")
	display.setImageClick(btn_get,handler(self,self.Func_onClickGetbtn))
	
	--冲击大礼包按钮
	local btn_continue = cc.uiloader:seekCsbNodeByName(self, "btn_continue")	
	display.setImageClick(btn_continue,handler(self,self.Func_onClickClosebtn))

	self.Text_tip_1 = cc.uiloader:seekCsbNodeByName(self, "Text_tip_1")
	self.img_icon = cc.uiloader:seekCsbNodeByName(self.Text_tip_1, "img_icon")
	
end

function SGTZRewardTip:setRewardTag(tag,rewardNum)
	self.nPrizeIndex = tag
	self.rewardNum = rewardNum

	self.Text_tip_1:setString("继续游戏将有机会获得："..self.rewardNum)
	self.img_icon:setPositionX(self.Text_tip_1:getContentSize().width+10)
end

function SGTZRewardTip:Func_onClickClosebtn()
	manager.popup:closePopup()
end

--立即领取
function SGTZRewardTip:Func_onClickGetbtn()
	manager.popup:closePopup()
	gameCenter.smGame:getTanZhuTaskMananger():sendReqPrize(self.nPrizeIndex)
end


return SGTZRewardTip
