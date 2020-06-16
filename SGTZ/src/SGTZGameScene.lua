
local SGTZGameScene = class("SGTZGameScene", function()
    return display.newLayer()
end)

	
local SGTZGameSink = require("game.SGTZ.SGTZGameSink")
local SGTZ = require("game.SGTZ.SGTZ")

local GameFrame = require("game.gameMainScene.GameFrame")
function SGTZGameScene:ctor()
   print("-----SGTZGameScene:ctor------")
   self:init()
end


function SGTZGameScene:init()	
	self.m_GameSink = SGTZGameSink.new()
	self.m_DWGuoShanCheLayer = SGTZ.new()
	--self.m_DWGuoShanCheLayer:setScaleY(1.5)
	--self.m_DWGuoShanCheLayer:setScaleX(1.8)
	--self.m_DWGuoShanCheLayer:setScale(1.5)
	
	self.m_GameSink:SetGameScene(self)
	self.m_GameSink:SetGameFruitScene(self.m_DWGuoShanCheLayer)

	self.m_DWGuoShanCheLayer:setGameSink(self.m_GameSink, self);	
	self:addChild(self.m_DWGuoShanCheLayer, 5)

	self.m_pGameFrameLayer = GameFrame.new()
	self.m_pGameFrameLayer:setPosition(cc.p(-15, 0));
	self:addChild(self.m_pGameFrameLayer, 10)
	-- self.m_pGameFrameLayer:setScale(1.5)

	--是否是第一次进来直接弹出 领取红包窗口
	-- if SGJ_MSG.IS_SHOW_REDPACKET == true then
	-- 	local action = transition.sequence({
	-- 		cc.DelayTime:create(0.5),
	-- 		cc.CallFunc:create(function()
	-- 			local view = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_RED_PACKET_TASK)
	-- 		end),
	-- 	})
	-- 	self:runAction(action)
	-- end
end

function SGTZGameScene:ClearAni()

end

function SGTZGameScene:SetLandLord(DZCharId, ActorDBID,  jackNum )
	-- self.m_DWGuoShanCheLayer:setGameplayerAni(DZCharId, ActorDBID, jackNum);
end

function SGTZGameScene:GetGameSink()
	return self.m_GameSink
end

function SGTZGameScene:AddFindRequestEx(sendId,  receiveId)
	
end

-- 魔法表情，获取位置
function SGTZGameScene:GetActorPos(nActorDBID, isFrom)
	-- if self.m_DWGuoShanCheLayer then
	-- 	return self.m_DWGuoShanCheLayer:GetActorPos(nActorDBID, isFrom)
	-- end
end

function SGTZGameScene:getFrameLayer()
	return self.m_pGameFrameLayer;
end

return SGTZGameScene
