--
-- Author: Your Name
-- Date: 2017-09-06 15:42:38
-- 游戏入口函数，这里创建游戏
-- 对应c++ 的 SGJGameScene::create();(继承于layer)
module(..., package.seeall)

-- 这里要放回对应的游戏对象 
function CreateGameFun()

	-- 这里要先卸载lua底层加载过的游戏代码(为了防止热更问题，所有游戏必须都要的操作)
	package.loaded["game.DZXXL.Base.Queue"] = nil
	package.loaded["game.DZXXL.XXL_Def"] = nil
	package.loaded["game.DZXXL.XXLAni"] = nil
	package.loaded["game.DZXXL.XXLGameScene"] = nil
	package.loaded["game.DZXXL.XXLGameSink"] = nil
	package.loaded["game.DZXXL.XXLHelp"] = nil
	package.loaded["game.DZXXL.XXLLayer"] = nil
	package.loaded["game.DZXXL.XXLPoolInfo"] = nil
	package.loaded["game.DZXXL.XXLRank"] = nil
	package.loaded["game.DZXXL.XXLTaskInfo"] = nil
	package.loaded["game.DZXXL.XXLTaskPass"] = nil
	package.loaded["game.DZXXL.debugDatas"] = nil
	
	-- 例如 return XXXGame.new()
	printInfo("------------------消消乐CreateGameFun--------------------")
	return  require("game.DZXXL.XXLGameScene").new()
end

function version()
	-- 此处放游戏版本号
	return 1
end



