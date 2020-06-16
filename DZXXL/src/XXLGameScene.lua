local XXLGameScene = class("XXLGameScene", function()
    return display.newLayer()
end)

local XXLGameSink = require("game.DZXXL.XXLGameSink")
local XXLLayer = require("game.DZXXL.XXLLayer")
local GameFrame = require("game.gameMainScene.GameFrame")

function XXLGameScene:ctor()
   print("-----XXLGameScene:ctor------")
   self:init()
end

function XXLGameScene:init()	
	self.m_GameSink = XXLGameSink.new()
	self.m_XXLLayer = XXLLayer.new()
	
	self.m_GameSink:SetGameScene(self)
	self.m_GameSink:SetGameXXLScene(self.m_XXLLayer)

	self.m_XXLLayer:setGameSink(self.m_GameSink, self);	
	self:addChild(self.m_XXLLayer, 5)

	self.m_pGameFrameLayer = GameFrame.new()
	self.m_pGameFrameLayer:setPosition(cc.p(-15, 0));
	self:addChild(self.m_pGameFrameLayer, 10)
end

function XXLGameScene:ClearAni()

end

function XXLGameScene:SetLandLord(DZCharId, ActorDBID,  jackNum )
	self.m_XXLLayer:setGameplayerAni(DZCharId, ActorDBID, jackNum);
end

function XXLGameScene:GetGameSink()
	return self.m_GameSink
end

function XXLGameScene:AddFindRequestEx(sendId,  receiveId)
	
end

function XXLGameScene:GetActorPos(nActorDBID, isFrom)
	if self.m_XXLLayer then
		return self.m_XXLLayer:GetActorPos(nActorDBID, isFrom)
	end
end

function XXLGameScene:getFrameLayer()
	return self.m_pGameFrameLayer;
end

return XXLGameScene
