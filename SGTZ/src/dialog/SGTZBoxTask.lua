
local SGTZBoxTask = class("SGTZBoxTask", function()
    local node=cc.uiloader:load("ccbResources/SGTZRes/ui/dialog/SGTZTask.csb")
    node:setAnchorPoint(cc.p(0.5,0.5))
    return node
end)

function SGTZBoxTask:ctor()
    print("--SGTZBoxTask:ctor--");
    self:setPosition(display.cx,display.cy)
    local btn_close = cc.uiloader:seekCsbNodeByName(self, "btn_close");
	display.setImageClick(btn_close,handler(self,self.Func_onClickClose));

    local btn_pay = cc.uiloader:seekCsbNodeByName(self, "img_buy");
	display.setImageClick(btn_pay,handler(self,self.Func_onClickPay));

    local btn_help = cc.uiloader:seekCsbNodeByName(self, "panel_help");
    btn_help:setTouchEnabled(true)
    display.setCsbSpriteClick(btn_help,handler(self,self.Func_onClickHelp));


    self.levelLimit = false;
	
    self.panel_box =  cc.uiloader:seekCsbNodeByName(self, "panel_box");
	self.layoutBox = {};
	self.explainImage = {};
	self.noticeTxt = {};
	self.m_BoxAction = {};
	self.taskLevel = 0
    for i=1,3 do
        self.layoutBox[i] = cc.uiloader:seekCsbNodeByName(self.panel_box, "panel_box"..i)
        self.m_BoxAction[i] = cc.uiloader:seekCsbNodeByName(self.layoutBox[i],"FileNode_"..i);
        for k,v in pairs(self.m_BoxAction[i]:getChildren()) do
        	if v:getName()~="Node_baoxiang" then
        		v:setVisible(false)
        	end
        end
        display.setImageClick(self.layoutBox[i],function()
            self:Func_onClickTaskBox(i);
        end);
    end

    self.listTaskView = cc.uiloader:seekCsbNodeByName(self, "list_task");
    -- self.listTaskView:setItemsMargin(10);
	self.panelTaskItem = cc.uiloader:seekCsbNodeByName(self, "panel_task_item");
	self.panelTaskItem:setVisible(false);

	self:registerEvent()

	self:RefreshTaskPopup();
end

function SGTZBoxTask:registerEvent()
	EventHelp.setEventIDLinster(self,handler(self,self.LuaEventLinster),{
			EVENT_ID.EVENT_PLAZA_TASK_CHANGE,
			EVENT_ID.EVENT_TZ_TASK_CONFIG,
			EVENT_ID.EVENT_TZ_TASK_DATA,
            EVENT_ID.EVENT_TZ_BOX_REWARD_RESPONSE,
		})
end

function SGTZBoxTask:LuaEventLinster(EventID, ... )
    print("------命令码EventID=："..EventID);
    local varTB = {...}
    if EventID == EVENT_ID.EVENT_PLAZA_TASK_CHANGE or EventID == EVENT_ID.EVENT_TZ_TASK_CONFIG or 
    EventID == EVENT_ID.EVENT_TZ_TASK_DATA or EventID == EVENT_ID.EVENT_TZ_BOX_REWARD_RESPONSE  then
    	self:RefreshTaskPopup();
    end

end

