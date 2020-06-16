--
-- Author: Your Name
-- Date: 2019-12-12 18:05:21
--
local TailFlameAnim = class("TailFlameAnim")

function TailFlameAnim:ctor()

end

function TailFlameAnim:addBallTailFlame(runningLayer,animIndex)
	local emitter
	if pp and pp.ParticleEmitter then
	    pp.ParticleEmitter:setTexturePath("ccbResources/SGTZRes/image/anim/texture/")
	    pp.ParticleEmitter:setSourcePath("ccbResources/SGTZRes/image/anim/json/")
	    emitter = pp.ParticleEmitter:create()   
	    emitter:readJsonDataFromFile("ccbResources/SGTZRes/image/anim/json/danzhu_0" .. animIndex .. ".par")
	    emitter:setRunningLayer(runningLayer)
		emitter:resetSystem()
	end
	return emitter
end

return TailFlameAnim
