local RES_FANGZHENGTTF = "ccbResources/fonts/fangzheng.ttf"
local HornView = import("game.public.HornView")
local XXLAni = require("game.DZXXL.XXLAni")
local HornView = import("game.public.HornView")
local PlazaController = require("script.view.plaza.plazaMain.PlazaController")
local XXLLayer = class("XXLLayer", function()
    local node = cc.uiloader:load("ccbResources/DZXXLRes/ui/XXLLayer.csb") 
    node:setAnchorPoint(cc.p(0.5,0.5))
    node:setContentSize(cc.size(display.width, display.height))
    ccui.Helper:doLayout(node)
    return node
end)

require("game.public.chinessDef")
require("game.public.toolsFunc")
require("game.DZXXL.XXL_Def")
require("game.DZXXL.debugDatas")

--引用框架内的调度器
local scheduler = require("framework.scheduler")
local resPath = "ccbResources/DZXXLRes/image/"
local elementImgs = {"XXL_yuansu1.png", "XXL_yuansu5.png", "XXL_yuansu3.png", "XXL_yuansu2.png", "XXL_yuansu4.png", "XXL_landlord.png"}

local debugIndex = 0

function XXLLayer:ctor()
	print("---XXLLayer.ctor---") 
	local tmp = cc.UserDefault:getInstance():getIntegerForKey("IsXxlSpeedUp", 0)
	if tmp == 0 then
		self.aniSpeed = 1
	else
		self.aniSpeed = 1.8
	end
	self.showPoolType = 1					--1：点击奖池；2：点击右侧元素规则
	self.m_Longpress = false 				--是否长按开始按钮
	self.m_TouchBtnTime = 0 				--长按开始按钮累计时间	
	self.m_btPlatFormFlag = 0 				--平台标记，是否为试玩，0不是，1是
	self.betNums = {}						--底注数组
	self.betIndexs = {2, 2, 2, 2, 2}		--五个下注的底注下标
	self.betMaxIndex = 0					--最大下注底注下标
	self.totalBet = 0						--当前总投入
	self.blocks = {}						--方块队列
	self.curScore = 0						--当前得分
	self.isPlaying = false 					--当前是否在摇奖中
	self.myCurGold = 0						--当前金币
	self.historyItems = {}					--左侧历史记录元素数组
	self.historyEleData = {}				--左侧历史记录数据
	self.removeMusicIndex = 2				--
	self.isSettling = false
	self.m_isShowRedPacketTips = true --是否显示领取红包的 气泡提示
	self.isClickStartBtn = false
	self.nRate = {} -- 倍率配置

	self.mXXLGuankaConfig = {} -- 消消乐关卡配置

	self.m_aniManager = XXLAni.new(self) 		--动画管理器

	self:setPosition(display.cx,display.cy)
	self:initView()
	self:initClick()
	self:initBlockPanel()
	self:updateDropAniBtnStatus(self.aniSpeed)
	self:initHornView()
	self:autoFited(self)
	self:registerEvent()

	for k,v in pairs(self.betIndexs) do
		local key = "XxlSelIndex_" .. k
		self.betIndexs[k] = cc.UserDefault:getInstance():getIntegerForKey(key, 2)
	end

	musicfunc.playGamePlayBGMusic(XXL_MSG.MUSIC_NAMES[14])
	self.guideFlag = center.user:getActorProp(ACTOR_PROP_GUIDE_ID_FLAGS)
	self.guideOpen = true
end

function XXLLayer:autoFited()
	if ( display.widthInPixels / display.heightInPixels ) >= 2 then
		local node_top_left = cc.uiloader:seekCsbNodeByName(self, "node_top_left")
		local node_center_left = cc.uiloader:seekCsbNodeByName(self, "node_center_left")
		local node_bottom_left = cc.uiloader:seekCsbNodeByName(self, "node_bottom_left")
		local node_top_right = cc.uiloader:seekCsbNodeByName(self, "node_top_right")
		local node_center_right = cc.uiloader:seekCsbNodeByName(self, "node_center_right")
		local node_bottom_right = cc.uiloader:seekCsbNodeByName(self, "node_bottom_right")
		node_top_left:moveBy(0, 66)
		node_center_left:moveBy(0, 66)
		node_bottom_left:moveBy(0, 66)
		node_top_right:moveBy(0, -66)
		node_center_right:moveBy(0, -66)
		node_bottom_right:moveBy(0, -66)
	end
end

-- function XXLLayer:initDebug()
-- 	local debugBtn = cc.uiloader:seekCsbNodeByName(self, "img_debug")
-- 	debugBtn:setVisible(false)
-- 	display.setImageClick(debugBtn, handler(self, function()
-- 		debugIndex = debugIndex % #debugDatas
-- 		debugIndex = debugIndex + 1

-- 		if debugIndex == 1 then
-- 			local datas = debugDatas[debugIndex]
-- 			self.m_pGameSink:OnGameMessage(datas.btCmd, datas.dict)
-- 		else
-- 			for i=2,#debugDatas do
-- 				local datas = debugDatas[i]
-- 				self.m_pGameSink:OnGameMessage(datas.btCmd, datas.dict)
-- 			end
-- 		end

-- 	end))
-- end

function XXLLayer:getOnMessageFun()
    return self.OnMessageFun
end

function XXLLayer:setOnMessageFun(pOnMessageFun)
    self.OnMessageFun = pOnMessageFun
end

function XXLLayer:initView()
	self.exitBtn = cc.uiloader:seekCsbNodeByName(self, "img_returnBtn")
	self.missionBtn = cc.uiloader:seekCsbNodeByName(self, "img_missionBtn")
	self.dropAniBtn = cc.uiloader:seekCsbNodeByName(self, "img_noAniBtn")
	self.img_leftBg = cc.uiloader:seekCsbNodeByName(self, "img_leftBg")
	self.poolBtn = cc.uiloader:seekCsbNodeByName(self, "img_poolBtn")
	self.storeBtn = cc.uiloader:seekCsbNodeByName(self, "img_storeBtn")
	self.roleBtn = cc.uiloader:seekCsbNodeByName(self, "img_roleBtn")
	self.totalCutBtn = cc.uiloader:seekCsbNodeByName(self, "img_totalCutBtn")
	self.totalAddBtn = cc.uiloader:seekCsbNodeByName(self, "img_totalAddBtn")
	self.startBtn = cc.uiloader:seekCsbNodeByName(self, "img_startBtn")
	self.moreMenuSet = cc.uiloader:seekCsbNodeByName(self, "img_setBtn")
	self.moreMenuRole = cc.uiloader:seekCsbNodeByName(self, "img_role")
	self.rankBtn = cc.uiloader:seekCsbNodeByName(self, "img_rank_xxl"):setVisible(not display.isAppstore)

	local parentNode = cc.uiloader:seekCsbNodeByName(self, "node_rank")
	local rankBtnPath = "ccbResources/public/ui/rank/node_rank_tab_paihangbang.csb"
	self.yuleRankBtn = cc.uiloader:load(rankBtnPath)
		:addTo(parentNode)
		:pos(0, 0)

	self.yuleRankAction = cc.uiloader:csbAniload(rankBtnPath)
	self.rankCountDown = cc.uiloader:seekCsbNodeByName(self.yuleRankBtn, "txt_rankTime")
	local rankBtnImage = cc.uiloader:seekCsbNodeByName(self.yuleRankBtn, "PHB_tubiao_1")
	display.setImageClick(rankBtnImage, handler(self, self.onClickYuLeRank))

	local rankConfig = gameCenter.smGame:getYuleRankManager():getYuleRankConfig()
	if next(rankConfig) ~= nil then
		self.yuleRankBtn:setVisible(true)
		self.rankTotalSecond = tonumber(rankConfig.nCountDownTime)
		self:setRankCountTime()
		self:startCountDownRankTime()
	else
		self.yuleRankBtn:setVisible(false)
	end

	local btnCount = 5
	self.cutBtns = {}
	for i=1,btnCount do
		self.cutBtns[i] = cc.uiloader:seekCsbNodeByName(self, "img_cutBtn_" .. i)
	end	

	self.addBtns = {}
	for i=1,btnCount do
		self.addBtns[i] = cc.uiloader:seekCsbNodeByName(self, "img_addBtn_" .. i)
	end	

	self.node_center_right = cc.uiloader:seekCsbNodeByName(self, "node_center_right")
	self.img_rightBg = cc.uiloader:seekCsbNodeByName(self, "img_rightBg")

	self.curRewardLabel = cc.uiloader:seekCsbNodeByName(self, "txt_curReward")
	self.userMoneyLabel = cc.uiloader:seekCsbNodeByName(self, "txt_userMoney")
	self.totalBetLabel = cc.uiloader:seekCsbNodeByName(self, "txt_total")
	self.poolMoneyLabel = cc.uiloader:seekCsbNodeByName(self, "txt_poolMoney")

	self.betLabels = {}
	for i=1,btnCount do
		self.betLabels[i] = cc.uiloader:seekCsbNodeByName(self, "txt_label_" .. i)
	end

	self.poolMoneyLabel:setString("")
	self.curRewardLabel:setString("0")
	self.totalBetLabel:setString("0")
	local myActor = center.user:getMyActor()
	if myActor then
		self.userMoneyLabel:setString(helpUntile.FormateNumber2(myActor[ACTOR_PROP_GOLD]))
		self.myCurGold = tonumber(myActor[ACTOR_PROP_GOLD])
	else
		self.myCurGold = 0
		self.userMoneyLabel:setString("0")
	end

	self.historyScrollView = cc.uiloader:seekCsbNodeByName(self, "scrollView_history")
	self.historyScrollView:setScrollBarEnabled(false)

	self.blockPanel = cc.uiloader:seekCsbNodeByName(self, "panel_block")
	self.centerBg = cc.uiloader:seekCsbNodeByName(self, "img_centerBg")
	self:updateTaskAccess()

	if center.roomList:isXXLGameModel() then
		self.roleBtn:loadTexture("ccbResources/DZXXLRes/image/XXL_jiangjindizhu_n.png")
	end

	self.Image_task_panel = cc.uiloader:seekCsbNodeByName(self, "Image_task_panel"):setVisible(false)
	self.Image_element_model = cc.uiloader:seekCsbNodeByName(self.Image_task_panel, "Image_element_model"):setVisible(false)
	self.Node_element_pos = cc.uiloader:seekCsbNodeByName(self.Image_task_panel, "Node_element_pos")
	self.mRemoveElementViews = {}
	self.Text_guanka = cc.uiloader:seekCsbNodeByName(self.Image_task_panel, "Text_guanka")
	self.Text_chip_tips = cc.uiloader:seekCsbNodeByName(self.Image_task_panel, "Text_chip_tips")
	self.Image_bubbleTip = cc.uiloader:seekCsbNodeByName(self, "Image_bubbleTip"):setVisible(false)
	self.img_gq_type = cc.uiloader:seekCsbNodeByName(self, "img_gq_type")
	local lastTime = cc.UserDefault:getInstance():getIntegerForKey("TodayFirstLoginXXLL",0)
	local dateTimeNow = tonumber(os.date("%d"))
	if lastTime == 0 then
		cc.UserDefault:getInstance():setIntegerForKey("TodayFirstLoginXXLL",dateTimeNow)
		self.Image_bubbleTip:setVisible(true)
		self.Image_bubbleTip:performWithDelay(function ()
			self.Image_bubbleTip:setVisible(false)
		end,3)
	else
		if lastTime ~= dateTimeNow then
			cc.UserDefault:getInstance():setIntegerForKey("TodayFirstLoginXXLL",dateTimeNow)
			self.Image_bubbleTip:setVisible(true)
			self.Image_bubbleTip:performWithDelay(function ()
				self.Image_bubbleTip:setVisible(false)
			end,3)
		end
	end
	self:resetShowXXLTask()

	if center.roomList:isXXLGameModel() then
		self:initXXLMenu()
	end
	self.m_aniManager:addTaskAni(self.Image_task_panel)


	self.Image_btn_cqg = cc.uiloader:seekCsbNodeByName(self, "Image_btn_cqg"):setVisible(false)
	self.Image_btn_ybwl = cc.uiloader:seekCsbNodeByName(self, "Image_btn_ybwl"):setVisible(false)
	PlazaController.initBigProfitBtn(self, self.Image_btn_ybwl)
	PlazaController.initSavingPotBtn(self, self.Image_btn_cqg)
