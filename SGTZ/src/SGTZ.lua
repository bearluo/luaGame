local RES_FANGZHENGTTF = "ccbResources/fonts/fangzheng.ttf"
local HornView = import("game.public.HornView")
local FruitsItem = import(".view.FruitsItem")
local ColumnItem = import(".view.ColumnItem")
local BallItem = import(".view.BallItem")
local PlazaController = require("script.view.plaza.plazaMain.PlazaController")

require("game.public.chinessDef")
require("game.public.toolsFunc")
local GoodsData = require("game.SGTZ.Base.GoodsData")
local Def = require("game.SGTZ.Base.Def")
-- local SGTZAni = require("game.SGTZ.SGTZAni")
local scheduler = require("framework.scheduler")
local SGTZEngine = require("game.SGTZ.Base.SGTZEngine").new()
local JieSuanAnim = require("game.SGTZ.anim.JieSuanAnim").new()
local TailFlameAnim = require("game.SGTZ.anim.TailFlameAnim").new()
local SGTZEditLayer = require("game.SGTZ.edit.SGTZEditLayer")
local FloatTextAnim = require("game.SGTZ.anim.FloatTextAnim")
local YuleRankBtn = require("game.public.YuleRank.YuleRankBtn")
local SGTZGuide1 = import(".guide.SGTZGuide1")
local SGTZGuide2 = import(".guide.SGTZGuide2")
local SGTZGuide3 = import(".guide.SGTZGuide3")
local SGTZGuide4 = import(".guide.SGTZGuide4")


-- local MAX_ROTATION,MIN_ROTATION = -28,-55
-- local MAX_ROTATION,MIN_ROTATION = -1,-27
-- local MAX_ROTATION,MIN_ROTATION = 27,0
-- local MAX_ROTATION,MIN_ROTATION = 55,28
local MAX_ROTATION,MIN_ROTATION = 55,-55
local JC_NUM = 4
local debugDraw = false
local debugEdit = false
local MAP_CREATE_OPEN = false
local DEFAULT_DT = Def.DEFAULT_DT -- 要能被 DEFAULT_RUNNING_TIME 整除
local DEFAULT_RUNNING_TIME = Def.DEFAULT_RUNNING_TIME 
local GAME_STATUS = {
	"idle",-- 游戏初始化状态
	"pre_waiting_play",-- 玩家操作前的清理工作
	"waiting_play",-- 等待玩家操作
	-- "simulate",-- 模拟碰撞结果
	"waiting_server_reward",-- 等待服务器结果
	"game_start",-- 游戏动画开始
	"game_end",-- 游戏动画结束
}
GAME_STATUS = createEnumTB(GAME_STATUS)

local t_singleMult = { 2, 5, 10, 50, 100, 500, 1000 }
local MOVE_PERSON_DT = DEFAULT_DT
local MOVE_PERSON_WAIT_POS_X = -70.00
local MOVE_PERSON_CHANGE_FACE_POS_X = {70,1563}
local MOVE_PERSON_OFFSET_X = (MOVE_PERSON_CHANGE_FACE_POS_X[2] - MOVE_PERSON_WAIT_POS_X) / DEFAULT_RUNNING_TIME
local DEFINE_COLUMNNUM = 14

local SGTZ = class("SGTZ", function()
    local node = cc.uiloader:load("ccbResources/SGTZRes/ui/SGTZLayer.csb") 
    node:setAnchorPoint(cc.p(0.5,0.5))

    -- 高度比例固定 宽度调整
    local scale = display.height / CONFIG_SCREEN_HEIGHT
    node:setContentSize(cc.size(CONFIG_SCREEN_WIDTH * scale, display.height))
	node:setPosition(display.cx,display.cy)
	node:setNodeEventEnabled(true)

    ccui.Helper:doLayout(node)
    return node
end)

function SGTZ:ctor()
	print("---SGTZ.ctor---") 
	musicfunc.playGamePlayBGMusic()	
	self:changeGameStatus(GAME_STATUS.idle)
	self:initTB()
	self:initView()
	self:initSGTZEngine()
	self:autoFited()

	if debugEdit then
		local lSGTZEditLayer = SGTZEditLayer.new()
		lSGTZEditLayer:addTo(self)
		lSGTZEditLayer:setEditSimulateFunc(handler(self, self.onEditSimulate))
	end
end

function SGTZ:onEnter()
	local index = cc.UserDefault:getInstance():getIntegerForKey("SGTZSingleLine",1)
	self:setBetsIndex(index)
	self:updateUserInfo()
	self:clearMap()
	self:changeGameStatus(GAME_STATUS.pre_waiting_play)
	if not cc.UserDefault:getInstance():getBoolForKey("SGTZ_Guide",false) then
		self:exeGuide1()
	end
end

function SGTZ:initTB()
	self.mRecordTab = {} -- 模拟碰撞记录数据
	self.mColumnView = {} -- 柱子ui界面
	self.mFruitsTab = {} -- 水果
	self.mFruitsView = {} -- 水果
	self.mRewardTab = {}-- 奖励
    self.mRewardTabIndex = 0 --当前碰撞次数
    self.mMap = {}
    self.mRotation = 90 --炮台旋转角度
	self.mVelocityLen = 1200
    self.mBallX,self.mBallY = 0,0
    self.mLineNum = 10--压住线条数
    self.mSingleLineNum = 500 -- 单线下注额度
    self.mScoreNum = 0 -- 底分
    self.mCurPlayScore = 0 -- 当前玩的下注额度
    self.mFruitCardUseFlag = 0 -- 水果免费卡道具使用标记
	self.mBetsIndex = 1 -- 单轨金额
	self.mFreeDrawLotteryNum = 0 -- 免费次数
	self.mPreBetBtnStatus = "norm" -- 上一次下注状态
	self.mBetBtnStatus = "norm" -- 当前下注状态
	self.mBurstJackpot = 0 -- 当前局奖池数
	self.mIsShiwan = false -- 试玩标记
	self.nExtraPrizePropGoodsType = GOODSTYPE_CARD_GOLD
	self.mPaoTaiMoveOffset = 0
end

function SGTZ:initView()
	self.Node_engine = cc.uiloader:seekCsbNodeByName(self, "Node_engine")
	self.Node_zidan = cc.uiloader:seekCsbNodeByName(self.Node_engine, "Node_zidan")
	self.Node_anim = cc.uiloader:seekCsbNodeByName(self, "Node_anim")


	self.node_up_bar = cc.uiloader:seekCsbNodeByName(self, "node_up_bar")--右上
	self.rule_btn = cc.uiloader:seekCsbNodeByName(self.node_up_bar, "rule_btn")
	display.setImageClick(self.rule_btn,handler(self,self.Func_onClickBtn_Help))
	--//任务
	local isXianWanXiaoHao = center.user:isXianWanXiaoHao()
	self.m_btn_task = cc.uiloader:seekCsbNodeByName(self.node_up_bar, "task_btn")
	self.m_btn_task:setVisible(center.yaoqing:isSwitchOpen("btTaskSwitch") and not isXianWanXiaoHao)
	display.setImageClick(self.m_btn_task,handler(self,self.Func_onClickBtn_task))
	self.m_sp_task_red = cc.uiloader:seekCsbNodeByName(self.m_btn_task,"red_point")
	PlazaController.registerEvent(self.m_sp_task_red,EVENT_ID.EVENT_PLAZA_TASK_CHANGE,handler(self, self.checkTaskRedPoint))
	self:checkTaskRedPoint()


	self.m_btn_setting = cc.uiloader:seekCsbNodeByName(self.node_up_bar, "setting_btn")	
	display.setImageClick(self.m_btn_setting,handler(self,self.Func_onClickBtn_setting))


	local Node_topLeft = cc.uiloader:seekCsbNodeByName(self, "Node_topLeft")
	self.btn_exit = cc.uiloader:seekCsbNodeByName(Node_topLeft, "Image_exit")
	display.setImageClick(self.btn_exit,handler(self,self.Func_onClickBtn_exit))
	self.Text_debug = cc.uiloader:seekCsbNodeByName(Node_topLeft, "Text_debug"):setVisible(sNeedGuest and true or false)

	self.Node_rank = cc.uiloader:seekCsbNodeByName(self, "Node_rank")
	YuleRankBtn.new():addTo(self.Node_rank)

	self.m_btn_boxTask = cc.uiloader:seekCsbNodeByName(self, "Image_btn_box_task")
	display.setImageClick(self.m_btn_boxTask,handler(self,self.Func_onClick_boxTask))
	self.m_btn_boxTask:setVisible(false)
	PlazaController.registerEvent(self.m_btn_boxTask,EVENT_ID.EVENT_TZ_TASK_CONFIG,handler(self, self.updateBoxTaskConfig))
	PlazaController.registerEvent(self.m_btn_boxTask,EVENT_ID.EVENT_PLAZA_TASK_CHANGE,handler(self, self.updateBoxTaskRedPot))
	PlazaController.registerEvent(self.m_btn_boxTask,EVENT_ID.EVENT_TZ_TASK_DATA,handler(self, self.updateBoxTaskRedPot))
	PlazaController.registerEvent(self.m_btn_boxTask,EVENT_ID.EVENT_TZ_BOX_REWARD_RESPONSE,handler(self, self.updateBoxTaskRedPot))
	self:updateBoxTaskConfig()
	self:updateBoxTaskRedPot()

	self:initPaoTai()
	self:initJiangChi()
	self:initUserInfo()
	self:initBetBtns()
	self:initMovePerson()
	self:initReward()
	self:initHornView()
end


function SGTZ:initHornView()
	-- local node_broadcast = cc.uiloader:seekCsbNodeByName(self, "node_broadcast")
	self.hornView = HornView.new()
        :addTo(self)
        :pos(display.cx, display.height - 140)
end

