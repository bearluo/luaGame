local SGTZEngine = class("SGTZEngine")
local scheduler = require("framework.scheduler")
local Def = require("game.SGTZ.Base.Def")

local function pRotate(pt1, pt2)
    return { x = pt1.x * pt2.x - pt1.y * pt2.y, y = pt1.x * pt2.y + pt1.y * pt2.x }
end

local function pUnrotate(pt1, pt2)
    return { x = pt1.x * pt2.x + pt1.y * pt2.y, y = pt1.y * pt2.x - pt1.x * pt2.y }
end
local RATIO = 1000
local function safeFloatToInt(f)
    return math.round(f * RATIO) / RATIO
end

local function safePosFloatToInt(p)
    return cc.p(math.round(p.x * RATIO) / RATIO,math.round(p.y * RATIO) / RATIO)
end

local function cos(a)
    return math.round(math.cos(a) * RATIO) / RATIO
end

local function sin(a)
    return math.round(math.sin(a) * RATIO) / RATIO
end

local DEBUG = false
local BALL_RADIUS = safeFloatToInt(33)
local COLUMN_RADIUS = safeFloatToInt(40)
local WORK_PATH_MAX_INDEX = 10
local DEFAULT_DT = Def.DEFAULT_DT -- 要能被 DEFAULT_RUNNING_TIME 整除
local DEFAULT_RUNNING_TIME = Def.DEFAULT_RUNNING_TIME 
local CACHE={}
local ROTATE = {
    cc.p(1,0),
    cc.p(0.9962,0.0872),
    cc.p(0.9848,0.1736),
    -- cc.p(math.cos(0),math.sin(0)),
    -- cc.p(math.cos(5),math.sin(5)),
    -- cc.p(math.cos(10),math.sin(10)),
}

function SGTZEngine:ctor()
    self.mColumnTab = {}
    self.mStaticColumnTab = {}
    self.mWorkPath = {}
    self.mWallTab = {}
    self.mGameBall = nil
    self.mIsPaused = false
    self.mDrawNode = nil
    self.mIsOpenDraw = false
    self.mIsSearchWorkPath = false
end

function SGTZEngine:clear()
    self.mColumnTab = {}
    self.mWallTab = {}
    self.mStaticColumnTab = {}
end

function SGTZEngine:pause()
    self.mIsPaused = true
end

function SGTZEngine:run()
    self.mIsPaused = false
end

function SGTZEngine:openDebugDraw(drawNode)
    self.mDrawNode = drawNode
    self.mIsOpenDraw = true
end

function SGTZEngine:closeDebugDraw(drawNode)
    self.mDrawNode = nil
    self.mIsOpenDraw = false
end

function SGTZEngine:draw()
    if not self.mIsOpenDraw then return end
    if tolua.isnull(self.mDrawNode) then return end

    self.mDrawNode:clear()

    for _,column in ipairs(self.mColumnTab) do
        column:draw(self.mDrawNode)
    end
    for _,column in ipairs(self.mStaticColumnTab) do
        column:draw(self.mDrawNode)
    end
    for _,wall in ipairs(self.mWallTab) do
        wall:draw(self.mDrawNode)
    end
    if self.mGameBall then
        self.mGameBall:draw(self.mDrawNode)
    end
end

-- 单球运动碰撞反弹
-- vel 重心到碰撞点的向量 --无关向量长度无关
-- velocity 速度向量
function SGTZEngine:reflex(vel,velocity)
    local angle = cc.pToAngleSelf(vel)-- math.atan2(y, x)
    local rotate = cc.p(math.cos(angle),math.sin(angle))
    -- dump(velocity,"rotate velocity")
    -- dump(rotate,"rotate")
    local vel0 = pUnrotate(velocity, rotate)
    -- dump(vel0,"rotated velocity")
    -- print("angle",angle,angle/math.pi * 180)
    vel0.x = -vel0.x
    local vel0F = pRotate(vel0, rotate)
    -- dump(vel0F,"vel0F")
    return safePosFloatToInt(vel0F)
end

