local BallItem = class("BallItem", function()
	local node = cc.uiloader:load("ccbResources/SGTZRes/ui/item/BallItem.csb")
	return node
end)

function BallItem:ctor()
	self.Image_animal_icon = cc.uiloader:seekCsbNodeByName(self, "Image_animal_icon")
	self.mAnim = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/item/BallItem.csb")
	self:runAction(self.mAnim)
	self.mIndex = 1
	self.emitterTab = {}
	-- self:performWithDelay(handler(self, self.initParticle), 1)
	-- self:initParticle()
end

function BallItem:onCollision()

end

function BallItem:stopMove()
	self.Image_animal_icon:setVisible(false)
	if self.effectNode then 
		for i,emitter in ipairs(self.emitterTab) do
			emitter:setVisible(false) 
		end
	end
end

function BallItem:startMove()
	self.Image_animal_icon:setVisible(true)
	if self.effectNode then 
		for i,emitter in ipairs(self.emitterTab) do
			emitter:setVisible(true) 
		end
	end
end

function BallItem:reset()
end

function BallItem:setIndex(index)
	self.mIndex = index
	self.Image_animal_icon:loadTexture("ccbResources/SGTZRes/image/icon/SG_danzhu0" .. index .. ".png")
	if self.effectNode then

		for i,emitter in ipairs(self.emitterTab) do
			emitter:readJsonDataFromFile("ccbResources/SGTZRes/image/anim/json/danzhu_0" .. index .. ".par")
		    emitter:setRunningLayer(self.effectNode)
		    -- self.emitter:stopSystem()
		    -- self.emitter:pause()
		    emitter:resume()
			emitter:resetSystem()
		end
	end
end

function BallItem:playDismissAnim(callback)
	local node = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/Node_sgdz_danzhuxiaoshi.csb")
	local action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_danzhuxiaoshi.csb")
	local SG_danzhu01_1 = cc.uiloader:seekCsbNodeByName(node, "SG_danzhu01_1")
	SG_danzhu01_1:setTexture("ccbResources/SGTZRes/image/icon/SG_danzhu0" .. self.mIndex .. ".png")
	
	node:runAction(action)
	action:setLastFrameCallFunc(function()
			node:removeSelf()
			if type(callback) == "function" then
				callback()
			end
		end)
	action:gotoFrameAndPlay(0,false)
	node:addTo(self)
end

function BallItem:initParticle()
	if pp and pp.ParticleEmitter then
		local node_particle = cc.uiloader:seekCsbNodeByName(self,"Node_particle")
	    pp.ParticleEmitter:setTexturePath("ccbResources/SGTZRes/image/anim/texture/")
	    pp.ParticleEmitter:setSourcePath("ccbResources/SGTZRes/image/anim/json/")
	    
	    self.effectNode = cc.Node:create()
	    -- self.effectNode:setPosition(-500,-200)
	    self.effectNode:scale(2)
	    self.effectNode:setLocalZOrder(10000)
	    -- manager.scene:getScene():addChild(self.effectNode)
	    node_particle:addChild(self.effectNode)
	    for i=1,1 do
		    local emitter = pp.ParticleEmitter:create()   
		    self.effectNode:addChild(emitter)
	    	table.insert(self.emitterTab,emitter)
	    end
	end
end
return BallItem