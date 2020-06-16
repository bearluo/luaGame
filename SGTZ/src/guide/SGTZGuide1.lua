local SGTZGuide1 = class("SGTZGuide1", function()
	return cc.uiloader:load("ccbResources/SGTZRes/ui/guide/SGTZGuide_1.csb")
end)

function SGTZGuide1:ctor()
	self.Panel_touch = cc.uiloader:seekCsbNodeByName(self, "Panel_touch")
	self.Panel_touch:setContentSize(display.width,display.height)
	display.setImageClickNoScale(self.Panel_touch, function()
			if type(self.mCallback) == "function" then
				self.mCallback()
			end
			self:removeSelf()
		end)
end

function SGTZGuide1:setFinishCallback(callback)
	self.mCallback = callback
end


return SGTZGuide1