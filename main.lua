local mod = RegisterMod("Item Info", 1)
local json = require("json")

-- Highest valid Item ID in this game's version
local NUM_ITEMS = Isaac.GetItemConfig():GetCollectibles().Size - 1

-- TODO:

-- On first frame/initial load, run check to determine collected items
--    Save items in a json to read from when continuing?
-- Determine when to run check for new items again (Every new room perhaps?)
-- Store collected items in table, if size changes between frames, recheck items?
-- Ensure not to insert duplicate items when rechecking items

-- Pills/Cards/Trinkets not currently supported
-- (LAST) Remove lost items from item pool
-- Shader to darken screen slightly when opening menu?

-- An offset may be necessary to render items if there are more items held
--      than available spaces to display them in one menu

-- Table holding ID of every item owned
local collectedItemIDs = {}
-- Table holding sprite of every item owned
local collectedItemSprites = {}

local menuOpen = false
local itemMenu = Sprite()
itemMenu:Load("gfx/ui/itemmenu.anm2", true)

local itemMenuAttrs = {
    -- Where to create the menu
    pos = Vector(175, 240),
    scale = Vector(0.7, 0.7),

    -- Where to begin drawing items ON the menu
    origin = Vector(180, 245),
    spacing = Vector(25, 25),

    -- Number of columns and rows to display items in 
    layout = Vector(5, 4)
}

local itemMenuIconAttrs = {}

local itemDescAttrs = {
    pos = Vector(325, 60)
}

-- Debug strings
local str = ''
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
local function heldCollectibles()
    local player = Isaac.GetPlayer(0)

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

-- TODO: Will be a more abstract version of renderMenuItems to work with multiple 
--      kinds of data
local function renderMenuIcons(offset)
end

-- Render the collected item's icons to the menu screen
-- Offset is int denoting starting position in collectedItemSprites
--      Used to display items when there are more than can fit on one screen
local function renderMenuItems(offset)
    offset = offset or 0

    -- Ensure player has at least one item to render
    if collectedItemIDs[1] then
        local itemPosInMenu
        local index
        local item
        for i=1, itemMenuAttrs.layout.Y do
            for j=1, itemMenuAttrs.layout.X do
                index = (i - 1) * itemMenuAttrs.layout.X + j
                -- Ensure we do not try to render more items than we have
                if collectedItemSprites[offset + index] then
                    item = collectedItemSprites[offset + index]
                    item:Load("gfx/ui/menuitem.anm2", true)
                    item:ReplaceSpritesheet(0, Isaac.GetItemConfig():GetCollectible(collectedItemIDs[index]).GfxFileName)
                    item:LoadGraphics()
                    item:SetFrame("Idle", 0)

                    itemPosInMenu = Vector(itemMenuAttrs.spacing.X * j + itemMenuAttrs.origin.X, 
                        itemMenuAttrs.spacing.Y * i + itemMenuAttrs.origin.Y)

                    item:RenderLayer(0, Isaac.WorldToRenderPosition(itemPosInMenu))
                    -- item:SetOverlayRenderPriority(true)
                else
                    item:Load("gfx/ui/menuitem.anm2", true)
                    item:SetFrame("Active", 0)
                    item:LoadGraphics()

                    itemPosInMenu = Vector(itemMenuAttrs.spacing.X * j + itemMenuAttrs.origin.X, 
                        itemMenuAttrs.spacing.Y * i + itemMenuAttrs.origin.Y)

                    -- Layer 0 is transparency layer, 1 is gray bg, 2 is square brackets
                    -- item:RenderLayer(0, Isaac.WorldToRenderPosition(itemPosInMenu))

                    item:RenderLayer(2, Isaac.WorldToRenderPosition(itemPosInMenu))
                    
                end
            end
        end
    end
end

function mod:onRender()
    local player = Isaac.GetPlayer(0)

    if Input.IsButtonTriggered(Keyboard.KEY_J, 0) and not Game():IsPaused() then
        menuOpen = not menuOpen
    end

    if menuOpen then
        -- Close menu
        if Input.IsActionTriggered(ButtonAction.ACTION_MENUBACK, 0) then
            menuOpen = false
        end

        heldCollectibles()
        
        -- Create menu to load items on upon
        -- itemMenu.Scale = itemMenuAttrs.scale
        itemMenu:SetFrame("Idle", 0)
        itemMenu:RenderLayer(0, Isaac.WorldToRenderPosition(itemMenuAttrs.pos))

        -- Does not yet support item rows. Will just render all items in a single row infinitely

        renderMenuItems()


        -- UI movment logic goes here
        if not Game():IsPaused() then
            
        end

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
    Isaac.RenderText(str, 100, 100, 255, 0, 0, 255)
    Isaac.RenderText(str2, 100, 125, 0, 255, 0, 255)
    Isaac.RenderText(str3, 100, 150, 0, 0, 255, 255)
end


-- Callbacks

mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.debugText)

mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, mod.onInput)

-- When to refresh collectedItems?
--   POST_UPDATE/POST_PLAYER_UPDATE/NEW_ROOM/EVAL_CACHE
--      POST_UPDATE called 30x per second, not called when paused
--      POST_PLAYER_UPDATE called 60x per second, not called when paused
--      NEW_ROOM should determine if it works for ALL rooms or only on first entry

-- POST_PICKUP_INIT is useful if we can detect items on the floor somehow