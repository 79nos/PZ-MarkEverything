local function isSameItem(item1, item2)
    if not item1 and not item2 then
        return true
    end

    if not item1 or not item2 then
        return false
    end

    return item1:getType() == item2:getType()
end

local function taskDuplicateItemOptions(args)
    local container = args.container
    local player = args.player

    local itemList = container:getItems()
    local allItems = {}

    for i = 0, itemList:size() - 1 do
        table.insert(allItems, itemList:get(i))
    end

    ISInventoryPane.sortItemsByTypeAndWeight(nil, allItems)

    local playerContainer = getPlayerInventory(player).inventory

    local lastItem = nil
    for i, item in ipairs(allItems) do
        if isSameItem(item, lastItem) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(getSpecificPlayer(player), item, item:getContainer(),
                playerContainer))
        end
        lastItem = item
    end
end

local function buildTakeDuplicateItems(player, context, container, onCharacter)
    if onCharacter then
        return
    end

    context:addOption(getText("ContextMenu_PZMarkEverything_ContainerOp_TakeDuplicateItems"),
        { player = player, container = container, }, taskDuplicateItemOptions)
end

Events["PZMarkEverything.OnFillContainerOperationContextMenu"].Add(buildTakeDuplicateItems)
