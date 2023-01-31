local function showCharacterContainerContextMenu(self)
    local page = self
    local context = ISContextMenu.get(page.player, getMouseX(), getMouseY())

    triggerEvent("PZMarkEverything.OnFillContainerOperationContextMenu", self.player, context, self.inventory,
        true)

    context:setVisible(true)
    if context.numOptions > 1 and JoypadState.players[page.player + 1] then
        context.origin = page
        context.mouseOver = 1
        setJoypadFocus(page.player, context)
    end
end

local function showNotCharacterContainerContextMenu(self)
    local page = self
    local context = ISContextMenu.get(page.player, getMouseX(), getMouseY())

    triggerEvent("PZMarkEverything.OnFillContainerOperationContextMenu", self.player, context, self.inventory,
        false)

    context:setVisible(true)
    if context.numOptions > 1 and JoypadState.players[page.player + 1] then
        context.origin = page
        context.mouseOver = 1
        setJoypadFocus(page.player, context)
    end
end

local originalInventoryPageCreateChildren = ISInventoryPage.createChildren
local newInventoryPageCreateChildren = function(self)
    originalInventoryPageCreateChildren(self)

    local titleBarHeight = self:titleBarHeight()
    local lootButtonHeight = titleBarHeight
    local btnText = "[" .. getText("IGUI_invpage_PZMarkEverything_Operation") .. "]"
    local textWid = getTextManager():MeasureStringX(UIFont.Small, btnText)

    local opBtn = ISButton:new(0, 0, textWid, lootButtonHeight, btnText, self, showCharacterContainerContextMenu)
    opBtn:initialise();
    opBtn.borderColor.a = 0.0;
    opBtn.backgroundColor.a = 0.0;
    opBtn.backgroundColorMouseOver.a = 0.7;
    opBtn.textColor = { r = 200 / 255, g = 200 / 255, b = 200 / 255, a = 1, }
    opBtn:setVisible(false);
    self:addChild(opBtn);
    self.PZMarkEverything = {
        containerOpBtn = opBtn
    }

    if self.onCharacter then
        opBtn.onclick = showCharacterContainerContextMenu
    else
        opBtn.onclick = showNotCharacterContainerContextMenu
    end
end
function ISInventoryPage:createChildren()
    newInventoryPageCreateChildren(self)
end

local originalInventoryPagePrerender = ISInventoryPage.prerender
local newInventoryPagePrerender = function(self)
    originalInventoryPagePrerender(self)

    if self.inventory then
        local titleWid = 0
        if self.title then
            titleWid = getTextManager():MeasureStringX(UIFont.Small, self.title)
        end

        if self.onCharacter then
            self.PZMarkEverything.containerOpBtn:setX(self.infoButton:getRight() + 1 + titleWid + 2)

        else
            local weightWid = getTextManager():MeasureStringX(UIFont.Small, "99.99 / 99")
            weightWid = math.max(90, weightWid + 10)

            self.PZMarkEverything.containerOpBtn:setX(self.width - 20 - weightWid - titleWid -
                self.PZMarkEverything.containerOpBtn:getWidth() - 2)

        end

        self.PZMarkEverything.containerOpBtn:setVisible(true)

    else
        self.PZMarkEverything.containerOpBtn:setVisible(false)
    end


end
function ISInventoryPage:prerender()
    newInventoryPagePrerender(self)
end

local function onReloading(fileName)
    if fileName ~= "shared/PZMarkEverything/ContainerOperation.lua" then
        return
    end

    print("reloading " .. fileName .. ", so set old hooks to empty function")

    newInventoryPageCreateChildren = originalInventoryPageCreateChildren
    newInventoryPagePrerender = originalInventoryPagePrerender
end

if not Events.PZEasyDebugOnDebugReloadingLuaFile then
    LuaEventManager.AddEvent("PZEasyDebugOnDebugReloadingLuaFile")
end
Events.PZEasyDebugOnDebugReloadingLuaFile.Add(onReloading)
