PZMarkEverything = PZMarkEverything or {}

if not Events["PZMarkEverything.OnFillContainerOperationContextMenu"] then
    LuaEventManager.AddEvent("PZMarkEverything.OnFillContainerOperationContextMenu")
end

if not Events["PZMarkEverything.OnFillItemOperationContextMenu"] then
    LuaEventManager.AddEvent("PZMarkEverything.OnFillItemOperationContextMenu")
end
