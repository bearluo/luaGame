
local XXLAni = class("XXLAni")
local xxlResPath = "ccbResources/DZXXLRes/ui/"
local STARTBTN_TAG = 101

function XXLAni:ctor(layer)
	self.xxlLayer = layer
end

function XXLAni:addTaskAni(pNode)
	local path = xxlResPath .. "node_xxl_renwu.csb"
	local actionNode = cc.uiloader:load(path)
		:addTo(pNode)
		:pos(224, 65)

	local actionTimeLine = cc.uiloader:csbAniload(path)
	actionTimeLine:gotoFrameAndPlay(0, true)
	actionNode:runAction(actionTimeLine)

end

function XXLAni:playRemoveTaskAnim(view,moveScale,startPos,endPos,isNeedEndAnim,callback)
	local moveTime = 0.3 / self.xxlLayer.aniSpeed
	view:setPosition(startPos)
	-- view:moveTo(moveTime, endPos.x, endPos.y)
	local action = transition.sequence({
		cc.Spawn:create({cc.MoveTo:create(moveTime, cc.p(endPos.x, endPos.y)),cc.ScaleTo:create(moveTime, moveScale, moveScale)}),
        cc.CallFunc:create(function()
        		if callback then
					callback()
				end
				if isNeedEndAnim then
					self:playRemoveTaskEndAnim(view)
				else
					view:removeSelf()
				end
        	end),
		
    })
    view:runAction(action)
end

function XXLAni:playRemoveTaskEndAnim(view)
	local removeScale = 1.2
	local removeTime = 0.5 / self.xxlLayer.aniSpeed
	local removeOpacity = 0.2
	local action = transition.sequence({
		cc.Spawn:create({cc.FadeTo:create(removeTime, removeOpacity),cc.ScaleTo:create(removeTime, removeScale, removeScale)}),
		cc.CallFunc:create(function()
        		view:removeSelf()
        	end),
	})
	view:runAction(action)
end

function XXLAni:playRemoveBlockAni(delayTime, node)
	if tolua.isnull(node) then
		return
	end

	local path = xxlResPath .. "node_xiaochu_tubiao.csb"
	node:runAction(cc.Sequence:create(
		cc.DelayTime:create(delayTime),
		cc.Hide:create(),
		cc.CallFunc:create(function()
			local actionNode = cc.uiloader:load(path)
				:addTo(node:getParent())
				:pos(node:getPositionX(), node:getPositionY())

			local actionTimeLine = cc.uiloader:csbAniload(path)
			actionTimeLine:gotoFrameAndPlay(0, false)
			local speed = actionTimeLine:getTimeSpeed() * self.xxlLayer.aniSpeed
			actionTimeLine:setTimeSpeed(speed)
			actionTimeLine:setLastFrameCallFunc(function()
				actionNode:removeFromParent()
				actionNode = nil		
			end)
			actionNode:runAction(actionTimeLine)
		end)
	))
end

function XXLAni:playRewardNumAni(parent, points, delayTime, data, callback)
	local x = points.leftX + (points.rightX - points.leftX) / 2 + 65
	local y = points.bottomY + (points.topY - points.bottomY) / 2
	local path = xxlResPath .. "node_xiaochu_fengshu_0.csb"
	
	if data.count >= 5 then
		path = xxlResPath .. "node_xiaochu_baoji.csb"
	end

	local node = display.newNode()
		:addTo(parent)
		:runAction(cc.Sequence:create(
				cc.DelayTime:create(delayTime),
				cc.CallFunc:create(function()
					local actionNode = cc.uiloader:load(path)
						:addTo(parent)
						:pos(x, y)

					local moneyLabel = cc.uiloader:seekCsbNodeByName(actionNode, "BitmapFontLabel_1")
					moneyLabel:setString(data.score)

					local coin = cc.uiloader:seekCsbNodeByName(actionNode, "JCXX_jinbi_6")
					coin:setPosition(cc.p(moneyLabel:getContentSize().width * -0.5 + coin:getContentSize().width * -0.5, 0))
					if center.roomList:isXXLGameModel() then
						coin:setTexture("ccbResources/DZXXLRes/image/JCXX_tili.png")
					end
					local actionTimeLine = cc.uiloader:csbAniload(path)
					actionTimeLine:gotoFrameAndPlay(0, false)
					local speed = actionTimeLine:getTimeSpeed() * self.xxlLayer.aniSpeed
					actionTimeLine:setTimeSpeed(speed)
					actionTimeLine:setLastFrameCallFunc(function()
						actionNode:removeFromParent()
						actionNode = nil
					end)
					actionNode:runAction(actionTimeLine)

					if callback then
						callback()
					end	
				end)
			))	
