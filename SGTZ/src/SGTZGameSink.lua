local SGTZGameSink = class("SGTZGameSink")
local Def = require("game.SGTZ.Base.Def")

function SGTZGameSink:ctor()
    print("---SGTZGameSink.ctor---")    
end


function SGTZGameSink:SetGameScene(pScene)
	self.m_pGameScene = pScene
end

function SGTZGameSink:SetGameFruitScene(pScene)	
	self.m_pGameFruitScene = pScene
end

--//初始化
function SGTZGameSink:Init(pTabkeSink)	
	print("--SGTZGameSink:Init --")
	self.m_pTableSink = pTabkeSink
	self:initData()
	self.m_pGameFruitScene:setMyData()
end

function SGTZGameSink:initData()	
	self.OnRecFunc_TB =
	{
		0,
		0,
		handler(self,self.OnRecv_OutCard), --2,	--水果机返回
		handler(self,self.OnRecv_SetBanker), --3,			--中奖
		handler(self,self.OnRecv_RoomInfo), -- 4,		--房间信息
		handler(self,self.OnRecv_GameEnd), -- 5,			--结算
		0,
		handler(self,self.OnRecv_PoolInfo),--7,		--奖池信息
		handler(self,self.onRecv_backPlazaTips), -- 8 --退出提示返回，大厅消息
		handler(self,self.onRecv_Tanzhu), -- 9 --水果机弹珠返回
	}

	-- 注册 OnRecv_OutCard 方法结构体 水果机返回 2	
	local OutCardData="uchar,1,outCardChairId,sint64,15,GetFruitData,"	
	self.m_pTableSink:gameRegisterEx(Def.DRAWLOTTERYSPONSE, OutCardData)


	-- 注册 OnRecv_SetBanker 方法结构体 中奖 3,	
	local SetBankerData="uchar,1,dzCharId,sint64,1,ActorDBID,slong,1,AllJackpotNum,"			
	self.m_pTableSink:gameRegisterEx(Def.JUDGEDZ, SetBankerData)


	-- 注册 OnRecv_RoomInfo 方法结构体 房间信息 4,

	-- score -- 底分
	-- JackpotNum 奖池
	-- freeDrawLotteryNum 免费卡个数
	-- fruitFreeCardLineNum 免费卡线数
	-- fruitFreeCardSingleLineGold 免费卡单线金币数
	-- nRoomType 房间类型
	-- btPlatformFlag 试玩标记
	-- btMaxLineNum 最大连线数
	local RoomInfoData="slong,1,score,uint64,1,JackpotNum,uint64,1,freeDrawLotteryNum,sint,1,fruitFreeCardLineNum,sint,1,fruitFreeCardSingleLineGold,sint,1,nRoomType,uchar,1,btPlatformFlag,uchar,1,btMaxLineNum,"		
	--sint,1,fruitFreeCardLineNum,sint,1,fruitFreeCardSingleLineGold,		
	self.m_pTableSink:gameRegisterEx(Def.SENDROOMINFO, RoomInfoData)


	-- 注册 OnRecv_GameEnd 方法结构体 结算 5,
	-- freeNumFinsh 免费摇奖次数结束
	-- freeDrawLotteryNum 免费摇奖次数
	-- getfreeDrawLotteryNum 本次活动的免费摇奖次数
	-- BurstJackpot 爆奖池结果
	-- drawlotteryGoldNum 本次摇奖获得的金币
	-- multGoldNum 赢取金币倍数
	-- freeDrawGetGoldNum 免费摇奖获得的金币
	-- ActorDBID 角色ID
	-- fruitFreeCardLeftNum 当前水果免费卡个数
	-- fruitFreeCardUseNum 本局消耗的水果免费卡个数
	local GameEndData="sint64,1,freeNumFinsh,sint64,1,freeDrawLotteryNum,sint64,1,getfreeDrawLotteryNum,sint64,1,BurstJackpot,sint64,1,drawlotteryGoldNum,sfloat,1,multGoldNum,sint64,1,freeDrawGetGoldNum,sint64,1,ActorDBID,sint64,1,fruitFreeCardLeftNum,uchar,1,fruitFreeCardUseNum,"				
	self.m_pTableSink:gameRegisterEx(Def.GAMERESULT, GameEndData)

	local PersonItem = "sint64,1,nActorDBID,sint64,1,nGold,sint64,1,nActorVipLevel,stchar,32,szPoolPlayerName,stchar,33,szPoolPlayerFace,sint,1,nTimes,"
    self.m_pTableSink:RegisterStruct("PersonItem", PersonItem)
	
	-- 注册 OnRecv_PoolInfo 方法结构体 奖池信息 7
	local PoolInfoData="uint64,1,AllGold,struct,15,PersonItem,sint,6,Bonus,sint,6,poolProportion1,sint,6,poolProportion2,sint,6,poolProportion3,uint64,1,nDayWinAllGold,"				
	self.m_pTableSink:gameRegisterEx(Def.GOLDPOOLINFORESPONSE, PoolInfoData)

	--注册 退出提示，返回大厅消息
	local returnPlazaTips = "uchar,1,btType,"
	self.m_pTableSink:gameRegisterEx(Def.EXITROOM_TIPS,returnPlazaTips)

	--注册 水果机弹珠返回
	local DRAWLOTTERYSPONSE_TANZHU = "uchar,1,outCardChairId,slong,1,nExtraPrizePropID,slong,1,nExtraPrizeNum,slong,1,nPoolPrizeScale,slong,1,nPrizeRatio,"
	self.m_pTableSink:gameRegisterEx(Def.DRAWLOTTERYSPONSE_TANZHU,DRAWLOTTERYSPONSE_TANZHU)


	local ReconnectData = ""
	self.m_pTableSink:setDropEndData(ReconnectData)
	self.m_pTableSink:setHalfWayJoinData(ReconnectData)
	self.m_pTableSink:setReplace(ReconnectData)