function SGTZEngine:shakeV(perV,nextV,shakeRotate)
    local angle = cc.pToAngleSelf(perV)-- math.atan2(y, x)
    local rotate = cc.p(math.cos(angle),math.sin(angle))
    local vel0 = pUnrotate(nextV, rotate)

    if vel0.y > 0 then
        vel0 = pUnrotate(vel0, shakeRotate)
    else
        vel0 = pRotate(vel0, shakeRotate)
    end

    local vel0F = pRotate(vel0, rotate)
    return safePosFloatToInt(vel0F)
end

function SGTZEngine:safeCircleDist(v,s,e)
    local position = self.mGameBall:getPosition()
    local radius = self.mGameBall:getRadius()
    local curVelocity = self.mGameBall:getVelocity()
    local positionV = v:getPosition()
    local radiusV = v:getRadius()

    local dt = (e + s) / 2
    local nextPosition = safePosFloatToInt(cc.pAdd(position,cc.pMul(curVelocity,dt)))
    local dist = cc.pGetDistance(positionV,nextPosition)
    local safeDist = safeFloatToInt(dist)
    local safeRadius = radiusV+radius
    local isSafe = dist > safeRadius
    local safeS = safeFloatToInt(s)
    local safeE = safeFloatToInt(e)
    if DEBUG then
        print("safeDist",s,e,safeS,safeE,dt,safeDist,safeRadius,isSafe)
    end

    if s == 0 and e == 0 then
        -- 因为2分回归先后顺序问题导致回滚的位置和之前的小球发生碰撞 地图随机因子 1576656052192
        error(string.format("safeCircleDist randomseed %s", tostring(self.mRandomseed)), 0)
    end
    if safeE <= safeS then return nextPosition end
    if isSafe then
        if safeDist <= safeRadius or safeE <= safeS then 
            return nextPosition
        end
        return self:safeCircleDist(v,dt,e)
    else
        return self:safeCircleDist(v,s,dt)
    end
end

function SGTZEngine:PointToSegDist(p,ps,pe)
    local x,y = p.x,p.y
    local x1,y1 = ps.x,ps.y
    local x2,y2 = pe.x,pe.y
    local cross = (x2 - x1) * (x - x1) + (y2 - y1) * (y - y1)--cc.pCross(cc.pSub(pe,ps),cc.pSub(p,ps))
    if cross <= 0 then return math.sqrt((x - x1) * (x - x1) + (y - y1) * (y - y1)) , ps end

    local d2 = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1)
    if cross >= d2 then return math.sqrt((x - x2) * (x - x2) + (y - y2) * (y - y2)) , pe end

    local r = cross / d2
    local px = x1 + (x2 - x1) * r
    local py = y1 + (y2 - y1) * r
    return math.sqrt((x - px) * (x - px) + (py - y) * (py - y)) , cc.p(px,py)
end

function SGTZEngine:safeLineDist(v,s,e)
    local position = self.mGameBall:getPosition()
    local radius = self.mGameBall:getRadius()
    local curVelocity = self.mGameBall:getVelocity()
    local positionS,positionE = v:getPosition()
    local dt = (e + s) / 2
    local nextPosition = safePosFloatToInt(cc.pAdd(position,cc.pMul(curVelocity,dt)))
    -- point 最近点坐标
    local dist,point = self:PointToSegDist(nextPosition,positionS,positionE)
    local safePoint = safePosFloatToInt(point)
    local safeDist = safeFloatToInt(dist)
    local safeRadius = radius
    local isSafe = safeDist > safeRadius
    local safeS = safeFloatToInt(s)
    local safeE = safeFloatToInt(e)
    if DEBUG then
        print("safeLineDist",s,e,dt,safeS,safeE,safeDist,safeRadius,isSafe)
    end
    if s == 0 and e == 0 then
        -- 因为2分回归先后顺序问题导致回滚的位置和之前的小球发生碰撞 地图随机因子 1576656052192
        error(string.format("safeLineDist randomseed %s", tostring(self.mRandomseed)), 0)
    end
    if safeE <= safeS then return nextPosition,safePoint end

    if isSafe then
        if safeDist <= safeRadius or safeE <= safeS then 
            return nextPosition,safePoint
        end
        return self:safeLineDist(v,dt,e)
    else
        return self:safeLineDist(v,s,dt)
    end
end

