local ContainerMarkConfig = {
    blue = {
        text = "ContextMenu_PZMarkEverything_ContainerMark_Blue",
        texture = getTexture("media/ui/PZMarkEverything-ItemMark-Blue.png"),
    },

    green = {
        text = "ContextMenu_PZMarkEverything_ContainerMark_Green",
        texture = getTexture("media/ui/PZMarkEverything-ItemMark-Green.png"),
    },

    red = {
        text = "ContextMenu_PZMarkEverything_ContainerMark_Red",
        texture = getTexture("media/ui/PZMarkEverything-ItemMark-Red.png"),
    },

    yellow = {
        text = "ContextMenu_PZMarkEverything_ContainerMark_Yellow",
        texture = getTexture("media/ui/PZMarkEverything-ItemMark-Yellow.png"),
    },
}

local function getModData(container)
    local vehiclePart = container:getVehiclePart()
    if vehiclePart then
        return vehiclePart:getModData()
    end

    local containingItem = container:getContainingItem()
    if containingItem then
        -- 道具上的ModData没有transmit方法，因此在联机情况下数据不能同步，也不会保存
        -- 所以直接不支持道具容器的标记
        return nil
    end

    -- 猜测parent下面会有多个容器，所以最后考虑使用parent
    local parent = container:getParent()
    if parent then
        return parent:getModData()
    end

    return nil
end

-- 需要与getMarkData中的判断条件保持相同
local function transmitMarkData(container)
    local vehiclePart = container:getVehiclePart()
    if vehiclePart then
        local vehicle = vehiclePart:getVehicle()
        vehicle:transmitPartModData(vehiclePart)
        return
    end

    local containingItem = container:getContainingItem()
    if containingItem then
        return nil
    end

    local parent = container:getParent()
    if parent then
        parent:transmitModData()
        return
    end
end

local function canMark(container)
    if container:getVehiclePart() then
        return true
    end

    if container:getContainingItem() then
        return false
    end

    if container:getParent() then
        return true
    end

    return false
end

local function mark(container, color)
    local modData = getModData(container)

    if not modData then
        return
    end

    local mark = modData.PZMarkEverything

    if not mark then
        mark = {}
        modData.PZMarkEverything = mark
    end

    mark.color = color

    transmitMarkData(container)
end

local function unmark(container)
    local modData = getModData(container)

    if not modData then
        return
    end

    if not modData.PZMarkEverything then
        return
    end

    modData.PZMarkEverything = nil

end

local function markOption(args)
    mark(args.container, args.color)
    transmitMarkData(args.container)
end

local function unmarkOption(args)
    unmark(args.container)
    transmitMarkData(args.container)
end

local orignalInventoryPageAddContainerButton = ISInventoryPage.addContainerButton
local newInventoryPageAddContainerButton = function(self, container, texture, name, tooltip)
    local button = orignalInventoryPageAddContainerButton(self, container, texture, name, tooltip)

    if canMark(container) then
        button.PZMarkEverything = {}
    else
        button.PZMarkEverything = nil
    end

    return button;
end
function ISInventoryPage:addContainerButton(container, texture, name, tooltip)
    return newInventoryPageAddContainerButton(self, container, texture, name, tooltip)
end

local orignalISButtonRender = ISButton.render
local newISButtonRender = function(self)
    orignalISButtonRender(self)

    if self.inventory and self.PZMarkEverything then
        local modData = getModData(self.inventory)
        if modData then
            local mark = modData.PZMarkEverything
            if mark then
                local config = ContainerMarkConfig[mark.color]
                if config then
                    local sizes = { 32, 40, 48 }
                    local containerButtonSize = sizes[getCore():getOptionInventoryContainerSize()]
                    self:drawTexture(config.texture, 0, containerButtonSize - 12, 1, 1, 1, 1)
                end
            end
        end
    end
end
function ISButton:render()
    newISButtonRender(self)
end

local function buildMarkContainerOp(player, context, container, onCharacter)
    if onCharacter then
        return
    end

    if canMark(container) then
        local colorSubMenu = ISContextMenu:getNew(context)
        context:addSubMenu(context:addOption(getText("ContextMenu_PZMarkEverything_ContainerOp_Mark", nil, nil))
            ,
            colorSubMenu)
        for color, cfg in pairs(ContainerMarkConfig) do
            colorSubMenu:addOption(getText(cfg.text), { container = container, color = color, },
                markOption)
        end
        context:addOption(getText("ContextMenu_PZMarkEverything_ContainerOp_Unmark"),
            { container = container },
            unmarkOption)
    end
end

Events["PZMarkEverything.OnFillContainerOperationContextMenu"].Add(buildMarkContainerOp)


local function onReloading(fileName)
    if fileName ~= "client/PZMarkEverything/ContainerMark.lua" then
        return
    end

    print("reloading PZMarkEverything_ContainerMark.lua, so set old hooks to empty function")

    newInventoryPageAddContainerButton = orignalInventoryPageAddContainerButton
    newISButtonRender = orignalISButtonRender
end

if not Events.PZEasyDebugOnDebugReloadingLuaFile then
    LuaEventManager.AddEvent("PZEasyDebugOnDebugReloadingLuaFile")
end
Events.PZEasyDebugOnDebugReloadingLuaFile.Add(onReloading)
