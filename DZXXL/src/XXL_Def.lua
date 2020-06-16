XXL_MSG = 
{
	BEGINGAME = 1,					--请求开始游戏	
	ROOM_INFO = 2,					--房间信息
	BEGIN = 3,						--游戏开始
	ANIMATION_RESULT = 4,			--动画结果
	END_RESULT = 5,					--游戏结束
	GOLDPOOL_INFO = 6,				--请求奖池信息
	GOLDPOOL_INFO_RET = 7,			--奖池信息	
}

XXL_MSG.ELEMENT = {
	DUCK = 0,
	CAT = 1,
	RABBIT = 2,
	FOX = 3,
	PIG = 4,
	PEOPLE = 5,
}

--iphonex移动的距离
XXL_MSG.IPHONE_X_LEN = 66

XXL_MSG.MUSIC = 
{
	
}

XXL_MSG.GameLandGlobalVar = {
    bOnMsg = false
}

XXL_MSG.IS_SHOW_REDPACKET = false --是否第一次弹出累赢红包界面

XXL_MSG.MUSIC_NAMES = {
	"ccbResources/DZXXLRes/audio/addbutton.mp3",
	"ccbResources/DZXXLRes/audio/Combo1.mp3",
	"ccbResources/DZXXLRes/audio/Combo2.mp3",
	"ccbResources/DZXXLRes/audio/Combo3.mp3",
	"ccbResources/DZXXLRes/audio/Combo4.mp3",
	"ccbResources/DZXXLRes/audio/Combo5.mp3",
	"ccbResources/DZXXLRes/audio/Combo6.mp3",
	"ccbResources/DZXXLRes/audio/critcal.mp3",
	"ccbResources/DZXXLRes/audio/startbutton.mp3",
	"ccbResources/DZXXLRes/audio/type0.mp3",
	"ccbResources/DZXXLRes/audio/type1.mp3",
	"ccbResources/DZXXLRes/audio/type2.mp3",
	"ccbResources/DZXXLRes/audio/type3.mp3",
	"ccbResources/DZXXLRes/audio/xiaoxiaobgm.mp3",
	"ccbResources/DZXXLRes/audio/xxl_gxhd.mp3",
	"ccbResources/DZXXLRes/audio/xxl_bigwinner.mp3",
	"ccbResources/DZXXLRes/audio/xxl_superwinner.mp3",
	"ccbResources/DZXXLRes/audio/xxl_openpool.mp3",
}

function XXL_MSG.clean()	
	XXL_MSG = nil
end