local PopupWindow = require("script.ui.PopupWindow")
local SGTZReward=class("SGTZReward",PopupWindow)

function SGTZReward:ctor()
	self.super.ctor(self,"ccbResources/SGTZRes/ui/dialog/SGTZReward.csb")

	self.mRatio = 1

	self:initView()
	self:reloadReward()
	self:updateReveiveDetail()
	self:registerEvent()
end

function SGTZReward:initView()
	local node_reward = cc.uiloader:seekCsbNodeByName(self, "node_reward")
	local receive_detail = cc.uiloader:seekCsbNodeByName(self, "receive_detail")

	--领取进度
	self.loadingBar_reward = cc.uiloader:seekCsbNodeByName(receive_detail, "LoadingBar_reward")

	self.rewardNode = {}    --奖励信息
	self.reveiveNode = {}	--领取按钮
	for i=1,3 do
		self.rewardNode[i] = cc.uiloader:seekCsbNodeByName(node_reward, "reward_"..i)
		cc.uiloader:seekCsbNodeByName(self.rewardNode[i], "icon1"):setTexture("ccbResources/SGTZRes/image/reward/YHB_hongbao0".. i .. ".png")
		cc.uiloader:seekCsbNodeByName(self.rewardNode[i], "icon2"):setTexture("ccbResources/SGTZRes/image/reward/YHB_hongbao0".. i .. ".png")
		local action  = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/item/reward_tubiao.csb")
		self.rewardNode[i]:runAction(action)
		self.rewardNode[i].action = action

		self.reveiveNode[i] = cc.uiloader:seekCsbNodeByName(receive_detail, "receive_"..i)
	end

	--//关闭按钮
	local closebtn = cc.uiloader:seekCsbNodeByName(self, "btn_close");
	display.setImageClick(closebtn,handler(self,self.Func_onClickClosebtn))


	self.move_person = cc.uiloader:seekCsbNodeByName(self, "FileNode_renwu")
	self.move_person_action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_ren.csb")
	self.move_person:runAction(self.move_person_action)
	self.move_person_action:gotoFrameAndPlay(0,true)
end

function SGTZReward:setRatio(ratio)
	self.mRatio = ratio
	self:updateReveiveDetail()
end

-- 监听事件
function SGTZReward:registerEvent()
	EventHelp.setEventIDLinster(self,handler(self,self.LuaEventLinster),{
			EVENT_ID.EVENT_TANZHU_CFG,
			EVENT_ID.EVENT_TANZHU_TASK_UPDATE,		
		})
end

function SGTZReward:LuaEventLinster(EventID, ... )
    print("------命令码EventID=："..EventID);
    local varTB = {...}
    if EventID == EVENT_ID.EVENT_TANZHU_CFG then
    	self:reloadReward()
    end

    if EventID == EVENT_ID.EVENT_TANZHU_TASK_UPDATE then
    	self:updateReveiveDetail()
    end
end

function SGTZReward:reloadReward()
	local rewardInfo = gameCenter.smGame:getTanZhuTaskMananger():getTanZhuPrizeInfo()
	local prizeMax = 0
	local prizeMin = 0

	for i=1,3 do
		local Text_reward = cc.uiloader:seekCsbNodeByName(self.rewardNode[i], "Text_reward")
		local img_icon = cc.uiloader:seekCsbNodeByName(Text_reward, "img_hongbao")

		prizeMax = tonumber(rewardInfo[i].nPrizeMax) 
		prizeMin = tonumber(rewardInfo[i].nPrizeMin)
		Text_reward:setString(string.format("%d~%d",prizeMin,prizeMax))
		img_icon:setPositionX(Text_reward:getContentSize().width+30)
	end
end

--更新进度
function SGTZReward:updateReveiveDetail()
	local rewardInfo = gameCenter.smGame:getTanZhuTaskMananger():getTanZhuPrizeInfo()
	--当前已达到的分数
	local curScore = checkint(gameCenter.smGame:getTanZhuTaskMananger():getCurScore())
	--最高奖励
	local rewardMax = tonumber(rewardInfo[3].nNeedScore)
	--下个档次的分数
	local nextNeedScore = 0

	for i=1,3 do
		local btn_receive = cc.uiloader:seekCsbNodeByName(self.reveiveNode[i], "btn_receive")
		local touch = cc.uiloader:seekCsbNodeByName(self.rewardNode[i], "reward_touch1")
		--已领取
		local all_get = cc.uiloader:seekCsbNodeByName(self.reveiveNode[i], "all_get"):setVisible(false)
		--可领取达到的次数
		local Text_num = cc.uiloader:seekCsbNodeByName(btn_receive, "Text_num")
		--每个档次的分数
		local needScore = tonumber(rewardInfo[i].nNeedScore)
		if i < 3 then
			nextNeedScore = tonumber(rewardInfo[i+1].nNeedScore)
		end

		--当前分数已达到下个档次，则不可领取
		local isCanGetNextRward = curScore >= nextNeedScore and i < 3
		if isCanGetNextRward then
			all_get:setVisible(true)
			btn_receive:setVisible(false)
			touch:setVisible(false)
		else
			all_get:setVisible(false)
			btn_receive:setVisible(true)
			touch:setVisible(true)
		end

		local intervalScore = 0
		if curScore >= needScore then
			intervalScore = 0
		else
			intervalScore = needScore - curScore
		end

		local count = math.ceil(intervalScore / self.mRatio)

		Text_num:stopAllActions()
		if count == 0 and not isCanGetNextRward then
			self.rewardNode[i].action:play("animation0",true)
			Text_num:setString("可领取奖励")	
			Text_num:runAction(cca.repeatForever(cca.seq({
				cca.scaleTo(0.5, 1.1),
				cca.scaleTo(0.5, 1.0),
			})))
		else
			Text_num:setString(string.format("还需发射%d次",count))
			self.rewardNode[i].action:gotoFrameAndPause(0)
		end	
		local function getRward()
			if curScore >= needScore then
				if i < 3 then
					local view = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_SGTZ_REWARD_TIP)
					if view then
						view:setRewardTag(i-1,rewardInfo[i+1].nPrizeMax)
					end
				else					
					--达到最高档次直接领取
					gameCenter.smGame:getTanZhuTaskMananger():sendReqPrize(2)

				end
			end
		end
		display.setImageClick(btn_receive,getRward)
		display.setImageClick(touch,getRward)
	end

	local index = 1
	for i=1,3 do
		local needScore = tonumber(rewardInfo[i].nNeedScore)
		if needScore >= curScore then
			index = i
			print("index = "..index)
			break;
		end
	end
	local percent = 0
	local total = self.loadingBar_reward:getContentSize().width
	if curScore <= 0 then
		percent = 0
	elseif curScore > 0 and curScore < rewardMax then
		local needScore = tonumber(rewardInfo[index].nNeedScore)
		print("total = "..total.."  curScore = "..curScore.."  needScore = "..needScore)
		percent = (total / 3 * (index - 1) + total / 3*(curScore/needScore))/total * 100
		print("进度条："..percent)
	else
		percent = 100
	end	
	self.loadingBar_reward:setPercent(percent)
	self.move_person:setPositionX(percent/100 * total)
end

function SGTZReward:Func_onClickClosebtn()
	manager.popup:closePopup()
end

return SGTZReward
