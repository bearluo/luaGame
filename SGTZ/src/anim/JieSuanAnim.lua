--
-- Author: Your Name
-- Date: 2019-12-12 18:05:21
--
local JieSuanAnim = class("JieSuanAnim")

function JieSuanAnim:ctor()
end

function JieSuanAnim:safeSetString(target,str)
	if target then 
		target:setString(str) 
	end
end

function JieSuanAnim:playDZTZ(target,gold,redbag,callback)
    local node = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/Node_sgdz_jiesuan_dztz.csb")
	local action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_jiesuan_dztz.csb")
	node:runAction(action)
	action:setLastFrameCallFunc(function()
			node:removeSelf()
			if type(callback) == "function" then
				callback()
			end
		end)
	action:gotoFrameAndPlay(0,false)
	local SG_js_db_1 = cc.uiloader:seekCsbNodeByName(node, "SG_js_db_1"):setVisible(false)
	local SG_js_db_2 = cc.uiloader:seekCsbNodeByName(node, "SG_js_db_2"):setVisible(false)
	local BitmapFontLabel_1
	local BitmapFontLabel_2
	if redbag > 0 then
		SG_js_db_1:setVisible(true)
		BitmapFontLabel_1 = cc.uiloader:seekCsbNodeByName(SG_js_db_1, "BitmapFontLabel_1")
		BitmapFontLabel_2 = cc.uiloader:seekCsbNodeByName(SG_js_db_1, "BitmapFontLabel_2")
	else
		SG_js_db_2:setVisible(true)
		BitmapFontLabel_1 = cc.uiloader:seekCsbNodeByName(SG_js_db_2, "BitmapFontLabel_1")
	end

	self:safeSetString(BitmapFontLabel_1,string.formatnumberthousands(tostring(gold)))
	self:safeSetString(BitmapFontLabel_2,string.formatnumberthousands(tostring(redbag)))

	local Panel_1 = cc.uiloader:seekCsbNodeByName(node, "Panel_1")
	Panel_1:setContentSize(cc.size(display.width,display.height))

	
    node:addTo(target)
end

function JieSuanAnim:playGXHD(target,gold,redbag,callback)
    local node = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/Node_sgdz_jiesuan_gxhd.csb")
	local action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_jiesuan_gxhd.csb")
	node:runAction(action)
	action:setLastFrameCallFunc(function()
			node:removeSelf()
			if type(callback) == "function" then
				callback()
			end
		end)
	action:gotoFrameAndPlay(0,false)
	
	local SG_js_db_1 = cc.uiloader:seekCsbNodeByName(node, "SG_js_db_1"):setVisible(false)
	local SG_js_db_2 = cc.uiloader:seekCsbNodeByName(node, "SG_js_db_2"):setVisible(false)
	local SG_js_db_3 = cc.uiloader:seekCsbNodeByName(node, "SG_js_db_3"):setVisible(false)

	local BitmapFontLabel_1
	local BitmapFontLabel_2
	if redbag > 0 and gold > 0 then
		SG_js_db_1:setVisible(true)
		BitmapFontLabel_1 = cc.uiloader:seekCsbNodeByName(SG_js_db_1, "BitmapFontLabel_1")
		BitmapFontLabel_2 = cc.uiloader:seekCsbNodeByName(SG_js_db_1, "BitmapFontLabel_2")
	elseif gold > 0 then
		SG_js_db_2:setVisible(true)
		BitmapFontLabel_1 = cc.uiloader:seekCsbNodeByName(SG_js_db_2, "BitmapFontLabel_1")
	else
		SG_js_db_3:setVisible(true)
		BitmapFontLabel_2 = cc.uiloader:seekCsbNodeByName(SG_js_db_3, "BitmapFontLabel_2")
	end

	self:safeSetString(BitmapFontLabel_1,string.formatnumberthousands(tostring(gold)))
	self:safeSetString(BitmapFontLabel_2,string.formatnumberthousands(tostring(redbag)))

	local Panel_1 = cc.uiloader:seekCsbNodeByName(node, "Panel_1")
	Panel_1:setContentSize(cc.size(display.width,display.height))

    node:addTo(target)
end