function SGTZ:autoFited()
	--全面屏适配
	if ( display.widthInPixels / display.heightInPixels ) >= 2 then
		local node_up_bar = cc.uiloader:seekCsbNodeByName(self, "node_up_bar")
		local Node_topLeft = cc.uiloader:seekCsbNodeByName(self, "Node_topLeft")

		Node_topLeft:setPositionX(Node_topLeft:getPositionX()+66)
		node_up_bar:setPositionX(node_up_bar:getPositionX()-66)
	end
end

function SGTZ:changeGameStatus(status,...)
	print("changeGameStatus",status)
	local oldGameStatus = self.mGameStatus

	if oldGameStatus == GAME_STATUS.game_start then
		self:clearScheduleUpdateGlobal()
	end

	self.mGameStatus = status
	if status == GAME_STATUS.game_start then
		self.mPaoTaiMoveOffset = self.mPaoTaiMoveOffset-130
    	-- self:playPaoTaiMove(self.mPaoTaiMoveOffset)
    	self:resetBall()
    	self:openBox()
    	for i=1,3 do
			self.mJiangchi[i]:setVisible(false)
	    end
		self:gameStart()
	elseif status == GAME_STATUS.game_end then
		self.mGameEndCo = PlazaController.co_create(handler(self,self.gameEnd))
		self:resumeGameEndFunc()
		-- self:gameEnd()
	-- elseif status == GAME_STATUS.simulate then
	-- 	self:simulate()
	elseif status == GAME_STATUS.pre_waiting_play then
		self:updateUserInfo()
		self:clearMap()
		self:resetBall()
		self.BitmapFontLabel_jiangchi:setString("??%")
		self:changeMovePersonStatus("wait")
		self:updateBall()
		self:checkAutoStart()
	elseif status == GAME_STATUS.waiting_play then
	elseif status == GAME_STATUS.waiting_server_reward then
    	self.mBall:startMove()
	end
end

function SGTZ:initSGTZEngine()
	local Node_random_pos = cc.uiloader:seekCsbNodeByName(self, "Node_random_pos")
	self.mMap = {}
	for i=1,Def.COUNT do
		local node = cc.uiloader:seekCsbNodeByName(Node_random_pos, "Node_" .. i)
		local radius = Def.getRadius(i)
		local data = {
			pos = cc.p(node:getPosition()),
			radius = radius,
		}
		table.insert(self.mMap,data)
	end
	self:initMapView()

	local bl = cc.p(cc.uiloader:seekCsbNodeByName(self, "Node_bl"):getPosition()) --cc.p(136,170)
    local br = cc.p(cc.uiloader:seekCsbNodeByName(self, "Node_br"):getPosition())--cc.p(1781,170)
    local tl = cc.p(cc.uiloader:seekCsbNodeByName(self, "Node_tl"):getPosition())--cc.p(192,807)
    local tr = cc.p(cc.uiloader:seekCsbNodeByName(self, "Node_tr"):getPosition())--cc.p(1729,807)
    local line = {
        {bl,br},
        {tl,tr},
        {bl,tl},
        {br,tr},
    }
    self.mBall = BallItem.new()
    self.mBall:addTo(self.Node_zidan)
    self.mBall:setLocalZOrder(100)
    self.mBall:setVisible(false)

    for i=1,#line do
        SGTZEngine:addWall(line[i][1],line[i][2])
    end

	local size = self.mPanelJiangchi:getContentSize()
	local pos = self.Node_engine:convertToNodeSpace(self.mPanelJiangchi:convertToWorldSpace(cc.p(size.width/2,size.height/2)))
	self.mEnginePanelJiangchi = SGTZEngine:addStaticColumn(pos,size.width/2,"PanelJiangchi")
	self.mEngineJiangchi = {}
    for i=1,3 do
    	local size = self.mJiangchi[i]:getContentSize()
		local pos = self.Node_engine:convertToNodeSpace(self.mJiangchi[i]:convertToWorldSpace(cc.p(size.width/2,size.height/2)))
    	self.mEngineJiangchi[i] = SGTZEngine:addStaticColumn(pos,size.width/2,"Jiangchi_" .. i)
    end

    if debugDraw then
	    local drawNode = cc.DrawNode:create()
	    drawNode:addTo(self.Node_engine)
	    SGTZEngine:openDebugDraw(drawNode)
    end
end

function SGTZ:initPaoTai()
	local maxRotation,minRotation = MAX_ROTATION,MIN_ROTATION
	local rotation = minRotation
	local offsetRotation = 10
    local Node_paotai = cc.uiloader:seekCsbNodeByName(self, "Node_paotai")
    local Node_pao = cc.uiloader:seekCsbNodeByName(self.Node_zidan, "Node_pao")
    self.Node_paotai = Node_paotai

    self.Image_pao = cc.uiloader:seekCsbNodeByName(self.Node_zidan, "Image_pao")
	self.Image_pao_action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_zhizheng.csb")
	self.Image_pao:runAction(self.Image_pao_action)
	self.Image_pao_action:gotoFrameAndPlay(0,true)

    self.Image_zidan = cc.uiloader:seekCsbNodeByName(self.Node_zidan, "Image_zidan")
    self.Image_pao_bg = cc.uiloader:seekCsbNodeByName(self.Node_zidan, "Image_pao_bg")

    self:setPaoRotation(rotation)

    Node_pao:schedule(function()
    		if GAME_STATUS.waiting_play ~= self.mGameStatus and GAME_STATUS.pre_waiting_play ~= self.mGameStatus then 
    			local flag = GAME_STATUS.waiting_play ~= self.mGameStatus and GAME_STATUS.waiting_server_reward ~= self.mGameStatus
				Node_pao:setVisible(not flag)
    			self.Image_zidan:setVisible(not flag)
    			self.Image_pao_bg:setVisible(not flag)
				self.mBall:setVisible(flag)
    			return 
    		else
				Node_pao:setVisible(true)
				self.Image_zidan:setVisible(true)
    			self.Image_pao_bg:setVisible(true)
				self.mBall:setVisible(false)
    		end
    		rotation = rotation + offsetRotation
    		if rotation >= maxRotation then
    			rotation = maxRotation
    			offsetRotation = -offsetRotation
    		end
    		if rotation <= minRotation then
    			rotation = minRotation
    			offsetRotation = -offsetRotation
    		end
    		self:setPaoRotation(rotation)
		end,  1/20)

    self.Text_bets = cc.uiloader:seekCsbNodeByName(Node_paotai, "Text_bets")
    self.add_btn = cc.uiloader:seekCsbNodeByName(Node_paotai, "add_btn")
    self.sub_btn = cc.uiloader:seekCsbNodeByName(Node_paotai, "sub_btn")


	display.setImageClick(self.add_btn,function()
			self:setBetsIndex(self.mBetsIndex+1)
		end)
	display.setImageClick(self.sub_btn,function()
			self:setBetsIndex(self.mBetsIndex-1)
		end)

    self.LoadingBar_lv = cc.uiloader:seekCsbNodeByName(Node_paotai, "LoadingBar_lv")
    self.LoadingBar_lv_0 = cc.uiloader:seekCsbNodeByName(Node_paotai, "LoadingBar_lv_0")
    self.LoadingBar_anim = cc.uiloader:seekCsbNodeByName(Node_paotai, "LoadingBar_anim")
    self.LoadingBar_anim_action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_xulitiaoman.csb")
	self.LoadingBar_anim:runAction(self.LoadingBar_anim_action)
end

function SGTZ:playPaoTaiMove(offset,callback)
	local oldAction = self.Node_paotai:getActionByTag(100)
	if oldAction and not oldAction:isDone() then
		return
	end
	if oldAction then self.Node_paotai:removeAction(oldAction) end
	local dt = 0.3
	local acts = {
		cca.moveBy(dt, 0, offset),
	}
	if callback then
		table.insert(acts,cca.callFunc(callback))
	end
	local action = cca.seq(acts)
	action:setTag(100)
	self.Node_paotai:runAction(action)
end

function SGTZ:initJiangChi()
    local Node_engine = cc.uiloader:seekCsbNodeByName(self, "Node_engine")
    self.mPanelJiangchi = cc.uiloader:seekCsbNodeByName(Node_engine, "Panel_jiangchi")
    self.BitmapFontLabel_jiangchi = cc.uiloader:seekCsbNodeByName(Node_engine, "BitmapFontLabel_jiangchi")
	self.BitmapFontLabel_jiangchi:setString("??%")
    self.mJiangchi = {}
    for i=1,3 do
    	self.mJiangchi[i] = cc.uiloader:seekCsbNodeByName(self.mPanelJiangchi, "Image_jiangchi_" .. i)
    end

	--//奖池
	self.Text_jiangchi = cc.uiloader:seekCsbNodeByName(self, "Text_jiangchi")
	PlazaController.registerEvent(self,EVENT_ID.EVENT_GLOBALLATTERY_UPDATE,handler(self, self.setShowJackpot))
    self.Text_cur_win = cc.uiloader:seekCsbNodeByName(self, "Text_cur_win")

    self.Image_pool_bg = cc.uiloader:seekCsbNodeByName(self, "Image_pool_bg")
    
	display.setImageClick(self.Image_pool_bg,function()
			self.m_pGameSink:RequestPoolInfo()
		end)
end

function SGTZ:initUserInfo()
    local Text_gold = cc.uiloader:seekCsbNodeByName(self, "Text_gold")
    local Text_vip = cc.uiloader:seekCsbNodeByName(self, "Text_vip")
    local Image_buy_gold_btn = cc.uiloader:seekCsbNodeByName(self, "Image_buy_gold_btn")

	display.setImageClick(Image_buy_gold_btn,PlazaController.popupMallGoldView)

	PlazaController.registerEvent(Text_gold,EVENT_ID.EVENT_PLAZA_ACTOR_PRIVATE,handler(self, self.updateUserInfo))
	PlazaController.registerEvent(Text_gold,EVENT_ID.EVENT_PLAZA_ACTOR_VARIABLE,handler(self, self.updateUserInfo))
end

