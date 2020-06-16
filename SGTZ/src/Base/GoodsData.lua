--
-- Author: Your Name
-- Date: 2017-07-03 15:18:48
--

--商品数据
local GoodsData = {}
local ID = {
	xiangjiao = 1,
	caomei = 2,
	pinggup = 3,
	mangguo = 4,
	xigua = 5,
	liulian = 6,
	free = 7 -- 免费的水果id
}
local spGoodsImage = 
{
	"ccbResources/SGTZRes/image/icon/SG_jl_1xiangjiao.png",
	"ccbResources/SGTZRes/image/icon/SG_jl_7caomei.png",
	"ccbResources/SGTZRes/image/icon/SG_jl_3pinggup.png",
	"ccbResources/SGTZRes/image/icon/SG_jl_6mangguo.png",
	"ccbResources/SGTZRes/image/icon/SG_jl_2xigua.png",
	"ccbResources/SGTZRes/image/icon/SG_jl_9liulian.png",
	"ccbResources/SGTZRes/image/icon/SG_jl_free.png",

	-- "ccbResources/SGTZRes/image/icon/SG_jl_8putao.png",
	-- "ccbResources/SGTZRes/image/icon/SG_jl_4shanzhu.png",
	-- "ccbResources/SGTZRes/image/icon/SG_jl_5sangshen.png",
}

-- 左闭右闭 [1,10]
local eTanZhuPrizeConfig = 
{
	weight = 510,
	{
		mult={1,5},
		weight=200,
		ratio = 1,
		id = ID.xiangjiao,
	},
	{
		mult={6,15},
		weight=150,
		ratio = 1,
		id = ID.caomei,
	},
	{
		mult={16,99},
		weight=100,
		ratio = 1,
		id = ID.pinggup,
	},
	{
		mult={100,199},
		weight=60,
		ratio = 1,
		id = ID.mangguo,
	},
}
-- 无奖励时的随机配置
local eTanZhuPrizeConfig2 = 
{
	weight = 1560,
	{
		mult={1,5},
		weight=300,
		ratio = 1,
		id = ID.xiangjiao,
	},
	{
		mult={6,15},
		weight=600,
		ratio = 1,
		id = ID.caomei,
	},
	{
		mult={16,99},
		weight=600,
		ratio = 1,
		id = ID.pinggup,
	},
	{
		mult={100,199},
		weight=60,
		ratio = 1,
		id = ID.mangguo,
	},
}
local eTanZhuPrizeConfig_Big = 
{
	weight = 100,
	{
		mult={100,199},
		weight=60,
		ratio = 1,
		id = ID.mangguo,
	},
	{
		mult={200,499},
		weight=30,
		ratio = 1,
		id = ID.xigua,
	},
	{
		mult={500,1000},
		weight=10,
		ratio = 1,
		id = ID.liulian,
	},
}

local freeConfig = {
	mult={1,3},--免费 (1~3) * 5
	weight=50,
	ratio = 5,
	id = ID.free,
}
local maxMult = 199
local minMult = 1
local maxMult_2 = 1000
local minMult_2 = 100

function GoodsData.getRamdomGoodsNum(config)
	if config then
		return math.random(config.mult[1],config.mult[2]) * config.ratio
	end
	return 1
end
function GoodsData.getBigRamdomGoods()
	local config = eTanZhuPrizeConfig_Big
	local weight = config.weight
	local random_num = math.random(1,weight)
	local uTouchPrizeID = 1
	local uTouchPrizeNum = 0
	for i,v in ipairs(config) do
		random_num = random_num - v.weight
		if random_num <= 0 then
			uTouchPrizeID = v.id
			uTouchPrizeNum = GoodsData.getRamdomGoodsNum(v)
			break
		end
	end
	if uTouchPrizeNum > 100 then
		uTouchPrizeNum = math.floor( uTouchPrizeNum / 100 ) * 100
	end
	return {
		uTouchPrizeID = uTouchPrizeID,
		uTouchPrizeNum = uTouchPrizeNum,
	}
end

function GoodsData.getSmallRamdomGoods()
	local config = eTanZhuPrizeConfig
	local weight = config.weight + freeConfig.weight
	local random_num = math.random(1,weight)
	local uTouchPrizeID = 1
	local uTouchPrizeNum = 0
	if random_num > config.weight then
		return {
				uTouchPrizeID = freeConfig.id,
				uTouchPrizeNum = GoodsData.getRamdomGoodsNum(freeConfig),
			}
	else
		for i,v in ipairs(config) do
			random_num = random_num - v.weight
			if random_num <= 0 then
				uTouchPrizeID = v.id
				uTouchPrizeNum = GoodsData.getRamdomGoodsNum(v)
				break
			end
		end
		if uTouchPrizeNum > 100 then
			uTouchPrizeNum = math.floor( uTouchPrizeNum / 100 ) * 100
		end
		return {
			uTouchPrizeID = uTouchPrizeID,
			uTouchPrizeNum = uTouchPrizeNum,
		}
	end
end

