local function selectSameItem(player, container, targetContainer, targetItemTypes)
    local toFloor = targetContainer:getType() == "floor";
    local hotBar = getPlayerHotbar(player)

    local selectedItems = {};
    local it = container:getItems();
    for i = 0, it:size() - 1 do
        local item = it:get(i);
        local ok = not item:isEquipped() and item:getType() ~= "KeyRing" and not hotBar:isInHotbar(item);
        if item:isFavorite() then
            ok = false;
        end
        if toFloor and instanceof(item, "Moveable") and item:getSpriteGrid() == nil and not item:CanBeDroppedOnFloor() then
            ok = false;
        end
        if not targetItemTypes[item:getType()] then
            ok = false;
        end

        if ok then
            table.insert(selectedItems, item);
        end
    end

    return selectedItems;
end

local function collectSameItem(args)
    local player = args.player
    local items = args.items

    local selectedItemTypes = {};
    local targetContainer = nil;
    local playerObj = getSpecificPlayer(player)

    if #items == 1 then
        local item = items[1];
        if item.items then
            item = item.items[1];
        end

        selectedItemTypes[item:getType()] = true;
        targetContainer = item:getContainer();
    else
        for i, item in ipairs(items) do
            local realItem = item
            if item.items then
                realItem = item.items[1]
            end

            selectedItemTypes[realItem:getType()] = true;

            local con = realItem:getContainer();

            if targetContainer ~= nil and con ~= targetContainer then
                return
            end

            targetContainer = con;
        end

    end

    if not targetContainer then
        return
    end

    local containers = {};

    for i, v in ipairs(getPlayerInventory(player).inventoryPane.inventoryPage.backpacks) do
        if v ~= targetContainer then
            table.insert(containers, v.inventory);
        end
    end
    for i, v in ipairs(getPlayerLoot(player).inventoryPane.inventoryPage.backpacks) do
        if v ~= targetContainer then
            table.insert(containers, v.inventory);
        end
    end


    for i, container in ipairs(containers) do
        local sameItems = selectSameItem(player, container, targetContainer, selectedItemTypes);

        if luautils.walkToContainer(container, player) then
            for i, item in ipairs(sameItems) do
                if not targetContainer:isItemAllowed(item) then
                    --
                elseif targetContainer:getType() == "floor" then
                    ISInventoryPaneContextMenu.dropItem(item, player)
                else
                    ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj,
                        item, container,
                        targetContainer))
                end
            end
        end
    end
end

local function buildCollectSameItemOption(player, contextMenu, items)
    contextMenu:addOption(getText("ContextMenu_PZMarkEverything_ItemOp_CollectSameItems"),
        { player = player, items = items, }, collectSameItem)
end

Events["PZMarkEverything.OnFillItemOperationContextMenu"].Add(buildCollectSameItemOption)
