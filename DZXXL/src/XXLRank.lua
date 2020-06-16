local XXLRank = class("XXLRank", function()
	return cc.uiloader:load("ccbResources/DZXXLRes/ui/node_xxl_rank.csb")
end)

function XXLRank:ctor()
	self:initView()
	self:initClick()
	self:setData()
	self:setPosition(cc.p(display.cx, display.cy))
end

function XXLRank:initView()
	self.closeBtn = cc.uiloader:seekCsbNodeByName(self, "img_close")
	self.scrollView = cc.uiloader:seekCsbNodeByName(self, "ScrollView_1")
end

function XXLRank:initClick()
	display.setImageClick(self.closeBtn, handler(self, self.onClickClose))
end

function XXLRank:setData()
	self.scrollView:stopAllActions()
	self.scrollView:removeAllChildren()
	self.rankItems = nil
	self.rankItems = {}

	local rankDatas = center.rank:getRankingList()[3]
	dump(center.rank:getRankingList(), " ============= rankDatas: ")
	local itemSize = cc.size(1335, 143)

	local count = 0
	if not rankDatas then
		return
	end
	for k,v in pairs(rankDatas) do
		if tonumber(v.nActorDBID) ~= 0 then
			count = count + 1
		end
	end
	
	local scrollViewSize = cc.size(self.scrollView:getContentSize().width, count * itemSize.height)
	if scrollViewSize.height < 520 then
		scrollViewSize = self.scrollView:getContentSize()
	end
	self.scrollView:setInnerContainerSize(scrollViewSize)
	self.scrollView:setScrollBarEnabled(false)

	local bgnIndex = 1
	if count > 8 then
		local repeatTimes = math.modf(count / 8)
        if count % 8 > 0 then
            repeatTimes = repeatTimes + 1
        end

		self.scrollView:runAction(cc.Repeat:create(cc.Sequence:create(
				cc.CallFunc:create(function()
					local itemDatas = {}
					for i=bgnIndex,bgnIndex + 7 do
						if i <= count then
							table.insert(itemDatas, rankDatas[i])
						else 
							break
						end
					end
					bgnIndex = bgnIndex + 8
					self:addListItems(itemDatas)
				end),
				cc.DelayTime:create(0.5)
			), repeatTimes))
	else
		self:addListItems(rankDatas)
	end

	self:setMyInfo()
end

function XXLRank:setMyInfo()
	local myImgPlace = cc.uiloader:seekCsbNodeByName(self, "img_myplace")
	local myTxtPlace = cc.uiloader:seekCsbNodeByName(self, "txt_myplace")
	local myName = cc.uiloader:seekCsbNodeByName(self, "txt_myname")
	local myMission = cc.uiloader:seekCsbNodeByName(self, "txt_mymission")
	local myRedpacket = cc.uiloader:seekCsbNodeByName(self, "txt_myredpacket")
	local myHeadPos = cc.uiloader:seekCsbNodeByName(self, "node_headPos")

	local myActor = center.user:getMyActor()
	myName:setString(helpUntile.GetShortName(myActor["szName"], 12, 12))

	local function linster(bSuccess, sprite)
		if tolua.isnull(myHeadPos) then
			return
		end

		if myHeadPos:getChildByTag(100) then
			myHeadPos:removeChildByTag(100, true)
		end		

		local size = cc.size(100, 100)
		local mask = display.newSprite("ccbResources/DZXXLRes/image/JCXX_touxiangkuang_da.png")
        if not bSuccess then  
            -- 失败处理 设置默认头像          
            local faceID = tonumber(myActor[ACTOR_PROP_DBID])%10 + 1
            sprite = display.newSprite("ccbResources/icon/"..faceID..".jpg")
        end

        local circleSp = display.createCircleSprite(sprite, mask)
        circleSp:setContentSize(cc.size(size.width, size.height))
        circleSp:setTag(100)
        circleSp:addTo(myHeadPos)

	end
	filefunc.openFace(myActor["szMD5FaceFile"], linster)

	local myRankData = center.rank:getMyRankData(3)
	if myRankData and next(myRankData) then

		myImgPlace:setVisible(tonumber(myRankData.nRanking) <= 3)
		myTxtPlace:setVisible(tonumber(myRankData.nRanking) > 3)

		if tonumber(myRankData.nRanking) > 3 then
			myTxtPlace:setString(myRankData.nRanking)		
		else
			myImgPlace:loadTexture("ccbResources/DZXXLRes/image/plaza_ZJM_PHB_PM" .. myRankData.nRanking .. ".png")
		end

		myMission:setString(myRankData.nValue .. "关")
		local num = helpUntile.FormateNumber(tostring(myRankData.nValueEx))
		myRedpacket:setString("x" .. num)
	else
		local myDatas = center.task:getXXLGuankaData()
		myImgPlace:setVisible(false)
		myTxtPlace:setVisible(true)
		myTxtPlace:setString("未上榜")
		if next(myDatas) ~= nil then
			local nGuanKaID = checkint(myDatas.nGuanKaID)
			myMission:setString(nGuanKaID .. "关")
			local nRedCount = checkint(myDatas.nRedCount)
			local num = helpUntile.FormateNumber(tostring(nRedCount))
			myRedpacket:setString("x" .. num)	
		else
			myMission:setString("")
			myRedpacket:setString("")	
		end
	end