function SGTZBoxTask:SetTaskBoxShow(box, finishCount, szTitle, rewardFlag)
	print("SetTaskBoxShow",box,finishCount,szTitle,rewardFlag)
	--任务等级
	local fnt_task_title = cc.uiloader:seekCsbNodeByName(self.panel_box, "fnt_task_title");
	fnt_task_title:setString(szTitle);

	--设置进度条进度
	local taskFinshCount = finishCount;
	local taskLoadingBarPercent = 0;
	local per = {22,60,100}
	--29	64  100
	if (taskFinshCount >= tonumber(box[2].sValue)) then
		local taskFinshCountCurr = taskFinshCount - tonumber(box[2].sValue);
		local boxSValue =  tonumber(box[3].sValue) - tonumber(box[2].sValue);
		if (boxSValue ~= 0) then
			taskLoadingBarPercent = (taskFinshCountCurr / boxSValue)*(per[3]-per[2]) + per[2];
		else
            taskLoadingBarPercent = (taskFinshCountCurr /  tonumber(box[3].sValue))*(per[3]-per[2]) + per[2];
        end

	elseif (taskFinshCount > tonumber(box[1].sValue)) then
		local taskFinshCountCurr = taskFinshCount - tonumber(box[1].sValue);
		local boxSValue = tonumber(box[2].sValue) - tonumber(box[1].sValue);
		if (boxSValue ~= 0) then
			taskLoadingBarPercent = (taskFinshCountCurr / boxSValue)*(per[2]-per[1]) + per[1];
		else
			taskLoadingBarPercent = (taskFinshCountCurr / tonumber(box[2].sValue))*(per[2]-per[1]) + per[1];
        end
	else
        taskLoadingBarPercent = (taskFinshCount / tonumber(box[1].sValue)) * per[1];
    end
	
	local loadingBarTask = cc.uiloader:seekCsbNodeByName(self.panel_box, "loadingbar_task");
	loadingBarTask:setPercent(taskLoadingBarPercent);

	--宝箱显示设置
	local SGJBIT_MASK = { 0x01, 0x02, 0x04 };
	
	self.m_TaskBoxState = {};
    for i=1,3 do
        if (self.layoutBox[i]) then
			local taskCountTxt = cc.uiloader:seekCsbNodeByName(self.layoutBox[i], "txt_task_percent");
			local strTaskCount = taskFinshCount;
			if (taskFinshCount > tonumber(box[i].sValue)) then
				strTaskCount = tonumber(box[i].sValue);
			end
		
			taskCountTxt:setString(strTaskCount.."/"..box[i].sValue);

			--设置状态
			self.m_TaskBoxState[i] = 0;
			local boxPath = "RW_baoxiang0"..i..".png";
			self.layoutBox[i]:setTouchEnabled(false);
			local img_Box_lock = cc.uiloader:seekCsbNodeByName(self.layoutBox[i], "img_lock_bg");
			--恢复初始状态
			self.m_BoxAction[i]:stopAllActions()
			for k,v in pairs(self.m_BoxAction[i]:getChildren()) do
				if v:getName()~="Node_baoxiang" then
        			v:setVisible(false)
        		end
			end
			if (not self.levelLimit) then

				-- if self.m_BoxAction[i] then
				-- 	self.m_BoxAction[i]:removeFromParent(true)
				-- 	self.m_BoxAction[i] = nil;
				-- end


				self.m_TaskBoxState[i] = bit.band(rewardFlag,SGJBIT_MASK[i])

				if self.m_TaskBoxState[i] > 0 then
					boxPath = "RW_baoxiang0".. tostring(i+6)..".png";
                end

				if (self.m_TaskBoxState[i] == 0) then
					self.layoutBox[i]:setTouchEnabled(true);
					if (taskFinshCount >= tonumber(box[i].sValue)) then
						self.m_TaskBoxState[i] = 2;
						boxPath = "RW_baoxiang0"..tostring(i+3)..".png";
						--宝箱动画
						local firstgameAction = cc.uiloader:csbAniload("ccbResources/SGTZRes/ui/oldEffect/Node_renwu.csb");
						self.m_BoxAction[i]:runAction(firstgameAction);
						firstgameAction:gotoFrameAndPlay(0, true);
						for k,v in pairs(self.m_BoxAction[i]:getChildren()) do
							v:setVisible(true)
						end
					else
						self.m_TaskBoxState[i] = 1;
						boxPath = "RW_baoxiang0"..i..".png";
					end
                end
				img_Box_lock:setVisible(false);
			
			else
				img_Box_lock:setVisible(true);
            end

            self.explainImage[i] = cc.uiloader:seekCsbNodeByName(self.layoutBox[i], "img_explain");
            self.explainImage[i]:setVisible(false)
			local tempStr = "宝箱是空的";
			if (tonumber(box[i].goodsId) > 0) then
				local goodsInfo = center.good:getGoodsInfo(tonumber(box[i].goodsId));
				if (goodsInfo) then
					tempStr = goodsInfo.szGoodsName.."X"..box[i].goodsNum;
                end
            end
			
			self.noticeTxt[i] = cc.uiloader:seekCsbNodeByName(self.explainImage[i], "txt_explain");
            self.noticeTxt[i]:setString(tempStr)

			local img = cc.uiloader:seekCsbNodeByName(self.layoutBox[i], "img_box");
			img:setTexture("ccbResources/SGTZRes/image/boxTask/" .. boxPath);
        end
    end
end

