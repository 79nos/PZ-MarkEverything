local function onFillInventoryObjectContextMenu(player, contextMenu, items)
    local subMenu = ISContextMenu:getNew(contextMenu)
    contextMenu:addSubMenu(contextMenu:addOption(getText("ContextMenu_PZMarkEverything_ItemOp"), nil, nil), subMenu)

    triggerEvent("PZMarkEverything.OnFillItemOperationContextMenu", player, subMenu, items)
end

Events["OnFillInventoryObjectContextMenu"].Add(onFillInventoryObjectContextMenu)
