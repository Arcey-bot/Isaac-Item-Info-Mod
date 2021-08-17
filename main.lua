local mod = RegisterMod("Item Info", 1)

-- Highest valid Item ID in this game's version
local NUM_COLLECTIBLES = CollectibleType.NUM_COLLECTIBLES - 1
local NUM_TRINKETS = TrinketType.NUM_TRINKETS - 1

-- TODO: Description text scrolling

-- Table holding Active/Passive/Trinkets in Isaac's inventory
local collectedItems = {}
-- Table holding ID of Active/Passive/Trinkets in Isaac's inventory
local collectedItemIDs = {
    collectibles = {},
    trinkets = {},
}
-- Table holding sprite of every item owned
local collectedItemSprites = {}

local floorItems = {}
local floorItemIDs = {}
local floorItemSprites = {}

local heldMenuOpen = false
local floorMenuOpen = false

local menuCursorPos = Vector(1, 1)
-- Offset 0 shows items 1-16, 1 shows items 17-32, etc.
local menuItemsOffset = 0
local itemMenu = Sprite()
itemMenu:Load("gfx/ui/itemmenu.anm2", true)

local itemMenuAttrs = {
    -- Where to create the menu
    pos = Vector(30, 150),
    scale = Vector(0.7, 0.7),

    -- Where to begin drawing items ON the menu
    origin = Vector(-12, 105),
    spacing = Vector(55, 55),

    -- Number of columns and rows to display items in 
    layout = Vector(4, 4)
}

local textAttrs = {
    header = {
        font = "font/upheaval.fnt",
        color = KColor(1, 1, 1, 1),
        offset = Vector(0, 0),
        pos = Vector(240, 45),
        scale = Vector(1, 1),
        boxWidth = 200,
        center = true,
        writer = Font(),
    },
    body = {
        font = "font/pftempestasevencondensed.fnt",
        color = KColor(1, 1, 1, 1),
        offset = Vector(0, 0),
        pos = Vector(240, 75),
        scale = Vector(1, 1),
        boxWidth = 0,
        center = false,
        writer = Font(),
    },
}

textAttrs.header.writer:Load(textAttrs.header.font)
textAttrs.body.writer:Load(textAttrs.body.font)

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

local function updateHeldTrinkets()
    local player = Isaac.GetPlayer(0)
    local index = 1

    while index <= #collectedItems do
        -- This can be the ID of a trinket
        if collectedItems[index]:IsTrinket() then
            -- Isaac no longer has this trinket
            if not player:HasTrinket(collectedItemIDs[index]) then
                collectedItemIDs.trinkets[collectedItemIDs[index]] = nil
                table.remove(collectedItems, index)
                table.remove(collectedItemIDs, index)
                table.remove(collectedItemSprites, index)
                index = index - 1
            end
        end
        index = index + 1
    end
    
    for i=1, NUM_TRINKETS do
        if player:HasTrinket(i) then
            local trinket = Isaac.GetItemConfig():GetTrinket(i)

            if not collectedItemIDs.trinkets[trinket.ID] then
                table.insert(collectedItems, trinket)
                table.insert(collectedItemIDs, trinket.ID)
                table.insert(collectedItemSprites, Sprite())
                collectedItemIDs.trinkets[trinket.ID] = trinket.ID
            end
        end
    end
end

-- Update collectedItemIDs list with ID of every currently held collectible (Actives/Passives)
local function updateHeldCollectibles()
    local player = Isaac.GetPlayer(0)
    local index = 1

    -- Remove items the player no longer has 
    while index <= #collectedItemIDs do
        -- This can be the ID of a collectible
        if collectedItems[index]:IsCollectible() then
            -- Isaac no longer has this collectible
            if not player:HasCollectible(collectedItemIDs[index]) then
                -- Do not increment on same index removed, otherwise we skip an item
                collectedItemIDs.collectibles[collectedItemIDs[index]] = nil
                table.remove(collectedItemIDs, index)
                table.remove(collectedItemSprites, index)
                table.remove(collectedItems, index)
                index = index - 1
            end 
        end
        index = index + 1
    end
    
    -- Get player's active & passive items
    for i=1, NUM_COLLECTIBLES do
        if player:HasCollectible(i) then
            local item = Isaac.GetItemConfig():GetCollectible(i)
            
            if not collectedItemIDs.collectibles[item.ID] then
                table.insert(collectedItemIDs, item.ID)
                table.insert(collectedItemSprites, Sprite())
                table.insert(collectedItems, item)
                collectedItemIDs.collectibles[item.ID] = item.ID
            end
        end

    end
