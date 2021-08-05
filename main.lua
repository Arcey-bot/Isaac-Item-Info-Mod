local mod = RegisterMod("Item Info", 1)

-- Highest valid Item ID in this game's version
local NUM_ITEMS = Isaac.GetItemConfig():GetCollectibles().Size - 1

-- Table holding Item object of every item owned
local collectedItems = {}
-- Table holding ID of every item owned
local collectedItemIDs = {}

local str = 'Hello'
local str2 = ''
local str3 = ''

local itemAvail = false

-- Check if table contains value
local function contains(tbl, val)
    for _, v in pairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

-- Update collectedItemIDs list with ID of every currently held collectible
local function heldCollectibles()
    local player = Isaac.GetPlayer(0)

    for i=1, NUM_ITEMS do
        if player:HasCollectible(i) then
            local item = Isaac.GetItemConfig():GetCollectible(i)

            if not contains(collectedItemIDs, item.ID) then
                table.insert(collectedItems, item)
                table.insert(collectedItemIDs, item.ID)
                itemAvail = true
            end
        end
    end
end

function mod:onRender()
    -- local player = Isaac.GetPlayer(0)

    -- if Input.IsButtonTriggered(Keyboard.KEY_J, 0) then       
    --     str = 'Checking'

    --     -- Ensure our item table is up to date
    --     heldCollectibles()

    --     Isaac.DebugString('Items table size - '..tostring(#collectedItems))

    --     -- Ensure table is not empty 
    --     if next(collectedItems) ~= nil then
    --         for i=1, #collectedItemIDs do
    --             Isaac.DebugString('Players has item - '..tostring(collectedItems[i].Name))
    --         end
    --     else
    --         Isaac.DebugString('Table empty - no data to display')
    --     end    
    -- end

    -- str = 'Completed'

    -- -- Try to display the sprite
    -- if itemAvail then
    --     pic:Load("gfx/ui/menuitem.anm2", true)
    --     -- pic:ReplaceSpriteSheet(0, collectedItems[1].GfxFileName)
    --     pic:LoadGraphics()
    --     pic:SetOverlayRenderPriority(true)
    --     pic:Render(Vector(75,75), Vector(0,0), Vector(0,0))
    --     pic:SetOverlayRenderPriority(true)
    --     pic:RenderLayer(0, Isaac.WorldToRenderPosition(Vector(75,100)))
    -- end

    
    -- THIS WORKS FUCK

    if Input.IsButtonPressed(Keyboard.KEY_J, 0) then
        local sprite = Sprite()
        sprite:Load("gfx/ui/menuitem.anm2", true)
        sprite:ReplaceSpritesheet(0, "gfx/collectibles_004_cricketshead.png")
        sprite:LoadGraphics()
        sprite:SetFrame("Idle", 0)
        -- sprite:Render(Vector(75,75), Vector(0,0), Vector(0,0))
        sprite:SetOverlayRenderPriority(true)
        sprite:RenderLayer(0, Isaac.WorldToRenderPosition(Vector(75,100)))
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
