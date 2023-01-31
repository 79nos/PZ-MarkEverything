local PZMarkEverything = {}

PZMarkEverything.itemMarkConfig = {
	blue = {
		text = "ContextMenu_PZMarkEverything_ItemMark_Blue",
		texture = getTexture("media/ui/PZMarkEverything-ItemMark-Blue.png"),
	},

	green = {
		text = "ContextMenu_PZMarkEverything_ItemMark_Green",
		texture = getTexture("media/ui/PZMarkEverything-ItemMark-Green.png"),
	},

	red = {
		text = "ContextMenu_PZMarkEverything_ItemMark_Red",
		texture = getTexture("media/ui/PZMarkEverything-ItemMark-Red.png"),
	},

	yellow = {
		text = "ContextMenu_PZMarkEverything_ItemMark_Yellow",
		texture = getTexture("media/ui/PZMarkEverything-ItemMark-Yellow.png"),
	},
}

-- *****************************************************************************
-- * ModData functions
-- *****************************************************************************

local function getMarkedList()
	local modData = getPlayer():getModData()
	if not modData.PZMarkEverything then
		modData.PZMarkEverything = {}
		modData.PZMarkEverything.markedList = {}
	end
	return modData.PZMarkEverything.markedList
end

local function mark(markID, color)
	local markedList = getMarkedList()
	local mark = markedList[markID]
	if mark == nil then
		mark = {}
		markedList[markID] = mark
	end

	mark.color = color
end

local function unmark(markID)
	local markedList = getMarkedList()
	local mark = markedList[markID]

	if mark == nil then
		return
	end

	markedList[markID] = nil
end

-- 部分物品type相同，但实际内容不相同，则在type后增加与内容相关的标志数据将其区分开
local function getItemMarkID(item)
	local type = item:getFullType()
	if type == "Base.Disc_Retail" then
		return type .. item:getMediaData():getIndex()
	end

	if type == "Base.VHS_Retail" or type == "Base.VHS_Home" then
		return type .. item:getMediaData():getIndex()
	end

	return type
end

local function markItemOption(args)
	mark(getItemMarkID(args.item), args.color)

	getPlayer():transmitModData()
end

local function markAllItemsOption(args)
	for i, item in ipairs(args.items) do
		local markID = getItemMarkID(item.items[1])

		mark(markID, args.color)
	end

	getPlayer():transmitModData()
end

local function unmarkItemOption(item)
	unmark(getItemMarkID(item))

	getPlayer():transmitModData()
end

local function unmarkAllItemsOption(items)
	for i, item in ipairs(items) do
		unmark(getItemMarkID(item.items[1]))
	end

	getPlayer():transmitModData()
end

-- *****************************************************************************
-- * Event trigger functions
-- *****************************************************************************

PZMarkEverything.OnFillInventoryObjectContextMenu = function(player, contextMenu, items)
	local subMenu = ISContextMenu:getNew(contextMenu)
	contextMenu:addSubMenu(contextMenu:addOption(getText("ContextMenu_PZMarkEverything_MarkOption"), nil, nil), subMenu)

	if #items == 1 then
		local item = items[1]
		if item.items then
			item = item.items[1]
		end

		local colorSubMenu = ISContextMenu:getNew(subMenu)
		subMenu:addSubMenu(subMenu:addOption(getText("ContextMenu_PZMarkEverything_MarkOption_MarkItem", nil, nil)),
			colorSubMenu)
		for color, cfg in pairs(PZMarkEverything.itemMarkConfig) do
			colorSubMenu:addOption(getText(cfg.text), { item = item, color = color, }, markItemOption)
		end

		subMenu:addOption(getText("ContextMenu_PZMarkEverything_MarkOption_UnmarkItem"), item, unmarkItemOption)

	else
		local colorSubMenu = ISContextMenu:getNew(subMenu)
		subMenu:addSubMenu(subMenu:addOption(getText("ContextMenu_PZMarkEverything_MarkOption_MarkAllItem", nil, nil)),
			colorSubMenu)
		for color, cfg in pairs(PZMarkEverything.itemMarkConfig) do
			colorSubMenu:addOption(getText(cfg.text), { items = items, color = color, }, markAllItemsOption)
		end

		subMenu:addOption(getText("ContextMenu_PZMarkEverything_MarkOption_UnmarkAllItem"), items,
			unmarkAllItemsOption)
	end