function SGTZEngine:collisionDetectionCircle(circleTab,nextPosition,nextVelocity,curObj,dt)
    if not self.mGameBall then return nextPosition,nextVelocity,curObj end
    local radius = self.mGameBall:getRadius()
    local curVelocity = self.mGameBall:getVelocity()

    for i,circle in ipairs(circleTab) do
        if not circle:isDestroy() then
            local position = circle:getPosition()
            local vel = cc.pSub(position,nextPosition)
            local dist = cc.pGetLength(vel)
            local safeDist = safeFloatToInt(dist)
            local minDist = circle:getRadius()+radius
            if safeDist < minDist then
                -- 回退到安全位置
                if safeDist == 0 then
                    local vel1 = cc.pNormalize(cc.pMul(curVelocity,-1))
                    nextPosition = safePosFloatToInt(cc.pAdd(position,cc.pMul(vel1,minDist)))
                else
                    local vel1 = cc.pNormalize(cc.pMul(vel,-1))
                    nextPosition = safePosFloatToInt(cc.pAdd(position,cc.pMul(vel1,minDist)))
                end
                -- 2分回退
                -- nextPosition = self:safeCircleDist(circle,0,dt)
                vel = cc.pSub(position,nextPosition)
                nextVelocity = self:reflex(vel,curVelocity)
                curObj = circle
                if DEBUG then
                    print("DEBUG collisionDetectionCircle",safeDist,minDist,position.x,position.y,nextPosition.x,nextPosition.y,nextVelocity.x,nextVelocity.y,circle:getTag())
                end
                return nextPosition,nextVelocity,curObj
            end
        end
    end
    return nextPosition,nextVelocity,curObj
end

function SGTZEngine:collisionDetectionWall(wallTab,nextPosition,nextVelocity,curObj,dt)
    if not self.mGameBall then return nextPosition,nextVelocity,curObj end
    local radius = self.mGameBall:getRadius()
    local curVelocity = self.mGameBall:getVelocity()
    for i,wall in ipairs(wallTab) do
        local positionS,positionE = wall:getPosition()
        local dist,position = self:PointToSegDist(nextPosition,positionS,positionE)
        local vel = cc.pSub(position,nextPosition)
        local safeDist = safeFloatToInt(dist)
        local minDist = radius
        if safeDist < minDist then
            -- 回退到安全位置
            if safeDist == 0 then
                local vel1 = cc.pNormalize(cc.pMul(curVelocity,-1))
                nextPosition = safePosFloatToInt(cc.pAdd(position,cc.pMul(vel1,minDist)))
            else
                local vel1 = cc.pNormalize(cc.pMul(vel,-1))
                nextPosition = safePosFloatToInt(cc.pAdd(position,cc.pMul(vel1,minDist)))
            end
            -- 2分回退
            -- nextPosition,position = self:safeLineDist(wall,0,dt)
            vel = cc.pSub(position,nextPosition)
            nextVelocity = self:reflex(vel,curVelocity)
            curObj = wall
            if DEBUG then
                print("DEBUG collisionDetectionWall",safeDist,minDist,nextPosition.x,nextPosition.y,nextVelocity.x,nextVelocity.y,wall:getTag())
            end
            return nextPosition,nextVelocity,curObj
        end
    end
    return nextPosition,nextVelocity,curObj
end