end

function XXLLayer:setRankCountTime()
	local day = math.modf(self.rankTotalSecond / 86400)

	local leftSecond = self.rankTotalSecond - day * 86400
	local hour = math.modf(leftSecond / 3600)

	leftSecond = leftSecond - hour * 3600
	local min = leftSecond / 60
	self.rankCountDown:setString(string.format("%d", day) .. "天" .. string.format("%02d", hour) .. "时" .. string.format("%02d", min)  .. "分")
end

function XXLLayer:startCountDownRankTime()
	self.yuleRankBtn:stopAllActions()
	self.yuleRankBtn:runAction(cc.Repeat:create(cc.Sequence:create(
		cc.DelayTime:create(1),
		cc.CallFunc:create(function()
			self.rankTotalSecond = self.rankTotalSecond - 1
			self:setRankCountTime()
		end)
	), self.rankTotalSecond))

	local rankBtnPath = "ccbResources/public/ui/rank/node_rank_tab_paihangbang.csb"
	self.yuleRankAction = cc.uiloader:csbAniload(rankBtnPath)
	self.yuleRankBtn:runAction(self.yuleRankAction)
	self.yuleRankAction:gotoFrameAndPlay(0, true)
end

function XXLLayer:initClick()
	display.setImageClick(self.exitBtn, handler(self, self.onClickExitBtn), 1, true)
	display.setImageClick(self.missionBtn, handler(self, self.onClickMissionBtn), 1, true)
	display.setImageClick(self.dropAniBtn, handler(self, self.onClickDropAniBtn))
	display.setImageClick(self.poolBtn, handler(self, self.onClickPoolBtn))
	display.setImageClick(self.storeBtn, handler(self, self.onClickStoreBtn))
	display.setImageClick(self.roleBtn, handler(self, self.onClickRoleBtn))
	display.setImageClick(self.totalCutBtn, handler(self, self.onClickTotalCutBtn), 1, true)
	display.setImageClick(self.totalAddBtn, handler(self, self.onClickTotalAddBtn), 1, true)
	display.setImageClick(self.moreMenuSet, handler(self, self.onClickSetBtn))
	display.setImageClick(self.moreMenuRole, handler(self, self.onClickGameRoleBtn))
	display.setImageClick(self.Image_task_panel, handler(self, self.showXXLTaskInfo))
	display.setImageClick(self.rankBtn, handler(self, self.onClickRank))

	for k,v in pairs(self.cutBtns) do
		display.setImageClick(v, handler(self, function()
			self:onClickCut(k)
		end), 1, true)
	end	

	for k,v in pairs(self.addBtns) do
		display.setImageClick(v, handler(self, function()
			self:onClickAdd(k)
		end), 1, true)
	end

	local function onTouchBegan(touch, event)
        local size = self.startBtn:getContentSize()
		local rect = cc.rect(-size.width / 2, -size.height / 2, size.width, size.height)
		local pTouch = self.startBtn:convertTouchToNodeSpaceAR(touch)--转换 触摸 到 节点空间	

		--判断是否触摸点在开始按钮上	
		if (not cc.rectContainsPoint(rect, pTouch)) then	
			return false
		else
			musicfunc.play2d(XXL_MSG.MUSIC_NAMES[9])
			self.startBtn:setScale(0.95)
			if self.m_Longpress then
				self.m_Longpress = false	
				self:unscheduleUpdateBtnTime()
				self.startBtn:loadTexture("ccbResources/DZXXLRes/image/XXL_btn_start.png")
				self.m_aniManager:stopStartBtnAni(self.startBtn)
			else
				self:unscheduleUpdateBtnTime()
				self.schedule_updatBtnTime = self.startBtn:schedule(handler(self, self.updateBtnTime), 0.01)-- scheduler.scheduleGlobal(handler(self, self.updateBtnTime), 0.01)	
			end
			
			return true
		end
	end	

	local function onTouchMoved(touch, event)
	end	

	local function onTouchEnded(touch, event)
		self.startBtn:setScale(1)
		self:unscheduleUpdateBtnTime()
		self.m_TouchBtnTime = 0
		if not self.isPlaying and not self.isSettling and not self.isClickStartBtn then
			self.isClickStartBtn = true
			self:RequestStart()		
		end
	end

	local dispatcher = cc.Director:getInstance():getEventDispatcher()
    local touchListener = cc.EventListenerTouchOneByOne:create()
 
    touchListener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    touchListener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
    touchListener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED) 
    dispatcher:addEventListenerWithSceneGraphPriority(touchListener, self.startBtn) 
    touchListener:setSwallowTouches(false)

end

--累赢红包
function XXLLayer:initRedpacket()
	--默认隐藏
	self.m_redPocketTipNode = cc.uiloader:seekCsbNodeByName(self,"redPocketTipSP")
	self.m_redPocketTipNode:setVisible(false)
	return
	-- --试玩不执行后面的逻辑
	-- if self.m_btPlatFormFlag == 1 then
	-- 	return 
	-- end

	-- self.m_Node_redPack = cc.uiloader:seekCsbNodeByName(self,"Node_redPack")
	-- if center.task:isOpenBRDZYuleWinGoldTask() == true then
	-- 	if not self:showRedPacketAni() then
	-- 		if self.m_isShowRedPacketTips == true then
	-- 			self.m_isShowRedPacketTips = false
	-- 			self.m_redPocketTipNode:setVisible(true)
	-- 			local action = transition.sequence({
	-- 				cc.DelayTime:create(3),
	-- 				cc.CallFunc:create(function()
	-- 					self.m_redPocketTipNode:setVisible(false)
	-- 				end),
	-- 			})
	-- 			self.m_redPocketTipNode:runAction(action)
	-- 		end
	-- 	end
	-- end

	-- --是否是第一次进来直接弹出 领取红包窗口
	-- if XXL_MSG.IS_SHOW_REDPACKET == true then
	-- 	-- local view = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_RED_PACKET_TASK)
	-- end
end

--显示累赢红包结果
function XXLLayer:showRedPacketAni()
	local curPercent = 0
	local isFinish = true
	local nGoldNum = tonumber(center.task:getCurYuleWinGoldNum())
	local lastTime = cc.UserDefault:getInstance():getIntegerForKey("TodayFirstLoginXXL")
	local dateTimeNow = tonumber(os.date("%d"))
	if lastTime == 0 then
		cc.UserDefault:getInstance():setIntegerForKey("TodayFirstLoginXXL", dateTimeNow)
		XXL_MSG.IS_SHOW_REDPACKET = true
	else
		if lastTime ~= dateTimeNow then
			cc.UserDefault:getInstance():setIntegerForKey("TodayFirstLoginXXL", dateTimeNow)
			XXL_MSG.IS_SHOW_REDPACKET = true
		end
	end

	local LevelItem = center.task:getYuleWinGoldTaskInfo()
	local nRedPacket = 0
	local firstMaxValue = 0 --已经领取的金额
	for i,v in ipairs(LevelItem) do
		if nGoldNum > tonumber(v.nTotalWinGoldNum) and tonumber(v.uFlag) == 1  then
			firstMaxValue = v.nTotalWinGoldNum
		else
			curPercent = ((nGoldNum - firstMaxValue) / (tonumber(v.nTotalWinGoldNum) - firstMaxValue)) * 100
			if curPercent > 100  then
				curPercent = 100
			end
			nRedPacket = v.nRedPacketNum
			isFinish = false
			break
		end
	end
	
	if not isFinish and self.m_btPlatFormFlag == 0 then
		self:showRedPackAni(curPercent, nRedPacket)
	end

	return isFinish
