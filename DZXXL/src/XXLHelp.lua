local XXLHelp = class("XXLHelp", function()
   return cc.uiloader:load("ccbResources/DZXXLRes/ui/node_xxl_help_dlg.csb")  --
end)
local PopAnimTag = 6666
--

function XXLHelp:ctor()
	print("--XXLHelp:ctor--")
	self:setPosition(display.cx,display.cy)
	self:initView()
	self:initClick()
	self:getSettleRoleImg()
	self:updateTabBarStatus(1)
end

function XXLHelp:initView()
	self.closeBtn = cc.uiloader:seekCsbNodeByName(self, "img_closeBtn")
	self.settleBtn = cc.uiloader:seekCsbNodeByName(self, "img_settlBtn")
	self.roleBtn = cc.uiloader:seekCsbNodeByName(self, "img_roleBtn")
	
	self.settlBtnOn = cc.uiloader:seekCsbNodeByName(self, "img_settleBtn_on")
	self.settlBtnOff = cc.uiloader:seekCsbNodeByName(self, "img_settleBtn_off")
	self.roleBtnOn = cc.uiloader:seekCsbNodeByName(self, "img_roleBtn_on")
	self.roleBtnOff = cc.uiloader:seekCsbNodeByName(self, "img_roleBtn_off")

	self.settleNode = cc.uiloader:seekCsbNodeByName(self, "node_settle")
	self.roleNode = cc.uiloader:seekCsbNodeByName(self, "node_role")

	self.settleNodePos = cc.uiloader:seekCsbNodeByName(self, "node_imgPos")

	if center.roomList:isXXLGameModel() then
		local Image_7 = cc.uiloader:seekCsbNodeByName(self, "Image_7")
		Image_7:loadTexture("ccbResources/DZXXLRes/image/XXL_wanfaxiangqing_n.png")
	end
end

function XXLHelp:initClick()
	display.setImageClick(self.closeBtn, handler(self, self.onClickClosebtn))
	display.setImageClick(self.settleBtn, handler(self, self.onClickSettlebtn))
	display.setImageClick(self.roleBtn, handler(self, self.onClickRolebtn))
end

function XXLHelp:onClickSettlebtn()
	self:updateTabBarStatus(1)
end

function XXLHelp:onClickRolebtn()
	self:updateTabBarStatus(2)
end

function XXLHelp:onClickClosebtn()
	manager.popup:closePopup()
end

function XXLHelp:updateTabBarStatus(curSelect)
	self.settlBtnOn:setVisible(curSelect == 1)
	self.settlBtnOff:setVisible(curSelect == 2)

	self.roleBtnOn:setVisible(curSelect == 2)
	self.roleBtnOff:setVisible(curSelect == 1)

	self.settleNode:setVisible(curSelect == 1)
	self.roleNode:setVisible(curSelect == 2)
end

function XXLHelp:setBetRate(rate)
	local Image_bet_rate = cc.uiloader:seekCsbNodeByName(self, "Image_bet_rate")
	for i=1,5 do
		local node = cc.uiloader:seekCsbNodeByName(Image_bet_rate, "Node_"..i)
		local node_rate = rate[i] or {}
		for j=1,6 do
			local text = cc.uiloader:seekCsbNodeByName(node, "Text_"..j)
			text:setString(string.format("%s倍",(node_rate[j] or 0)/100))
		end
	end
end

function XXLHelp:getSettleRoleImg(nPacketPicID)
	if tolua.isnull(self.settleNodePos) or not nPacketPicID then
		return
	end

	local function linster(bSuccess, sprite)
		if bSuccess then
            self.settleNodePos:removeAllChildren()
			sprite:addTo(self.settleNodePos)
		end
	end
	filefunc.openPic(nPacketPicID,linster)
end

return XXLHelp