function SGTZ:updateUserInfo()
	if self.mGameStatus == GAME_STATUS.waiting_play or self.mGameStatus == GAME_STATUS.idle or self.mGameStatus == GAME_STATUS.pre_waiting_play then
	    local Text_vip = cc.uiloader:seekCsbNodeByName(self, "Text_vip")
		local vipLevel=center.user:getActorProp(ACTOR_PROP_VIPLEVEL)
		Text_vip:setString("VIP" .. tostring(vipLevel))
		local coinNum = center.user:getActorProp(ACTOR_PROP_GOLD)
		self:setUserShowGold(coinNum)
	end
end

function SGTZ:setUserShowGold(coinNum)
    local Text_gold = cc.uiloader:seekCsbNodeByName(self, "Text_gold")
	Text_gold:setString(helpUntile.FormateNumber2(coinNum))
end

function SGTZ:initReward()	
	local Node_topLeft = cc.uiloader:seekCsbNodeByName(self, "Node_topLeft")
	local FileNode_rewardPacket = cc.uiloader:seekCsbNodeByName(Node_topLeft, "FileNode_rewardPacket"):setVisible(false)
	local btn_rewardPacket = cc.uiloader:seekCsbNodeByName(FileNode_rewardPacket, "btn_rewardPacket")
	display.setImageClick(btn_rewardPacket,handler(self,self.Func_onClickBtn_reward))
	
	--还需发射多少次可领取奖励
	local Text_num = cc.uiloader:seekCsbNodeByName(btn_rewardPacket, "Text_num")
	local img_icon = cc.uiloader:seekCsbNodeByName(btn_rewardPacket, "img_icon")
	local img_icon_bg = cc.uiloader:seekCsbNodeByName(btn_rewardPacket, "img_icon_bg")
	local Panel_clip = cc.uiloader:seekCsbNodeByName(btn_rewardPacket, "Panel_clip")
	local Panel_clip_width = Panel_clip:getContentSize().width
	local FileNode_anim = cc.uiloader:seekCsbNodeByName(btn_rewardPacket, "FileNode_anim")
    local action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_ljyhb_jingdutiao.csb")
	FileNode_anim:runAction(action)
	action:gotoFrameAndPlay(0,true)

	local FileNode_complete = cc.uiloader:seekCsbNodeByName(btn_rewardPacket, "FileNode_complete")
    local action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_ljyhb_mang.csb")
	FileNode_complete:runAction(action)
	action:gotoFrameAndPlay(0,true)


	local maxHeight = 131
	local preRwardIndex = -1
	local function initData()
		local isOpen = gameCenter.smGame:getTanZhuTaskMananger():isOpenTanZhuTask()	
		btn_rewardPacket:setVisible(isOpen and not self.mIsShiwan)

		local rewardInfo = gameCenter.smGame:getTanZhuTaskMananger():getTanZhuPrizeInfo()
		if not rewardInfo or next(rewardInfo) == nil then
			return
		end

		--当前已达到的分数
		local curScore = gameCenter.smGame:getTanZhuTaskMananger():getCurScore()
		local index = 3
		local rewardIndex = 0
		for i=1,3 do
			--每个档次的分数
			local needScore = tonumber(rewardInfo[i].nNeedScore)
			if needScore > curScore then
				index = i
				break
			end
		end	
		rewardIndex = index-1
		local preNeedScore = 0
		if index > 1 then
			preNeedScore = tonumber(rewardInfo[index-1].nNeedScore)
		end
		local needScore = tonumber(rewardInfo[index].nNeedScore)
		if curScore > needScore then curScore = needScore end
		local intervalScore = needScore - curScore
		local percent = (curScore - preNeedScore) / (needScore - preNeedScore)

		local height = maxHeight * percent
		Panel_clip:setContentSize(cc.size(Panel_clip_width,height))
		FileNode_anim:setPositionY(height)
		FileNode_anim:setVisible( percent > 0 and percent < 1)
		local ratio = self.mSingleLineNum*self.mLineNum
		local count = math.ceil(intervalScore / ratio)

		if count == 0 then
			rewardIndex = rewardIndex + 1
			FileNode_complete:setVisible(true)
			Text_num:setString("有奖励可领哦")
		else
			FileNode_complete:setVisible(false)
			Text_num:setString(string.format("还需发射\n%d次",count))
		end
		img_icon:loadTexture("ccbResources/SGTZRes/image/reward/YHB_hongbao0"..index..".png")

		-- if preRwardIndex ~= -1 and preRwardIndex ~= rewardIndex and rewardIndex > 0 then
		-- 	musicfunc.play2d(Def.MUSIC.AUDIO_HONGBAO_ARRIVED)
		-- end
		preRwardIndex = rewardIndex

		if index == 1 then
			img_icon_bg:setContentSize(cc.size(0,0))
			img_icon_bg:loadTexture("ccbResources/SGTZRes/image/reward/YHB_hongbao04.png")
		else
			img_icon_bg:setContentSize(cc.size(0,0))
			img_icon_bg:loadTexture("ccbResources/SGTZRes/image/reward/YHB_hongbao0".. (index-1) ..".png")
		end
	end
	initData()
	PlazaController.registerEvent(Text_num,EVENT_ID.EVENT_TANZHU_CFG,initData)
	PlazaController.registerEvent(Text_num,EVENT_ID.EVENT_TANZHU_TASK_UPDATE,initData)
end


function SGTZ:setPaoRotation(rotation)
    local Node_pao = cc.uiloader:seekCsbNodeByName(self.Node_zidan, "Node_pao")
    Node_pao:setRotation(rotation)
    self.mRotation = rotation
end

function SGTZ:resetBall()
	SGTZEngine:initBall(self.mBallX,self.mBallY,self.mRotation,self.mVelocityLen)
    self.mBall:setPosition(self.mBallX,self.mBallY)
    self.mBall:reset()
end

function SGTZ:simulate(randomMap)
	print("simulate",randomMap)
	local size = self.Image_zidan:getContentSize()
	-- print("simulate2222")
	local pos = self.Node_engine:convertToNodeSpace(self.Image_zidan:convertToWorldSpace(cc.p(size.width/2,size.height/2)))
    
	-- print("simulate3333")
	self.mBallX,self.mBallY = pos.x,pos.y

	-- print("simulate4444")
    self:resetBall()

    local columnNum = DEFINE_COLUMNNUM
    print("地图生成中",randomMap)
    local columnTab = SGTZEngine:initMap(self.mMap,randomMap)
    print("地图生成完成")
    local recordTime = 0
    local dt = DEFAULT_DT
    local recordTab = {}
    SGTZEngine:setCollisionListener(function(column,index)
            table.insert(recordTab,index)
        end)
    while recordTime < DEFAULT_RUNNING_TIME do
    	-- print("simulate",recordTime)
        recordTime = recordTime + dt
    	SGTZEngine:update(dt)
    end
    return recordTab,columnTab
end

function SGTZ:clearScheduleUpdateGlobal()
	if self.mUpdateGlobalHandler then
        scheduler.unscheduleGlobal(self.mUpdateGlobalHandler)
        -- self:stopAction(self.mUpdateGlobalHandler)
        self.mUpdateGlobalHandler = nil
	end
end

