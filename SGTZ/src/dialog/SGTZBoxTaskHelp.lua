local SGTZBoxTaskHelp = class("SGTZBoxTaskHelp", function()
    local node=cc.uiloader:load("ccbResources/SGTZRes/ui/dialog/SGTZTaskHelp.csb")  --
    node:setAnchorPoint(cc.p(0.5,0.5))
    return node
end)


function SGTZBoxTaskHelp:ctor()
    print("--SSGTZBoxTaskHelp:ctor--")
    self:setPosition(display.cx,display.cy)
    local btn_close = cc.uiloader:seekCsbNodeByName(self, "btn_close")
	display.setImageClick(btn_close,handler(self,self.Func_onClickClose))

    self.m_config = center.task:getTaskTanZhuTaskConfig()

    local txt_help = cc.uiloader:seekCsbNodeByName(self, "txt_help")
    txt_help:setString(self.m_config.szDes)

end

function SGTZBoxTaskHelp:Func_onClickClose()
	manager.popup:closePopup()
end

return SGTZBoxTaskHelp
