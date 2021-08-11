local mod = RegisterMod("Item Info", 1)

-- Highest valid Item ID in this game's version
local NUM_ITEMS = Isaac.GetItemConfig():GetCollectibles().Size - 1

-- TODO:

-- On first frame/initial load, run check to determine collected items
--    Save items in a json to read from when continuing?
-- Determine when to run check for new items again (Every new room perhaps?)
-- Store collected items in table, if size changes between frames, recheck items?

-- Descriptions can use most of RenderTempest from loadout to render text
--      Need to add functionality for multiline descriptions when width exceeds limit

-- Pills/Cards/Trinkets not currently supported
-- Shader to darken screen slightly when opening menu?

-- Table holding ID of every item owned
local collectedItemIDs = {}
-- Table holding sprite of every item owned
local collectedItemSprites = {}

local menuOpen = false
local menuCursorPos = Vector(1, 1)
-- Offset 0 shows items 1-16, 1 shows items 17-32, etc.
local menuItemsOffset = 0
local itemMenu = Sprite()
itemMenu:Load("gfx/ui/itemmenu.anm2", true)

local itemMenuAttrs = {
    -- Where to create the menu
    pos = Vector(50, 150),
    scale = Vector(0.7, 0.7),

    -- Where to begin drawing items ON the menu
    origin = Vector(8, 108),
    spacing = Vector(55, 55),

    -- Number of columns and rows to display items in 
    layout = Vector(4, 4)
}

local textAttrs = {
    header = {
        font = "font/upheaval.fnt",
        color = KColor(1, 1, 1, 1),
        offset = Vector(0, 0),
        pos = Vector(250, 45),
        scale = Vector(1, 1),
        boxWidth = 200,
        center = true,
    },
    subheader = {
        font = "font/terminus.fnt",
        color = KColor(1, 1, 1, 1),
        offset = Vector(0, 0),
        pos = Vector(250, 75),
        scale = Vector(0.75, 0.75),
        boxWidth = 200,
        center = true,
    },
    body = {
        font = "font/terminus8.fnt",
        color = KColor(1, 1, 1, 1),
        offset = Vector(0, 0),
        pos = Vector(250, 100),
        scale = Vector(1, 1),
        boxWidth = 0,
        center = false,
    },
}

-- Debug strings
local str1 = ''
local str2 = ''
local str3 = ''

-- Check if table contains value
local function contains(tbl, val)
    for _, v in pairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end


-- TODO: This will likely become an onEvent function once finalized
-- Update collectedItemIDs list with ID of every currently held collectible
local function updateHeldCollectibles()
    local player = Isaac.GetPlayer(0)
    local index = 1

    -- Remove items the player no longer has 
    while index <= #collectedItemIDs do
        if not player:HasCollectible(collectedItemIDs[index]) then
            -- Do not increments on same index removed, otherwise we skip an item
            table.remove(collectedItemIDs, index)
            table.remove(collectedItemSprites, index)
        else
            index = index + 1
        end
    end
    
    -- Get player's active & passive items
    for i=1, NUM_ITEMS do
        if player:HasCollectible(i) then
            local item = Isaac.GetItemConfig():GetCollectible(i)
            
            if not contains(collectedItemIDs, item.ID) then
                table.insert(collectedItemIDs, item.ID)
                table.insert(collectedItemSprites, Sprite())
            end
        end
    end

end

local function getItemText(id)
    local item = require('resources/items/'..tostring(id)..'.lua')
    Isaac.DebugString(item.title)
    Isaac.DebugString(item.id)
    Isaac.DebugString(item.description[1])
end

-- Resize text as needed to render within text's limits
local function fitText(str)

end

-- settings is a table with the same properties as textAttrs.header/subheader/body
local function renderText(str, settings)
    local f = Font()
    f:Load(settings.font)
    f:DrawStringScaled(str, settings.pos.X, settings.pos.Y, settings.scale.X, settings.scale.Y, settings.color, settings.boxWidth, settings.center)
end