function SGTZEngine:collisionDetection(dt)
    -- print("update start")
    local position = self.mGameBall:getPosition()
    local radius = self.mGameBall:getRadius()
    local curVelocity = self.mGameBall:getVelocity()
    local curPosition = cc.pAdd(position,cc.pMul(curVelocity,dt))
    local nextPosition = safePosFloatToInt(curPosition)
    local nextVelocity = safePosFloatToInt(curVelocity)
    local curObj = nil

    if DEBUG then
        print("DEBUG collisionDetection start",dt,nextPosition.x,nextPosition.y,nextVelocity.x,nextVelocity.y)
    end

    nextPosition,nextVelocity,curObj = self:collisionDetectionWall(self.mWallTab,nextPosition,nextVelocity,curObj,dt)
    nextPosition,nextVelocity,curObj = self:collisionDetectionCircle(self.mStaticColumnTab,nextPosition,nextVelocity,curObj,dt)
    nextPosition,nextVelocity,curObj = self:collisionDetectionCircle(self.mColumnTab,nextPosition,nextVelocity,curObj,dt)
    
    if DEBUG then
        print("DEBUG collisionDetection",dt,nextPosition.x,nextPosition.y,nextVelocity.x,nextVelocity.y,curObj and curObj:getTag())
    end

    if self.mIsSearchWorkPath then
        if curObj then
            self:onSearchWorkPathCollision(curObj,curVelocity,nextPosition,nextVelocity)
        else
            self.mGameBall:setPosition(nextPosition)
            self.mGameBall:setVelocity(nextVelocity)
        end
    else
        if curObj then
            if self.mWorkPathIndex <= WORK_PATH_MAX_INDEX then
                local id = tonumber(self.mWorkPath[self.mWorkPathIndex])
                if not id then
                    id = math.random(1,#ROTATE)
                    self.mWorkPath[self.mWorkPathIndex] = id
                end
                self.mWorkPathIndex = self.mWorkPathIndex + 1
                local rotate = ROTATE[id]
                nextVelocity = self:shakeV(curVelocity,nextVelocity,rotate)
            end
        end

        self.mGameBall:setPosition(nextPosition)
        self.mGameBall:setVelocity(nextVelocity)
        if iskindof(curObj, "Column") then
            self:onCollision(curObj)
        end
    end
    -- dump(self.mPosition)
    -- print("update end")
end

function SGTZEngine:setCollisionListener(listener)
    self.mCollisionListener = listener
end

function SGTZEngine:onCollision(obj)
    if self.mCollisionListener then
        self.mCollisionListener(obj,obj:getTag())
    end
end

function SGTZEngine:addWall(p1,p2)
    local position1 = safePosFloatToInt(p1)
    local position2 = safePosFloatToInt(p2)
    local wall = SGTZEngine.Wall.new()
    wall:setPosition(position1,position2)
    wall:setTag("wall" .. #self.mWallTab)
    table.insert(self.mWallTab,wall)
end

function SGTZEngine:addStaticColumn(position,r,tag)
    local position = safePosFloatToInt(position)
    local radius = safeFloatToInt(r)
    local node = SGTZEngine.Column.new(radius)
    node:setPosition(position)
    table.insert(self.mStaticColumnTab,node)
    node:setTag(tag or "null")
    return node
end

function SGTZEngine:workPathID2Char(id)
    return string.char(id)
end
function SGTZEngine:workPathChar2ID(c)
    return string.byte(c)
end
function SGTZEngine:encodeWorkPath(tab)
    return table.concat(tab,'')
end
function SGTZEngine:decodeWorkPath(str)
    local len = string.len(str)
    local ret = {}
    for i=1,len do
        ret[i] = string.sub(str,i,i)
    end
    return ret
end
function SGTZEngine:encodeRecordTab(tab)
    local str = ""
    for i,v in ipairs(Def.Fruits) do
        if i == 1 then
            str = tostring(tab[v])
        else
            str = str .. ',' .. tostring(tab[v])
        end
    end
    return str
end
function SGTZEngine:decodeRecordTab(str)
    return string.split(str,',')
end


function SGTZEngine:dfs(data)
    local pos = data.pos
    local vel = data.vel
    local recordTab = data.recordTab
    local workPath = data.workPath
    local isJanchi = data.isJanchi
    self.mGameBall:setPosition(pos)
    self.mGameBall:setVelocity(vel)
    local dt = DEFAULT_DT

    while not self.mCurData.isCollision and data.recordTime < DEFAULT_RUNNING_TIME do
        data.recordTime = data.recordTime + dt
        self:update(dt)
    end
    if self.mCurData.isCollision then return end


    if data.recordTime >= DEFAULT_RUNNING_TIME then
        -- print("searchWorkPath",workPath)
        local small_fruits_collision_count = 0
        local cacheId = "fruits_"
        for i,v in ipairs(Def.Small_Fruits) do
            if recordTab[v] and recordTab[v] >= Def.Small_Fruits_collision_count then
                small_fruits_collision_count = small_fruits_collision_count + 1
                cacheId = cacheId .. "1"
            else
                cacheId = cacheId .. "0"
            end
        end
        local big_fruits_collision_count = 0
        for i,v in ipairs(Def.Big_Fruits) do
            if recordTab[v] and recordTab[v] >= Def.Big_Fruits_collision_count then
                big_fruits_collision_count = big_fruits_collision_count + 1
                cacheId = cacheId .. "1"
            else
                cacheId = cacheId .. "0"
            end
        end
        -- dump(recordTab,"recordTab")
        -- print(big_fruits_collision_count + small_fruits_collision_count > 0 or isJanchi)

        -- if big_fruits_collision_count + small_fruits_collision_count > 0 or isJanchi then
            local jsNum = isJanchi and 1 or 0
            local workPathStr = workPath
            local recordTabStr = "record_" .. self:encodeRecordTab(recordTab) .. jsNum
            cacheId = cacheId .. jsNum
            local path = self:getFilePath(big_fruits_collision_count,small_fruits_collision_count,jsNum)

            -- print("path",path)
            if not CACHE[cacheId] then CACHE[cacheId] = 0 end
            if CACHE[workPathStr] then error("workPathStr:" .. workPathStr) end
            if not CACHE[recordTabStr] and CACHE[cacheId] <= 10 then
                CACHE[cacheId] = CACHE[cacheId] + 1
                CACHE[recordTabStr] = 1
                CACHE[workPathStr] = 1
                io.writefile(path, workPathStr .. ';',"a+b")
            end
            -- if isJanchi then
                -- self.mIsPaused = true
            -- end
        -- end
    end
end

function SGTZEngine:setSavePath(path)
    self.mSavePath = path
end

function SGTZEngine:getFilePath(big_fruits_collision_count,small_fruits_collision_count,isJc)
    return self.mSavePath .. self:getFileRelativePath(self.mAngle,big_fruits_collision_count,small_fruits_collision_count,isJc)
end

function SGTZEngine:getFileRelativePath(angle,big_fruits_collision_count,small_fruits_collision_count,isJc)
    return string.format("%d_%d%d%d",angle,big_fruits_collision_count,small_fruits_collision_count,isJc)
end

function SGTZEngine:initMap(posMap,workPathStr)
    local len = #posMap
    self.mColumnTab = {}
    self.mWorkPath = self:decodeWorkPath(workPathStr or "")
    self.mWorkPathIndex = 1
    -- dump(self.mWorkPath,"self.mWorkPath")
    for i=1,len do
        local position = safePosFloatToInt(posMap[i].pos)
        local radius = safeFloatToInt(posMap[i].radius)
        local node = SGTZEngine.Column.new(radius)
        node:setPosition(position)
        table.insert(self.mColumnTab,node)
        node:setTag(#self.mColumnTab)
    end
    return self.mColumnTab
end

function SGTZEngine:getWorkPathStr()
    return self:encodeWorkPath(self.mWorkPath)
end

function SGTZEngine:searchWorkPath()
    print("DEBUG searchWorkPath",self.mAngle)
    self.mIsSearchWorkPath = true

    local data = {
        pos = self.mGameBall:getPosition(),
        vel = self.mGameBall:getVelocity(),
        workPath = "",
        recordTab = {},
        recordTime = 0,
        isJanchi = false,
    }
    for i,v in ipairs(self.mColumnTab) do
        data.recordTab[i] = 0
    end
    for i=1,3 do
        data.recordTab["Jiangchi_" .. i] = 0
    end
    data.recordTab["PanelJiangchi"] = 0
    self.mCurData = data
    self:dfs(data)
    print("DEBUG searchWorkPath end",self.mAngle)
end

function SGTZEngine:onSearchWorkPathCollision(curObj,curVelocity,nextPosition,nextVelocity)
    self.mCurData.isCollision = true
    local recordTab = clone(self.mCurData.recordTab)
    local workPath = self.mCurData.workPath
    local recordTime = self.mCurData.recordTime
    local isJanchi = self.mCurData.isJanchi
    if iskindof(curObj,"Column") then
        local index = curObj:getTag()
        if type(index) == "string" and string.sub(index,1,-2) == "Jiangchi_" then
            recordTab[index] = recordTab[index] + 1
            if not isJanchi then
                isJanchi = true
                for i=1,3 do
                    isJanchi = isJanchi and recordTab["Jiangchi_" .. i] % 2 == 1
                end
            end
        else
            recordTab[index] = recordTab[index] + 1
        end
    end

    if string.len(workPath) >= WORK_PATH_MAX_INDEX then
        local newData = {
            pos = nextPosition,
            vel = nextVelocity,
            workPath = workPath,
            recordTab = recordTab,
            recordTime = recordTime,
            isJanchi = isJanchi,
        }
        local preData = self.mCurData
        self.mCurData = newData
        self:dfs(newData)
        self.mCurData = preData
    else
        for id,rotate in ipairs(ROTATE) do
            local newData = {
                pos = nextPosition,
                vel = self:shakeV(curVelocity,nextVelocity,rotate),
                workPath = workPath..tostring(id),
                recordTab = recordTab,
                recordTime = recordTime,
                isJanchi = isJanchi,
            }
            local preData = self.mCurData
            self.mCurData = newData
            self:dfs(newData)
            self.mCurData = preData
        end
    end
end

function SGTZEngine:initBall(x,y,rotation,vLen)
    local angle = (90 - rotation)/180 * math.pi
    local velocity = safePosFloatToInt(cc.p(math.cos(angle)*vLen,math.sin(angle)*vLen))
    local pos = safePosFloatToInt(cc.p(x,y))
    self.mGameBall = SGTZEngine.Ball.new()
    self.mGameBall:setPosition(pos)
    self.mGameBall:setVelocity(velocity)
    self.mGameBallPos = pos
    self.mWorkPathIndex = 1
    self.mAngle = rotation
    CACHE = {}
end

function SGTZEngine:getBallPosition()
    return self.mGameBall:getPosition()
end

function SGTZEngine:update(dt)
    if self.mIsPaused then return end
    self:collisionDetection(dt)
    self:draw()
end

local BallColor = cc.c4f(1, 1, 1, 1)
local ColumnColor = cc.c4f(1, 0, 0, 1)
local WallColor = cc.c4f(1, 0.5, 1, 1)
local Base = class("Base")
SGTZEngine.Base = Base

function Base:ctor()
    self.mPosition = cc.p(0,0)
    self.mRadius = 0
    self.mColor = BallColor
    self.mDestroy = false
end

function Base:getRadius()
    return self.mRadius
end

function Base:setPosition(x, y)
    if type(x) == "number" then
        self.mPosition = cc.p(x, y)
    else
        self.mPosition = x
    end
end

function Base:getPosition()
    return self.mPosition
end

function Base:setDestroy(flag)
    self.mDestroy = flag
end

function Base:isDestroy()
    return self.mDestroy
end

function Base:draw(drawNode)
    if not self:isDestroy() then
        drawNode:drawDot(self.mPosition,self.mRadius,self.mColor)
    end
end

function Base:setTag(flag)
    self.mTag = flag
end

function Base:getTag()
    return self.mTag
end



local Ball = class("Ball",Base)
SGTZEngine.Ball = Ball
function Ball:ctor()
    self.mVelocity = cc.p(0,0)
    self.mColor = BallColor
    self.mRadius = BALL_RADIUS
end

function Ball:setVelocity(velocity)
    self.mVelocity = velocity
end
function Ball:getVelocity()
    return self.mVelocity
end

local Column = class("Column",Base)
SGTZEngine.Column = Column
function Column:ctor(r)
    self.mRadius = r or COLUMN_RADIUS
    self.mColor = ColumnColor
end

local Wall = class("Wall",Base)
SGTZEngine.Wall = Wall
function Wall:ctor()
    self.mPosition = cc.p(0,0)
    self.mPositionRT = cc.p(0,0)
    self.mColor = WallColor
end

function Wall:setPositionRT(x,y)
    if type(x) == "number" then
        self.mPositionRT = cc.p(x, y)
    else
        self.mPositionRT = x
    end
end

function Wall:getPosition()
    return self.mPosition,self.mPositionRT
end

function Wall:setPosition(xs,ys,xe,ye)
    if type(xs) == "number" then
        self.mPosition = cc.p(xs, ys)
        self.mPositionRT = cc.p(xe, ye)
    else
        self.mPosition = xs
        self.mPositionRT = ys
    end
end

function Wall:draw(drawNode)
    local lb = self.mPosition
    local rt = self.mPositionRT
    local tab = {
        cc.p(lb.x,lb.y),
        -- cc.p(lb.x,rt.y),
        cc.p(rt.x,rt.y),
        -- cc.p(rt.x,lb.y),
    }
    -- drawNode:drawSolidPoly(tab, #tab, self.mColor)
    drawNode:drawLine(tab[1], tab[2], self.mColor)
end

return SGTZEngine