end

function XXLLayer:showRedPackAni(nPercent, nRedPacket)
	if self.effectNode then
		self.effectNode:removeFromParent()
		self.effectNode = nil
	end

	local path = "ccbResources/public/ui/ani/tx_honbao_yeti.csb"
	if tolua.isnull(self.effectNode) then
		self.effectNode = cc.uiloader:load(path)
			:addTo(self.m_Node_redPack)
			:setLocalZOrder(-1)

		local bgSP = cc.uiloader:seekCsbNodeByName(self.effectNode,"LJZHB_hongbaotubiao_1")
		display.setCsbSpriteClick(bgSP, function()
			if center.task:getYuleWinGoldTaskType() == 0 then
				local view = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_RED_PACKET_TASK)
			else
				local view = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_RED_PACKET_SZ_TASK)
			end
		end)
	else
		self.effectNode:stopAllActions()
	end

	local Node_text = cc.uiloader:seekCsbNodeByName(self.effectNode, "Node_text")
	local Text_num = cc.uiloader:seekCsbNodeByName(Node_text, "Text_num")
	Text_num:setString(nRedPacket)

	--影藏光效
	local gxSP = cc.uiloader:seekCsbNodeByName(self.effectNode, "KSDH_guang_5_0")
	gxSP:setVisible(false)
	local gxSP_1 = cc.uiloader:seekCsbNodeByName(self.effectNode, "ani_guangxiao1_8")
	gxSP_1:setVisible(false)
	local sp_10 = cc.uiloader:seekCsbNodeByName(self.effectNode, "Sprite_10")
	sp_10:setVisible(false)

	--第二段效果
	local nodeNext = cc.uiloader:seekCsbNodeByName(self.effectNode, "Node_1")
	nodeNext:setVisible(false)

	if tolua.isnull(self.effectATL) then
		self.effectATL = cc.uiloader:csbAniload(path)
		self.effectNode:runAction(self.effectATL)
	end
	
	self.effectATL:gotoFrameAndPlay(0,false)
	self.effectATL:play("animation0",true)

	local panl =cc.uiloader:seekCsbNodeByName(self.effectNode,"Panel_1")
	local spRed = cc.uiloader:seekCsbNodeByName(self.effectNode,"Sprite_2")

	if nPercent<= 20 then
		panl:setContentSize(cc.size(93,17))
		spRed:setPosition(cc.p(0,-33))
	elseif nPercent <= 40 then
		panl:setContentSize(cc.size(93,27))
		spRed:setPosition(cc.p(0,-23))
	elseif nPercent <= 60 then
		panl:setContentSize(cc.size(93,37))
		spRed:setPosition(cc.p(0,-3))
	elseif nPercent <= 90 then
		panl:setContentSize(cc.size(93,47))
		spRed:setPosition(cc.p(0,7))
	elseif nPercent < 100 then
		panl:setContentSize(cc.size(93,85))
		spRed:setPosition(cc.p(0,17))
	elseif nPercent == 100 then
		panl:setContentSize(cc.size(93,117))
		spRed:setVisible(false)
		gxSP:setVisible(true)
		gxSP_1:setVisible(true)

		sp_10:setVisible(true)
		self.effectATL:play("animation0",false)
		nodeNext:setVisible(true)
		self.effectATL:play("animation1",true)
	end
end

function XXLLayer:initHornView()
	local nodeTopCenter = cc.uiloader:seekCsbNodeByName(self, "node_bottom_center")
	self.hornView = HornView.new()
        :addTo(nodeTopCenter)
        :pos(-140, 30)
end

--显示版本号
function XXLLayer:showVesText()
	local ver = "e709b0"
    display.newTTFLabel({
            text = ver,
            font = "Arial",
            size = 18,
            color = cc.c3b(98, 65, 28), -- 使用纯红色
        })
        :setAnchorPoint(cc.p(0, 0.5))
        :addTo(self)
        :pos(display.width * 0.85, 15)
        :setLocalZOrder(10000)
end

function XXLLayer:setGameSink(gamesink, pScene)
	self.m_pGameScene = pScene  	--游戏场景
	self.m_pGameSink = gamesink     --游戏逻辑
end

function XXLLayer:getGameSink()
	return self.m_pGameSink  --游戏逻辑
end

-- 监听事件
function XXLLayer:registerEvent()
	EventHelp.setEventIDLinster(self,handler(self,self.LuaEventLinster),
			{
				EVENT_ID.EVENT_PLAZA_TASK_CHANGE,			--任务状态改变消息
				EVENT_ID.EVENT_GLOBALLATTERY_UPDATE,--全局彩池更新
				EVENT_ID.EVENT_PLAZA_YULE_TOTAL_WIN_GOLD_NUM_CHANGE,
				EVENT_ID.EVENT_PLAZA_YULE_TOTAL_WIN_GOLD_TASK_STATUS_CHANGE,
				EVENT_ID.EVENT_GETREWARDTIPS, 
				EVENT_ID.EVENT_XXL_SHOW_CHALLENGE_GUANKA,
				EVENT_ID.EVENT_XXL_CHALLENGE_GUANKA,
				EVENT_ID.EVENT_YAO_QING_ModuleSwitch,
				EVENT_ID.EVENT_YULE_RANK_CONFIG,
				EVENT_ID.EVENT_YULE_RANK_CTRL,
				EVENT_ID.EVENT_GAME_EXIT,
			})
end

function XXLLayer:UnRegisterEvent()
	EventHelp.removeNodeEventID(self)
end

function XXLLayer:LuaEventLinster(EventID, varTB )
    if EventID == EVENT_ID.EVENT_PLAZA_TASK_CHANGE then
    	self:updateTaskAccess()
    elseif EventID == EVENT_ID.EVENT_GETREWARDTIPS then
    	--购买物品，金币发生变化
    	local myActor = center.user:getMyActor()
    	if myActor then
    		self.myCurGold = tonumber(myActor[ACTOR_PROP_GOLD])
			self:updateMyInfo()
    	end
    elseif EventID == EVENT_ID.EVENT_GLOBALLATTERY_UPDATE then
    	self:updatePoolMoney(varTB)
    elseif EventID == EVENT_ID.EVENT_PLAZA_YULE_TOTAL_WIN_GOLD_NUM_CHANGE or EventID == EVENT_ID.EVENT_PLAZA_YULE_TOTAL_WIN_GOLD_TASK_STATUS_CHANGE then
		-- self:showRedPacketAni()
	elseif EventID == EVENT_ID.EVENT_XXL_SHOW_CHALLENGE_GUANKA then
		local nGuanKaID = checkint(varTB)
		local config = center.task:getXXLGuankaConfigByID(nGuanKaID)
        if config then
			local size = self.Image_task_panel:getContentSize()
			local view = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_XXL_TASK_INFO,self.Image_task_panel:convertToWorldSpace(cc.p(size.width/2,size.height/2)))
            if view then
                view:setConfig(config,self:getXXLGuankaMulConfigInfo())
                view:showStartBtn()
                if self.m_Longpress then
                	view:setAutoClose()
                end
            end
        elseif center.task:isXXLGuankaOver() then
			self:resetShowXXLTask()
        end
	elseif EventID == EVENT_ID.EVENT_XXL_CHALLENGE_GUANKA then
		local nGuanKaID = checkint(varTB)
		self:resetShowXXLTask()
	elseif EventID == EVENT_ID.EVENT_YAO_QING_ModuleSwitch then
		local isOpen = center.yaoqing:isSwitchOpen("btXxlPassSwitch")
		if not isOpen or display.isAppstore then
			self.yuleRankBtn:setVisible(false)
		else
			self.yuleRankBtn:setVisible(true)
		end
	elseif EventID == EVENT_ID.EVENT_YULE_RANK_CONFIG then

		local rankConfig = gameCenter.smGame:getYuleRankManager():getYuleRankConfig()
		if next(rankConfig) ~= nil then
			self.yuleRankBtn:setVisible(true)
			self.rankTotalSecond = tonumber(rankConfig.nCountDownTime)
			self:setRankCountTime()
			self:startCountDownRankTime()
		else
			self.yuleRankBtn:stopAllActions()
			self.yuleRankBtn:setVisible(false)
		end
	elseif EventID == EVENT_ID.EVENT_YULE_RANK_CTRL then

		local rankConfig = gameCenter.smGame:getYuleRankManager():getYuleRankConfig()
		local isOpen =  gameCenter.smGame:getYuleRankManager():isYuleRankOpen()
		dump(rankConfig, " ========== isOpen: " .. tostring(isOpen))
		if isOpen and next(rankConfig) ~= nil then
			self.yuleRankBtn:setVisible(true)
			self.rankTotalSecond = tonumber(rankConfig.nCountDownTime)
			self:setRankCountTime()
			self:startCountDownRankTime()
		else
			self.yuleRankBtn:stopAllActions()
			self.yuleRankBtn:setVisible(false)
		end
	elseif EventID == EVENT_ID.EVENT_GAME_EXIT then
        self:onClickExitBtn()
    end
end

function XXLLayer:RemoveRes()	

end

function XXLLayer:CleanGameRes()
	self:stopAllActions()
	musicfunc.stopAllEffect()
	XXL_MSG.clean()
	self:UnRegisterEvent()
	self:RemoveRes()
	self:RemoveSchedule()	  
end


function XXLLayer:RemoveSchedule()

	self:unscheduleUpdateBtnTime()