-- Handles displaying all relevant text of selected item
local function renderSelectedItemText()
    -- Index of selected item in collectedItemIDs
    local index = (menuCursorPos.Y - 1) * itemMenuAttrs.layout.X + menuCursorPos.X + menuItemsOffset
    local item = require('resources/items/'..tostring(collectedItemIDs[index])..'.lua')

    renderText(item.title, textAttrs.header)
    renderText("Item ID: "..item.id, textAttrs.subheader)


    -- local yOffset = f:GetLineHeight()
    -- for i, str in ipairs(item.description) do
    --     f:DrawStringScaled(str, itemTextAttrs.body.pos.X, (i * yOffset + itemTextAttrs.body.pos.Y), scale.X, scale.Y, KColor(1, 1, 1, 1), itemTextAttrs.body.boxWidth, itemTextAttrs.body.center)
    -- end

end

-- Render the collected item's icons to the menu screen
-- Offset is number denoting starting position in collectedItemSprites table
--      Used to display items when there are more than can fit on one screen
local function renderMenuItems(offset)
    -- Ensure player has at least one item to render
    if collectedItemIDs[1] then
        local itemPosInMenu
        local index
        local item

        for i=1, itemMenuAttrs.layout.Y do
            for j=1, itemMenuAttrs.layout.X do
                index = (i - 1) * itemMenuAttrs.layout.X + j + offset
                -- Render a player's item if available
                if collectedItemSprites[index] then
                    item = collectedItemSprites[index]
                    item:Load("gfx/ui/menuitem.anm2", true)
                    item:ReplaceSpritesheet(0, Isaac.GetItemConfig():GetCollectible(collectedItemIDs[index]).GfxFileName)
                    item:LoadGraphics()
                    item:SetFrame("Idle", 0)

                    itemPosInMenu = Vector(itemMenuAttrs.spacing.X * j + itemMenuAttrs.origin.X, 
                        itemMenuAttrs.spacing.Y * i + itemMenuAttrs.origin.Y)

                    item:RenderLayer(0, Isaac.WorldToRenderPosition(itemPosInMenu))
                    item:SetOverlayRenderPriority(true)
                -- If no items available, render nothing
                else
                    item:Load("gfx/ui/menuitem.anm2", true)
                    item:SetFrame("Active", 0)
                    item:LoadGraphics()

                    itemPosInMenu = Vector(itemMenuAttrs.spacing.X * j + itemMenuAttrs.origin.X, 
                        itemMenuAttrs.spacing.Y * i + itemMenuAttrs.origin.Y)

                    -- Layer 0 is transparency layer, 1 is gray bg, 2 is square brackets
                    -- item:RenderLayer(0, Isaac.WorldToRenderPosition(itemPosInMenu))

                    item:RenderLayer(0, Isaac.WorldToRenderPosition(itemPosInMenu))
                    
                end
            end
        end
    end
end

