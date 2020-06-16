--
-- Author: Your Name
-- Date: 2019-12-12 18:05:21
--
local FloatTextAnim = class("FloatTextAnim", function()
    return cc.uiloader:load("ccbResources/SGTZRes/ui/anim/FloatTextAnim.csb") 
end)

function FloatTextAnim:ctor()
	self.Text_num = cc.uiloader:seekCsbNodeByName(self, "Text_num")
end

function FloatTextAnim:setTextNum(str)
	self.Text_num:setString(str)
end

function FloatTextAnim:play(callback)
	self.mCallback = callback
	self:clearAnimAction()
	self.mAnimAction = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/FloatTextAnim.csb")
	self:runAction(self.mAnimAction)
	self.mAnimAction:setLastFrameCallFunc(handler(self, self.onAnimEndEvent))
	self.mAnimAction:gotoFrameAndPlay(0,false)
end

function FloatTextAnim:onAnimEndEvent()
	if self.mCallback then
		self.mCallback()
	end
end

function FloatTextAnim:clearAnimAction()
	if self.mAnimAction then
		self:stopAction(self.mAnimAction)
		self.mAnimAction = nil
	end
end

return FloatTextAnim
