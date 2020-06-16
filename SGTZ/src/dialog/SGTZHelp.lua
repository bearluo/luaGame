local PopupWindow = require("script.ui.PopupWindow")
local SGTZHelp=class("SGTZHelp",PopupWindow)

function SGTZHelp:ctor()
	self.super.ctor(self,"ccbResources/SGTZRes/ui/dialog/SGTZHelp.csb")
	self:initHelpWindow()
end

function SGTZHelp:initHelpWindow()
	local content_pos = cc.uiloader:seekCsbNodeByName(self, "content_pos")

	--//游戏信息
	self.m_base_rewardInfo = cc.uiloader:load("ccbResources/SGTZRes/ui/dialog/SGTZHelpReward.csb")
	content_pos:addChild(self.m_base_rewardInfo);
	--//游戏玩法
	self.m_base_rewardPlay = cc.uiloader:load("ccbResources/SGTZRes/ui/dialog/SGTZHelpPlay.csb");
	content_pos:addChild(self.m_base_rewardPlay);

	--//设置标签点击效果
	self.m_switch_btn_Reward = cc.uiloader:seekCsbNodeByName(self, "switch_btn_Reward") --//奖励信息按钮
	self.m_switch_btn_Play = cc.uiloader:seekCsbNodeByName(self, "switch_btn_Play")		--//游戏玩法按钮
	
	local Play_state_wx = cc.uiloader:seekCsbNodeByName(self.m_switch_btn_Play, "state_xz")
	local Reward_state_wx = cc.uiloader:seekCsbNodeByName(self.m_switch_btn_Reward, "state_xz")

	display.setCsbSpriteClick(Play_state_wx,function()
			self:SetInfoShowByTag(1)
		end)
	display.setCsbSpriteClick(Reward_state_wx,function()
			self:SetInfoShowByTag(2)
		end)

	--//关闭按钮
	local closebtn = cc.uiloader:seekCsbNodeByName(self, "clost_btn");
	display.setImageClick(closebtn,handler(self,self.Func_onClickClosebtn))
	self:SetInfoShowByTag(2)
end

--//设置按钮点击后的显示内容
function SGTZHelp:SetInfoShowByTag(nTag)
	
	local function initSeleteState(rect, tagNode, isSeletet)
		rect:setVisible(isSeletet);

		if isSeletet then
			cc.uiloader:seekCsbNodeByName(tagNode,"state_xz"):setOpacity(255)
			cc.uiloader:seekCsbNodeByName(tagNode,"state_wxz"):setOpacity(0)
		else
			cc.uiloader:seekCsbNodeByName(tagNode,"state_xz"):setOpacity(0)
			cc.uiloader:seekCsbNodeByName(tagNode,"state_wxz"):setOpacity(255)
		end
	end
	
	if (nTag == 2) then
		initSeleteState(self.m_base_rewardPlay, self.m_switch_btn_Play, false);
		initSeleteState(self.m_base_rewardInfo, self.m_switch_btn_Reward, true);
	elseif (nTag == 1) then	
		initSeleteState(self.m_base_rewardPlay, self.m_switch_btn_Play, true);
		initSeleteState(self.m_base_rewardInfo, self.m_switch_btn_Reward, false);
	end
end


function SGTZHelp:Func_onClickClosebtn()
	manager.popup:closePopup()
end

return SGTZHelp