-- 是否任务等级限制框
function SGTZBoxTask:ShowTaskLevelImpede(taskLevel, myVipLevel)
    local listDefaultSize = self.listTaskView:getContentSize();
    local m_iTaskListHeight = 370;
	local mTaskImpedeImg = cc.uiloader:seekCsbNodeByName(self, "img_impede");

	if (taskLevel <= myVipLevel) then
		--设置任务领取限制显示
		self.levelLimit = false;
		mTaskImpedeImg:setVisible(false);
		--设置任务列表显示高度
		self.listTaskView:setContentSize(listDefaultSize.width, m_iTaskListHeight + mTaskImpedeImg:getContentSize().height);
	else
		self.levelLimit = true;
		mTaskImpedeImg:setVisible(true);
		local describeText = cc.uiloader:seekCsbNodeByName(self, "txt_impede_describe");
		describeText:setString("你现在还不是VIP"..taskLevel..",成为即可领取任务奖励");
		self.listTaskView:setContentSize(listDefaultSize.width, m_iTaskListHeight);
	end
end

--任务详情显示
function SGTZBoxTask:ShowTaskFromTaskLevel()
    if not tolua.isnull(self.listTaskView) then
		self.listTaskView:removeAllChildren();
	end
	
	--状态排序
	local temptaskList = {};        --1 未完成
	local unFinishtaskList = {};    --2 已完成未领取
    local gotRewardtaskList = {};   --3 已领取
    
    for i,v in ipairs(self.m_SGJTaskList) do
        local taskItem = center.task:getTaskItem(v.sTaskListID);
		if not taskItem then
			v.uNowFinish = 0;
            v.boxState = 1;
            table.insert( temptaskList, v)
		
		else
			v.uNowFinish = taskItem.uNowFinish;
			v.boxState = 1;
			if (taskItem.uReceiveFinish == v.uFinishTimes) then
                v.boxState = 3;
                table.insert( gotRewardtaskList, v)
			
			elseif ((taskItem.uNowFinish / v.uFinishTimes) >= 1) then
                v.boxState = 2;
                table.insert( unFinishtaskList, v)
			
            else
                table.insert( temptaskList, v)
            end
        end
    end

    for i,v in ipairs(temptaskList) do
        table.insert( unFinishtaskList, v)
    end

    for i,v in ipairs(gotRewardtaskList) do
        table.insert( unFinishtaskList, v)
    end

	--任务显示
    for i,v in ipairs(unFinishtaskList) do
		local item = self:getTaskItemUI(self.panelTaskItem, v, self.levelLimit);
		self.listTaskView:pushBackCustomItem(item);
    end
end

function SGTZBoxTask:RefreshTaskPopup()
	--显示是否可以进行任务
    self.m_taskConfig = center.task:getTaskTanZhuTaskConfig()
    self.m_taskData = center.task:getTaskTanZhuTaskData()
    dump(self.m_taskConfig,"RefreshTaskPopup taskConfig")
    dump(self.m_taskData,"RefreshTaskPopup taskData")
	self:getSGJTaskList()
	if (not self.m_taskConfig.vipMin  or not self.m_taskData.repea) then
		return;
    end

	local taskLevel = tonumber(self.m_taskConfig.vipMin)-- + self.m_taskData.repea;
	self.taskLevel = self.m_taskConfig.vipMin
	local myActor = center.user:getMyActor();
    local viplevel = myActor and myActor[ACTOR_PROP_VIPLEVEL] or 0;
    print("taskLevel",taskLevel)
	self:ShowTaskLevelImpede(taskLevel, tonumber(viplevel));
	--宝箱显示
	self:SetTaskBoxShow(self.m_taskConfig.sGuoshancheBox, self.m_taskData.finishCount, self.m_taskConfig.szTitle, self.m_taskData.rewardFlag);
	--显示任务详情
	self:ShowTaskFromTaskLevel();
end

function SGTZBoxTask:getSGJTaskList()
	self.m_SGJTaskList = {};

    if  self.m_taskConfig.sGuoshancheTaskList and (table.getn(self.m_taskConfig.sGuoshancheTaskList) > 0) then

		for i,v in ipairs(self.m_taskConfig.sGuoshancheTaskList) do
			local sTaskLists =  self.m_taskConfig.sGuoshancheTaskList[i];
			local src = center.task:getTaskViewByListID(sTaskLists["lTaskListID"]);
			if	(src) then
				table.insert( self.m_SGJTaskList, src )
			end
        end
    end
end