end

function XXLAni:playScoreAni(node)

	node:runAction(cc.Sequence:create(
			cc.ScaleTo:create(0.3, 1.5),
			cc.DelayTime:create(0.1),
			cc.ScaleTo:create(0.1, 1)
		))	

	local path = xxlResPath .. "node_xiaochu_fengshu.csb"
	local actionNode = cc.uiloader:load(path)
		:addTo(node:getParent())
		:pos(node:getPositionX() - 20, node:getPositionY() + 5)

	local actionTimeLine = cc.uiloader:csbAniload(path)
	actionTimeLine:gotoFrameAndPlay(0, false)
	local speed = actionTimeLine:getTimeSpeed() * self.xxlLayer.aniSpeed
	actionTimeLine:setTimeSpeed(speed)
	actionTimeLine:setLastFrameCallFunc(function()
		actionNode:removeFromParent()
		actionNode = nil
	end)
	actionNode:runAction(actionTimeLine)

end

function XXLAni:playStartBtnAni(node)

	local btnSize = node:getContentSize()
	local path = xxlResPath .. "node_xiaochu_kaishi_anniu.csb"
	local actionNode = cc.uiloader:load(path)
		:addTo(node)
		:setTag(STARTBTN_TAG)
		:pos(btnSize.width * 0.5, btnSize.height * 0.5)

	local actionTimeLine = cc.uiloader:csbAniload(path)
	actionTimeLine:gotoFrameAndPlay(0, true)
	local speed = actionTimeLine:getTimeSpeed() * self.xxlLayer.aniSpeed
	actionTimeLine:setTimeSpeed(speed)
	actionNode:runAction(actionTimeLine)

end

function XXLAni:stopStartBtnAni(node)
	local aniNode = node:getChildByTag(STARTBTN_TAG)
	if aniNode and not tolua.isnull(aniNode) then
		aniNode:removeFromParent()
	end
end

function XXLAni:addLandlordBlockAni(node)
	local nodeSize = node:getContentSize()
	local path = xxlResPath .. "node_dizhu_touxiang.csb"
	local actionNode = cc.uiloader:load(path)
		:addTo(node)
		:pos(nodeSize.width * 0.5, nodeSize.height * 0.5)

	if center.roomList:isXXLGameModel() then
		local image = cc.uiloader:seekCsbNodeByName(actionNode, "XXL_yuansu0_1")
		image:setTexture("ccbResources/DZXXLRes/image/XXL_yuansu0_n.png")
	end

	local actionTimeLine = cc.uiloader:csbAniload(path)
	actionTimeLine:gotoFrameAndPlay(0, true)
	local speed = actionTimeLine:getTimeSpeed() * self.xxlLayer.aniSpeed
	actionTimeLine:setTimeSpeed(speed)
	actionNode:runAction(actionTimeLine)
end