end

function XXLRank:addListItems(datas)
	local listSize = self.scrollView:getInnerContainerSize()
	local itemHeight = 143
	local bgnY = listSize.height - itemHeight * 0.5
	local bgnIndex = #self.rankItems + 1
	if #self.rankItems > 0 then
		bgnY = bgnY - ((bgnIndex - 1) * itemHeight)
	end

	local itemRes = "ccbResources/DZXXLRes/ui/node_xxl_rank_item.csb"
	for k,v in pairs(datas) do
		self.rankItems[bgnIndex] = cc.uiloader:load(itemRes)
			:addTo(self.scrollView)
			:pos(listSize.width * 0.5, bgnY - (k - 1) * itemHeight)

		local imgPlace = cc.uiloader:seekCsbNodeByName(self.rankItems[bgnIndex], "img_place")
		local txtPlace = cc.uiloader:seekCsbNodeByName(self.rankItems[bgnIndex], "txt_place")
		local name = cc.uiloader:seekCsbNodeByName(self.rankItems[bgnIndex], "txt_name")
		local mission = cc.uiloader:seekCsbNodeByName(self.rankItems[bgnIndex], "txt_mission")
		local redpacket = cc.uiloader:seekCsbNodeByName(self.rankItems[bgnIndex], "txt_redpacket")
		local nodeHead = cc.uiloader:seekCsbNodeByName(self.rankItems[bgnIndex], "node_headpos")

		name:setString(helpUntile.GetShortName(v.szName, 12, 12))
		mission:setString(v.nValue .. "关")
		local num = helpUntile.FormateNumber2(tostring(v.nValueEx))
		redpacket:setString("x" .. num)

		imgPlace:setVisible(tonumber(v.nRanking) <= 3)
		txtPlace:setVisible(tonumber(v.nRanking) > 3)
		if tonumber(v.nRanking) > 3 then
			txtPlace:setString(v.nRanking)		
		else
			imgPlace:loadTexture("ccbResources/DZXXLRes/image/plaza_ZJM_PHB_PM" .. v.nRanking .. ".png")
		end

		local function linster(bSuccess, sprite)
			if tolua.isnull(nodeHead) then
				return
			end

			if nodeHead:getChildByTag(100) then
				nodeHead:removeChildByTag(100, true)
			end		

			local size = cc.size(100, 100)
			local mask = display.newSprite("ccbResources/DZXXLRes/image/JCXX_touxiangkuang_da.png")
	        if not bSuccess then  
	            -- 失败处理 设置默认头像          
	            local faceID = tonumber(v.nActorDBID) % 10 + 1
	            sprite = display.newSprite("ccbResources/icon/"..faceID..".jpg")
	        end

	        local circleSp = display.createCircleSprite(sprite, mask)
	        circleSp:setContentSize(cc.size(size.width, size.height))
	        circleSp:setTag(100)
	        circleSp:addTo(nodeHead)
		end
		filefunc.openFace(v.szMD5FaceFile, linster)
		bgnIndex = bgnIndex + 1
	end

end

function XXLRank:onClickClose()
	manager.popup:popPopup(POPUP_ID.POPUP_TYPE_XXL_RANK)
end

return XXLRank