function SGTZ:gameStart()
	if self.mBetBtnStatus == "free" then
		musicfunc.play2d(Def.MUSIC.AUDIO_FREE_GAME)
	else
		musicfunc.play2d(Def.MUSIC.AUDIO_LAUNCH)
	end
    local recordTime = 0
    local dt = DEFAULT_DT

    self.mRewardTabIndex = 0
    SGTZEngine:setCollisionListener(handler(self, self.onCollision))
    self:resetBall()
    self.mBallTailFlameAnim = TailFlameAnim:addBallTailFlame(self.Node_zidan,self.mBetsIndex)
    if self.mBallTailFlameAnim then
    	self.mBallTailFlameAnim:addTo(self.mBall)
    end

    self:changeMovePersonStatus("walk")
    local startTime = os.time()
    local offset_add = 0
    self.mUpdateGlobalHandler = scheduler.scheduleUpdateGlobal(function(offset_dt)
    -- self.mUpdateGlobalHandler = self:schedule(function()
   			-- print(offset_dt)
   			local count = math.floor((offset_dt + offset_add) / dt)
   			offset_add = (offset_dt + offset_add) % dt
   			for i=1,count do
	            recordTime = recordTime + dt
	            SGTZEngine:update(dt)
	            self:movePerson(dt)
	            local pos = SGTZEngine:getBallPosition()
	    		self.mBall:setPosition(pos.x,pos.y)
	    		if recordTime >= DEFAULT_RUNNING_TIME then 
	    			print("cost time:",os.time() - startTime)
					self:changeGameStatus(GAME_STATUS.game_end)
	                return 
	            end
	        end
        end,dt)
end

function SGTZ:onCollision(column,index)
	self.mRewardTabIndex = self.mRewardTabIndex + 1
	print("onCollision",self.mRewardTabIndex,self.mRewardTab[self.mRewardTabIndex],index)
	if type(index) == "number" then
		local goldNum = self.mRewardTab[self.mRewardTabIndex]
		-- 碰水果
		if self.mFruitsView[index] then
			local fruitsReward = self.mFruitsTab[index] -- 当前柱子的水果奖励
			local isCanGetFruitsReward = fruitsReward and self.mFruitsView[index]:isCanGetFruitsReward() -- 当前柱子的水果奖励是否能领取
			if isCanGetFruitsReward then
				local uTouchPrizeID = checkint(fruitsReward.uTouchPrizeID)
				local uTouchPrizeNum = checkint(fruitsReward.uTouchPrizeNum)
				local x,y = self.mFruitsView[index]:getPosition()
				self.mFruitsView[index]:onCollision(function()
					-- self.mFruitsView[index]:setVisible(false)
					-- self.mColumnView[index]:setVisible(true)
					-- 添加掉了水果
					self:addDropFruits(cc.p(x,y),fruitsReward)
				end)
				local isComplete = self.mFruitsView[index]:isComplete()
				if isComplete then
					if GoodsData.isFreeFruits(uTouchPrizeID) then
						-- 添加免费水果奖励
					else
						self:addDrawlotteryGoldNum( uTouchPrizeNum * self.mCurPlayScore )
						if uTouchPrizeID == 1 then
							JieSuanAnim:playGoldAnim(self.Node_zidan,cc.p(x, y),3,function(goldNode)
								self:attractAnim(goldNode)
							end)
							JieSuanAnim:playGoldPoolAnim(self.Node_zidan,cc.p(x, y),callback)
						elseif uTouchPrizeID == 2 then
							JieSuanAnim:playGoldAnim(self.Node_zidan,cc.p(x, y),5,function(goldNode)
								self:attractAnim(goldNode)
							end)
							JieSuanAnim:playGoldPoolAnim(self.Node_zidan,cc.p(x, y),callback)
						else 
							JieSuanAnim:playGoldAnim(self.Node_zidan,cc.p(x, y),5,function(goldNode)
								self:attractAnim(goldNode)
							end)
							JieSuanAnim:playGoldPoolAnim(self.Node_zidan,cc.p(x, y),callback)
						end
					end
					musicfunc.play2d(Def.MUSIC.AUDIO_FRUITS_COLLISION)
				else
					musicfunc.play2d(Def.MUSIC.AUDIO_FRUITS_GEAR)
				end
			end
		-- 碰金币
		elseif self.mColumnView[index] then
			if goldNum then
				local x,y = self.mColumnView[index]:getPosition()
				local floatText = FloatTextAnim.new()
				floatText:setPosition(x, y)
				floatText:addTo(self.Node_zidan)
				floatText:setTextNum("+" .. goldNum)
				floatText:play(function()
						if not tolua.isnull(floatText) then
							floatText:removeSelf()
						end
					end)
				if self.nExtraPrizePropGoodsType == GOODSTYPE_CARD_GOLD then
					self:addDrawlotteryGoldNum(goldNum)
					JieSuanAnim:playGoldAnim(self.Node_zidan,cc.p(x, y),2,function(goldNode)
							self:attractAnim(goldNode)
						end)
				else
					JieSuanAnim:playHongBaoAnim(self.Node_zidan,cc.p(x, y),2,function(goldNode)
							self:attractAnim(goldNode)
						end)
					-- JieSuanAnim:playGoldAnim(target,num,callback)
				end
			end
			self.mColumnView[index]:onCollision()
			musicfunc.play2d(Def.MUSIC.AUDIO_GOLD_COLLISION)
		end
	else
		local tag = index
		local isOpenJiangChi = true
		for i=1,3 do
			isOpenJiangChi = isOpenJiangChi and self.mJiangchi[i]:isVisible()
	    end

	    if not isOpenJiangChi then
			for i=1,3 do
				if tag == "Jiangchi_" .. i then
					self.mJiangchi[i]:setVisible(not self.mJiangchi[i]:isVisible())
					if self.mJiangchi[i]:isVisible() then
						musicfunc.play2d(Def.MUSIC.AUDIO_FRUITS_COLLISION)
					end
				end
				isOpenJiangChi = isOpenJiangChi and self.mJiangchi[i]:isVisible()
		    end
		end
	    -- 爆奖池
	    if isOpenJiangChi and self.mBurstJackpot > 0 then
	    	self:addDrawlotteryGoldNum(self.mBurstJackpot)
	    	self.mBurstJackpot = 0
			self.BitmapFontLabel_jiangchi:setString( self.nPoolPrizeScale .. "%")
			musicfunc.play2d(Def.MUSIC.AUDIO_HIT_LOTTERY_POOL)
			musicfunc.play2d(Def.MUSIC.AUDIO_SETTLEMENT_CHEERS)
			local callback = nil
			local pos = {}
			for i=1,#self.mMap do
				pos[i] = self.Node_anim:convertToNodeSpace(self.Node_zidan:convertToWorldSpace(self.mMap[i].pos))
			end
			JieSuanAnim:playPoolOpen(self.Node_anim,pos,callback)
		end
	end
end

function SGTZ:gameEnd()

	-- 弹珠碎裂动画
    self.mBall:stopMove()
    if self.mBallTailFlameAnim then
    	self.mBallTailFlameAnim:removeSelf()
    end
	self.mBall:playDismissAnim(handler(self, self.resumeGameEndFunc))
	coroutine.yield("playDismissAnim")
	-- freeNumFinsh 免费摇奖次数结束
	-- freeDrawLotteryNum 免费摇奖次数 -- 当前免费次数
	-- getfreeDrawLotteryNum 本次活动的免费摇奖次数 -- 本次获得的免费次数
	-- BurstJackpot 爆奖池结果
	-- drawlotteryGoldNum 本次摇奖获得的金币
	-- multGoldNum 赢取金币倍数
	-- freeDrawGetGoldNum 免费摇奖获得的金币 -- n次免费获得的总奖励
	-- ActorDBID 角色ID
	-- fruitFreeCardLeftNum 当前水果免费卡个数
	-- fruitFreeCardUseNum 本局消耗的水果免费卡个数 -- 无用
	-- 结算动画
	local nExtraPrizePropID = self.nExtraPrizePropID
	local nExtraPrizeNum = self.nExtraPrizeNum
	local redbagPrizeNum = self.nExtraPrizePropGoodsType == GOODSTYPE_TREASURE and nExtraPrizeNum or 0
	local nPoolPrizeScale = self.nPoolPrizeScale
	local gameEndData = self.mGameEndData or {}
	local getfreeDrawLotteryNum = checkint(gameEndData.getfreeDrawLotteryNum)
	local drawlotteryGoldNum = checkint(gameEndData.drawlotteryGoldNum)
	local BurstJackpot = checkint(gameEndData.BurstJackpot)
	local freeDrawLotteryNum = checkint(gameEndData.freeDrawLotteryNum)
	self:setDrawlotteryGoldNum(drawlotteryGoldNum)
	if BurstJackpot > 0 then
		musicfunc.play2d(Def.MUSIC.AUDIO_SETTLEMENT)
		JieSuanAnim:playMZBK(self.Node_anim,drawlotteryGoldNum-BurstJackpot,BurstJackpot,redbagPrizeNum,handler(self, self.resumeGameEndFunc))
		coroutine.yield("BurstJackpotAnim")
	elseif drawlotteryGoldNum > 0 or redbagPrizeNum > 0 then
		if self.mCurPlayScore * self.mLineNum > drawlotteryGoldNum then
			musicfunc.play2d(Def.MUSIC.AUDIO_SETTLEMENT_NOT_WIN)
			JieSuanAnim:playPTJS(self.Node_anim,drawlotteryGoldNum,redbagPrizeNum,handler(self, self.resumeGameEndFunc))
		elseif self.mCurPlayScore * self.mLineNum * 5 > drawlotteryGoldNum then
			musicfunc.play2d(Def.MUSIC.AUDIO_SETTLEMENT)
			JieSuanAnim:playGXHD(self.Node_anim,drawlotteryGoldNum,redbagPrizeNum,handler(self, self.resumeGameEndFunc))
		else
			musicfunc.play2d(Def.MUSIC.AUDIO_SETTLEMENT)
			musicfunc.play2d(Def.MUSIC.AUDIO_SETTLEMENT_CHEERS)
			JieSuanAnim:playDZTZ(self.Node_anim,drawlotteryGoldNum,redbagPrizeNum,handler(self, self.resumeGameEndFunc))
		end
		coroutine.yield("DrawlotteryGoldAnim")
	else
		-- 一般都有奖励 不会触发
		self:performWithDelay(handler(self, self.resumeGameEndFunc), 1)
		coroutine.yield("wait")
	end

	if getfreeDrawLotteryNum > 0 then
		-- self:performWithDelay(function()
		-- 		print("FreeDrawLotteryAnim End")
				self:changeBetBtnStatus("free")
				-- self:resumeGameEndFunc()
			-- end, 2)
		-- coroutine.yield("FreeDrawLotteryAnim")
	end
	self:setFreeDrawLotteryNum(freeDrawLotteryNum,true)
	if self.mPaoTaiMoveOffset ~= 0 then
    	-- self:playPaoTaiMove(-self.mPaoTaiMoveOffset)
    	self.mPaoTaiMoveOffset = 0
	end
	self:performWithDelay(handler(self, self.resumeGameEndFunc), 1)
	coroutine.yield("PaoTaiMove")

    -- 检测是否弹窗抽奖宝箱
    if freeDrawLotteryNum == 0 and center.luckdraw:checkAndShowLuckDrawBox() then
    	self:changeBetBtnStatus("norm")
    end

	self:changeGameStatus(GAME_STATUS.pre_waiting_play)
end

function SGTZ:resumeGameEndFunc(...)
	local ret = {coroutine.resume(self.mGameEndCo,...)}
	if ret[1] then
		return unpack(ret)
	else
		self:changeGameStatus(GAME_STATUS.pre_waiting_play)
		__G__TRACKBACK__(ret[2])
		return unpack(ret)
	end
end

-- 柱子金币数 -- 水果
function SGTZ:onServerReward(nExtraPrizePropID, nExtraPrizeNum,nPoolPrizeScale,nPrizeRatio)
	self.nExtraPrizePropID = nExtraPrizePropID
	-- 需要提前知道是给金币还是红包  这里协议要改  需求变更成写死红包
	-- local goodInfo = center.good:getGoodsInfo(nExtraPrizePropID)
	-- if goodInfo then
	-- 	self.nExtraPrizePropGoodsType = goodInfo.lGoodsType
	-- else
	-- 	self.nExtraPrizePropGoodsType = GOODSTYPE_CARD_GOLD
	-- end
	self.nExtraPrizeNum = nExtraPrizeNum
	self.nPoolPrizeScale = checkint(nPoolPrizeScale)
	self.nPrizeRatio = nPrizeRatio
end

function SGTZ:setGameSink(gamesink, pScene)
	print("FruitMachine:setGameSink")
	self.m_pGameScene = pScene  	--游戏场景
	self.m_pGameSink = gamesink     --游戏逻辑
end

function SGTZ:setMyData()
end

function SGTZ:getServerFriutData()
end
--//设置房间信息奖池
function SGTZ:OnReceiveRoomInfo(info)
	print("FruitMachine:OnReceiveRoomInfo")
	-- 设置当前奖池
	self:setShowJackpot(tonumber(info.JackpotNum))
	self.mScoreNum = checkint(info.score)
	self:updateBets()

	local freeDrawLotteryNum = checkint(info.freeDrawLotteryNum)
	self.mIsShiwan = checkint(info.btPlatformFlag) == 1
	self:updateBoxTaskConfig()

	self:setFreeDrawLotteryNum(freeDrawLotteryNum,true)
	self:setDrawlotteryGoldNum(0)
	if freeDrawLotteryNum > 0 then
		self:changeBetBtnStatus("free")
	else
		self:changeBetBtnStatus("norm")
	end
	-- 通知水果累计红包参数变更
	EventHelp.FrieEventID(EVENT_ID.EVENT_TANZHU_TASK_UPDATE)
end
-- 设置免费次数
function SGTZ:setFreeDrawLotteryNum(num,isUpdateView)
	self.mFreeDrawLotteryNum = num
	if isUpdateView then
		self:updateFreeDrawLotteryView()
	end
end

function SGTZ:updateFreeDrawLotteryView()
	self.Text_free_num:setString(tostring(self.mFreeDrawLotteryNum).."次")
end

-- 设置本局获得金币数
function SGTZ:setDrawlotteryGoldNum(num)
	self.mDrawlotteryGoldNum = num
	self:updateDrawlotteryGoldView()
end

function SGTZ:addDrawlotteryGoldNum(num)
	print("addDrawlotteryGoldNum",num)
	self.mDrawlotteryGoldNum = self.mDrawlotteryGoldNum + num
	self:updateDrawlotteryGoldView()
end

function SGTZ:updateDrawlotteryGoldView()
	self.Text_cur_win:setString("本局获得：" .. string.formatnumberthousands(tostring(self.mDrawlotteryGoldNum)))
end

function SGTZ:setBetsIndex(index)
	if self.mGameStatus == GAME_STATUS.waiting_play or self.mGameStatus == GAME_STATUS.idle then
		index = checkint(index)
		local min,max = 1,#t_singleMult
		if index < min then index = min end
		if index > max then index = max end
		local isNeedAnim = self.mBetsIndex ~= index
		self.mBetsIndex = index
		cc.UserDefault:getInstance():setIntegerForKey("SGTZSingleLine",self.mBetsIndex)
		self:updateBets(isNeedAnim)
	end
end

function SGTZ:updateBets(isNeedAnim)
	self.mSingleLineNum = t_singleMult[self.mBetsIndex] * self.mScoreNum
	self.Text_bets:setString(tostring(self.mSingleLineNum*self.mLineNum))
	local percent = self.mBetsIndex / #t_singleMult * 100
	self.LoadingBar_lv:setPercent(percent)
    self.LoadingBar_lv_0:setPercent(percent)
    if isNeedAnim then
    	self.LoadingBar_anim_action:gotoFrameAndPlay(0,false)
    end
	
	self:updateBall()
	-- 通知水果累计红包参数变更
	EventHelp.FrieEventID(EVENT_ID.EVENT_TANZHU_TASK_UPDATE)
end

function SGTZ:updateBall()
	if self.mGameStatus ~= GAME_STATUS.waiting_play and self.mGameStatus ~= GAME_STATUS.pre_waiting_play then return end
	self.mBall:setIndex(self.mBetsIndex)
    self.Image_zidan:loadTexture("ccbResources/SGTZRes/image/icon/SG_danzhu0" .. self.mBetsIndex .. ".png")

	local flag = self.mBetsIndex > JC_NUM
    self.mPanelJiangchi:setVisible(flag)
    for i=1,3 do
    	self.mJiangchi[i]:setVisible(flag)
    end
end

function SGTZ:checkAutoStart()
	self:performWithDelay(function()
			self:changeGameStatus(GAME_STATUS.waiting_play)
			if self.mBetBtnStatus == "free" then
				if self.mFreeDrawLotteryNum == 0 then
					self:changeBetBtnStatus(self.mPreBetBtnStatus)
				elseif self.mFreeDrawLotteryNum > 0 and self:onStartBtnClick() then
					self:setFreeDrawLotteryNum(self.mFreeDrawLotteryNum-1,true)
					return
				end
			end

			if self.mBetBtnStatus == "auto" then
				if self:onStartBtnClick() then
					return
				end
			end
			-- 检查按钮是否恢复 norm 状态
			-- 自动投注失败 恢复正常状态
			if self.mBetBtnStatus == "auto" then
				self:changeBetBtnStatus("norm")
			end
		end, 0.5)
end

function SGTZ:setOnGameEnd(data)

	local nExtraPrizePropID = self.nExtraPrizePropID
	local nExtraPrizeNum = self.nExtraPrizeNum
	local nPoolPrizeScale = self.nPoolPrizeScale
	self.mGameEndData = data
	-- freeNumFinsh 免费摇奖次数结束
	-- freeDrawLotteryNum 免费摇奖次数
	-- getfreeDrawLotteryNum 本次活动的免费摇奖次数
	-- BurstJackpot 爆奖池结果
	-- drawlotteryGoldNum 本次摇奖获得的金币
	-- multGoldNum 赢取金币倍数 -- 这个数据有问题
	-- freeDrawGetGoldNum 免费摇奖获得的金币
	-- ActorDBID 角色ID
	-- fruitFreeCardLeftNum 当前水果免费卡个数
	-- fruitFreeCardUseNum 本局消耗的水果免费卡个数
	-- local multGoldNum = checkint(data.multGoldNum)
	local BurstJackpot = checkint(data.BurstJackpot)
	local getfreeDrawLotteryNum = checkint(data.getfreeDrawLotteryNum)
	local isHasBurstJackpot = BurstJackpot > 0
	self.mBurstJackpot = BurstJackpot
	self.nPoolPrizeScale = nPoolPrizeScale
	self:setDrawlotteryGoldNum(0)

	-- 初始化奖池
	local flag = self.mBetsIndex > JC_NUM
    self.mEnginePanelJiangchi:setDestroy(not flag)
    for i=1,3 do
    	self.mEngineJiangchi[i]:setDestroy(not flag)
    end

	local tanZhuPrizeInfo = {}
	local bigFruitsNum = 0
	local bigFruits = nil
	local prizeRatio = self.nPrizeRatio
	local fruitNum = 0
	local angle = self.mRotation
	local randomseedMap = nil
	local isHasResult = false
	local fileName = ""
	-- 搜索结果

	-- test 
	-- angle = 15
	-- prizeRatio = 100
	-- BurstJackpot = 5155927
	-- isHasBurstJackpot = BurstJackpot > 0
	-- getfreeDrawLotteryNum = 0

	-- 免费水果
	local freeFruit = GoodsData.splitFreeFruits(getfreeDrawLotteryNum)
	local freeFruitNum = #freeFruit

	if prizeRatio > 0 then
		local searchResult = {}
		bigFruits,prizeRatio = GoodsData.getRandomBigFruits(prizeRatio,freeFruitNum)
		if bigFruits then
			bigFruitsNum = 1
		end
		if prizeRatio > 0 then
			local searchLen = 4
			if prizeRatio < 10 then
				searchLen = 2 + freeFruitNum
				searchLen = math.min(4,searchLen)
			end
			for i=1,searchLen do
				if freeFruitNum + i <= 4 then
					local fruits = GoodsData.splitMultToFruits(prizeRatio,i)
					if fruits then
						searchResult[i] = fruits
					end
				end
			end
		else

		end
		dump(bigFruits,"bigFruits")
		dump(searchResult,"searchResult")
		if prizeRatio > 0 then
			local keys = table.keys(searchResult)
			local len = #keys
			while len > 0 do
				if len >= 2 then
					fruitNum = table.remove(keys,checkint(os.time()) % 2 + 1)
				else
					fruitNum = table.remove(keys,1)
				end
				-- fruitNum = table.remove(keys,1)
				len = len - 1
				angle,randomseedMap,fileName = self:searchWorkPath(self.mRotation,bigFruitsNum,freeFruitNum + fruitNum,self.mBetsIndex > JC_NUM,isHasBurstJackpot)
				if angle and randomseedMap then
					isHasResult = true
					tanZhuPrizeInfo = searchResult[fruitNum]
					-- 添加免费水果奖励
					for i,v in ipairs(freeFruit) do
						table.insert(tanZhuPrizeInfo,v)
					end
					break
				end
			end
		else
			-- 无小水果情况
			angle,randomseedMap,fileName = self:searchWorkPath(self.mRotation,bigFruitsNum,freeFruitNum,self.mBetsIndex > JC_NUM,isHasBurstJackpot)
			if angle and randomseedMap then
				isHasResult = true
				-- 添加免费水果奖励
				for i,v in ipairs(freeFruit) do
					table.insert(tanZhuPrizeInfo,v)
				end
			end
		end
	elseif freeFruitNum > 0 then
		angle,randomseedMap,fileName = self:searchWorkPath(self.mRotation,0,freeFruitNum,self.mBetsIndex > JC_NUM,isHasBurstJackpot)
		if angle and randomseedMap then
			isHasResult = true
			-- 添加免费水果奖励
			for i,v in ipairs(freeFruit) do
				table.insert(tanZhuPrizeInfo,v)
			end
		end
	else
		angle,randomseedMap,fileName = self:searchWorkPath(self.mRotation,0,0,self.mBetsIndex > JC_NUM,isHasBurstJackpot)
		if angle and randomseedMap then
			isHasResult = true
		end
	end

	print(self.nPrizeRatio,"nPrizeRatio")
	print(self.mRotation,"mRotation")
	dump(tanZhuPrizeInfo,"tanZhuPrizeInfo")

	if not isHasResult then
		-- 找不到解决方案 直接播放结算奖励
		tipsFunc.newHintTip("游戏异常（错误码：404）")
		self:changeGameStatus(GAME_STATUS.game_end)
		error(self.mBetsIndex .. "|" .. self.mRotation .. "|" .. self.nPrizeRatio .. "|" .. getfreeDrawLotteryNum .. "|" .. BurstJackpot)
		return 
	end
	local tanZhuPrizeInfoLen = #tanZhuPrizeInfo
	local randomseed = nil
	--test
	-- angle = 11
	print("angle",angle)

	local function search()
		local hashMap = {}
		local jcHashMap = {}
		if randomseedMap and next(randomseedMap) then
			randomseed = table.remove(randomseedMap,math.random(1,#randomseedMap))
		else
			tipsFunc.newHintTip("游戏异常（错误码：405）")
			self:changeGameStatus(GAME_STATUS.game_end)
			error(fileName)
		end
		self:updateDebugInfo(fileName,randomseed,self.nPrizeRatio,getfreeDrawLotteryNum,BurstJackpot,nExtraPrizeNum)
		-- randomseed = 1112313313
		print("randomseed",randomseed)
		local isSuccess,recordTab,columnTab = self:checkMapRight(randomseed,hashMap,jcHashMap,tanZhuPrizeInfoLen,bigFruitsNum,isHasBurstJackpot)
		if not isSuccess then
			return false
		end
		local recordTabLen = #recordTab
		local countColumn = #columnTab
		local func = GoodsData.getSmallRamdomGoods
		if tanZhuPrizeInfoLen == 0  then
			func = GoodsData.getSmallRamdomGoods2
		end
		local index = 1
		self.mFruitsTab = {}
		for i,id in ipairs(Def.Fruits) do
			-- local countXiangJiao = GoodsData.countXiangJiao(self.mFruitsTab)
			if Def.isBigFruits(id) then
				if bigFruitsNum == 1 then
					self.mFruitsTab[id] = bigFruits
				else
					self.mFruitsTab[id] = GoodsData.getBigRamdomGoods()
				end
			else
				if hashMap[id] and hashMap[id] >= Def.getFruitsCollisionCount(id) then
					self.mFruitsTab[id] = tanZhuPrizeInfo[index] or func()
					index = index + 1
				else
					self.mFruitsTab[id] = func()
				end
			end
		end
		dump(hashMap,"hashMap")
		-- 随机把金币均匀分配到各个碰撞次数上
		-- goldCount 碰撞柱子一共要送的次数
		-- 用来折叠代码块 不要去除
		if true then
			self.mRewardTab = {}
			local goldCount = recordTabLen
			for i,id in ipairs(recordTab) do
				-- string 类型的是静态柱子
				if self.mFruitsTab[id] or type(id) == "string" then
					goldCount = goldCount - 1
					self.mRewardTab[i] = 0
				end
			end
			print("nExtraPrizeNum",nExtraPrizeNum)
			print("goldCount",goldCount)
			local averageGold = nExtraPrizeNum / goldCount
			print("averageGold",averageGold)
			local averageGoldF = math.floor(averageGold)
			local averageGoldF2 = math.floor(averageGoldF/2)
			local offset = nExtraPrizeNum - averageGoldF * goldCount
			local goldTabIndex = {}
			for i=1,recordTabLen do
				if not self.mRewardTab[i] then
					local gold = math.random(averageGoldF2,averageGoldF+offset)
					self.mRewardTab[i] = gold
					offset = averageGoldF + offset - gold
					table.insert(goldTabIndex,i)
				end
			end
			local goldTabIndexLen = #goldTabIndex
			while offset > 0 do
				local add = math.ceil(offset / 2)
				offset = offset - add
				local index = goldTabIndex[math.random(1,goldTabIndexLen)]
				self.mRewardTab[index] = self.mRewardTab[index] + add
			end
			dump(self.mRewardTab,"mRewardTab")
			dump(self.mFruitsTab,"mFruitsTab")
		end
		return true
	end

	self:setPaoRotation(angle)
	-- 死循环搜索
	while not search() do print("not found result") end

	self:resetMap()
	self:changeGameStatus(GAME_STATUS.game_start)
end

function SGTZ:initMapView()
	for i=1,#self.mMap do
		local pos = self.mMap[i].pos
		if Def.isFruits(i) then
			local fruitsItem = FruitsItem.new(Def.isBigFruits(i) and Def.Big_Fruits_collision_count or Def.Small_Fruits_collision_count)
			fruitsItem:setPosition(pos.x, pos.y)
			fruitsItem:addTo(self.Node_zidan)
			self.mFruitsView[i] = fruitsItem
		else
			local columnItem = ColumnItem.new(self.nExtraPrizePropGoodsType)
			columnItem:setPosition(pos.x, pos.y)
			columnItem:addTo(self.Node_zidan)
			self.mColumnView[i] = columnItem
		end
	end
end

function SGTZ:openBox()
	for _,v in pairs(self.mFruitsView) do
		v:openBox()
	end
end

function SGTZ:clearMap()
	for _,v in pairs(self.mFruitsView) do
		v:reset()
		v:closeBox()
	end
	self.mPanelJiangchi:setVisible(false)
    for i=1,3 do
    	self.mJiangchi[i]:setVisible(false)
    end
end

function SGTZ:resetMap()
	for id,v in pairs(self.mFruitsView) do
		v:setAnimalIcon(self.mFruitsTab[id].uTouchPrizeID,self.mFruitsTab[id].uTouchPrizeNum)
		v:reset()
	end
end

function SGTZ:setGoldPoolInfo(poolinfo)
	print("--SGTZ:setGoldPoolInfo--")
	dump(poolinfo, "奖池信息")
	local PupSettle = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_SGTZ_POOL)	
	if PupSettle then
		PupSettle:initPoolInfo(poolinfo)
	end
end
function SGTZ:backPlazaTips()

end

function SGTZ:CleanGameRes()
	self:clearScheduleUpdateGlobal()
	musicfunc.stopAllEffect()
	GoodsData.clean()
	Def.clean()
end

function SGTZ:Func_onClickBtn_exit()	
	print("--水果机退出游戏:DWGuoShanChe:Func_onClickBtn_exit--")
	if self.mGameStatus ~= GAME_STATUS.waiting_play and self.mGameStatus ~= GAME_STATUS.idle and self.mGameStatus ~= GAME_STATUS.pre_waiting_play then
		-- tipsFunc.newHintPopupYes("您正处于游戏状态，无法退出")
		tipsFunc.newHintTip("您正处于游戏状态，无法退出", time)
		return 
	end
	-- if self.mFreeDrawLotteryNum > 0 then
	-- 	tipsFunc.newHintPopupYes("您正处于免费摇奖状态，无法退出")
	-- 	return 
	-- end
	self.m_pGameSink:OutRoom()
end

function SGTZ:checkTaskRedPoint()		
	if (center.task:getCanAwardTaskCount(TASK_TYPE_NOVICE) + center.task:getCanAwardTaskCount(TASK_TYPE_DAY) + center.task:getCanAwardTaskCount(TASK_TYPE_TIME) + center.task:getCanAwardTaskCount(TASK_TYPE_BUYU) > 0) then
		self.m_sp_task_red:setVisible(true)
	else
		self.m_sp_task_red:setVisible(false)
	end	
end
function SGTZ:Func_onClickBtn_task()	
	print("FuncClick_Task")
	local view=manager.popup:newPopup(POPUP_ID.POPUP_TYPE_TASK)
	if not view then return end
	local canAwardNoviceTask=center.task:getCanAwardTaskCount(TASK_TYPE_NOVICE)
	local canAwardDayTask=center.task:getCanAwardTaskCount(TASK_TYPE_DAY)
	if canAwardDayTask>0 and canAwardNoviceTask==0 then
		view:selectDaliyTask()
		return 
	end
	view:selectNoviceTask()
end

function SGTZ:Func_onClickBtn_setting()
	manager.popup:newPopup(POPUP_ID.POPUP_TYPE_SETTING)
end

--帮助按钮
function SGTZ:Func_onClickBtn_Help()
	print("Func_onClickBtn_Help")	
	manager.popup:newPopup(POPUP_ID.POPUP_TYPE_SGTZ_HELP)
end

function SGTZ:showFreeAnim()
	if self.mFreeAnimNode then return end
	local Node_free_anim = cc.uiloader:seekCsbNodeByName(self, "Node_free_anim")
	self.mFreeAnimNode = cc.uiloader:load("ccbResources/SGTZRes/ui/anim/Node_mianfeiyouxi.csb")
	self.mFreeAnim = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_mianfeiyouxi.csb")
	self.mFreeAnimNode:runAction(self.mFreeAnim)
	self.mFreeAnim:gotoFrameAndPlay(0,true)
	self.mFreeAnimNode:addTo(Node_free_anim)
end

function SGTZ:dismissFreeAnim()
	if self.mFreeAnimNode then 
		self.mFreeAnimNode:removeSelf()
		self.mFreeAnimNode = nil
		self.mFreeAnim = nil
	end
end
--累胜赢红包按钮
function SGTZ:Func_onClickBtn_reward()
	local rewardInfo = gameCenter.smGame:getTanZhuTaskMananger():getTanZhuPrizeInfo()
	if not rewardInfo or next(rewardInfo) == nil then
		return
	end
	--当前已达到的分数
	local curScore = gameCenter.smGame:getTanZhuTaskMananger():getCurScore()
	if tonumber(rewardInfo[3].nNeedScore) <= curScore then
		--达到最高档次直接领取
		gameCenter.smGame:getTanZhuTaskMananger():sendReqPrize(2)
	else
		local view = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_SGTZ_REWARD)
		if view then
			view:setRatio(self.mSingleLineNum*self.mLineNum)
		end
	end
end

function SGTZ:changeBetBtnStatus(status)
	print("changeBetBtnStatus",status)
	self.mPreBetBtnStatus = self.mBetBtnStatus
	local oldStatus = self.mBetBtnStatus
	if oldStatus == "auto" then
		self.Image_auto_btn:setVisible(false)
	elseif oldStatus == "free" then
		self.Image_free_btn:setVisible(false)
		self:dismissFreeAnim()
	elseif oldStatus == "norm" then
		self.Image_start_btn:setVisible(false)
    	self.Image_start_btn:stopAllActions()
	end
	self.mBetBtnStatus = status
	if status == "auto" then
		self.Image_auto_btn:setVisible(true)
	elseif status == "free" then
		self.Image_free_btn:setVisible(true)
		self:showFreeAnim()
	elseif status == "norm" then
		self.Image_start_btn:setVisible(true)
	end
end

function SGTZ:initBetBtns()
	self.Image_start_btn = cc.uiloader:seekCsbNodeByName(self, "Image_start_btn"):setVisible(false)
	self.Image_free_btn = cc.uiloader:seekCsbNodeByName(self, "Image_free_btn"):setVisible(false)

	local FileNode_free_anim = cc.uiloader:seekCsbNodeByName(self.Image_free_btn, "FileNode_free_anim")
	local action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_anniu.csb")
	FileNode_free_anim:runAction(action)
	action:gotoFrameAndPlay(0,true)

	self.Text_free_num = cc.uiloader:seekCsbNodeByName(self.Image_free_btn, "Text_free_num")
	self.Image_auto_btn = cc.uiloader:seekCsbNodeByName(self, "Image_auto_btn"):setVisible(false)
	local FileNode_auto_anim = cc.uiloader:seekCsbNodeByName(self.Image_auto_btn, "FileNode_auto_anim")
	local action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_anniu.csb")
	FileNode_auto_anim:runAction(action)
	action:gotoFrameAndPlay(0,true)

	display.setImageClick(self.Image_auto_btn,function()
			self:changeBetBtnStatus("norm")
		end)

	display.setImageClick(self.Image_free_btn,function()
			if self.mFreeDrawLotteryNum > 0 and self:onStartBtnClick() then
				self:setFreeDrawLotteryNum(self.mFreeDrawLotteryNum-1,true)
			end
		end)
	local delayAciton = nil
	local function onTouchBegan(touch, event)
        local target = event:getCurrentTarget()

        local locationInNode = target:convertToNodeSpace(touch:getLocation())
        local s = target:getContentSize()
        local rect = cc.rect(0, 0, s.width, s.height)
        
        if self.Image_start_btn:isVisible() and cc.rectContainsPoint(rect, locationInNode) then
        	delayAciton = self.Image_start_btn:performWithDelay(function()
					self:changeBetBtnStatus("auto")
    				self:onStartBtnClick()
    				if delayAciton then
				    	self.Image_start_btn:stopAction(delayAciton)
				    	delayAciton = nil
				    end
        		end, 1)
        	self.Image_start_btn:setScale(1.05)
            return true
        end
        return false
    end

    local function onTouchMoved(touch, event)
       
    end

    local function onTouchEnded(touch, event)
        self.Image_start_btn:setScale(1)
        if delayAciton then
	    	self.Image_start_btn:stopAction(delayAciton)
	    	delayAciton = nil
	    end
    	self:onStartBtnClick()
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.Image_start_btn)
end