end

function XXLLayer:updateTaskAccess()
	local nodeRedPoint = cc.uiloader:seekCsbNodeByName(self, "img_missionRedPoint")
    local count = center.task:getCanAwardTaskCount(TASK_TYPE_NOVICE) + center.task:getCanAwardTaskCount(TASK_TYPE_DAY) + center.task:getCanAwardTaskCount(TASK_TYPE_TIME) + center.task:getCanAwardTaskCount(TASK_TYPE_BUYU)
    if count > 0 then
        nodeRedPoint:setVisible(true)
    else
        nodeRedPoint:setVisible(false)
    end
end

function XXLLayer:updateMyInfo()
	self.userMoneyLabel:setString(helpUntile.FormateNumber2(self.myCurGold))
end

function XXLLayer:onClickYuLeRank()
	manager.popup:newPopup(POPUP_ID.POPUP_TYPE_YULE_RANK)
end


function XXLLayer:onClickExitBtn()
	self.m_pGameSink:OutRoom()
end

function XXLLayer:onClickMissionBtn()
	local view = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_TASK)
	if not view then 
		return 
	end

	local canAwardNoviceTask = center.task:getCanAwardTaskCount(TASK_TYPE_NOVICE)
	local canAwardDayTask = center.task:getCanAwardTaskCount(TASK_TYPE_DAY)
	if canAwardDayTask > 0 and canAwardNoviceTask == 0 then
		view:selectDaliyTask()
	else
		view:selectNoviceTask()
	end
end

function XXLLayer:onClickDropAniBtn()
	if self.aniSpeed == 1 then
		self.aniSpeed = 1.8
	else
		self.aniSpeed = 1
	end

	self:updateDropAniBtnStatus(self.aniSpeed)
end

function XXLLayer:onClickPoolBtn()
	self.showPoolType = 1
	self.m_pGameSink:RequestPoolInfo()
end

function XXLLayer:onClickStoreBtn()
	local shop = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_SHOP)
    shop:selectTagBtnByTagID(MALL_TAG_GOLD)
end

function XXLLayer:onClickRoleBtn()
	self.showPoolType = 2
	self.m_pGameSink:RequestPoolInfo()
end

function XXLLayer:RequestStart()
	print("RequestStart")
	local myActor = center.user:getMyActor()
	local myMoney = tonumber(myActor[ACTOR_PROP_GOLD])
	local total = self:getMyTotalBet()

	if total <= 0 then
		self.isClickStartBtn = false
		tipsFunc.newHintTip("请选择投入金额")
	elseif total > myMoney then
		self.isClickStartBtn = false
		self.isPlaying = false
		local shop = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_SHOP)
    	shop:selectTagBtnByTagID(MALL_TAG_GOLD)

    	self.m_Longpress = false	
		self:unscheduleUpdateBtnTime()
		self.startBtn:loadTexture("ccbResources/DZXXLRes/image/XXL_btn_start.png")
		self.m_aniManager:stopStartBtnAni(self.startBtn)
	else
		local bets = {}
		for k,v in pairs(self.betLabels) do
			bets[k] = v:getString()
		end

		self.m_pGameSink:RequestStart(false, bets)
		if self.m_Longpress then
			-- 自动下注上报
			gameCenter.game:getTableSink():uploadBetData(1)
		end
	end

end

function XXLLayer:onClickCut(index)
	musicfunc.play2d(XXL_MSG.MUSIC_NAMES[1])
	if next(self.betNums) == nil or next(self.betLabels) == nil or self.isPlaying then
		return
	end

	local curIndex = self.betIndexs[index]
	local newIndex = curIndex - 1
	if newIndex <= 0 then
		newIndex = self.betMaxIndex
	end

	self.totalBet = self.totalBet - self.betNums[curIndex] + self.betNums[newIndex]
	self.betIndexs[index] = newIndex
	self.betLabels[index]:setString(self.betNums[newIndex])
	self.totalBetLabel:setString(self.totalBet)

	local key = "XxlSelIndex_" .. index
	cc.UserDefault:getInstance():setIntegerForKey(key, newIndex)
	cc.UserDefault:getInstance():flush() 
	self:updateXXLGuankaMulTaskInfo()
end

function XXLLayer:onClickAdd(index)
	musicfunc.play2d(XXL_MSG.MUSIC_NAMES[1])
	if next(self.betNums) == nil or next(self.betLabels) == nil or self.isPlaying then
		return
	end

	local curIndex = self.betIndexs[index]
	local newIndex = curIndex + 1
	if newIndex > self.betMaxIndex then
		newIndex = 1
	end

	self.totalBet = self.totalBet - self.betNums[curIndex] + self.betNums[newIndex]
	self.betIndexs[index] = newIndex
	self.betLabels[index]:setString(self.betNums[newIndex])
	self.totalBetLabel:setString(self.totalBet)

	local key = "XxlSelIndex_" .. index
	cc.UserDefault:getInstance():setIntegerForKey(key, newIndex)
	cc.UserDefault:getInstance():flush() 
	self:updateXXLGuankaMulTaskInfo()
end

function XXLLayer:onClickTotalCutBtn()
	musicfunc.play2d(XXL_MSG.MUSIC_NAMES[1])
	if next(self.betNums) == nil or next(self.betLabels) == nil or self.isPlaying then
		return
	end

	for k,v in pairs(self.betIndexs) do
		local curIndex = self.betIndexs[k]
		local newIndex = curIndex - 1
		if newIndex > 0 then
			self.totalBet = self.totalBet - self.betNums[curIndex] + self.betNums[newIndex]
			self.betIndexs[k] = newIndex
			self.betLabels[k]:setString(self.betNums[newIndex])
			self.totalBetLabel:setString(self.totalBet)
			local key = "XxlSelIndex_" .. k
			cc.UserDefault:getInstance():setIntegerForKey(key, newIndex)
		end
	end
	cc.UserDefault:getInstance():flush() 
	self:updateXXLGuankaMulTaskInfo()
end

function XXLLayer:onClickTotalAddBtn()
	musicfunc.play2d(XXL_MSG.MUSIC_NAMES[1])
	if next(self.betNums) == nil or next(self.betLabels) == nil or self.isPlaying then
		return
	end

	for k,v in pairs(self.betIndexs) do
		local curIndex = self.betIndexs[k]
		local newIndex = curIndex + 1
		if newIndex <= self.betMaxIndex then
			self.totalBet = self.totalBet - self.betNums[curIndex] + self.betNums[newIndex]
			self.betIndexs[k] = newIndex
			self.betLabels[k]:setString(self.betNums[newIndex])
			self.totalBetLabel:setString(self.totalBet)

			local key = "XxlSelIndex_" .. k
			cc.UserDefault:getInstance():setIntegerForKey(key, newIndex)
		end
	end
	cc.UserDefault:getInstance():flush() 
	self:updateXXLGuankaMulTaskInfo()
end

function XXLLayer:onClickSetBtn()
	local set = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_SETTING)
end

function XXLLayer:onClickRank()
	local set = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_XXL_RANK)
end

function XXLLayer:onClickGameRoleBtn()
	local gameRole = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_XXL_PRUITHELP)
	if gameRole then
		gameRole:setBetRate(self.nRate)
	end
end

function XXLLayer:updateDropAniBtnStatus(select)
	self.aniSpeed = select

	if self.aniSpeed == 1 then
		cc.UserDefault:getInstance():setIntegerForKey("IsXxlSpeedUp", 0)
	else
		cc.UserDefault:getInstance():setIntegerForKey("IsXxlSpeedUp", 1)
	end

	local on = cc.uiloader:seekCsbNodeByName(self.dropAniBtn, "img_checkOn")	
	on:setVisible(self.aniSpeed == 1.8)
end

function XXLLayer:onRecvPoolInfo(dict)
	local pool = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_XXL_POOL_INFO)
	pool:initPoolInfo(dict, self.showPoolType)
end

function XXLLayer:onRecvRoomInfo(dict)
	if dict.btPlatFormFlag == 1 then
		self.isShiWan=true
		self.rankBtn:setVisible(false)
	else
		local isOpen = center.yaoqing:isSwitchOpen("btXxlPassSwitch")
		if not isOpen or display.isAppstore then
			self.rankBtn:setVisible(false)
		end
	end
	self:resetShowXXLTask()
	self.m_btPlatFormFlag = tonumber(dict.btPlatFormFlag)		--是否试玩平台
	self.betMaxIndex = tonumber(dict.btSingleBettingCount)		--底注最多下标
	self:initRedpacket()
	--初始化底注数组
	for k,v in pairs(dict.nSingleBetting) do
		if k > self.betMaxIndex then
			break
		end

		self.betNums[k] = tonumber(v)
	end

	--初始化总下注和各个方块的当前投注
	self.totalBet = 0
	for k,v in pairs(self.betLabels) do
		local index = self.betIndexs[k]
		v:setString(self.betNums[index])
		self.totalBet = self.totalBet + tonumber(self.betNums[index])
	end
	self.totalBetLabel:setString(self.totalBet)

	--初始化奖池
	self:updatePoolMoney(tostring(dict.nAllGold))

	--初始化倍率配置
	self.nRate = {}
	local index = 0
	for i,v in ipairs(dict.nRate) do
		if i%6 == 1 then
			index = index + 1
			self.nRate[index] = {}
		end
		table.insert(self.nRate[index],v)
	end
	dump(self.nRate,"初始化倍率配置")
	-- if center.yaoqing:isSwitchOpen("btXxlPassSwitch") and not self.isShiWan  then
		self:checkOneShowXXLGuanka()
	-- end
	self:updateXXLGuankaMulTaskInfo()
end

function XXLLayer:updatePoolMoney(money)
	self.poolMoney = money
	local num = string.formatnumberthousands(money)
	self.poolMoneyLabel:setString(num)
