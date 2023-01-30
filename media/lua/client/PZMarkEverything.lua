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

PZMarkEverything.getMarkedList = function()
	local modData = getPlayer():getModData()
	if not modData.PZMarkEverything then
		modData.PZMarkEverything = {}
		modData.PZMarkEverything.markedList = {}
	end
	return modData.PZMarkEverything.markedList
end

PZMarkEverything.markItem = function(args)
	local markedList = PZMarkEverything.getMarkedList()
	local mark = markedList[args.markID]

	if mark == nil then
		mark = {}
		markedList[args.markID] = mark
	end

	mark.color = args.color
end

PZMarkEverything.markAllItems = function(args)
	for i, markID in ipairs(args.markIDs) do
		PZMarkEverything.markItem({ markID = markID, color = args.color })
	end
end

PZMarkEverything.unmarkItem = function(id)
	local markedList = PZMarkEverything.getMarkedList()
	local mark = markedList[id]

	if mark == nil then
		return
	end

	markedList[id] = nil
end

PZMarkEverything.unmarkAllItems = function(markIDs)
	for i, markID in ipairs(markIDs) do
		PZMarkEverything.unmarkItem(markID)
	end
end

-- 部分物品type相同，但实际内容不相同，则在type后增加与内容相关的标志数据将其区分开
PZMarkEverything.getItemMarkID = function(item)
	local type = item:getFullType()
	if type == "Base.Disc_Retail" then
		return type .. item:getMediaData():getIndex()
	end

	if type == "Base.VHS_Retail" or type == "Base.VHS_Home" then
		return type .. item:getMediaData():getIndex()
	end

	return type
end

-- *****************************************************************************
-- * Event trigger functions
-- *****************************************************************************

PZMarkEverything.OnFillInventoryObjectContextMenu = function(player, contextMenu, items)
	local subMenu = ISContextMenu:getNew(contextMenu)
	contextMenu:addSubMenu(contextMenu:addOption(getText("ContextMenu_PZMarkEverything_MarkOption"), nil, nil), subMenu)

	if #items == 1 then
		local item = items[1].items[1]
		local markID = PZMarkEverything.getItemMarkID(item)

		local colorSubMenu = ISContextMenu:getNew(subMenu)
		subMenu:addSubMenu(subMenu:addOption(getText("ContextMenu_PZMarkEverything_MarkOption_MarkItem", nil, nil)),
			colorSubMenu)
		for color, cfg in pairs(PZMarkEverything.itemMarkConfig) do
			colorSubMenu:addOption(getText(cfg.text), { markID = markID, color = color, }, PZMarkEverything.markItem)
		end

		subMenu:addOption(getText("ContextMenu_PZMarkEverything_MarkOption_UnmarkItem"), markID, PZMarkEverything.unmarkItem)

	else
		local markIDs = {}
		for i, v in ipairs(items) do
			local item = v.items[1]
			local markID = PZMarkEverything.getItemMarkID(item)

			table.insert(markIDs, markID)

		end
		if #markIDs > 0 then
			local colorSubMenu = ISContextMenu:getNew(subMenu)
			subMenu:addSubMenu(subMenu:addOption(getText("ContextMenu_PZMarkEverything_MarkOption_MarkAllItem", nil, nil)),
				colorSubMenu)
			for color, cfg in pairs(PZMarkEverything.itemMarkConfig) do
				colorSubMenu:addOption(getText(cfg.text), { markIDs = markIDs, color = color, }, PZMarkEverything.markAllItems)
			end

			subMenu:addOption(getText("ContextMenu_PZMarkEverything_MarkOption_UnmarkAllItem"), markIDs,
				PZMarkEverything.unmarkAllItems)
		end
	end
end
Events.OnFillInventoryObjectContextMenu.Add(PZMarkEverything.OnFillInventoryObjectContextMenu)

-- *****************************************************************************
-- * Main functions
-- *****************************************************************************

PZMarkEverything.original_render = ISInventoryPane.renderdetails
function ISInventoryPane:renderdetails(doDragged)
	PZMarkEverything.original_render(self, doDragged)

	local markedList = PZMarkEverything.getMarkedList()
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
					local mark = markedList[PZMarkEverything.getItemMarkID(item)]

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