function SGTZ:playBetBtnPressDown(btn)
	local oldAction = btn:getActionByTag(100)
	if oldAction and not oldAction:isDone() then
		return
	end
	if oldAction then btn:removeAction(oldAction) end
	local offset = 20
	local dt = 0.1
	local action = cca.seq({
		cca.moveBy(dt, 0, -offset),
		cca.moveBy(dt, 0, offset),
	})
	action:setTag(100)
	btn:runAction(action)
end

function SGTZ:onStartBtnClick()
	-- 生成提前准备的地图
	if MAP_CREATE_OPEN then
		self:preMapCreate(true)
		self:preMapCreate(false)
	else
		if self.mGameStatus == GAME_STATUS.waiting_play then
			-- self:changeGameStatus(GAME_STATUS.simulate)
			local coinNum = checkint(center.user:getActorProp(ACTOR_PROP_GOLD))
		    if self.mFreeDrawLotteryNum == 0 and self.mSingleLineNum * self.mLineNum > coinNum then
				local function sureFunc()
	    			local view = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_SHOP)
			        if view then
			    	   view:selectTagBtnByTagID(MALL_TAG_GOLD)
			    	end
				end
				tipsFunc.newHintPopupYes(hintStrfunc.getText("IndianaGoldNotEnough"),sureFunc)
		    	return false
		    elseif self.m_pGameSink:RequestCP(9,self.mSingleLineNum,self.mFruitCardUseFlag) then
		    	if self.mFreeDrawLotteryNum == 0 then
		    		self:setUserShowGold(coinNum - self.mSingleLineNum * self.mLineNum)
		    	end
		    	self:playBetBtnPressDown(self.Image_start_btn)
		    	self:playBetBtnPressDown(self.Image_free_btn)
		    	self:playBetBtnPressDown(self.Image_auto_btn)
				self:changeGameStatus(GAME_STATUS.waiting_server_reward)
	    		self.mCurPlayScore = self.mSingleLineNum
				return true
			else
				tipsFunc.newHintTip("网络异常，稍后再试")
				return false
			end
		end
	end
	return false
