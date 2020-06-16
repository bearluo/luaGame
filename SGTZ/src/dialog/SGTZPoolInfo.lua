local PopupWindow = require("script.ui.PopupWindow")
local SGTZPoolInfo=class("SGTZPoolInfo",PopupWindow)
local RANK_ITEM_PAHT = "ccbResources/SGTZRes/ui/item/node_poolinfo_rank_item.csb"

local BIAOGE_PAHT = {
	"",
	"ccbResources/SGTZRes/image/dec/JCXX_biaoge_2.png",
	"ccbResources/SGTZRes/image/dec/JCXX_biaoge_3.png",
	"ccbResources/SGTZRes/image/dec/JCXX_biaoge_4.png",
	"ccbResources/SGTZRes/image/dec/JCXX_biaoge_4.png",
}
function SGTZPoolInfo:ctor()
	self.super.ctor(self,"ccbResources/SGTZRes/ui/dialog/SGTZGoldPoolInfo.csb")
	--//关闭按钮
	local closebtn = cc.uiloader:seekCsbNodeByName(self, "close_layer");
	display.setImageClick(closebtn,handler(self,self.Func_onClickClosebtn))
end

function SGTZPoolInfo:initPoolInfo(poolinfo)

	local gold_pool_num = cc.uiloader:seekCsbNodeByName(self, "gold_pool_num")
	local t_str2 = string.formatnumberthousands(tostring(poolinfo.AllGold))
	gold_pool_num:setString(""..t_str2)

	local todayTotalLabel = cc.uiloader:seekCsbNodeByName(self, "txt_todayTotal")
	todayTotalLabel:setString(poolinfo.nDayWinAllGold)
	-- local todayIcon = cc.uiloader:seekCsbNodeByName(self, "img_todayIcon")
	-- todayIcon:pos(todayTotalLabel:getPositionX() - todayTotalLabel:getContentSize().width * 0.5 - todayIcon:getContentSize().width * 0.25 - 5, todayIcon:getPositionY())
	
	self:initRewardInfo(poolinfo)

	local preName = cc.uiloader:seekCsbNodeByName(self, "pre_player_name")
	local preGold = cc.uiloader:seekCsbNodeByName(self, "pre_reward_gold")
	local preTime = cc.uiloader:seekCsbNodeByName(self, "pre_player_time")
	local LastWinningDBID = tonumber(poolinfo.PersonItem[1].nActorDBID)  
	if LastWinningDBID > 0 then
		self.userIconLayer = cc.uiloader:seekCsbNodeByName(self, "pre_player_head")
		local UserIconImg = display.newSprite()
		self.userIconLayer:addChild(UserIconImg)
		--待完善
		t_str2 = helpUntile.GetShortName(poolinfo.PersonItem[1].szPoolPlayerName, 12, 12)
		preName:setString(""..t_str2);	
		t_str2 = poolinfo.PersonItem[1].szPoolPlayerFace

		--待完善
		self:getWinUserIcon(t_str2, UserIconImg, poolinfo.PersonItem[1].nActorDBID)

		t_str2 = helpUntile.FormateNumber3(tonumber(poolinfo.PersonItem[1].nGold))
		preGold:setString(""..t_str2)
		preTime:setString(os.date("%m-%d %H:%M", poolinfo.PersonItem[1].nTimes))
	else
		preName:setString("")
		preGold:setString("")
		preTime:setString("")
	end


	local itemRes = RANK_ITEM_PAHT
	local rankView = cc.uiloader:seekCsbNodeByName(self, "ScrollView_1")
	local itemSize = cc.size(594, 110)

	local count = 0
	for i=2,#poolinfo.PersonItem do
		if tonumber(poolinfo.PersonItem[i].nActorDBID) ~= 0 then
			count = count + 1
		end
	end
	
	local scrollViewSize = cc.size(rankView:getContentSize().width, count * itemSize.height + itemSize.height/ 2)
	if scrollViewSize.height < 413 then
		scrollViewSize = rankView:getContentSize()
	end
	rankView:setInnerContainerSize(scrollViewSize)
	rankView:setScrollBarEnabled(false)
	local x, bgnY = rankView:getContentSize().width * 0.5, scrollViewSize.height - itemSize.height/ 2
	local index = 1

	self.items = {}
	for i=2,#poolinfo.PersonItem do
		if tonumber(poolinfo.PersonItem[i].nActorDBID) ~= 0 then
			local item = cc.uiloader:load(itemRes)
				:addTo(rankView)
				:pos(x, bgnY - (index - 1) * itemSize.height)

			local name = cc.uiloader:seekCsbNodeByName(item, "txt_name")
			local money = cc.uiloader:seekCsbNodeByName(item, "txt_money")
			local head = cc.uiloader:seekCsbNodeByName(item, "head_pos")
			local times = cc.uiloader:seekCsbNodeByName(item, "txt_times")
			
			name:setString(helpUntile.GetShortName(poolinfo.PersonItem[i].szPoolPlayerName, 12, 12))
			money:setString(helpUntile.FormateNumber3(tonumber(poolinfo.PersonItem[i].nGold)))
			times:setString(os.date("%m-%d %H:%M", poolinfo.PersonItem[i].nTimes))

			local function linster(bSuccess, sprite)
				print("sssszzz",bSuccess)

				if tolua.isnull(head) then
		            return
		        end

		        if not tolua.isnull(head) and head:getChildByTag(100) then
		            head:removeChildByTag(100, true)
		        end

		        local mask = display.newSprite("ccbResources/SGTZRes/image/dec/JCXX_touxiangkuang_xiao.png")
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
			count = count + 1
		end
	end