function XXLAni:playSettleAni(node, index, money, callback)
	local aniFilePath = {"node_xxl_jiesuan_hyh.csb", "node_xxl_jiesuan_sl.csb", "node_xxl_jiesuan_gxhd.csb", "node_xxl_jiesuan_dyj.csb", "node_xxl_jiesuan_cjdyj.csb"}
	
	local path = xxlResPath .. aniFilePath[index]
	local actionNode = cc.uiloader:load(path)
		:addTo(node)
		:pos(display.cx, display.cy + 120)

	if index == 5 and center.roomList:isXXLGameModel() then
		local farmer = cc.uiloader:seekCsbNodeByName(actionNode, "tx_xxl_cjdyj_renwu_5")
		farmer:setVisible(false)		
	end

	local moneyLabel = cc.uiloader:seekCsbNodeByName(actionNode, "BitmapFontLabel_1")
	if moneyLabel then
		if money > 99999999 then
			moneyLabel:setString(helpUntile.FormateNumber2(money))
		else
			moneyLabel:setString(money)
		end
		local icon = cc.uiloader:seekCsbNodeByName(actionNode, "JCXX_jinbi_6")
		if center.roomList:isXXLGameModel() then
			icon:setTexture("ccbResources/DZXXLRes/image/JCXX_tili.png")
		end
		local bgnX = 633 * 0.5 - (icon:getContentSize().width + moneyLabel:getContentSize().width) * 0.5
		icon:setPositionX(bgnX)
		moneyLabel:setPositionX(bgnX + icon:getContentSize().width)
	end

	local bg = display.newRect(cc.rect(0, 0, display.width, display.height),{fillColor = cc.c4f(0, 0, 0, 0.4)})
		:setContentSize(cc.size(display.width, display.height))
		:addTo(actionNode)
		:pos(display.width * -0.5, display.height * -0.5 - 120)
		:setLocalZOrder(-1)

	local actionTimeLine = cc.uiloader:csbAniload(path)
	actionTimeLine:gotoFrameAndPlay(0, true)
	-- local speed = actionTimeLine:getTimeSpeed() * self.xxlLayer.aniSpeed
	-- actionTimeLine:setTimeSpeed(speed)

	actionTimeLine:addFrameEndCallFunc(25, "overAction", function()
        self:playDelayAni(node, 0.5 / self.xxlLayer.aniSpeed, callback)
		actionNode:removeFromParent()
		actionNode = nil
    end)

	actionNode:runAction(actionTimeLine)

end

function XXLAni:playPoolAni(node, money, callback)
	local fileName = "node_xxl_jiesuan_ddjc.csb"
	
	local path = xxlResPath .. fileName
	local actionNode = cc.uiloader:load(path)
		:addTo(node)
		:pos(display.cx, display.cy + 120)

	if center.roomList:isXXLGameModel() then
		local lorder = cc.uiloader:seekCsbNodeByName(actionNode, "tx_xxl_cjdyj_renwu_5")
		lorder:setVisible(false)
	end

	local moneyLabel = cc.uiloader:seekCsbNodeByName(actionNode, "BitmapFontLabel_1")
	if moneyLabel then
		if money > 99999999 then
			moneyLabel:setString(helpUntile.FormateNumber2(money))
		else
			moneyLabel:setString(money)
		end
		local icon = cc.uiloader:seekCsbNodeByName(actionNode, "JCXX_jinbi_6")
		if center.roomList:isXXLGameModel() then
			icon:setTexture("ccbResources/DZXXLRes/image/JCXX_tili.png")
		end
		local bgnX = 633 * 0.5 - (icon:getContentSize().width + moneyLabel:getContentSize().width) * 0.5
		icon:setPositionX(bgnX)
		moneyLabel:setPositionX(bgnX + icon:getContentSize().width)
	end
	
	local bg = display.newRect(cc.rect(0, 0, display.width, display.height),{fillColor = cc.c4f(0, 0, 0, 0.4)})
		:setContentSize(cc.size(display.width, display.height))
		:addTo(actionNode)
		:pos(display.width * -0.5, display.height * -0.5 - 120)
		:setLocalZOrder(-1)

	local actionTimeLine = cc.uiloader:csbAniload(path)
	actionTimeLine:gotoFrameAndPlay(0, true)
	-- local speed = actionTimeLine:getTimeSpeed() * self.xxlLayer.aniSpeed
	-- actionTimeLine:setTimeSpeed(speed)
	actionTimeLine:addFrameEndCallFunc(25, "overAction", function()
		if callback then
			callback()
		end

		actionNode:removeFromParent()
		actionNode = nil
    end)

	actionNode:runAction(actionTimeLine)

end

function XXLAni:playDelayAni(node, delayTime, callback)
	node:runAction(cc.Sequence:create(
			cc.DelayTime:create(delayTime),
			cc.CallFunc:create(function()
				if callback then
					callback()
				end
			end)
		))	
end

return XXLAni





  	