end

function XXLLayer:onRecvGameBegin(dict)
	if self.myCurGold > 0 then
		local total = self:getMyTotalBet()
		self.myCurGold = self.myCurGold - total
		self:updateMyInfo()
	end

	self.removeMusicIndex = 2
	self.isPlaying = true
	--清空消除的历史记录
	self.historyScrollView:removeAllChildren()
	self.historyItems = {}

	--重置当前获得金币为0
	self.curRewardLabel:setString("0")
	self.curScore = 0
	--是否播放消除动画
	if tonumber(dict.btAnimationFlag) == 0 then
		--初始化矩阵
		self:cleanBlockPanel()
		self:addBlocks(dict.InitItem)

		self.m_aniManager:playDelayAni(self.blockPanel, 1 / self.aniSpeed, handler(self, function()
			if "function" == type(self.OnMessageFun) then
				self.OnMessageFun(true)
			end
		end))
	else

	end

end

function XXLLayer:onRecvAniResult(dict)
	self:removeBlocks(dict)
end

function XXLLayer:onRecvGameEnd(dict)
	self.isClickStartBtn = false
	self.isSettling = true
	local function aniCallBack()
		self.isSettling = false
		self.isPlaying = false

		self.historyEleData = {}
		self:updateXXLGuankaMulTaskInfo()
		if self.mXXLGuankaConfig and self.mXXLGuankaConfig.taskType == 2 or self.mXXLGuankaConfig.taskType == 1 then
			for i=1,#elementImgs do
				if self.mRemoveElementViews[i] and not tolua.isnull(self.mRemoveElementViews[i]) then
					self.mRemoveElementViews[i]:setEliminateValue(0)
				end
			end
		end
		

		if "function" == type(self.OnMessageFun)then
			self.OnMessageFun(true);
		end

		if self.m_Longpress then
			self:RequestStart()
		end
		
		if center.user:checkGuideIsOpen(center.user.HALL_GUIDE_ID.GUIDE_XXL_JIASU,self.guideFlag) and self.guideOpen then 
			self.guideOpen = false
			self:checkXXLGuide(10)
		else
		    -- 检测是否弹窗抽奖宝箱
		    center.luckdraw:checkAndShowLuckDrawBox()
		end
	end

	local settleAniIndex = 1
	local rewardPool = tonumber(dict.nHavePoolGoldNum)
	local rewardMoney = tonumber(dict.nGameWinGoldNum)

	local totalBet = self:getMyTotalBet()
	local musicIndex = 8
	local bgMusicIndex = 0
	if rewardMoney <= 0 then 		
		musicIndex = 8
		settleAniIndex = 1
	elseif rewardMoney <= totalBet then
		musicIndex = 8
		settleAniIndex = 2
	elseif rewardMoney > totalBet then
		local mutl = rewardMoney / totalBet
		if mutl >= 5  then
			musicIndex = 12
			settleAniIndex = 5
			bgMusicIndex = 17
		elseif mutl >=3 and mutl < 5  then
			musicIndex = 11
			settleAniIndex = 4
			bgMusicIndex = 16
		else
			musicIndex = 10
			settleAniIndex = 3
			bgMusicIndex = 15
		end
	else
		musicIndex = 10
		settleAniIndex = 3
	end

	local function settleFun()
		if bgMusicIndex > 0 then
			musicfunc.play2d(XXL_MSG.MUSIC_NAMES[bgMusicIndex])
		end
		musicfunc.play2d(XXL_MSG.MUSIC_NAMES[musicIndex])

		self.m_aniManager:playSettleAni(self, settleAniIndex, rewardMoney, handler(self, function()
			if rewardPool > 0 then
				musicfunc.play2d(XXL_MSG.MUSIC_NAMES[13])
				musicfunc.play2d(XXL_MSG.MUSIC_NAMES[18])
				self.m_aniManager:playPoolAni(self, rewardPool, handler(self, function()
					aniCallBack()
				end))
			else
				aniCallBack()
			end
		end))

	end

	settleFun()

	local myActor = center.user:getMyActor()
	if myActor then
		self.myCurGold = tonumber(myActor[ACTOR_PROP_GOLD])
		self:updateMyInfo()
	end

	for i=1,#elementImgs do
		local view = self.mRemoveElementViews[i]
		if not tolua.isnull(view) then
			view:updateStatus()
		end
	end
	-- if center.yaoqing:isSwitchOpen("btXxlPassSwitch")  and not self.isShiWan then
	

	self:checkXXLGuankaPass()

	-- end
end

function XXLLayer:getMyTotalBet()
	local totalBet = 0

	if next(self.betNums) ~= nil then
		for k,v in pairs(self.betIndexs) do
			totalBet = totalBet + self.betNums[v]
		end
	end

	return totalBet
end

function XXLLayer:cleanBlockPanel()
	for k,v in pairs(self.blocks) do
		v:removeFromParent()
		v = nil
	end

	self.blocks = {}
end

function XXLLayer:dropBlocks(dict)
	local panelWidth, panelHeight = 910, 910
	local blockWidth, blockHeight = 910 / 7, 910 / 7
	local bgnX, bgnY = blockWidth * 0.5, panelHeight - blockHeight * 0.5
	local count = tonumber(dict.btSupplyCount)

	for k,v in pairs(dict.SpointItem) do
		if k > count then
			break
		end
		local x, y = bgnX + blockWidth * v.y, bgnY - blockHeight * v.x
		local index = v.x * 7 + v.y + 1
		self.blocks[index]:removeAllChildren()
		self.blocks[index]:setTexture(resPath .. elementImgs[v.btElementType + 1])
		self.blocks[index]:pos(x, y + panelHeight)
		self.blocks[index]:runAction(cc.Sequence:create(
					cc.Show:create(),
					cc.MoveTo:create(0.5 / self.aniSpeed, cc.p(x, y))
				))

		if (v.btElementType + 1) == #elementImgs then
			self.m_aniManager:addLandlordBlockAni(self.blocks[index])
		end

		self.blocks[index].status = 0
	end

	self.m_aniManager:playDelayAni(self.blockPanel, 0.8 / self.aniSpeed, handler(self, function()
		if "function" == type(self.OnMessageFun) then
			self.OnMessageFun(true)
		end
	end))

end

function XXLLayer:removeBlocks(dict)
	--清空待移除的队列
	local historyDatas = {}
	local removeList = {}
	--遍历SRemovePointItem，元素属性btLocalNum > 0，则需要被消除
	for i=#self.blocks,1,-1 do
		local curItemDatas = dict.SRemovePointItem[i]
		local localNum = tonumber(curItemDatas.btLocalNum)
		if localNum > 0 then
			--统计历史记录
			historyDatas[localNum] = historyDatas[localNum] or {count = 0, btElementType = 0}
			historyDatas[localNum].count = historyDatas[localNum].count + 1 						--块数
			historyDatas[localNum].btElementType = curItemDatas.btElementType 						--区域下标
			historyDatas[localNum].score = dict.nLocalPrice[localNum]
			if curItemDatas.btElementType + 1 == #elementImgs then
				historyDatas[localNum].isBet = true
			else
				historyDatas[localNum].isBet = self.betIndexs[curItemDatas.btElementType + 1] > 1
			end
			--按消除区域归类方块
			removeList[localNum] = removeList[localNum] or {}
			table.insert(removeList[localNum], i)
		end
	end

	--计算每个消除块的leftX，rightX，topY，bottomY，用来计算中心点X，Y
	self.points = {}
	for k,v in pairs(removeList) do
		local mixX, mixY = 0, 0
		local minX, minY = 910, 910
		for i=#v,1,-1 do
			local curIndex = v[i]
			local curX, curY = self.blocks[curIndex]:getPositionX(), self.blocks[curIndex]:getPositionY()
			if curX > mixX then
				mixX = curX
			end			

			if curY > mixY then
				mixY = curY
			end			

			if curX < minX then
				minX = curX
			end			

			if curY < minY then
				minY = curY
			end
		end
		self.points[k] = {leftX = minX, rightX = mixX, topY = mixY, bottomY = minY}
	end

	local lastCount = #self.historyItems 	
	self:addNewHistory(historyDatas)			--addNewHistory要在updateHistory之前调用，先增加item，后做更新item的动画

	local function playRemoveSound(delayTime, musicIndex)
		node = display.newNode()
			:addTo(self)
			:runAction(cc.Sequence:create(
					cc.DelayTime:create(delayTime),
					cc.CallFunc:create(function()
						musicfunc.play2d(XXL_MSG.MUSIC_NAMES[musicIndex])
					end)
				))
	end

	local isXXLGuankaOver = center.task:isXXLGuankaOver()
	local isOpen = center.yaoqing:isSwitchOpen("btXxlPassSwitch")
	local isCanPlay = not isOver and isOpen and not self.isShiWan 
	local isXXLGameModel = center.roomList:isXXLGameModel()
	local taskType = 0
	if self.mXXLGuankaConfig and self.mXXLGuankaConfig.taskType then
		taskType = tonumber(self.mXXLGuankaConfig.taskType)
	end
	dump(historyDatas, " =========== historyDatas: ")
	dump(removeList,"removeListXXL")
	--消除方块
	for k,v in pairs(removeList) do
		local delayTime = (k - 1) * 1 / self.aniSpeed
		local playTaskAni = true

		--连消类型的任务，要判断消除的数量，是不是大于任务要求的数量，否则，不做动画
		if taskType == 2 then
			local nType = historyDatas[k].btElementType + 1
			local removeElement = self.mRemoveElementViews[nType]
			if removeElement and not tolua.isnull(removeElement) then
				
				local label = cc.uiloader:seekCsbNodeByName(removeElement, "Text_element_num")
				
				if label then
					local numString = label:getString()
					if numString and numString ~= "" and string.len(numString) > 1 then
						
						numString = string.gsub(numString, "x", "")
						if numString and tonumber(numString) > historyDatas[k].count then
							playTaskAni = false
						end

					end
				end
			end
		end

		for i=#v,1,-1 do
			--每个区域延时0.2s，播放消除动画
			local curIndex = v[i]
			self.blocks[curIndex].status = 1
			self.m_aniManager:playRemoveBlockAni(delayTime, self.blocks[curIndex])

			if playTaskAni then

				--消除任务动画
				local nType = historyDatas[k].btElementType + 1
				local removeElement = self.mRemoveElementViews[nType]
				local startView = self.blocks[curIndex]
				local curIndex = self.betIndexs[nType]
				local betNum = checkint(self.betNums[curIndex])
				local minBet = checkint(self.mXXLGuankaConfig.nChip)
				
				if isCanPlay and not tolua.isnull(removeElement) and minBet <= betNum and not removeElement:isComplete() then
					removeElement:setEliminateValue(removeElement:getEliminateValue() + betNum)
					self:performWithDelay(function()
							if isCanPlay and not tolua.isnull(removeElement) and not tolua.isnull(startView) then
								local view = startView:clone()
								view:addTo(self)
								local startPos = startView:convertToWorldSpace(cc.p(0,0))
								local size = removeElement:getContentSize()
								local endPos = removeElement:convertToWorldSpace(cc.p(size.width/2,size.height/2))

								self.m_aniManager:playRemoveTaskAnim(view,0.5,startPos,endPos,i==1,function()
										if not tolua.isnull(removeElement) then
											removeElement:removeAnim(1,removeElement)
										end
									end)
							end
						end, delayTime)
				end
				
			end
		end
		
		self.removeMusicIndex = self.removeMusicIndex + 1
		if self.removeMusicIndex > 7 then
			self.removeMusicIndex = 2
		end
		playRemoveSound(delayTime, self.removeMusicIndex)

		--播放每个消除块获得的分数动画
		self.m_aniManager:playRewardNumAni(self.centerBg, self.points[k], delayTime, historyDatas[k], handler(self, function()
			--更新当前得分
			self.curScore = self.curScore + historyDatas[k].score
			self.curRewardLabel:setString(helpUntile.FormateNumber2(self.curScore))
			self.m_aniManager:playScoreAni(self.curRewardLabel)
			self:updateHistory(k, lastCount)
		end))

		--消除最后一个区域后，下移悬空的方块
		if #removeList == k then
			self.m_aniManager:playDelayAni(self, delayTime + 0.5 / self.aniSpeed, handler(self, function()
				self:moveDownBlocks(dict)
			end))
		end
	end