end

--//@:pActor 进入的用户	
function SGTZGameSink:OnUserEnter( pActor, nChairID)
	if self:isMe(pActor) then	--(pActor:IsMe())
		self.m_pGameScene:ClearAni()
	end
	return true
end

function SGTZGameSink:isMe(pActor)
	return self.m_pTableSink:isMe(pActor)
end

--//用户退出
function SGTZGameSink:OnUserOut(pActor, nChairID)
	return true
end

--//用户掉线
function SGTZGameSink:OnUserDrop(pActor, nChairID)
	return true
end

--//用户掉线重入
function SGTZGameSink:OnUserDropEnd(pActor, nChairID)
	return true
end

--//用户举手
function SGTZGameSink:OnUserRaiseHands(pActor, nChairID)
	return true
end

--//游戏开始
function SGTZGameSink:OnGameStart()
	return true
end

--//游戏结束
function SGTZGameSink:OnGameEnd()
	return true
end

--//游戏数据交互
function SGTZGameSink:OnGameMessage(btCmd,dict)
    if self.OnRecFunc_TB[btCmd+1]~=0 then
        self.OnRecFunc_TB[btCmd+1](dict)
    end
end

--//时钟回调
function SGTZGameSink:OnTimer( uTimerID)
	
end

--//游戏规则
function SGTZGameSink:OnGameRule( dict )
	return true
end

--//掉线重入
function SGTZGameSink:OnDropEnd( dict )
	return true
end

--//重登踢号
function SGTZGameSink:OnReplace(dict)
	--踢回大厅	
	self:OutRoom()
	return true
end

--//好友请求
function SGTZGameSink:AddFindRequest(sendId, receiveId)
	self.m_pGameScene:AddFindRequestEx(sendId, receiveId)
	return true
end

--//中途入桌
function SGTZGameSink:OnHalfWayJoin( dict )
	return true
end

--//GM中途进入
function SGTZGameSink:OnGMJoin( dict )
	return true
end

--//2 水果机结果返回
function SGTZGameSink:OnRecv_OutCard(dict )
	print("SGTZGameSink:OnRecv_OutCard")
	dump(dict)
	local outCardDB = {}
	outCardDB.outCardChairId = dict.outCardChairId

	outCardDB.GetFruitData = {}
	for i = 1, 3 do
       	outCardDB.GetFruitData[i] = {}
        for j=1,5 do
            outCardDB.GetFruitData[i][j] = dict.GetFruitData[5*(i - 1) + j ]
        end     
    end
   
   self.m_pGameFruitScene:getServerFriutData(outCardDB.GetFruitData, outCardDB.outCardChairId)
end


--3 中奖
function SGTZGameSink:OnRecv_SetBanker(dict )
	print("SGTZGameSink:OnRecv_SetBanker")
	dump(dict)
	self.m_pGameScene:SetLandLord(dict.dzCharId, dict.ActorDBID, dict.AllJackpotNum)	