end

function SGTZ:initMovePerson()
	self.move_person = cc.uiloader:seekCsbNodeByName(self, "move_person")
	self.move_person_action = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/anim/Node_sgdz_ren.csb")
	self.move_person:runAction(self.move_person_action)
	self.move_person_action:gotoFrameAndPlay(0,true)
	self:changeMovePersonStatus("wait")
end

function SGTZ:changeMovePersonStatus(status)
	local old_status = self.move_person_status

	if old_status == "walk" then
		-- self.move_person:stopAction(self.move_person_move_action)
	end

	self.move_person_status = status
	if status == "wait" then
		self.move_person:setPositionX(MOVE_PERSON_WAIT_POS_X)
		MOVE_PERSON_OFFSET_X = math.abs(MOVE_PERSON_OFFSET_X)
		self.move_person:setRotationSkewY(180)
	elseif status == "walk" then
		-- self.move_person_move_action = self.move_person:schedule(function()
		-- 		local x = self.move_person:getPositionX() + MOVE_PERSON_OFFSET_X
		-- 		self.move_person:setPositionX(x)

		-- 		if MOVE_PERSON_OFFSET_X > 0 and x > MOVE_PERSON_CHANGE_FACE_POS_X[2] then
		-- 			self.move_person:setRotationSkewY(0)
		-- 			MOVE_PERSON_OFFSET_X = -MOVE_PERSON_OFFSET_X
		-- 		elseif MOVE_PERSON_OFFSET_X < 0 and x < MOVE_PERSON_CHANGE_FACE_POS_X[1] then
		-- 			self.move_person:setRotationSkewY(180)
		-- 			MOVE_PERSON_OFFSET_X = -MOVE_PERSON_OFFSET_X
		-- 		end
		-- 	end, MOVE_PERSON_DT)
	end