end

function XXLLayer:updateHistory(index, lastCount)
	local itemSize = cc.size(220, 124)				--item宽高
	local innerSize = self.historyScrollView:getInnerContainerSize()
	local bgnY = innerSize.height - 0.5 * itemSize.height

	for j=1,(lastCount + index - 1) do
		local y = self.historyItems[j]:getPositionY() - itemSize.height
		self.historyItems[j]:pos(innerSize.width * 0.5, y)
	end

	self.historyItems[lastCount + index]:runAction(cc.Sequence:create(
		cc.MoveTo:create(0.3 / self.aniSpeed, cc.p(innerSize.width * 0.5, bgnY))
	))
end

function XXLLayer:addNewHistory(datas)
	dump(datas, " =======addNewHistory======== ")
	local curCount = #self.historyItems 			--当前总共有多少个item
	local itemSize = cc.size(220, 124)				--item宽高
	local innerHeight = (curCount + #datas) * itemSize.height 		--滚动区域高为：(当前item + 新增item) * item.height
	self.historyScrollView:setInnerContainerSize(cc.size(itemSize.width, innerHeight))	
	local innerSize = self.historyScrollView:getInnerContainerSize()
	local bgnY = innerSize.height - 0.5 * itemSize.height
	local imageName = "XXL_yuansu0.png"
	if center.roomList:isXXLGameModel() then
		imageName = "XXL_yuansu0_n.png"
	end

	--由于滚动区域的尺寸改变，需要更新已有Item位置
	for k,v in pairs(self.historyItems) do
		v:pos(innerSize.width * 0.5, bgnY - (curCount - k) * itemSize.height)
	end
	dump(self.historyEleData, " =========before========= ")
	--添加新的item
	for k,v in pairs(datas) do
		self.historyItems[curCount + k] = cc.uiloader:load("ccbResources/DZXXLRes/ui/node_history_item.csb")
			:addTo(self.historyScrollView)
			:pos(innerSize.width * -0.5, bgnY)

		if self.historyEleData[v.btElementType + 1] == nil then
			self.historyEleData[v.btElementType + 1] = {}
		end
		table.insert(self.historyEleData[v.btElementType + 1], v.count)
		
		if not v.isBet then
			self.historyItems[curCount + k]:setColor(cc.c3b(166, 166, 166))
		end

		local iconImg = cc.uiloader:seekCsbNodeByName(self.historyItems[curCount + k], "img_icon")
		local numLabel = cc.uiloader:seekCsbNodeByName(self.historyItems[curCount + k], "txt_count")

		if v.btElementType + 1 == #elementImgs then
			iconImg:loadTexture(resPath .. imageName)
		else
			iconImg:loadTexture(resPath .. elementImgs[v.btElementType + 1])
		end
		numLabel:setString(v.count)
	end
	dump(self.historyEleData, " =========after========= ")

end

function XXLLayer:moveDownBlocks(dict)

	local panelWidth, panelHeight = 910, 910
	local blockWidth, blockHeight = 910 / 7, 910 / 7
	local bgnX, bgnY = blockWidth * 0.5, panelHeight - blockHeight * 0.5
	local moveDelYs = {}
	--交换方块
	function swapBlock(a, b)
		return b, a
	end

	--从左往右，按列遍历，最左侧为第1列
	for column=1,7 do

		--从下往上，按行遍历，最上面为第一行
		--冒泡交换上下方块，将空块移到最上面
		for row=7,1,-1 do

			local count = 1 + (7 - row) + 1

			for i=7,count,-1 do
				local curIndex = (i - 1) * 7 + column
				local nextIndex = (i - 2) * 7 + column

				if self.blocks[curIndex].status == 1 then
					self.blocks[curIndex], self.blocks[nextIndex] = swapBlock(self.blocks[curIndex], self.blocks[nextIndex])

					if self.blocks[curIndex].status == 0 then
						moveDelYs[curIndex] = bgnY - blockHeight * (i - 1)
					end

					if self.blocks[nextIndex].status == 0 then
						moveDelYs[nextIndex] = bgnY - blockHeight * (i - 2)
					end
				
				end

			end

		end

	end

	for k,v in pairs(self.blocks) do
		if v.status == 0 and moveDelYs[k] and moveDelYs[k] > 0 then
			v:runAction(cc.MoveTo:create(0.2 / self.aniSpeed, cc.p(v:getPositionX(), moveDelYs[k])))
		end
	end

	self.m_aniManager:playDelayAni(self.blockPanel, 0.3 / self.aniSpeed, handler(self, function()
		self:dropBlocks(dict)
	end))
end

function XXLLayer:addBlocks(datas)
	local panelWidth, panelHeight = 910, 910
	local blockWidth, blockHeight = 910 / 7, 910 / 7
	local bgnX, bgnY = blockWidth * 0.5, panelHeight - blockHeight * 0.5
	local delYs = {blockHeight * 1.5, blockHeight, blockHeight * 0.5, 0, blockHeight * 0.5, blockHeight, blockHeight * 1.5}
	for k,v in pairs(datas) do
		local row = (k - 1) % 7
		local column = math.modf((k - 1) / 7)
		local x, y = bgnX + blockWidth * row, bgnY - blockHeight * column
		self.blocks[k] = display.newSprite(resPath .. elementImgs[v + 1])
			:addTo(self.blockPanel)
			:pos(x, y + panelHeight + delYs[row + 1])
		self.blocks[k]:runAction(cc.MoveTo:create(0.8 / self.aniSpeed, cc.p(x, y)))
		self.blocks[k].status = 0 --方块状态， 1：已清除；0：正常

		if (v + 1) == #elementImgs then
			self.m_aniManager:addLandlordBlockAni(self.blocks[k])
		end
	end
end

function XXLLayer:initBlockPanel()
	local blockTypes = {
		3, 2, 2, 3, 2, 2, 3,
		2, 5, 5, 2, 5, 5, 2,
		5, 4, 4, 5, 4, 4, 5, 
		5, 4, 0, 4, 0, 4, 5, 
		2, 5, 4, 1, 4, 5, 2, 
		3, 2, 5, 4, 5, 2, 3, 
		2, 3, 2, 5, 2, 3, 2
	}

	local panelWidth, panelHeight = 910, 910
	local blockWidth, blockHeight = 910 / 7, 910 / 7
	local bgnX, bgnY = blockWidth * 0.5, panelHeight - blockHeight * 0.5
	local delYs = {blockHeight * 1.5, blockHeight, blockHeight * 0.5, 0, blockHeight * 0.5, blockHeight, blockHeight * 1.5}
	for k=1,49 do
		local enum = blockTypes[k]
		local row = (k - 1) % 7
		local column = math.modf((k - 1) / 7)
		local x, y = bgnX + blockWidth * row, bgnY - blockHeight * column
		self.blocks[k] = display.newSprite(resPath .. elementImgs[enum + 1])
			:addTo(self.blockPanel)
			:pos(x, y)
		self.blocks[k].status = 0 --方块状态， 1：已清除；0：正常

		if (enum + 1) == #elementImgs then
			self.m_aniManager:addLandlordBlockAni(self.blocks[k])
		end
	end

end

function XXLLayer:updateBtnTime()
	self.m_TouchBtnTime = self.m_TouchBtnTime + 0.01
	if self.m_TouchBtnTime >= 0.5 then
		self.m_Longpress = true
		self:unscheduleUpdateBtnTime()
		self.startBtn:loadTexture("ccbResources/DZXXLRes/image/XXL_btn_start1.png")
		self.m_aniManager:playStartBtnAni(self.startBtn)
	end
end

function XXLLayer:unscheduleUpdateBtnTime()
	if self.schedule_updatBtnTime then
		-- scheduler.unscheduleGlobal(self.schedule_updatBtnTime)
		self.startBtn:stopAction(self.schedule_updatBtnTime)
		self.schedule_updatBtnTime = nil
	end
end

function XXLLayer:reset()
	self.aniSpeed = 1  				--是否跳过动画
	self.showPoolType = 1					--1：点击奖池；2：点击右侧元素规则
	self.m_Longpress = false 				--是否长按开始按钮
	self.m_TouchBtnTime = 0 				--长按开始按钮累计时间	
	self.m_btPlatFormFlag = 0 				--平台标记，是否为试玩，0不是，1是
	self.nRate = {} -- 倍率配置
	self.betNums = {}
	self.curScore = 0
	self.isPlaying = false
	self.removeMusicIndex = 2

	self:updateDropAniBtnStatus(self.aniSpeed)
	self:unscheduleUpdateBtnTime()
	self.startBtn:loadTexture("ccbResources/DZXXLRes/image/XXL_btn_start.png")
end

function XXLLayer:resetShowXXLTask()
	local isOver = center.task:isXXLGuankaOver() 						--是否完成
	local isOpen = center.yaoqing:isSwitchOpen("btXxlPassSwitch")		--开关是否打开
	local isCanPlay = not isOver and isOpen and not self.isShiWan 		--没完成 且 开关打开 且 不是试玩
	self.mXXLGuankaConfig = {}
	for i=1,#elementImgs do
		local view = self.mRemoveElementViews[i]
		if not tolua.isnull(view) then
			view:removeSelf()
		end
	end
	self.mRemoveElementViews = {}
	self.Node_element_pos:removeAllChildren()

	self.Image_task_panel:setVisible(false)

	if not isCanPlay then
		return
	end

	local mDatas = center.task:getXXLGuankaData() 			--获取自己当前的关卡数据
	local nGuanKaID = checkint(mDatas.nGuanKaID)
	local curConfig = center.task:getXXLGuankaConfigByID(nGuanKaID)

	if not curConfig then
		return 
	end
		
	self.Image_task_panel:setVisible(true)

	local nChip = checkint(curConfig.nChip)
	local guanKaRemoveElement = checktable(curConfig.GuanKaRemoveElement)

	self.mXXLGuankaConfig = curConfig
	self.Text_guanka:setString(string.format("第%d关",nGuanKaID))
	if tonumber(curConfig.taskType) == 1 then
		self.Text_chip_tips:setString(string.format("（单局任务，最少投入%d）",nChip))
		self.img_gq_type:loadTexture("ccbResources/DZXXLRes/image/XX_rw_danjuxc.png")
	elseif tonumber(curConfig.taskType) == 2 then
		self.Text_chip_tips:setString(string.format("（单局任务，最少投入%d）",nChip))
		self.img_gq_type:loadTexture("ccbResources/DZXXLRes/image/XX_rw_danjulj.png")
	else
		self.img_gq_type:loadTexture("ccbResources/DZXXLRes/image/XX_rw_leijixc.png")
		self.Text_chip_tips:setString(string.format("（单个最少投入%d）",nChip))
	end

	self.addElementView = {}

	for i,v in ipairs(guanKaRemoveElement) do
		local nNum = checkint(v.nNum)
		if nNum > 0 then
			local nType = checkint(v.nType) + 1
			local removeNum = center.task:getXXLGuankaRemoveNumByType(nType)
			local view = self.Image_element_model:clone():setVisible(true)
			local Image_element_icon = cc.uiloader:seekCsbNodeByName(view, "Image_element_icon")
			local Text_element_num = cc.uiloader:seekCsbNodeByName(view, "Text_element_num")
			local Image_complete = cc.uiloader:seekCsbNodeByName(view, "Image_complete")
			local eliminate = 0
			local imageName = "XXL_yuansu0.png"
			if center.roomList:isXXLGameModel() then
				imageName = "XXL_yuansu0_n.png"
			end

			if nType == #elementImgs then
				Image_element_icon:loadTexture(resPath .. imageName)
			else
				Image_element_icon:loadTexture(resPath .. elementImgs[nType])
			end
			local that = self 
			function view:updateStatus()
				print("updateStatus")
				that:updateXXLGuankaMulTaskInfo()
			end
			
			function view:removeAnim(num,removeAnimView)
				if num and not tolua.isnull(removeAnimView) then
					local Text_element_num = cc.uiloader:seekCsbNodeByName(removeAnimView, "Text_element_num")
					local Image_complete = cc.uiloader:seekCsbNodeByName(removeAnimView, "Image_complete")
					if Text_element_num:getString() == "" then
						return 
					end
					if checkint(Text_element_num:getString())-1 >= 1 then
						Text_element_num:setString(checkint(Text_element_num:getString())-1)
					else
						Image_complete:setVisible(true)
						Text_element_num:setString("")
					end
				end
			end

			function view:isComplete()
				--return removeNum >= nNum * curConfig.nChip
				return eliminate >= nNum * curConfig.nChip 
			end

			function view:getEliminateValue()
				return eliminate
			end
			function view:setEliminateValue(value)
				eliminate = value
			end

			table.insert(self.addElementView,view)
			self.mRemoveElementViews[nType] = view
			view:updateStatus()
		end
	end

	local itemWidth = self.Image_element_model:getContentSize().width
	local offsetW = 15
	local itemNum = #self.addElementView
	local startX = -((itemWidth + offsetW) * itemNum - offsetW)/2

	for i,view in ipairs(self.addElementView) do
		view:addTo(self.Node_element_pos)
		view:setPosition(cc.p(startX+itemWidth/2,0))
		startX = startX + itemWidth + offsetW
	end

end

function XXLLayer:showXXLTaskInfo()
	if not next(self.mXXLGuankaConfig) then return end

	local mDatas = center.task:getXXLGuankaData()
	local btSucessFlag = true
	local guanKaRemoveElement = checktable(self.mXXLGuankaConfig.GuanKaRemoveElement)
	dump(guanKaRemoveElement,"guanKaRemoveElementssss")
	for i,v in ipairs(guanKaRemoveElement) do
		local nNum = checkint(v.nNum)
		if nNum > 0 then
			local nType = checkint(v.nType) + 1
			local removeNum = center.task:getXXLGuankaRemoveNumByType(nType)
			if v.nType == 5 then
				btSucessFlag = btSucessFlag and removeNum >= v.nNum
			else
				btSucessFlag = btSucessFlag and removeNum >= nNum*self.mXXLGuankaConfig.nChip
			end
		end
	end
	local nGuanKaID = checkint(mDatas.nGuanKaID)
	if btSucessFlag then
		local view = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_XXL_TASK_PASS)
		if view then
			view:setConfig(self.mXXLGuankaConfig)
			if self.m_Longpress then
            	view:setAutoClose()
            end
		end
		return 
	end
	
	local size = self.Image_task_panel:getContentSize()
	local view = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_XXL_TASK_INFO,self.Image_task_panel:convertToWorldSpace(cc.p(size.width/2,size.height/2)))
	if view then
		view:setConfig(self.mXXLGuankaConfig,self:getXXLGuankaMulConfigInfo())

		if self.m_Longpress then
        	view:setAutoClose()
        end

		return view
	end
