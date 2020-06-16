local Def = 
{
	DRAWLOTTERY = 1,		--水果机开始	
	DRAWLOTTERYSPONSE = 2,	--水果机返回
	JUDGEDZ = 3,			--中奖
	SENDROOMINFO = 4,		--房间信息
	GAMERESULT = 5,			--结算
	GOLDPOOLINFOREQUEST = 6,		--奖池信息
	GOLDPOOLINFORESPONSE = 7,		--奖池信息	
	EXITROOM_TIPS = 8,      --淘金币房间(超过一定金额退出提示)
	DRAWLOTTERYSPONSE_TANZHU = 9, --水果机弹珠返回
}

Def.IS_SHOW_REDPACKET = false --是否第一次弹出累赢红包界面
Def.DEFAULT_DT = 0.01 -- 要能被 DEFAULT_RUNNING_TIME 整除
Def.DEFAULT_RUNNING_TIME = 10
--iphonex移动的距离
Def.IPHONE_X_LEN = 66
Def.Big_Fruits_Radius = 81
Def.Small_Fruits_Radius = 70
Def.Column_Radius = 40

Def.COUNT = 16
Def.Fruits = {
	2,5,11,13,14,
}
Def.Small_Fruits = {
	2,5,11,14,
}
Def.Big_Fruits = {
	13,
}

Def.Small_Fruits_collision_count = 6
Def.Big_Fruits_collision_count = 12

Def.MUSIC = 
{
	AUDIO_HIT_LOTTERY_POOL = "ccbResources/SGTZRes/audio/hit_lottery_pool.mp3" ,--命中彩池
	AUDIO_FREE_GAME = "ccbResources/SGTZRes/audio/free_game.mp3" ,--免费游戏
	AUDIO_FRUITS_COLLISION = "ccbResources/SGTZRes/audio/fruits_collision.mp3" ,--撞击水果
	AUDIO_GOLD_COLLISION = "ccbResources/SGTZRes/audio/gold_collision.mp3" ,--金币撞击
	AUDIO_LAUNCH = "ccbResources/SGTZRes/audio/launch.mp3" ,--弹珠发射
	AUDIO_SETTLEMENT = "ccbResources/SGTZRes/audio/settlement.mp3" ,--游戏结算
	AUDIO_SETTLEMENT_NOT_WIN = "ccbResources/SGTZRes/audio/critcal.mp3" ,--游戏结算 没赢钱
	AUDIO_SETTLEMENT_CHEERS = "ccbResources/SGTZRes/audio/midWin.mp3" ,--胜利的欢呼声
	AUDIO_FRUITS_GEAR = "ccbResources/SGTZRes/audio/fruits_gear.mp3" ,--水果齿轮亮
}

function Def.eventtouzhuStatistics()

	adsHelp.eventStatistics("FruitMachine_touzhu")
	
end

function Def.eventyaoganStatistics()
	adsHelp.eventStatistics("FruitMachine_yaogan")
end

function Def.eventJiangchiStatistics()
	adsHelp.eventStatistics("FruitMachine_Jiangchi")
end

function Def.eventguizeStatistics()
	adsHelp.eventStatistics("FruitMachine_guize")
end

function Def.isBigFruits(id)
	for i,v in ipairs(Def.Big_Fruits) do
		if v == id then return true end
	end
	return false
end

function Def.isSmallFruits(id)
	for i,v in ipairs(Def.Small_Fruits) do
		if v == id then return true end
	end
	return false
end

function Def.isFruits(id)
	for i,v in ipairs(Def.Fruits) do
		if v == id then return true end
	end
	return false
end

function Def.getRadius(id)
	if Def.isBigFruits(id) then
		return Def.Big_Fruits_Radius
	elseif Def.isSmallFruits(id) then
		return Def.Small_Fruits_Radius
	else
		return Def.Column_Radius
	end
end

function Def.getFruitsCollisionCount(id)
	return Def.isBigFruits(id) and Def.Big_Fruits_collision_count or Def.Small_Fruits_collision_count
end

function Def.clean()	
	Def = nil
end

return Def