function GoodsData.getSmallRamdomGoods2()
	local config = eTanZhuPrizeConfig2
	local weight = config.weight + freeConfig.weight
	local random_num = math.random(1,weight)
	local uTouchPrizeID = 1
	local uTouchPrizeNum = 0
	if random_num > config.weight then
		return {
				uTouchPrizeID = freeConfig.id,
				uTouchPrizeNum = GoodsData.getRamdomGoodsNum(freeConfig),
			}
	else
		for i,v in ipairs(config) do
			random_num = random_num - v.weight
			if random_num <= 0 then
				uTouchPrizeID = v.id
				uTouchPrizeNum = GoodsData.getRamdomGoodsNum(v)
				break
			end
		end
		if uTouchPrizeNum > 100 then
			uTouchPrizeNum = math.floor( uTouchPrizeNum / 100 ) * 100
		end
		return {
			uTouchPrizeID = uTouchPrizeID,
			uTouchPrizeNum = uTouchPrizeNum,
		}
	end
end

function GoodsData.getFruitsByMult(fruitsConfig,mult)
	local uTouchPrizeID
	for i,config in ipairs(fruitsConfig) do
		uTouchPrizeID = config.id
		if config.mult[1] * config.ratio <= mult and mult <= config.mult[2] * config.ratio then
			return {
				uTouchPrizeID = uTouchPrizeID,
				uTouchPrizeNum = mult,
			}
		end
	end
	local len = #fruitsConfig
	uTouchPrizeID = fruitsConfig[len].id
	return {
		uTouchPrizeID = uTouchPrizeID,
		uTouchPrizeNum = mult,
	}
end

function GoodsData.getRandomBigFruits(sumMult,freeFruitNum)
	-- 倍数小于下限 直接返回
	if sumMult < minMult_2 then return nil,sumMult end
	local smallFruitsNum = sumMult - maxMult * (3 - freeFruitNum)

	local min_uTouchPrizeNum = math.max( minMult_2 , smallFruitsNum )
	local max_uTouchPrizeNum = math.min( maxMult_2 , sumMult) -- 确定上限值
	local random_uTouchPrizeNum = math.random(min_uTouchPrizeNum,max_uTouchPrizeNum)
	if random_uTouchPrizeNum > 100 then 
		random_uTouchPrizeNum = math.floor( random_uTouchPrizeNum / 100 ) * 100
		if random_uTouchPrizeNum < min_uTouchPrizeNum then
			random_uTouchPrizeNum = min_uTouchPrizeNum
		end
	end
	local fruits = GoodsData.getFruitsByMult(eTanZhuPrizeConfig_Big,random_uTouchPrizeNum)
	return fruits,sumMult - random_uTouchPrizeNum
end

-- 分割倍数返回水果组合
function GoodsData.splitMultToFruits(sumMult,count)
	local ret = {}
	local min_uTouchPrizeNum = minMult
	local max_uTouchPrizeNum = maxMult
	local sum = sumMult
	if min_uTouchPrizeNum * count > sumMult then return false end
	if max_uTouchPrizeNum * count < sumMult then return false end

	for i=1,count do
		local max_uTouchPrizeNum_c = math.min( max_uTouchPrizeNum , sum - ( min_uTouchPrizeNum * (count - i) ))
		local min_uTouchPrizeNum_c = math.max( min_uTouchPrizeNum , sum - ( max_uTouchPrizeNum * (count - i) ))
		if max_uTouchPrizeNum_c < min_uTouchPrizeNum_c then return false end
		local random_uTouchPrizeNum = math.random(min_uTouchPrizeNum_c,max_uTouchPrizeNum_c)

		if i == count then
			random_uTouchPrizeNum = max_uTouchPrizeNum_c
		elseif random_uTouchPrizeNum > 100 then 
			random_uTouchPrizeNum = math.floor( random_uTouchPrizeNum / 100 ) * 100
			if random_uTouchPrizeNum < min_uTouchPrizeNum_c then
				random_uTouchPrizeNum = min_uTouchPrizeNum_c
			end
		end

		sum = sum - random_uTouchPrizeNum
		local fruits = GoodsData.getFruitsByMult(eTanZhuPrizeConfig,random_uTouchPrizeNum)
		if fruits then
			table.insert(ret,fruits)
		end
	end
	return ret
end

function GoodsData.splitFreeFruits(num)
	local config = freeConfig
	local ret = {}
	for i=config.mult[2],config.mult[1],-1 do
		local v = i * config.ratio
		while v <= num do
			num = num - v
			table.insert(ret,{
				uTouchPrizeID = freeConfig.id,
				uTouchPrizeNum = v,
			})
		end
	end
	return ret
end
function GoodsData.countXiangJiao(Fruits)
	local count = 0
	for i,v in ipairs(Fruits) do
		if v.uTouchPrizeID == ID.xiangjiao then
			count = count + 1
		end
	end
	return count 
end

function GoodsData.isFreeFruits(id)
	return id == freeConfig.id
end

function GoodsData.getFruitsImagePathByID(id)
	return spGoodsImage[id]
end

function GoodsData.clean()
	GoodsData = nil
end

return GoodsData
--------------------------------------
	
	