end

-- settings is a table with the same properties as textAttrs.header/body
local function renderText(str, settings --[[table]])
    settings.writer:DrawStringScaled(str, settings.pos.X + settings.offset.X, settings.pos.Y + settings.offset.Y, settings.scale.X, settings.scale.Y, settings.color, settings.boxWidth, settings.center)
end

-- Handles displaying all relevant text of selected item
local function renderSelectedItemText(collection --[[table]], collectionIDs --[[table]])
    -- Index of selected item in collectedItemIDs
    local index = (menuCursorPos.Y - 1) * itemMenuAttrs.layout.X + menuCursorPos.X + menuItemsOffset
    -- local item = require('resources/items/collectibles/'..tostring(collectedItemIDs[index])..'.lua')
    local item 

    -- TODO: I would love to make this not look like eye vomit. More like the declaration above
    if collection[index] then
        if collection[index]:IsCollectible() then
            item = require('resources/items/collectibles/'..tostring(collectionIDs[index])..'.lua')
        else
            item = require('resources/items/trinkets/'..tostring(collectionIDs[index])..'.lua')
        end
    else
        item = require('resources/items/collectibles/nil.lua')
    end
    renderText(item.title, textAttrs.header)

    local yOffset = 16
    for _, str in ipairs(item.description) do
        renderText(str, textAttrs.body)
        textAttrs.body.offset.Y = yOffset + textAttrs.body.offset.Y 
    end
    textAttrs.body.offset.Y = 0
end

-- Render the collected item's icons to the menu screen
-- Offset is number denoting starting position in collectedItemSprites table
--      Used to display items when there are more than can fit on one screen
local function renderMenuItems(collection --[[table]], collectionSprites --[[table]], offset --[[int]])
    -- Ensure player has at least one item to render
    if next(collection) then
        local itemPosInMenu
        local index
        local item

        for i=1, itemMenuAttrs.layout.Y do
            for j=1, itemMenuAttrs.layout.X do
                index = (i - 1) * itemMenuAttrs.layout.X + j + offset
                -- Render a player's item if available
                if collectionSprites[index] then
                    item = collectionSprites[index]
                    item:Load("gfx/ui/menuitem.anm2", true)
                    item:ReplaceSpritesheet(0, collection[index].GfxFileName)
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