function SGTZBoxTask:getTaskItemUI(layout,taskInfo,levelLimit)
	dump(taskInfo,"FruitBoxtaskInfo")
    self.node = layout:clone();
	self.node:setVisible(true);
	
	self.m_pImageRect = cc.uiloader:seekCsbNodeByName(self.node, "panel_head");
	--设置图片
	self:SetTaskIcon(taskInfo.nPicID,self.m_pImageRect);

	--任务描述
	local taskTitleTxt = cc.uiloader:seekCsbNodeByName(self.node, "text_task_title");
	taskTitleTxt:setString(taskInfo.szChildName);
	local taskExplainTxt = cc.uiloader:seekCsbNodeByName(self.node, "text_task_describe");
    taskExplainTxt:setString(taskInfo.szTips);
    
	--任务进度
	local taskNumTxt = cc.uiloader:seekCsbNodeByName(self.node, "txt_task_num");
	local taskProgress = center.task:getTaskItem(taskInfo.sTaskListID);
	local laskLoadingBar = cc.uiloader:seekCsbNodeByName(self.node, "loadingbar_item");
	local strTaskNum = "0/1";
	if taskProgress then
		strTaskNum = taskProgress.uNowFinish.."/"..taskInfo.uFinishTimes;
		laskLoadingBar:setPercent(tonumber(taskProgress.uNowFinish) / tonumber(taskInfo.uFinishTimes) *100);
	else
		strTaskNum = "0/"..taskInfo.uFinishTimes;
		laskLoadingBar:setPercent(0 / taskInfo.uFinishTimes *100);
	end
	taskNumTxt:setString(strTaskNum);
    
	
	local getGoodsImg = cc.uiloader:seekCsbNodeByName(self.node, "img_get");
	local taskFinishImg = cc.uiloader:seekCsbNodeByName(self.node, "img_task_finish");
	-- local img_suo = cc.uiloader:seekCsbNodeByName(self.node, "img_suo");
	-- img_suo:setVisible(false)

	if (taskInfo.boxState == 3) then
		taskFinishImg:setVisible(true);
		getGoodsImg:setVisible(false);
		removeGraySprite(getGoodsImg)
    elseif (taskInfo.boxState == 2) then
        display.setImageClick(getGoodsImg,function()
            if (not levelLimit) then
				--getGoodsImg:setTouchEnabled(false);
                --请求领取奖励
                center.task:sendFinishTask(taskInfo.sTaskListID);
            else
            	tipsFunc.newHintTip(string.format("Vip%d才能解锁奖励哦~",self.taskLevel)) 
            end
        end);
		removeGraySprite(getGoodsImg)
		taskFinishImg:setVisible(false);
		-- if levelLimit then
		-- 	img_suo:setVisible(true)
		-- 	img_suo:setSwallowTouches(false)
		-- end
	else
		taskFinishImg:setVisible(false);
		setGraySpriteAPI(getGoodsImg);
	end
	
	return self.node;
end

-- 下载任务图片
function SGTZBoxTask:SetTaskIcon(nPicID,SpriteParent)
    local function linster(bSuccess,sprite)
        if tolua.isnull(SpriteParent) then
            return
        end
        if bSuccess then
            if SpriteParent:getChildByTag(1) then
                SpriteParent:removeChildByTag(1, true)
            end
            sprite:addTo(SpriteParent,0)
            sprite:setPosition(cc.p(SpriteParent:getContentSize().width/2,SpriteParent:getContentSize().height/2))
            sprite:setTag(1)
        end
    end
    if SpriteParent:getChildByTag(1) then
        SpriteParent:removeChildByTag(1, true)
    end
    filefunc.openPic(nPicID,linster)
end

-- 宝箱点击
function SGTZBoxTask:Func_onClickTaskBox(boxId)
    if self.m_TaskBoxState[boxId]==1 then
        local explainImage = cc.uiloader:seekCsbNodeByName(self.layoutBox[boxId], "img_explain");
        if (explainImage:isVisible()) then
            explainImage:setVisible(false);
        else
            for i=1,3 do
                self.explainImage[i] = cc.uiloader:seekCsbNodeByName(self.layoutBox[i], "img_explain");
                if (i == boxId) then
                    self.explainImage[boxId]:setVisible(true);
                else
                    self.explainImage[i]:setVisible(false);
                end
            end	
        end
    elseif self.m_TaskBoxState[boxId]==2  then
        center.task:sendTanZhuBoxReward(self.m_taskData.taskLevelID, boxId-1);
		self.layoutBox[boxId]:setTouchEnabled(true);
    end
end

function SGTZBoxTask:Func_onClickClose()
	manager.popup:closePopup()
end

function SGTZBoxTask:Func_onClickPay()
    local view = manager.popup:newPopup(POPUP_ID.POPUP_TYPE_SHOP)
	view:selectTagBtnByTagID(MALL_TAG_GOLD)
end

function SGTZBoxTask:Func_onClickHelp()
    manager.popup:newPopup(POPUP_ID.POPUP_TYPE_SGTZ_BOXTASK_HELP)
end

return SGTZBoxTask
