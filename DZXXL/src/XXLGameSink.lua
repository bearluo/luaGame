local Queue = import("game.DZXXL.Base.Queue")
local XXLGameSink = class("XXLGameSink")
require("game.DZXXL.XXL_Def")

function XXLGameSink:ctor()
    print("---XXLGameSink.ctor---")    
end


function XXLGameSink:SetGameScene(pScene)
	self.m_pGameScene = pScene
end

function XXLGameSink:SetGameXXLScene(pScene)	
	self.m_pGameXXLScene = pScene
end

--//初始化
function XXLGameSink:Init(pTabkeSink)	
	print("--XXLGameSink:Init --")
	self.m_queue = Queue:new() 
	self.m_pTableSink = pTabkeSink
	self:initData()
end

function XXLGameSink:initData()	

	self.OnRecFunc_TB =
	{
		0,										--1, 请求开始游戏
		handler(self, self.OnRecv_RoomInfo), 	--2, 房间信息
		handler(self, self.OnRecv_GameBegin), 	--3, 游戏开始
		handler(self, self.OnRecv_AniResult), 	--4, 动画结果
		handler(self, self.OnRecv_GameEnd), 	--5, 游戏结束
		0, 										--6, 请求奖池信息
		handler(self, self.OnRecv_PoolInfo),	--7, 奖池信息
	}

	-- 注册 OnRecv_RoomInfo 方法结构体 房间信息 2
	local RoomInfo = "sint64,1,nAllGold,uchar,1,btPlatFormFlag,uchar,1,btSingleBettingCount,sint,15,nSingleBetting,uchar,1,btReviewSwitch,ushort,30,nRate,"	
	self.m_pTableSink:gameRegisterEx(XXL_MSG.ROOM_INFO, RoomInfo)

	local GameBegin = "uchar,1,btAnimationFlag,uchar,49,InitItem,"	
	self.m_pTableSink:gameRegisterEx(XXL_MSG.BEGIN, GameBegin)

	-- 注册 OnRecv_AniResult 方法结构体 动画结果 4
	local SpointItem = "uchar,1,x,uchar,1,y,uchar,1,btElementType,"
    self.m_pTableSink:RegisterStruct("SpointItem", SpointItem)

    local SRemovePointItem = "uchar,1,btLocalNum,uchar,1,btElementType,"
    self.m_pTableSink:RegisterStruct("SRemovePointItem", SRemovePointItem)

	local AniResult = "uchar,1,btSupplyCount,struct,49,SpointItem,uchar,1,btRemoveLocalCount,struct,49,SRemovePointItem,sint,17,nLocalPrice,"	
	self.m_pTableSink:gameRegisterEx(XXL_MSG.ANIMATION_RESULT, AniResult)

    -- 注册 OnRecv_GameEnd 方法结构体 游戏结束 4
	local EndResult = "ushort,1,nXiaoChuCount,sint64,1,nGameWinGoldNum,sint64,1,nHavePoolGoldNum,"	
	self.m_pTableSink:gameRegisterEx(XXL_MSG.END_RESULT, EndResult)    

 	local PersonItem = "sint64,1,nActorDBID,sint64,1,nGold,sint64,1,nActorVipLevel,sint,1,nTimes,stchar,32,szPoolPlayerName,stchar,33,szPoolPlayerFace,ushort,1,nTableID,uchar,1,btPrizePoolFlag,"
    self.m_pTableSink:RegisterStruct("PersonItem", PersonItem)

	-- 注册 OnRecv_PoolInfo 方法结构体 奖池信息 6
	local PoolInfo = "sint64,1,nAllGold,struct,15,PersonItem,sint,15,nTotalBetting,ushort,15,btPoolRate3,ushort,15,btPoolRate4,ushort,15,btPoolRate5,ushort,15,btPoolRate6,ushort,15,btPoolRate7,ushort,15,btPoolRate8,uint64,1,nDayWinAllGold,"	
	self.m_pTableSink:gameRegisterEx(XXL_MSG.GOLDPOOL_INFO_RET, PoolInfo)
end

--//@:pActor 进入的用户	
function XXLGameSink:OnUserEnter( pActor, nChairID)
	if self:isMe(pActor) then	--(pActor:IsMe())
		self.m_pGameScene:ClearAni()
	end
	return true
end

function XXLGameSink:isMe(pActor)
	return self.m_pTableSink:isMe(pActor)
end

--//用户退出
function XXLGameSink:OnUserOut(pActor, nChairID)
	return true
end

--//用户掉线
function XXLGameSink:OnUserDrop(pActor, nChairID)
	return true
end

--//用户掉线重入
function XXLGameSink:OnUserDropEnd(pActor, nChairID)
	return true
end

--//用户举手
function XXLGameSink:OnUserRaiseHands(pActor, nChairID)
	return true
end

--//游戏开始
function XXLGameSink:OnGameStart()
	return true
end

--//游戏结束
function XXLGameSink:OnGameEnd()
	return true
end