end
Events.OnFillInventoryObjectContextMenu.Add(PZMarkEverything.OnFillInventoryObjectContextMenu)

-- *****************************************************************************
-- * Main functions
-- *****************************************************************************

PZMarkEverything.originalRenderdetails = ISInventoryPane.renderdetails
PZMarkEverything.newRenderdetails = function(self, doDragged)
	PZMarkEverything.originalRenderdetails(self, doDragged)

	local markedList = getMarkedList()
	local player = getSpecificPlayer(self.player)
	local y = 0;
	local alt = false;
	local MOUSEX = self:getMouseX()
	local MOUSEY = self:getMouseY()
	local YSCROLL = self:getYScroll()
	local HEIGHT = self:getHeight()

	-- [NOTICE]
	-- The source code below is the basicaly same as the vanilla code in Build 41.50.
	-- Due to changes in the vanilla code, it may not work properly.

	for k, v in ipairs(self.itemslist) do
		local count = 1;
		-- Go through each item in stack..
		for k2, v2 in ipairs(v.items) do
			local item = v2;
			local doIt = true;
			local xoff = 0;
			local yoff = 0;
			local isDragging = false
			if self.dragging ~= nil and self.selected[y + 1] ~= nil and self.dragStarted then
				xoff = MOUSEX - self.draggingX;
				yoff = MOUSEY - self.draggingY;
				if not doDragged then
					doIt = false;
				else
					isDragging = true
				end
			else
				if doDragged then
					doIt = false;
				end
			end
			local topOfItem = y * self.itemHgt + YSCROLL
			if not isDragging and ((topOfItem + self.itemHgt < 0) or (topOfItem > HEIGHT)) then
				doIt = false
			end

			if doIt == true then
				-- only do icon if header or dragging sub items without header.
				local tex = item:getTex();
				if tex ~= nil then
					local texDY = 1
					local texWH = math.min(self.itemHgt - 2, 32)
					local auxDXY = math.ceil(20 * self.texScale)
					local mark = markedList[getItemMarkID(item)]

					if mark ~= nil then
						local cfg = PZMarkEverything.itemMarkConfig[mark.color]

						if cfg ~= nil then
							if count == 1 then
								self:drawTexture(cfg.texture, (9 + xoff),
									(y * self.itemHgt) + self.headerHgt - 1 + auxDXY +
									yoff, 1, 1, 1, 1);

							elseif v.count > 2 or (doDragged and count > 1 and self.selected[(y + 1) - (count - 1)] == nil) then
								self:drawTexture(cfg.texture, (9 + 16 + xoff), (y * self.itemHgt) + self.headerHgt - 1 +
									auxDXY + yoff, 1, 1, 1, 1);

							end
						end
					end

				end
			end

			if count == 1 then
				if alt == nil then alt = false; end
				alt = not alt;
			end

			y = y + 1;

			if count == 1 and self.collapsed ~= nil and v.name ~= nil and self.collapsed[v.name] then
				break
			end
			if count == ISInventoryPane.MAX_ITEMS_IN_STACK_TO_RENDER + 1 then
				break
			end
			count = count + 1;
		end
	end
end
function ISInventoryPane:renderdetails(doDragged)
	PZMarkEverything.newRenderdetails(self, doDragged)
end

local function onReloading(fileName)
	if fileName ~= "client/PZMarkEverything_ItemMark.lua" then
		return
	end

	print("reloading PZMarkEverything_ItemMark.lua, so set old hooks to empty function")

	PZMarkEverything.newRenderdetails = PZMarkEverything.originalRenderdetails
end

if not Events.PZEasyDebugOnDebugReloadingLuaFile then
	LuaEventManager.AddEvent("PZEasyDebugOnDebugReloadingLuaFile")
end
Events.PZEasyDebugOnDebugReloadingLuaFile.Add(onReloading)