function JieSuanAnim:playPTJS(target,gold,redbag,callback)
    local node = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/Node_sgdz_jiesuan_gxhd.csb")
	local action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_jiesuan_gxhd.csb")
	node:runAction(action)
	action:setLastFrameCallFunc(function()
			node:removeSelf()
			if type(callback) == "function" then
				callback()
			end
		end)
	action:gotoFrameAndPlay(0,false)
	
	cc.uiloader:seekCsbNodeByName(node, "SG_js_gongxihd_2"):setVisible(false)
	local SG_js_db_1 = cc.uiloader:seekCsbNodeByName(node, "SG_js_db_1"):setVisible(false)
	local SG_js_db_2 = cc.uiloader:seekCsbNodeByName(node, "SG_js_db_2"):setVisible(false)
	local SG_js_db_3 = cc.uiloader:seekCsbNodeByName(node, "SG_js_db_3"):setVisible(false)

	local BitmapFontLabel_1
	local BitmapFontLabel_2
	if redbag > 0 and gold > 0 then
		SG_js_db_1:setVisible(true)
		BitmapFontLabel_1 = cc.uiloader:seekCsbNodeByName(SG_js_db_1, "BitmapFontLabel_1")
		BitmapFontLabel_2 = cc.uiloader:seekCsbNodeByName(SG_js_db_1, "BitmapFontLabel_2")
	elseif gold > 0 then
		SG_js_db_2:setVisible(true)
		BitmapFontLabel_1 = cc.uiloader:seekCsbNodeByName(SG_js_db_2, "BitmapFontLabel_1")
	else
		SG_js_db_3:setVisible(true)
		BitmapFontLabel_2 = cc.uiloader:seekCsbNodeByName(SG_js_db_3, "BitmapFontLabel_2")
	end

	self:safeSetString(BitmapFontLabel_1,string.formatnumberthousands(tostring(gold)))
	self:safeSetString(BitmapFontLabel_2,string.formatnumberthousands(tostring(redbag)))

	local Panel_1 = cc.uiloader:seekCsbNodeByName(node, "Panel_1")
	Panel_1:setContentSize(cc.size(display.width,display.height))

    node:addTo(target)
end

function JieSuanAnim:playMZBK(target,num1,num2,redbag,callback)
    local node = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/Node_sgdz_jiesuan_mzbk.csb")
	local action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_jiesuan_mzbk.csb")
	node:runAction(action)
	action:setLastFrameCallFunc(function()
			node:removeSelf()
			if type(callback) == "function" then
				callback()
			end
		end)
	action:gotoFrameAndPlay(0,false)

	local SG_js_db_1 = cc.uiloader:seekCsbNodeByName(node, "SG_js_db_1"):setVisible(false)
	local SG_js_db_2 = cc.uiloader:seekCsbNodeByName(node, "SG_js_db_2"):setVisible(false)
	local BitmapFontLabel_1
	local BitmapFontLabel_2
	local BitmapFontLabel_3
	if redbag > 0 then
		SG_js_db_2:setVisible(true)
		BitmapFontLabel_1 = cc.uiloader:seekCsbNodeByName(SG_js_db_2, "BitmapFontLabel_1")
		BitmapFontLabel_2 = cc.uiloader:seekCsbNodeByName(SG_js_db_2, "BitmapFontLabel_2")
		BitmapFontLabel_3 = cc.uiloader:seekCsbNodeByName(SG_js_db_2, "BitmapFontLabel_3")
	else
		SG_js_db_1:setVisible(true)
		BitmapFontLabel_1 = cc.uiloader:seekCsbNodeByName(SG_js_db_1, "BitmapFontLabel_1")
		BitmapFontLabel_2 = cc.uiloader:seekCsbNodeByName(SG_js_db_1, "BitmapFontLabel_2")
	end

	if num1 > 0 then
		self:safeSetString(BitmapFontLabel_1,string.formatnumberthousands(tostring(num1)))
		self:safeSetString(BitmapFontLabel_2,'+' .. string.formatnumberthousands(tostring(num2)))
		BitmapFontLabel_2:setPositionX(BitmapFontLabel_1:getPositionX() + BitmapFontLabel_1:getContentSize().width) 
	else
		self:safeSetString(BitmapFontLabel_1,"")
		self:safeSetString(BitmapFontLabel_2,string.formatnumberthousands(tostring(num2)))
		BitmapFontLabel_2:setPositionX(BitmapFontLabel_1:getPositionX() + BitmapFontLabel_1:getContentSize().width)
	end
	self:safeSetString(BitmapFontLabel_3,string.formatnumberthousands(tostring(redbag)))

	local Panel_1 = cc.uiloader:seekCsbNodeByName(node, "Panel_1")
	Panel_1:setContentSize(cc.size(display.width,display.height))

    node:addTo(target)