--//游戏数据交互
function XXLGameSink:OnGameMessage(btCmd, dict)

	if btCmd == XXL_MSG.GOLDPOOL_INFO_RET then
		self.OnRecFunc_TB[btCmd](dict)
		return true
	end

    --接口传入
    if not self.m_pGameXXLScene:getOnMessageFun() then
        self.m_pGameXXLScene:setOnMessageFun(handler(self, self.OnGameMsg))
    end

    --判断接口
    if self.OnRecFunc_TB[btCmd] ~= nil then
        local msgData = {}
        msgData.btCmd = btCmd
        msgData.dict = dict
        self.m_queue:push(msgData)
    else
    	print(" ============== cmd not define ")
    end

    --处理消息
    self:OnGameMsg()
	return true
end

--处理协议
function XXLGameSink:OnGameMsg(bNextMsg)

    --?若处理中异常 nil截断 判断时间 大于N秒则强制下一条消息

    --强制处理
    if bNextMsg then
        XXL_MSG.GameLandGlobalVar.bOnMsg = false
    end

    --是否处理中
    if XXL_MSG.GameLandGlobalVar.bOnMsg then
        print("\n\n\n\n处理消息中\n\n\n\n")
        return false
    end

    --消息判断
    if self.m_queue:empty() then
        print("\n\n\n\n队列暂无消息\n\n\n\n")
        return false
    end

    --设置标示
    XXL_MSG.GameLandGlobalVar.bOnMsg = true

    --消息处理
    local msg = self.m_queue:pop()
    -- dump({msg[1]}, "\n\n\n\n\n\n消息处理", 5)
    self.OnRecFunc_TB[msg[1].btCmd](msg[1].dict)

    --继续处理
    if msg[1].btCmd == XXL_MSG.ROOM_INFO
    or msg[1].btCmd == XXL_MSG.GOLDPOOL_INFO_RET then
        self:OnGameMsg(true)
    end
end

--//时钟回调
function XXLGameSink:OnTimer( uTimerID)
	
end

--//游戏规则
function XXLGameSink:OnGameRule( dict )
	return true
end

--//掉线重入
function XXLGameSink:OnDropEnd( dict )
	return true
end

--//重登踢号
function XXLGameSink:OnReplace(dict)
	--踢回大厅	
	self:OutRoom()
	return true
end

--//好友请求
function XXLGameSink:AddFindRequest(sendId, receiveId)
	self.m_pGameScene:AddFindRequestEx(sendId, receiveId)
	return true
end

--//中途入桌
function XXLGameSink:OnHalfWayJoin( dict )
	return true
end

--//GM中途进入
function XXLGameSink:OnGMJoin( dict )
	return true
end

---- 2 房间信息
function XXLGameSink:OnRecv_RoomInfo(dict )
	dump(dict, " ====OnRecv_RoomInfo==== ")
	self.m_pGameXXLScene:onRecvRoomInfo(dict)
end

---- 3 游戏开始
function XXLGameSink:OnRecv_GameBegin(dict )
	dump(dict, " ====OnRecv_GameBegin==== ")
	self.m_pGameXXLScene:onRecvGameBegin(dict)
end

---- 4 动画结果
function XXLGameSink:OnRecv_AniResult(dict)
	dump(dict, " ====OnRecv_AniResult==== ")
	self.m_pGameXXLScene:onRecvAniResult(dict)
end

---- 5 游戏结算
function XXLGameSink:OnRecv_GameEnd(dict )
	dump(dict, " ====OnRecv_GameEnd==== ")
	self.m_pGameXXLScene:onRecvGameEnd(dict)
end

--6 奖池信息
function XXLGameSink:OnRecv_PoolInfo(dict)
	dump(dict, " ====OnRecv_PoolInfo==== ")
	self.m_pGameXXLScene:onRecvPoolInfo(dict)
end

function XXLGameSink:GetMe()
	return self.m_pTableSink:GetMe()
end

--//请求摇奖 1
function XXLGameSink:RequestStart(isDropAni, betMoneys)
	local betsString = ""
	for k,v in pairs(betMoneys) do
		betsString = betsString .. "slong,1," .. v .. ","
	end

	local isDropAniFlag = 1
	if not isDropAni then
		isDropAniFlag = 0
	end

	local sendStr = "uchar,1," .. XXL_MSG.BEGINGAME .. ",uchar,1," .. isDropAniFlag .. "," .. betsString
	dump(sendStr)
	self.m_pTableSink:SendGameMessage(sendStr)	
end

--//请求奖池信息 6
function XXLGameSink:RequestPoolInfo()
	print("XXLGameSink:RequestPoolInfo")
	local sendStr = "uchar,1,"..XXL_MSG.GOLDPOOL_INFO..","
	dump(sendStr)
	self.m_pTableSink:SendGameMessage(sendStr)	
end

--//退出房间
function XXLGameSink:OutRoom()
	print("XXLGameSink:OutRoom")	
	self.m_pTableSink:cleanGameRegister()
	self.m_pTableSink:OutRoom()
end

function XXLGameSink:getActorByDBIDEx(ActorDBID)
	return self.m_pTableSink:getActorByDBIDEx(ActorDBID)
end

function XXLGameSink:RemoveRes()	

	self.m_pGameXXLScene:CleanGameRes()
end


return XXLGameSink

