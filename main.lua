local mod = RegisterMod("Item Info", 1)
local json = require("json")

-- If we check items that do not exist within the game, we will receive arbitrary T/F responses
local AfterbirthPlusItems = 552 -- Number of items in AB+
local RepentenceItems = 730 -- Number of items in Repentence


-- TODO:

-- On first frame/initial load, run check to determine collected items
--    Save items in a json to read from when continuing?
-- Determine when to run check for new items again (Every new room perhaps?)
-- Store collected items in table, if size changes between frames, recheck items?
-- Ensure not to insert duplicate items when rechecking items

-- (LAST) Remove lost items from item pool

local menuOpen = false
local itemMenu = Sprite()

-- Table holding ID of every item owned
local collectedItems = {}

local menuPos = Vector(70,85)

local str = 'Hello'
local extra = ''
local str2 = ''

itemMenu:Load("gfx/ui/itemmenu.anm2", true)

local function initMenu()
    itemMenu:SetFrame("Idle", 0)
    itemMenu:RenderLayer(0, Isaac.WorldToRenderPosition(menuPos))
end

-- Check if table contains value
local function contains(tbl, val)
    for _, v in pairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

local function savePlayerItems()
    local player = Isaac.GetPlayer(0)

    str = 'Checking...'

    for i=1, AfterbirthPlusItems do
        -- Save item if player owns it
        if player:HasCollectible(i) then
            local item = Isaac.GetItemConfig():GetCollectible(i)

            -- If we don't have the item saved, save it
            if not contains(collectedItems, item.ID) then
                Isaac.DebugString('Item already owned - '..item.Name)
            else
                table.insert(collectedItems, item.ID)
                Isaac.DebugString('Saved item - '..item.Name)
            end
        end
    end

    str = "Completed"
    str2 = #collectedItems
end

local function showPlayerItems()
    -- This literally only works for one item right now, it might render them over each other
    for i = 1, #collectedItems do
        local item = Sprite()
        item:Load("gfx/ui/menuitem.anm2", true)
        Isaac.DebugString(collectedItems[i].GfxFileName)
        -- -- Must load first, otherwise there is no spritesheet to replace
        item:ReplaceSpriteSheet(0, collectedItems[i].GfxFileName)
        -- -- item:Load(collectedItems[i].GfxFileName, true)
        item:LoadGraphics()
    end
end

function mod:onRender()
    if Input.IsButtonTriggered(Keyboard.KEY_J, 0) and not Game():IsPaused() then
        menuOpen = not menuOpen
    end

    if Input.IsButtonTriggered(Keyboard.KEY_L, 0) then
        savePlayerItems()
    end

    if menuOpen then
        -- Close menu
        if Input.IsActionTriggered(ButtonAction.ACTION_MENUBACK, 0) then
            menuOpen = false
        end

        local player = Isaac.GetPlayer(0)

        local stuff = {}

        for i=1, AfterbirthPlusItems do
            if player:HasCollectible(i) then
                table.insert(collectedItems, Isaac.GetItemConfig():GetCollectible(i))
                Isaac.DebugString('Isaac has item - '..collectedItems[i].Name)
            end
        end
        
        for i=1, #collectedItems do
            local tmp = Sprite()
            tmp:Load("gfx/ui/menuitem.anm2", true)
            table.insert(stuff, tmp)
        end

        for i=1, #collectedItems do
            -- Isaac.DebugString(collectedItems[i].GfxFileName)
            Isaac.DebugString('STUFF BREAKDOWN- ')
            for j=1, #stuff do
                Isaac.DebugString('Stuff '..j..' - '..tostring(stuff[j]))
            end
            Isaac.DebugString('ITEMS BREAKDOWN - '..type(collectedItems[i]))
            for j=1, #collectedItems do
                Isaac.DebugString('Stuff '..j..' - '..tostring(collectedItems[j]))
            end
            -- -- Must load first, otherwise there is no spritesheet to replace
            stuff[i]:ReplaceSpriteSheet(0, collectedItems[i].GfxFileName)
            stuff[i]:LoadGraphics()
            -- stuff[i].Render(Vector(100,100))
        end


        itemMenu:SetFrame("Idle", 0)
        itemMenu:RenderLayer(0, Isaac.WorldToRenderPosition(menuPos))

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
    extra = tostring(menuOpen)
    Isaac.RenderText(str, 100, 100, 255, 0, 0, 255)
    Isaac.RenderText(extra, 100, 125, 0, 255, 0, 255)
    Isaac.RenderText(str2, 100, 150, 0, 0, 255, 255)
end


-- Callbacks

mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.debugText)

mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, mod.onInput)
