--
-- Author: Your Name
-- Date: 2017-09-06 15:42:38
-- 游戏入口函数，这里创建游戏
-- 对应c++ 的 SGJGameScene::create();(继承于layer)
module(..., package.seeall)

-- 这里要放回对应的游戏对象 
function CreateGameFun()

	-- 这里要先卸载lua底层加载过的游戏代码(为了防止热更问题，所有游戏必须都要的操作)
	local removeTab = {}
	for i,v in pairs(package.loaded) do
		if type(i) == "string" and string.find(i,"game.SGTZ",1) == 1 then
			table.insert(removeTab,i)
		end
	end
	for i,v in ipairs(removeTab) do
		package.loaded[v] = nil
	end

	preLoadImage()
	-- 例如 return XXXGame.new()
	printInfo("------------------水果机CreateGameFun--------------------")
	return  require("game.SGTZ.SGTZGameScene").new()
end

local ResPng = {
	{"ccbResources/SGTZRes/image/anim/tx_HBC_jinji_lizi.png",cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444},
	{"ccbResources/SGTZRes/image/anim/tx_ddz_xxl_xiaochu01.png",cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444},
	{"ccbResources/SGTZRes/image/anim/tx_sgdz_jinbi2.png",cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444},
	{"ccbResources/SGTZRes/image/anim/tx_sgdz_jinbi1.png",cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444},
	{"ccbResources/SGTZRes/image/anim/SG_js_db3.png",cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444},
	{"ccbResources/SGTZRes/image/bg/gameBg.png",cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444},
	{"ccbResources/SGTZRes/image/anim/tx_pdk_kuosanglizi.png",cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444},
}
function preLoadImage()
	local function callback() end
	for k,v in pairs(ResPng) do
        -- print(v)
        if v[2] then
	        cc.Texture2D:setDefaultAlphaPixelFormat(v[2])
	        display.addImageAsync(v[1],callback)
	        cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888)
	    else
	        display.addImageAsync(v[1],callback)
	    end
    end
end

function version()
	-- 此处放游戏版本号
	return 3
end