end

---- 4 房间信息
function SGTZGameSink:OnRecv_RoomInfo(dict )
	print("SGTZGameSink:OnRecv_RoomInfo")
	dump(dict)
	self.m_pGameFruitScene:OnReceiveRoomInfo(dict)
end

--//5 游戏结算
function SGTZGameSink:OnRecv_GameEnd(dict )
	print("SGTZGameSink:OnRecv_GameEnd")
	dump(dict)
	self.m_pGameFruitScene:setOnGameEnd(dict)
end

--6 奖池信息
function SGTZGameSink:OnRecv_PoolInfo(dict )
	print("SGTZGameSink:OnRecv_PoolInfo")
	dump(dict,"OnRecv_PoolInfo")
	self.m_pGameFruitScene:setGoldPoolInfo(dict)
end

--8 退出提示，返回大厅消息
function SGTZGameSink:onRecv_backPlazaTips(dict)
	print("SGTZGameSink:onRecv_backPlazaTips")
	self.m_pGameFruitScene:backPlazaTips()
end

--//水果机摇奖 1 水果机开始	
function SGTZGameSink:RequestCP(lineNum,singleLineNum,fruitCardUseFlag)
	print("SGTZGameSink:RequestCP")
	if not fruitCardUseFlag then
		fruitCardUseFlag=0
	end
	local sendStr = "uchar,1,"..Def.DRAWLOTTERY..",slong,1,"..lineNum..",slong,1,"..singleLineNum..",uchar,1,"..fruitCardUseFlag..","
	dump(sendStr)
	return self.m_pTableSink:SendGameMessage(sendStr)	
end

function SGTZGameSink:GetMe()
	return self.m_pTableSink:GetMe()
end

--//请求奖池信息 6
function SGTZGameSink:RequestPoolInfo()
	print("SGTZGameSink:RequestPoolInfo")
	local sendStr = "uchar,1,"..Def.GOLDPOOLINFOREQUEST..","
	dump(sendStr)
	self.m_pTableSink:SendGameMessage(sendStr)	
end

--//退出房间
function SGTZGameSink:OutRoom()
	print("SGTZGameSink:OutRoom")	
	self.m_pTableSink:cleanGameRegister()
	self.m_pTableSink:OutRoom()
end

function SGTZGameSink:getActorByDBIDEx(ActorDBID)
	return self.m_pTableSink:getActorByDBIDEx(ActorDBID)
end

function SGTZGameSink:RemoveRes()	

	self.m_pGameFruitScene:CleanGameRes()
end
-- 水果机弹珠 -- 弃用
-- function SGTZGameSink:RequestTanzhu(touchIDTab,lineNum,singleLineNum,fruitCardUseFlag)
-- 	print("SGTZGameSink:RequestTanzhu")
-- 	if not fruitCardUseFlag then
-- 		fruitCardUseFlag=0
-- 	end
-- 	local len = #touchIDTab
-- 	local sendStr = "uchar,1,"..Def.DRAWLOTTERY_TANZHU..",slong,1,"..lineNum..",slong,1,"..singleLineNum..",uchar,1,"..fruitCardUseFlag..",uchar,1,"..len..",uchar,100,"
-- 	for i=1,100 do
-- 		if touchIDTab[i] then
-- 			sendStr = sendStr .. checkint(touchIDTab[i]) .. ","
-- 		else
-- 			sendStr = sendStr .. "0,"
-- 		end
-- 	end
-- 	dump(sendStr)
-- 	return self.m_pTableSink:SendGameMessage(sendStr)	
-- end

function SGTZGameSink:onRecv_Tanzhu(dict )
	print("SGTZGameSink:onRecv_Tanzhu")
	dump(dict)
	local nExtraPrizePropID = checkint(dict.nExtraPrizePropID)
	local nExtraPrizeNum = checkint(dict.nExtraPrizeNum)
	local nPoolPrizeScale = checkint(dict.nPoolPrizeScale) / 10 -- 服务器发的是千分比
	local nPrizeRatio = checkint(dict.nPrizeRatio) -- 水果倍率
   	self.m_pGameFruitScene:onServerReward(nExtraPrizePropID, nExtraPrizeNum,nPoolPrizeScale,nPrizeRatio)
end

return SGTZGameSink