end

function XXLLayer:checkXXLGuankaPass()
	if not next(self.mXXLGuankaConfig) then return end
	local isOver = center.task:isXXLGuankaOver()
	local isOpen = center.yaoqing:isSwitchOpen("btXxlPassSwitch")
	local isCanPlay = not isOver and isOpen and not self.isShiWan 
	if not isCanPlay then
		return
	end

	local btSucessFlag = true
	local guanKaRemoveElement = checktable(self.mXXLGuankaConfig.GuanKaRemoveElement)
	for i,v in ipairs(guanKaRemoveElement) do
		local nNum = checkint(v.nNum)
		if nNum > 0 then
			local nType = checkint(v.nType) + 1
			local removeNum = center.task:getXXLGuankaRemoveNumByType(nType)
			if v.nType == 5 then
				btSucessFlag = btSucessFlag and removeNum >= v.nNum
			else
				btSucessFlag = btSucessFlag and removeNum >= nNum*self.mXXLGuankaConfig.nChip
			end
		end
	end

	if btSucessFlag then
		local view = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_XXL_TASK_PASS)
		if view then
			view:setConfig(self.mXXLGuankaConfig)
			if self.m_Longpress then
            	view:setAutoClose()
            end
		end
	end
end

function XXLLayer:checkOneShowXXLGuanka()
	if not next(self.mXXLGuankaConfig) then return end
	local isOver = center.task:isXXLGuankaOver()
	local isOpen = center.yaoqing:isSwitchOpen("btXxlPassSwitch")
	local isCanPlay = not isOver and isOpen and not self.isShiWan 
	if not isCanPlay then
		return
	end
	local btSucessFlag = true
	local guanKaRemoveElement = checktable(self.mXXLGuankaConfig.GuanKaRemoveElement)
	for i,v in ipairs(guanKaRemoveElement) do
		local nNum = checkint(v.nNum)
		if nNum > 0 then
			local nType = checkint(v.nType) + 1
			local removeNum = center.task:getXXLGuankaRemoveNumByType(nType)
			if v.nType == 5 then
				btSucessFlag = btSucessFlag and removeNum >= v.nNum
			else
				btSucessFlag = btSucessFlag and removeNum >= nNum*self.mXXLGuankaConfig.nChip
			end
		end
	end

	if btSucessFlag then
		local view = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_XXL_TASK_PASS)
		if view then
			view:setConfig(self.mXXLGuankaConfig)
			if self.m_Longpress then
            	view:setAutoClose()
            end
		end
		return
	end

	local perTime = cc.UserDefault:getInstance():getIntegerForKey("showXXLGuankTime",0)
	local curTime = os.time()
	local perDay = math.floor(perTime / 86400)
	local curDay = math.floor(curTime / 86400)
	print("checkOneShowXXLGuanka",perDay,curDay)
	if perDay < curDay then
		cc.UserDefault:getInstance():setIntegerForKey("showXXLGuankTime",curTime)
		local view = self:showXXLTaskInfo()
		if view then
			view:performWithDelay(function()
					if tolua.isnull(view) then return end
					view:dismiss()
					if center.user:checkGuideIsOpen(center.user.HALL_GUIDE_ID.GUIDE_XXL_ENTER_ROOM,self.guideFlag) then
						self:checkXXLGuide(9)
					end
				end, 2)
		end
	else
		if center.user:checkGuideIsOpen(center.user.HALL_GUIDE_ID.GUIDE_XXL_ENTER_ROOM,self.guideFlag) then
			self:checkXXLGuide(9)
		end
	end
