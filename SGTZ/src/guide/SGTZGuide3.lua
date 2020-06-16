local SGTZGuide3 = class("SGTZGuide3", function()
	local node =  cc.uiloader:load("ccbResources/SGTZRes/ui/guide/SGTZGuide_3.csb")
	return node
end)

function SGTZGuide3:ctor()
    self.Panel_touch = cc.uiloader:seekCsbNodeByName(self, "Panel_touch")
    self.Panel_touch:setContentSize(display.width,display.height)
    self.Panel_touch:opacity(0)

    display.setImageClick(self.Panel_touch, function()
            if type(self.mCallback) == "function" then
                self.mCallback()
            end
            self:removeSelf()
        end)
    self.Image_shou = cc.uiloader:seekCsbNodeByName(self, "Image_shou")
end

function SGTZGuide3:setFinishCallback(callback)
	self.mCallback = callback
end

function SGTZGuide3:setWorldPos(worldPoint)
    self:initShader(worldPoint)
    local pos = self:convertToNodeSpace(worldPoint)
    self.Image_shou:setPosition(pos.x,pos.y)
end

function SGTZGuide3:initShader(pos)
    self.mCanva = cc.RenderTexture:create(display.width, display.height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888)
    self.mCanva:addTo(self)
    -- self.mCanva:getSprite():setPosition(display.cx, display.cy)
    local mask = display.newScale9Sprite("ccbResources/SGTZRes/image/guide/JC_zhezhao.png", pos.x, pos.y + 50, cc.size(530, 220), capInsets)
    self.mCanva:begin()  
    mask:visit()  
    self.mCanva:endToLua() 

    local vShaderByteArray = [==[
        attribute vec4 a_position;
        attribute vec4 a_color;
        attribute vec2 a_texCoord;
        #ifdef GL_ES
            varying lowp vec4 v_fragmentColor;
            varying mediump vec2 v_texCoord;
        #else
            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
        #endif
        void main()
        {
            gl_Position = CC_PMatrix * a_position;
            v_fragmentColor = a_color;
            v_texCoord = a_texCoord;
        }
    ]==]
    local fShaderByteArray = [==[
    varying vec4 v_fragmentColor;
    varying vec2 v_texCoord;

    void main()
    {
        vec4 textureColor0 = texture2D(CC_Texture0, v_texCoord);
        gl_FragColor = vec4(0,0,0,(1.0-textureColor0.a)*0.7);
    }
    ]==]
    local pProgram = cc.GLProgram:createWithByteArrays(vShaderByteArray,fShaderByteArray)
    pProgram:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    pProgram:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    pProgram:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)

    pProgram:link()
    pProgram:use()
    pProgram:updateUniforms()

    self.mCanva:getSprite():setGLProgram(pProgram)
    self.mCanva:setLocalZOrder(-1)
end


return SGTZGuide3