local function handleCursorMovement()
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
                    else
                        menuItemsOffset = 0
                    end
                    menuCursorPos.Y = 1 
                end

            end
            -- Move cursor up
            if Input.IsActionTriggered(ButtonAction.ACTION_MENUUP, 0) then
                menuCursorPos.Y = menuCursorPos.Y - 1
                if menuCursorPos.Y < 1 then
                    -- There is a previous "page"/layout to move to
                    if menuItemsOffset > 0 then
                        menuItemsOffset = menuItemsOffset - (itemMenuAttrs.layout.X * itemMenuAttrs.layout.Y)
                    -- If there are more items than can be shown on first page, move to last page
                    else
                        --  Offset + 16 gives the index of every item that will be rendered with that offset 
                        -- Ex: ceil(49 items / (4 * 4)) = 4.     4 - 1 = 3.      3 * 4 * 4 = 48, exactly the offset the 49th item should have
                        menuItemsOffset = math.ceil(#collectedItemIDs / (itemMenuAttrs.layout.X * itemMenuAttrs.layout.Y) - 1) * itemMenuAttrs.layout.X * itemMenuAttrs.layout.Y
                    end
                    menuCursorPos.Y = itemMenuAttrs.layout.Y
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
end

local function renderMenuCursor()
    local cursor = Sprite()
    cursor:Load("gfx/ui/menuitem.anm2", true)
    cursor:SetFrame("Idle", 0)
    cursor:LoadGraphics()
    local cursorDrawPos = Vector(itemMenuAttrs.spacing.X * menuCursorPos.X + itemMenuAttrs.origin.X, 
    itemMenuAttrs.spacing.Y * menuCursorPos.Y + itemMenuAttrs.origin.Y)
    -- cursor:SetOverlayRenderPriority(true)
    cursor:RenderLayer(2, Isaac.WorldToRenderPosition(cursorDrawPos))
end

function mod:onRender()
    if Input.IsButtonTriggered(Keyboard.KEY_J, 0) and not Game():IsPaused() then
        updateHeldCollectibles()
        updateHeldTrinkets()
        heldMenuOpen = not heldMenuOpen
        -- Reset cursor to beginning when menu is closed
        menuCursorPos = Vector(1, 1)
        menuItemsOffset = 0
    end

    if Input.IsButtonTriggered(Keyboard.KEY_N, 0) and not Game():IsPaused() then
        -- TODO: This is pretty damn ugly too
        for _, v in ipairs(Isaac.GetRoomEntities()) do
            -- It is something we can pickup
            if v.Type == EntityType.ENTITY_PICKUP then
                -- It is a collectible
                if v.Variant == PickupVariant.PICKUP_COLLECTIBLE then
                    local item = Isaac.GetItemConfig():GetCollectible(v.SubType)

                    table.insert(floorItems, item)
                    table.insert(floorItemIDs, item.ID)
                    table.insert(floorItemSprites, Sprite())
                -- It is a trinket
                elseif v.Variant == PickupVariant.PICKUP_TRINKET then
                    local item = Isaac.GetItemConfig():GetTrinket(v.SubType)

                    table.insert(floorItems, item)
                    table.insert(floorItemIDs, item.ID)
                    table.insert(floorItemSprites, Sprite())
                end
            end
        end

        floorMenuOpen = not floorMenuOpen
        menuCursorPos = Vector(1, 1)
        menuItemsOffset = 0

        if not floorMenuOpen then
            floorItems = {}
            floorItemIDs = {}
            floorItemSprites = {}
        end
    end

    if heldMenuOpen then
        -- Close menu
        if Input.IsActionTriggered(ButtonAction.ACTION_MENUBACK, 0) then
            heldMenuOpen = false
            menuCursorPos = Vector(1, 1)
            menuItemsOffset = 0
        end
       
        -- Create menu that items will be drawn on upon
        itemMenu:SetFrame("Idle", 0)
        itemMenu:RenderLayer(0, Isaac.WorldToRenderPosition(itemMenuAttrs.pos))

        renderMenuItems(collectedItems, collectedItemSprites, menuItemsOffset)
        renderSelectedItemText(collectedItems, collectedItemIDs)
        handleCursorMovement()
        renderMenuCursor()

    elseif floorMenuOpen then
        if Input.IsActionTriggered(ButtonAction.ACTION_MENUBACK, 0) then
            floorMenuOpen = false
            menuCursorPos = Vector(1, 1)
            menuItemsOffset = 0
        end
       
        -- Create menu that items will be drawn on upon
        itemMenu:SetFrame("Idle", 0)
        itemMenu:RenderLayer(0, Isaac.WorldToRenderPosition(itemMenuAttrs.pos))

        renderMenuItems(floorItems, floorItemSprites, menuItemsOffset)
        renderSelectedItemText(floorItems, floorItemIDs)
        handleCursorMovement()
        renderMenuCursor()
    end
end

function mod:onInput(entity, hook, button)
	if heldMenuOpen and entity ~= nil then
		if hook == InputHook.GET_ACTION_VALUE then
			return 0
		else
			return false
		end
	end
end

function mod:debugText()
    Isaac.RenderText(str1, 75, 50, 255, 0, 0, 255)
    Isaac.RenderText(str2, 75, 75, 0, 255, 0, 255)
    Isaac.RenderText(str3, 200, 50, 0, 0, 255, 255)
end

-- Callbacks

mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.debugText)

mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, mod.onInput)