function mod:onRender()
    local player = Isaac.GetPlayer(0)

    if Input.IsButtonPressed(Keyboard.KEY_N, 0) then
        renderSelectedItemText()
    end

    if Input.IsButtonTriggered(Keyboard.KEY_J, 0) and not Game():IsPaused() then
        menuOpen = not menuOpen
        -- Reset cursor to beginning when menu is closed
        menuCursorPos = Vector(1, 1)
        menuItemsOffset = 0
    end

    if menuOpen then
        -- Close menu
        if Input.IsActionTriggered(ButtonAction.ACTION_MENUBACK, 0) then
            menuOpen = false
            menuCursorPos = Vector(1, 1)
            menuItemsOffset = 0
        end

        updateHeldCollectibles()
        
        -- Create menu that items will be drawn on upon
        -- itemMenu.Scale = itemMenuAttrs.scale
        itemMenu:SetFrame("Idle", 0)
        itemMenu:RenderLayer(0, Isaac.WorldToRenderPosition(itemMenuAttrs.pos))

        renderMenuItems(menuItemsOffset)

        renderSelectedItemText()

        -- The game is not actually "paused", the player's inputs are essentially hijacked though
        --      Basically, you can still be attacked by enemies while this menu is open
        if not Game():IsPaused() then
            -- Move cursor down
            if Input.IsActionTriggered(ButtonAction.ACTION_MENUDOWN, 0) then
                menuCursorPos.Y = menuCursorPos.Y + 1

                -- Moving beyond bounds current menu page
                if menuCursorPos.Y > itemMenuAttrs.layout.Y then
                    -- There are enough items to render another page
                    if #collectedItemIDs > menuItemsOffset + (itemMenuAttrs.layout.X * itemMenuAttrs.layout.Y) then
                        menuItemsOffset = menuItemsOffset + (itemMenuAttrs.layout.X * itemMenuAttrs.layout.Y)  
                    -- Not enough items to render another page, wrap around to initial page
                    elseif #collectedItemIDs <= menuItemsOffset + (itemMenuAttrs.layout.X * itemMenuAttrs.layout.Y) and menuItemsOffset > 0 then
                        menuItemsOffset = 0
                    end
                    menuCursorPos.Y = 1 
                    -- We could call renderMenuItems(), but it shouldn't be necessary within onRender()
                    -- Isaac.DebugString('Offset in menu - '..tostring(menuItemsOffset))
                    -- renderMenuItems(menuItemsOffset)
                end

            end
            -- Move cursor up
            if Input.IsActionTriggered(ButtonAction.ACTION_MENUUP, 0) then
                menuCursorPos.Y = menuCursorPos.Y - 1
                if menuCursorPos.Y < 1 then
                    -- Move to previous "page"/layout
                    if menuItemsOffset > 0 then
                        menuCursorPos.Y = itemMenuAttrs.layout.Y
                        menuItemsOffset = menuItemsOffset - (itemMenuAttrs.layout.X * itemMenuAttrs.layout.Y)
                    -- If there are more items than can be shown on one page, move to last page
                    elseif #collectedItemIDs > itemMenuAttrs.layout.X * itemMenuAttrs.layout.Y and menuItemsOffset == 0 then 
                        menuCursorPos.Y = itemMenuAttrs.layout.Y
                        --  Offset + 16 gives the index of every item that will be rendered with that offset 
                        -- Ex: ceil(49 items / (4 * 4)) = 4.     4 - 1 = 3.      3 * 4 * 4 = 48, exactly the offset the 49th item should have
                        menuItemsOffset = math.ceil(#collectedItemIDs / (itemMenuAttrs.layout.X * itemMenuAttrs.layout.Y) - 1) * itemMenuAttrs.layout.X * itemMenuAttrs.layout.Y
                    end
                end
            end
            -- Move cursor right
            if Input.IsActionTriggered(ButtonAction.ACTION_MENURIGHT, 0) then
                menuCursorPos.X = menuCursorPos.X + 1
                if menuCursorPos.X > itemMenuAttrs.layout.X then
                    menuCursorPos.X = 1
                end
            end
            -- Move cursor left
            if Input.IsActionTriggered(ButtonAction.ACTION_MENULEFT, 0) then
                menuCursorPos.X = menuCursorPos.X - 1
                if menuCursorPos.X < 1 then
                    menuCursorPos.X = itemMenuAttrs.layout.X
                end
            end
        end
        
        -- Render cursor
        local cursor = Sprite()

        cursor:Load("gfx/ui/menuitem.anm2", true)
        cursor:SetFrame("Idle", 0)
        cursor:LoadGraphics()

        local cursorDrawPos = Vector(itemMenuAttrs.spacing.X * menuCursorPos.X + itemMenuAttrs.origin.X, 
        itemMenuAttrs.spacing.Y * menuCursorPos.Y + itemMenuAttrs.origin.Y)

        -- cursor:SetOverlayRenderPriority(true)
        cursor:RenderLayer(2, Isaac.WorldToRenderPosition(cursorDrawPos))
    end
end

function mod:onInput(entity, hook, button)
	if menuOpen and entity ~= nil then
		if hook == InputHook.GET_ACTION_VALUE then
			return 0
		else
			return false
		end
	end
end

function mod:debugText()
    Isaac.RenderText(str1, 100, 100, 255, 0, 0, 255)
    Isaac.RenderText(str2, 100, 125, 0, 255, 0, 255)
    Isaac.RenderText(str3, 300, 150, 0, 0, 255, 255)
end

-- function mod:onNewRoom()
--     heldCollectibles()
-- end

-- Callbacks

mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.debugText)

mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, mod.onInput)
-- mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.onNewRoom)
-- Add a callback for on game init and newroom is more than sufficient

-- When to refresh collectedItems?
--   POST_UPDATE/POST_PLAYER_UPDATE/NEW_ROOM/EVAL_CACHE
--      POST_UPDATE called 30x per second, not called when paused
--      POST_PICKUP_UPDATE called 60x per second, not called when paused
--      NEW_ROOM should determine if it works for ALL rooms or only on first entry

-- POST_PICKUP_INIT is useful if we can detect items on the floor somehow