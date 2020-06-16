local XXLPoolInfo =class("XXLPoolInfo", function()	
	return cc.uiloader:load("ccbResources/DZXXLRes/ui/node_pool_info.csb")
end)
local PopAnimTag = 6666
function XXLPoolInfo:ctor()
	self:setPosition(display.cx,display.cy)

	--//关闭按钮
	local closebtn = cc.uiloader:seekCsbNodeByName(self, "img_close");
	display.setImageClick(closebtn,handler(self,self.Func_onClickClosebtn))
end

function XXLPoolInfo:initPoolInfo(poolinfo, showType)

	local node_role = cc.uiloader:seekCsbNodeByName(self, "node_role")
	local node_rank = cc.uiloader:seekCsbNodeByName(self, "node_rank")

	node_role:setVisible(showType == 2)
	node_rank:setVisible(showType == 1)

	local todayTotalLabel = cc.uiloader:seekCsbNodeByName(self, "txt_today_pool")
	todayTotalLabel:setString(poolinfo.nDayWinAllGold or 0)
	local todayIcon = cc.uiloader:seekCsbNodeByName(self, "img_today_icon")
	todayIcon:pos(todayTotalLabel:getPositionX() - todayTotalLabel:getContentSize().width * 0.5 - todayIcon:getContentSize().width * 0.5, todayIcon:getPositionY())

	local t_str2 = string.formatnumberthousands(tostring(poolinfo.nAllGold))
	local txt_poolMoney = cc.uiloader:seekCsbNodeByName(self, "txt_poolMoney")
	txt_poolMoney:setString(t_str2)

	self:initRewardInfo(poolinfo)

	if showType == 1 then
		local preName = cc.uiloader:seekCsbNodeByName(self, "txt_rankName")
		local preGold = cc.uiloader:seekCsbNodeByName(self, "txt_rankMoney")
		local preTime = cc.uiloader:seekCsbNodeByName(self, "txt_time")
		local LastWinningDBID = tonumber(poolinfo.PersonItem[1].nActorDBID)  
		if LastWinningDBID > 0 then
			self.userIconLayer = cc.uiloader:seekCsbNodeByName(self, "node_rankHead")
			local UserIconImg = display.newSprite()
			self.userIconLayer:addChild(UserIconImg)
			--待完善
			t_str2 = helpUntile.GetShortName(poolinfo.PersonItem[1].szPoolPlayerName, 12, 12)
			preName:setString(""..t_str2);	
			t_str2 = poolinfo.PersonItem[1].szPoolPlayerFace

			--待完善
			self:getWinUserIcon(t_str2, UserIconImg, LastWinningDBID)

			t_str2 = helpUntile.FormateNumber2(tonumber(poolinfo.PersonItem[1].nGold))
			preGold:setString(""..t_str2)

			preTime:setString(os.date("%m-%d %H:%M", poolinfo.PersonItem[1].nTimes or 0))
		else
			preName:setString("")
			preGold:setString("")
			preTime:setString("")
		end


		local itemRes = "ccbResources/DZXXLRes/ui/node_poolinfo_rank_item.csb"
		local rankView = cc.uiloader:seekCsbNodeByName(self, "scrollview_rank")
		local count = 0
		for i=2,#poolinfo.PersonItem do
			if tonumber(poolinfo.PersonItem[i].nActorDBID) ~= 0 then
				count = count + 1
			end
		end
		
		local scrollViewSize = cc.size(rankView:getContentSize().width, count * 90)
		if scrollViewSize.height < 380 then
			scrollViewSize = rankView:getContentSize()
		end
		rankView:setInnerContainerSize(scrollViewSize)

		local x, bgnY = scrollViewSize.width * 0.5, scrollViewSize.height - 45
		local index = 1
		for i=2,#poolinfo.PersonItem do
			if tonumber(poolinfo.PersonItem[i].nActorDBID) ~= 0 then
				local item = cc.uiloader:load(itemRes)
					:addTo(rankView)
					:pos(x, bgnY - (index - 1) * 90)

				local name = cc.uiloader:seekCsbNodeByName(item, "txt_name")
				local money = cc.uiloader:seekCsbNodeByName(item, "txt_money")
				local head = cc.uiloader:seekCsbNodeByName(item, "head_pos")
				local times = cc.uiloader:seekCsbNodeByName(item, "txt_time")
				
				name:setString(helpUntile.GetShortName(poolinfo.PersonItem[i].szPoolPlayerName, 12, 12))
				money:setString(helpUntile.FormateNumber2(tonumber(poolinfo.PersonItem[i].nGold)))
				times:setString(os.date("%m-%d %H:%M", poolinfo.PersonItem[i].nTimes or 0))

				local function linster(bSuccess, sprite)
					print("sssszzz",bSuccess)

					if tolua.isnull(head) then
			            return
			        end

			        if not tolua.isnull(head) and head:getChildByTag(100) then
			            head:removeChildByTag(100, true)
			        end

			        local mask = display.newSprite("ccbResources/DZXXLRes/image/JCXX_touxiangkuang_xiao.png")
			        if not bSuccess then  
			            -- 失败处理 设置默认头像          
			            local faceID = tonumber(poolinfo.PersonItem[i].nActorDBID) % 10 + 1
			            sprite = display.newSprite("ccbResources/icon/"..faceID..".jpg")
			        end

			        local circleSp = display.createCircleSprite(sprite, mask)
			        circleSp:setContentSize(cc.size(68, 68))
			        circleSp:setTag(100)
			        circleSp:addTo(head)

				end
				filefunc.openFace(poolinfo.PersonItem[i].szPoolPlayerFace, linster)
				index = index + 1
			end
		end

		rankView:setScrollBarEnabled(false)
	end

	if center.roomList:isXXLGameModel() then
		local img_roleTips = cc.uiloader:seekCsbNodeByName(self, "img_roleTips")
		img_roleTips:loadTexture("ccbResources/DZXXLRes/image/JCXX_dizhuufuize_tu_n.png")
	end