end

function SGTZ:movePerson(dt)
	if self.move_person_status ~= "walk" then return end
	local x = self.move_person:getPositionX() + MOVE_PERSON_OFFSET_X * dt
	self.move_person:setPositionX(x)

	if MOVE_PERSON_OFFSET_X > 0 and x > MOVE_PERSON_CHANGE_FACE_POS_X[2] then
		-- self.move_person:setRotationSkewY(0)
		MOVE_PERSON_OFFSET_X = -MOVE_PERSON_OFFSET_X
	elseif MOVE_PERSON_OFFSET_X < 0 and x < MOVE_PERSON_CHANGE_FACE_POS_X[1] then
		self.move_person:setRotationSkewY(180)
		MOVE_PERSON_OFFSET_X = -MOVE_PERSON_OFFSET_X
	end
end

function SGTZ:addDropFruits(pos,fruitsReward)
	dump(fruitsReward,"addDropFruits")
	local uTouchPrizeID = checkint(fruitsReward.uTouchPrizeID)
	local uTouchPrizeNum = checkint(fruitsReward.uTouchPrizeNum)

	local path = GoodsData.getFruitsImagePathByID(uTouchPrizeID)
	if path then
		local sprite = display.newSprite(path)
		sprite:setPosition(pos)
		sprite:addTo(self.Node_zidan)
		self:attractAnim(sprite)
	end
end

function SGTZ:attractAnim(node)
	local speed = 0.05
	node:schedule(function()
			local x,y = node:getPosition()
			local mpos = self.Node_zidan:convertToNodeSpace(self.move_person:convertToWorldSpace(cc.p(0,0)))
			local mx,my = mpos.x,mpos.y
			speed = speed * 1.2
			local nx = (mx-x) * speed + x
			local ny = (my-y) * speed + y
			node:setPosition(nx, ny)
			if speed >= 0.8 or ( math.abs(nx-mx) < 30 and math.abs(ny-my) < 30 ) then
				node:removeSelf()
			end
		end, 1/20)
end

--//设置奖池
function  SGTZ:setShowJackpot(coinNum)
	local jianju=30
	coinNum=string.formatnumberthousands(tostring(coinNum))
	self.Text_jiangchi:setString(""..coinNum)
end

function SGTZ:exeGuide1()
	local view = SGTZGuide1.new()
	view:setPosition(display.cx, display.cy)
	view:addTo(self)
	view:setFinishCallback(handler(self, self.exeGuide2))
end

function SGTZ:exeGuide2()
	local view = SGTZGuide2.new()
	view:setPosition(display.cx, display.cy)
	view:addTo(self)
	if self.rule_btn then
		local size = self.rule_btn:getContentSize()
		view:setWorldPos(self.rule_btn:convertToWorldSpace(cc.p(size.width/2,size.height/2)))
	end
	view:setFinishCallback(handler(self, self.exeGuide3))