end

function XXLLayer:initXXLMenu()
	self.img_rightBg:setVisible(false)
	-- self.dropAniBtn:setVisible(false)
	self:updateDropAniBtnStatus(1)
	self.img_leftBg:loadTexture("ccbResources/DZXXLRes/image/XXL_db1_sh.png")
	self.poolBtn:setTouchEnabled(false)
	self.poolBtn:loadTexture("ccbResources/DZXXLRes/image/XXL_jiangchi_sh.png")
	self.poolMoneyLabel:setVisible(false)
	self.moreMenuRole:setVisible(false)

	if not tolua.isnull(self.mXXLMenu) then self.mXXLMenu:removeSelf() end

	self.mXXLMenu = cc.uiloader:load("ccbResources/DZXXLRes/ui/Node_xxl_bet_menu.csb")
	self.mXXLMenu:addTo(self.node_center_right)
	self.mXXLMenu:setPosition(self.img_rightBg:getPosition())


	self.userMoneyLabel = cc.uiloader:seekCsbNodeByName(self.mXXLMenu, "txt_userMoney")
	self.userMoneyLabel:setString(helpUntile.FormateNumber2(self.myCurGold))
	self.totalBetLabel = cc.uiloader:seekCsbNodeByName(self.mXXLMenu, "txt_total")
	self.totalBetLabel:setString(self.totalBet)

	-- 初始化
	for k,v in pairs(self.betIndexs) do
		local key = "XxlSelIndex_" .. k
		cc.UserDefault:getInstance():setIntegerForKey(key, 2)
	end
	cc.UserDefault:getInstance():flush()


	self.img_startBtn = cc.uiloader:seekCsbNodeByName(self.mXXLMenu, "img_startBtn")
	display.setImageClick(self.img_startBtn,handler(self, self.onClickStartBtn) )
	self.img_storeBtn = cc.uiloader:seekCsbNodeByName(self.mXXLMenu, "img_storeBtn")
	display.setImageClick(self.img_storeBtn, handler(self, self.onClickStoreBtn))
end

function XXLLayer:onClickStartBtn()
	print("onClickStartBtn")
	if not self.isPlaying and not self.isSettling and not self.isClickStartBtn then
		self.isClickStartBtn = true
		self:RequestStart()		
	end
end

function XXLLayer:getXXLGuankaMulConfigInfo()
	print("getXXLGuankaMulInfo")
    -- 获得当前关卡任务配置
    local mDatas = center.task:getXXLGuankaData()
    local mConfigs = center.task:getXXLGuankaConfig()
    if not next(mDatas) or not next(mConfigs)  then
        return 
    end
    print("true")
    local nGuanKaID = checkint(mDatas.nGuanKaID)						--当前关卡ID
    local curConfig = center.task:getXXLGuankaConfigByID(nGuanKaID) 	--当前关卡配置
    if not curConfig then
        return 
    end

    --统计那些方块还没消除
    local removeElement = {}
    for k,v in pairs(curConfig.GuanKaRemoveElement) do
    	if v.nNum > 0 then
    		if tonumber(self.mXXLGuankaConfig.taskType) ~= 0 then
    			table.insert(removeElement,v)
    		else
    			--计算还差多少积分才算消完，剩余 = 需要消除的数量 * 指定的积分 - 已经消除的得分
	    		local surplusValue = v.nNum * curConfig.nChip - center.task:getXXLGuankaRemoveNumByType(v.nType + 1)			--
				--如果该元素未消除
	    		if surplusValue > 0 then
	    			table.insert(removeElement,v)
	    		end
    		end
    	end
    end
    dump(removeElement,"removeElementtt")

    local mulTb = {}
    for k,v in pairs(removeElement) do
    	
    	mulTb[v.nType] = curConfig.nChip 										--默认赋值最低筹码
    	local curBetMoney = self.betLabels[v.nType + 1] and tonumber(self.betLabels[v.nType + 1]:getString()) or 0		--当前类型押注金额

    	--判断当前押注是不是大于最低押注，是就赋值为当前押注
    	if curBetMoney >= curConfig.nChip then
    		mulTb[v.nType] = curBetMoney
    	end
    
    end
    dump(mulTb,"mulTbmulTb")
    return mulTb
end

function XXLLayer:getBlockRemovedCount(eleType, linkCount)
	dump(self.historyEleData, " =========== eleType: " .. eleType)
	dump(self.betNums, " ========= betNums: ")
	local count = 0
	local curIndex = self.betIndexs[eleType]
	local betNum = checkint(self.betNums[curIndex])
	local minBet = checkint(self.mXXLGuankaConfig.nChip)
	print(" ============ betNum: " .. betNum .. ", minBet: " .. minBet)
	if not self.historyEleData or not self.historyEleData[eleType] or betNum < minBet then
		return count
	end

	if linkCount then
		print(" ============= linkCount: " .. linkCount)
		for k,v in pairs(self.historyEleData[eleType]) do
			if v >= linkCount then
				count = v
				break
			end
		end
	else
		for k,v in pairs(self.historyEleData[eleType]) do
			count = count + v
		end
	end
	return count
end

function XXLLayer:updateXXLGuankaMulTaskInfo()
	print("updateXXLGuankaMulTaskInfo")

	local mulConfig = self:getXXLGuankaMulConfigInfo()
	print(mulConfig)
	if not mulConfig then
		return 
	end
	local mDatas = center.task:getXXLGuankaData()
    local nGuanKaID = checkint(mDatas.nGuanKaID) 						--当前关卡ID
    local curConfig = center.task:getXXLGuankaConfigByID(nGuanKaID) 	--当前关卡配置
    

    local curTaskType = tonumber(self.mXXLGuankaConfig.taskType)
    dump(curConfig,"curConfig")

    --遍历当前配置要消除的元素
    for k,v in pairs(curConfig.GuanKaRemoveElement) do
    	if v.nNum > 0 then

    		local view = self.mRemoveElementViews[v.nType + 1]
    		if tolua.isnull(view) then 
    			return 
    		end

		    local Text_element_num = cc.uiloader:seekCsbNodeByName(view, "Text_element_num")
    		local Image_complete = cc.uiloader:seekCsbNodeByName(view, "Image_complete")
    		local sumValue = 0					--总共要消除多少积分
    		local eliminateValue = 0			--已经消除的积分
    		local surplusValue = 0				--剩余需要消除的积分

    		--如果是地主元素，总价值为需要消除的个数, 已经消除的积分也是数量
    		if v.nType == 5 then
    			sumValue = v.nNum
    		else
    			sumValue = v.nNum * curConfig.nChip
    		end

    		--获取当前已经消除的积分
    		local eliminateValue = center.task:getXXLGuankaRemoveNumByType(v.nType + 1)
    		local preStr = ""
    		local surplusValue = 0
    		if curTaskType == 2 then

    			preStr = "x"
    			if v.nType ~= 5 then
    				local removeCount = self:getBlockRemovedCount(v.nType + 1, v.nNum)
    				eliminateValue = removeCount * mulConfig[v.nType]
    				print(" ============== removeCount: " .. removeCount)
    			end

    		elseif curTaskType == 1 then

				if v.nType ~= 5 then
    				local removeCount = self:getBlockRemovedCount(v.nType + 1)
    				eliminateValue = removeCount * mulConfig[v.nType]
    			end

    		end

    		local surplusValue = sumValue - eliminateValue 
    		print(" ============== sumValue: " .. sumValue .. ", eliminateValue: " .. eliminateValue)
    		if surplusValue > 0 then
    			local num = 0
    			if v.nType == 5 then
    				Text_element_num:setString(preStr .. surplusValue)
    			else
    				num = math.ceil(surplusValue / mulConfig[v.nType])
    				Text_element_num:setString(preStr .. num)
    			end

    			if curTaskType == 2 and v.nType ~= 5 then
    				local removeCount = self:getBlockRemovedCount(v.nType + 1, num)
    				if removeCount > 0 then
    					Image_complete:setVisible(true)
    				else
    					Image_complete:setVisible(false)
    				end
    			else
    				Image_complete:setVisible(false)
    			end

		   	else
		    	Text_element_num:setString("")
		    	Image_complete:setVisible(true)
		    end
		end
	end
end

function XXLLayer:checkXXLGuide(step)
	print("checkXXLGuide")
	self.userGuide = require("script.view.plaza.guide.NewPlayerGuide").new()
	self.userGuide:addTo(self)
	self.userGuide:setGuideStep(step,self)
end

return XXLLayer