end

function XXLPoolInfo:initRewardInfo(poolinfo)

	local width, height = 910, 400
	local count = 0
	for k,v in pairs(poolinfo.nTotalBetting) do
		if tonumber(v) >= 0 then
			count = count + 1
		else
			break
		end
	end

	local rewardView = cc.uiloader:seekCsbNodeByName(self, "scrollview_reward")
	local titleNode = cc.uiloader:seekCsbNodeByName(self, "img_rewardRoleTitle")
	local itemWidth, itemHeigt = width, height / count
	local bgnX, bgnY = width * 0.5, height - itemHeigt * 0.5
	local fontRes = "ccbResources/fonts/fangzheng.ttf"
	for k,v in pairs(poolinfo.nTotalBetting) do

		if tonumber(v) < 0 then
			break
		end

		local imageName = ""
		if k == count then
			imageName = "ccbResources/DZXXLRes/image/JCXX_biaoge15.png"
			if k % 2 == 0 then
				imageName = "ccbResources/DZXXLRes/image/JCXX_biaoge4.png"
			end
		else
			imageName = "ccbResources/DZXXLRes/image/JCXX_biaoge2.png"
			if k % 2 == 0 then
				imageName = "ccbResources/DZXXLRes/image/JCXX_biaoge3.png"
			end
		end

		local curY = bgnY - (k - 1) * itemHeigt
		display.newScale9Sprite(
				imageName, 
				bgnX, curY, 
				cc.size(itemWidth, itemHeigt), 
				cc.rect(455, 15, 1, 1)
			)
			:addTo(rewardView)

		cc.ui.UILabel.new({
				text = v,
				font = fontRes,
				size = 32,
				color = cc.c3b(0xe5, 0x72, 0x15)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(rewardView)
			:pos(80, curY)		

		cc.ui.UILabel.new({
				text = ((tonumber(poolinfo.btPoolRate3[k]) / 100)) .. "%",
				font = fontRes,
				size = 32,
				color = cc.c3b(0xa5, 0x5a, 0x11)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(rewardView)
			:pos(225, curY)	

		cc.ui.UILabel.new({
				text = ((tonumber(poolinfo.btPoolRate4[k]) / 100)) .. "%",
				font = fontRes,
				size = 32,
				color = cc.c3b(0xa5, 0x5a, 0x11)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(rewardView)
			:pos(350, curY)	

		cc.ui.UILabel.new({
				text = ((tonumber(poolinfo.btPoolRate5[k]) / 100)) .. "%",
				font = fontRes,
				size = 32,
				color = cc.c3b(0xa5, 0x5a, 0x11)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(rewardView)
			:pos(475, curY)		

		cc.ui.UILabel.new({
				text = ((tonumber(poolinfo.btPoolRate6[k]) / 100)) .. "%",
				font = fontRes,
				size = 32,
				color = cc.c3b(0xa5, 0x5a, 0x11)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(rewardView)
			:pos(600, curY)

		cc.ui.UILabel.new({
				text = ((tonumber(poolinfo.btPoolRate7[k]) / 100)) .. "%",
				font = fontRes,
				size = 32,
				color = cc.c3b(0xa5, 0x5a, 0x11)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(rewardView)
			:pos(725, curY)

		cc.ui.UILabel.new({
				text = ((tonumber(poolinfo.btPoolRate8[k]) / 100)) .. "%",
				font = fontRes,
				size = 32,
				color = cc.c3b(0xa5, 0x5a, 0x11)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(rewardView)
			:pos(850, curY)
	end

	rewardView:setScrollBarEnabled(false)

	local posXs = {-520, -396, -275, -148, -22, 103}
	local titles = {"3", "4", "5", "6", "7", "8+"}
	for k,v in pairs(titles) do
		cc.ui.UILabel.new({
				text = v,
				font = fontRes,
				size = 42,
				color = cc.c3b(0xe9, 0x42, 0x01)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(self)
			:pos(posXs[k], -4)
	end
end

function XXLPoolInfo:getWinUserIcon(nPicID, spriteNode, DBID)
	local function linster(bSuccess,sprite)
		print("sssszzz",bSuccess)

		if tolua.isnull(spriteNode) then
            return
        end

        if not tolua.isnull(spriteNode) and spriteNode:getChildByTag(100) then
            spriteNode:removeChildByTag(100, true)
        end

        local mask = display.newSprite("ccbResources/DZXXLRes/image/JCXX_touxiangkuang_da.png")
        if not bSuccess then  
            -- 失败处理 设置默认头像          
            local faceID = tonumber(DBID) % 10 + 1
            sprite = display.newSprite("ccbResources/icon/"..faceID..".jpg")
        end

        local circleSp = display.createCircleSprite(sprite, mask)
        circleSp:setContentSize(cc.size(100, 100))
        circleSp:setTag(100)
        circleSp:addTo(spriteNode)

	end
	filefunc.openFace(nPicID,linster)
end

function XXLPoolInfo:Func_onClickClosebtn()

	manager.popup:closePopup()
end
function XXLPoolInfo:showAnim()
	self:setVisible(false)
	self:setScale(0.01)
	action=cca.seq({cca.show(),cca.scaleTo(0.15, 1.5)})
	action:setTag(PopAnimTag)
	self:stopAllActionsByTag(PopAnimTag)
	self:runAction(action)
end
function XXLPoolInfo:hideAnim()
	local action = cca.seq({cca.scaleTo(0.1, 0.05),cca.hide()})
	action:setTag(PopAnimTag)
	self:stopAllActionsByTag(PopAnimTag)
	self:runAction(action)
end
function XXLPoolInfo:removeAnim()
	local action = cca.seq({cca.scaleTo(0.1, 0.05),cca.removeSelf()})
	action:setTag(PopAnimTag)
	self:stopAllActionsByTag(PopAnimTag)
	self:runAction(action)
end

return XXLPoolInfo