end

function SGTZ:exeGuide3()
	local view = SGTZGuide3.new()
	view:setPosition(display.cx, display.cy)
	view:addTo(self)
	if self.Node_paotai then
		local size = self.Node_paotai:getContentSize()
		view:setWorldPos(self.Node_paotai:convertToWorldSpace(cc.p(size.width/2,size.height/2)))
	end
	view:setFinishCallback(handler(self, self.exeGuide4))
end

function SGTZ:exeGuide4()	
	local view = SGTZGuide4.new()
	view:setPosition(display.cx, display.cy)
	view:addTo(self)

	if self.Image_start_btn then
		local size = self.Image_start_btn:getContentSize()
		view:setWorldPos(self.Image_start_btn:convertToWorldSpace(cc.p(size.width/2,size.height/2)))
	end
	view:setFinishCallback(function()
			cc.UserDefault:getInstance():setBoolForKey("SGTZ_Guide",true)
			self:onStartBtnClick()
		end)
end


function SGTZ:onEditSimulate(map,angle)
	if self.mGameStatus == GAME_STATUS.waiting_play then
    	local recordTab,columnTab = self:simulate(table.remove(self.mRandomseedMapTemp))
		-- 测试 随机因子
		self:setPaoRotation(-55)
    	local recordTab,columnTab = self:simulate(1233333)
    	-- end
    	dump(recordTab)
		self:resetMap()
		self:changeGameStatus(GAME_STATUS.waiting_server_reward)
		self:changeGameStatus(GAME_STATUS.game_start)
		-- self:performWithDelay(handler(self,self.onEditSimulate), 8)
	end
end

function SGTZ:preMapCreate(flag)
	self:changeGameStatus(GAME_STATUS.waiting_server_reward)
	local path = cc.FileUtils:getInstance():getWritablePath()
    self.mEnginePanelJiangchi:setDestroy(not flag)
    for i=1,3 do
    	self.mEngineJiangchi[i]:setDestroy(not flag)
    end
    SGTZEngine:setSavePath(path .. (flag and "jc/" or "nor/"))
    cc.FileUtils:getInstance():removeDirectory(path .. (flag and "jc/" or "nor/"))
    cc.FileUtils:getInstance():createDirectory(path .. (flag and "jc/" or "nor/"))

	local maxRotation,minRotation = MAX_ROTATION,MIN_ROTATION
    for angle=minRotation,maxRotation,1 do 
		self:setPaoRotation(angle)
		local size = self.Image_zidan:getContentSize()
		local pos = self.Node_engine:convertToNodeSpace(self.Image_zidan:convertToWorldSpace(cc.p(size.width/2,size.height/2)))
		self.mBallX,self.mBallY = pos.x,pos.y
		self:resetBall()

	    SGTZEngine:initMap(self.mMap)
		SGTZEngine:searchWorkPath()
	end
	self:changeGameStatus(GAME_STATUS.pre_waiting_play)
end

function SGTZ:checkMapRight(randomseed,hashMap,jcHashMap,fruitsLen,bigFruitsLen,isOpenBurstJackpot)
	local hashLen = 0
	local recordTab,columnTab = self:simulate(randomseed)
	local recordTabLen = #recordTab
	local countColumn = #columnTab
	print("countColumn",countColumn)
	for i,id in ipairs(recordTab) do
		-- 剔除固定柱子
		if type(id) == "string" then
			jcHashMap[id] = i
		else
			if hashMap[id] then
				hashMap[id] = hashMap[id] + 1
			else
				hashMap[id] = 1
				hashLen = hashLen + 1
			end
		end
	end
	-- 如果不存在预生成的地图 就需要检测合法性
	-- if not randomseed then
		local small_fruits_count = 0
		for i,v in ipairs(Def.Small_Fruits) do
			if hashMap[v] and hashMap[v] >= Def.Small_Fruits_collision_count then
				small_fruits_count = small_fruits_count + 1
			end
		end
		local big_fruits_count = 0
		for i,v in ipairs(Def.Big_Fruits) do
			if hashMap[v] and hashMap[v] >= Def.Big_Fruits_collision_count then
				big_fruits_count = big_fruits_count + 1
			end
		end
		if big_fruits_count ~= bigFruitsLen or small_fruits_count ~= fruitsLen then return false,recordTab,columnTab end
		local isJanchi = true
		for i=1,3 do
			isJanchi = isJanchi and jcHashMap["Jiangchi_" .. i] and jcHashMap["Jiangchi_" .. i] % 2 == 1 or false
	    end
		print("isJanchi",isJanchi)
		print("isOpenBurstJackpot",isOpenBurstJackpot)
	    if isJanchi ~= isOpenBurstJackpot then return false end
	-- end
	return true,recordTab,columnTab
end
-- angle 角度
-- ex 是否存在奖池柱子
-- jc 是否打开奖池
function SGTZ:getRandomseedMap(angle,ex,jc)
	local randomseedMap = {}
    local relativePath = "ccbResources/SGTZRes/config/S_R_" .. ex ..  "_" .. jc .. "_"  .. angle
	print("relativePath",relativePath)
    local path = cc.FileUtils:getInstance():fullPathForFilename(relativePath)
	print("path",path)
    local dataStr = cc.FileUtils:getInstance():getStringFromFile(path)
	print("dataStr",dataStr)
	randomseedMap = string.split(dataStr,'|')
	-- 最后一个是空字符 需要移除
	randomseedMap[#randomseedMap] = nil
	return randomseedMap
end
-- 打开宝箱任务
function SGTZ:Func_onClick_boxTask()
	musicfunc.playTouchBtnEffect()	
	manager.popup:newPopup(POPUP_ID.POPUP_TYPE_SGTZ_BOXTASK)
end

function SGTZ:updateBoxTaskConfig()
	local m_boxTaskConfig = center.task:getTaskTanZhuTaskConfig()
	print("updateBoxTaskConfig",m_boxTaskConfig and m_boxTaskConfig.btState and not self.mIsShiwan and not display.isAppstore)
	print(tonumber(m_boxTaskConfig.btState)==1)
	if m_boxTaskConfig and m_boxTaskConfig.btState and not self.mIsShiwan and not display.isAppstore then
		self.m_btn_boxTask:setVisible(tonumber(m_boxTaskConfig.btState)==1)
	else
		self.m_btn_boxTask:setVisible(false)
	end
end

function SGTZ:updateBoxTaskRedPot()
	local m_boxTaskConfig = center.task:getTaskTanZhuTaskConfig()
	local redPot = cc.uiloader:seekCsbNodeByName(self.m_btn_boxTask, "sp_red_point")
	redPot:setVisible(false)
	if m_boxTaskConfig and m_boxTaskConfig.btState then
		local m_boxTaskData = center.task:getTaskTanZhuTaskData()
		local rewardNum = 0
		local SGJBIT_MASK = { 0x01, 0x02, 0x04 };
		if m_boxTaskData.finishCount then
			for i,v in ipairs(m_boxTaskConfig.sGuoshancheBox) do
				if tonumber(v.sValue) <= tonumber(m_boxTaskData.finishCount) and bit.band(tonumber(m_boxTaskData.rewardFlag),SGJBIT_MASK[i]) == 0 then
					rewardNum = rewardNum + 1
				end
			end
		end
		
		if  m_boxTaskConfig.sGuoshancheTaskList and table.getn(m_boxTaskConfig.sGuoshancheTaskList) > 0 then
			for i,v in ipairs(m_boxTaskConfig.sGuoshancheTaskList) do
				local taskInfo = center.task:getTaskViewByListID(v.lTaskListID)
				if taskInfo then
					local taskItem = center.task:getTaskItem(taskInfo.sTaskListID)
					if taskItem and tonumber(taskItem.uNowFinish) >= tonumber(taskInfo.uFinishTimes) and tonumber(taskItem.uReceiveFinish) < tonumber(taskInfo.uFinishTimes) then
						rewardNum = rewardNum + 1
					end
				end
			end
		end

		redPot:setVisible(rewardNum>0)
	else
		self.m_btn_boxTask:setVisible(false)
	end
end

function SGTZ:searchWorkPath(angle,big_fruits,small_fruits,jc,isHasBurstJackpot)
	print("searchWorkPath","angle,big_fruits,small_fruits,jc,isHasBurstJackpot",angle,big_fruits,small_fruits,jc,isHasBurstJackpot)
	local relativePath = "ccbResources/SGTZRes/config/" .. (jc and "jc/" or "nor/")
	local searchAngle = {0,1,-1,2,-2,3,-3,4,-4,5,-5}
	local fileName = nil
	local sAngle = angle
	local ret = {}
	for i,v in ipairs(searchAngle) do
		sAngle = angle+v
		if MAX_ROTATION >= sAngle and sAngle >= MIN_ROTATION then
			fileName = relativePath .. SGTZEngine:getFileRelativePath(sAngle,big_fruits,small_fruits,isHasBurstJackpot and 1 or 0)
			if cc.FileUtils:getInstance():isFileExist(fileName) then
				local path = cc.FileUtils:getInstance():fullPathForFilename(fileName)
				print("path",path)
			    local dataStr = cc.FileUtils:getInstance():getStringFromFile(path)
				print("dataStr",dataStr)
				ret = string.split(dataStr,';')
				-- 最后一个是空字符 需要移除
				ret[#ret] = nil
				return sAngle,ret,fileName
			end
		end
	end
end

function SGTZ:updateDebugInfo(fileName,randomseed,prizeRatio,getfreeDrawLotteryNum,burstJackpot,extraPrizeNum)
	local str = string.sub(fileName,29,-1) .. 
	"\nrandomseed:" .. randomseed .. 
	"\nRatio:" .. prizeRatio ..
	"\nfreeDraw:" .. getfreeDrawLotteryNum .. 
	"\nJackpot:" .. burstJackpot .. 
	"\nextra:" .. extraPrizeNum
	self.Text_debug:setString(str)
end

return SGTZ