end

function JieSuanAnim:playPoolOpen(target,posTab,callback)
    -- 随机爆金币
	for i,pos in ipairs(posTab) do
	    local node = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/Node_sgdz_CJ_bao.csb")
		local action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_CJ_bao.csb")
		node:runAction(action)
		action:setLastFrameCallFunc(function()
			node:removeSelf()
		end)
		local startIndex = math.random(1,20)
		local scale = math.random(1.0,1.0)
		local x,y = pos.x,pos.y--math.random(-400,400),math.random(-300,300)
		node:setScale(scale)
		node:setPosition(x, y)
		action:gotoFrameAndPlay(startIndex,false)
    	node:addTo(target)
	end

    local node = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/Node_sgdz_CJ_caidai.csb")
	local action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_CJ_caidai.csb")
	node:runAction(action)
	action:setLastFrameCallFunc(function()
			node:removeSelf()
			if type(callback) == "function" then
				callback()
			end
		end)
	action:gotoFrameAndPlay(0,false)

    node:addTo(target)
end

-- function JieSuanAnim:playGoldAnim(target,pos,num,callback)
--     -- 随机爆金币
--     local dt = 0.5
--     local startX = -90.00 * ( num - 1 ) / 2
-- 	for i=1,num do
-- 	    local node = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/jinbi.csb")
-- 		local action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/jinbi.csb")
-- 		node:runAction(action)
-- 		node:setPosition(pos.x, pos.y)
-- 		action:gotoFrameAndPlay(0,true)

-- 		local x,y = startX + 90.00 * ( i - 1 ),100
-- 		local height = 100
-- 		local count = 1
-- 		local jumpAciton = cca.jumpBy(dt, x, y, height, count)
-- 		local callFuncAction = cca.callFunc(function()
-- 				if callback then
-- 					callback(node)
-- 				end
-- 			end)
-- 		local acts = {jumpAciton,callFuncAction}
-- 		local sequenceAciton = cca.seq(acts)
-- 		node:runAction(sequenceAciton)
--     	node:addTo(target)
-- 	end
-- end

function JieSuanAnim:playGoldAnim(target,pos,num,callback)
    -- 随机爆金币
    local dt = 0.5
    local startX = -90.00 * ( num - 1 ) / 2
	for i=1,num do
	    local node = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/jinbi.csb")
		local action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/jinbi.csb")
		node:runAction(action)
		node:setPosition(pos.x, pos.y)
		action:gotoFrameAndPlay(0,true)

		local x,y = startX + 90.00 * ( i - 1 ),math.random(-100,100)
		local height = math.random(-100,100)
		local count = 1
		local jumpAciton = cca.jumpBy(dt, x, y, height, count)
		local callFuncAction = cca.callFunc(function()
				if callback then
					callback(node)
				end
			end)
		local acts = {jumpAciton,callFuncAction}
		local sequenceAciton = cca.seq(acts)
		node:runAction(sequenceAciton)
    	node:addTo(target)
	end
end

function JieSuanAnim:playHongBaoAnim(target,pos,num,callback)
    -- 随机爆金币
    local dt = 0.5
    local startX = -90.00 * ( num - 1 ) / 2
	for i=1,num do
	    local node = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/hongbao.csb")
		local action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/hongbao.csb")
		node:runAction(action)
		node:setPosition(pos.x, pos.y)
		action:gotoFrameAndPlay(0,true)

		local x,y = startX + 90.00 * ( i - 1 ),math.random(-100,100)
		local height = math.random(-100,100)
		local count = 1
		local jumpAciton = cca.jumpBy(dt, x, y, height, count)
		local callFuncAction = cca.callFunc(function()
				if callback then
					callback(node)
				end
			end)
		local acts = {jumpAciton,callFuncAction}
		local sequenceAciton = cca.seq(acts)
		node:runAction(sequenceAciton)
    	node:addTo(target)
	end
end

function JieSuanAnim:playGoldPoolAnim(target,pos,callback)
    -- 随机爆金币
	local node = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/Node_sgdz_CJ_bao.csb")
	local action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_CJ_bao.csb")
	node:runAction(action)
	action:setLastFrameCallFunc(function()
		if callback then
			callback()
		end
		node:removeSelf()
	end)
	local x,y = pos.x,pos.y
	node:setPosition(x, y)
	action:gotoFrameAndPlay(0,false)
	node:addTo(target)
end

return JieSuanAnim