end

function SGTZPoolInfo:initRewardInfo(poolinfo)
	local count = 0
	for k,v in pairs(poolinfo.Bonus) do
		if tonumber(v) ~= 0 then
			count = count + 1
		else
			break
		end
	end
	local width, height = 872, 96 * count

	local titleNode = cc.uiloader:seekCsbNodeByName(self, "img_rewardTitle")
	local itemWidth, itemHeigt = width, height / count
	local bgnX, bgnY = titleNode:getPositionX(), titleNode:getPositionY() - titleNode:getContentSize().height * 0.5
	local offsetX = 0
	local offsetWidth = 0
	local fontRes = "ccbResources/fonts/fangzheng.ttf"
	for k,v in pairs(poolinfo.Bonus) do

		if tonumber(v) == 0 then
			break
		end
		offsetX = 0
		offsetWidth = 0
		local imageName = ""
		if k == count then
			imageName = BIAOGE_PAHT[5]
			if k % 2 == 0 then
				imageName = BIAOGE_PAHT[4]
			end
		else
			imageName = BIAOGE_PAHT[2]
			if k % 2 == 0 then
				offsetX = 0
				imageName = BIAOGE_PAHT[3]
			else
				-- offsetWidth = -8
			end
		end

		local curY = bgnY - (k - 1) * itemHeigt
		-- display.newScale9Sprite(
		-- 		imageName, 
		-- 		bgnX+offsetX, curY, 
		-- 		cc.size(itemWidth+offsetWidth, itemHeigt), 
		-- 		cc.rect(455, 15, 1, 1)
		-- 	)
		local bg = display.newSprite(
				imageName,
				bgnX, curY 
			)
			:setAnchorPoint(cc.p(0.5, 1))
			:addTo(titleNode:getParent())
		curY = curY - bg:getContentSize().height * 0.5
		cc.ui.UILabel.new({
				text = v * 10,
				font = fontRes,
				size = 32,
				color = cc.c3b(0xd9, 0x56, 0x1c)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(titleNode:getParent())
			:pos(-620, curY)		

		cc.ui.UILabel.new({
				text = ((tonumber(poolinfo.poolProportion1[k]) / 1000) * 100) .. "%",
				font = fontRes,
				size = 32,
				color = cc.c3b(0xd9, 0x56, 0x1c)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(titleNode:getParent())
			:pos(-415, curY)	

		cc.ui.UILabel.new({
				text = "赢得",
				font = fontRes,
				size = 32,
				color = cc.c3b(0xa9, 0x44, 0x1c)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(titleNode:getParent())
			:pos(-415 - 65, curY)		
		cc.ui.UILabel.new({
				text = "宝库",
				font = fontRes,
				size = 32,
				color = cc.c3b(0xa9, 0x44, 0x1c)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(titleNode:getParent())
			:pos(-415 + 65, curY)

		cc.ui.UILabel.new({
				text = ((tonumber(poolinfo.poolProportion2[k]) / 1000) * 100) .. "%",
				font = fontRes,
				size = 32,
				color = cc.c3b(0xd9, 0x56, 0x1c)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(titleNode:getParent())
			:pos(-180, curY)	
		cc.ui.UILabel.new({
				text = "赢得",
				font = fontRes,
				size = 32,
				color = cc.c3b(0xa9, 0x44, 0x1c)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(titleNode:getParent())
			:pos(-180 - 65, curY)		
		cc.ui.UILabel.new({
				text = "宝库",
				font = fontRes,
				size = 32,
				color = cc.c3b(0xa9, 0x44, 0x1c)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(titleNode:getParent())
			:pos(-180 + 65, curY)	

		cc.ui.UILabel.new({
				text = ((tonumber(poolinfo.poolProportion3[k]) / 1000) * 100) .. "%",
				font = fontRes,
				size = 32,
				color = cc.c3b(0xd9, 0x56, 0x1c)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(titleNode:getParent())
			:pos(55, curY)
		cc.ui.UILabel.new({
				text = "赢得",
				font = fontRes,
				size = 32,
				color = cc.c3b(0xa9, 0x44, 0x1c)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(titleNode:getParent())
			:pos(55 - 65, curY)		
		cc.ui.UILabel.new({
				text = "宝库",
				font = fontRes,
				size = 32,
				color = cc.c3b(0xa9, 0x44, 0x1c)
			})
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(titleNode:getParent())
			:pos(55 + 65, curY)	
	end
end

function SGTZPoolInfo:getWinUserIcon(nPicID, spriteNode, DBID)
	local function linster(bSuccess,sprite)
		print("sssszzz",bSuccess)

		if tolua.isnull(spriteNode) then
            return
        end

        if not tolua.isnull(spriteNode) and spriteNode:getChildByTag(100) then
            spriteNode:removeChildByTag(100, true)
        end

        local mask = display.newSprite("ccbResources/SGTZRes/image/dec/JCXX_touxiangkuang_da.png")
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

function SGTZPoolInfo:Func_onClickClosebtn()

	manager.popup:closePopup()
end

return SGTZPoolInfo