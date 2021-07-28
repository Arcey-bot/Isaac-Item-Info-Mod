local mod = RegisterMod("Item Info", 1)
local json = require("json")

local menuOpen = false
local itemMenu = Sprite()
itemMenu:Load("gfx/ui/loadoutmenu.anm2", true)

function mod:onRender()
    Isaac.DebugString('Calling render')
    if Input.IsButtonTriggered(Keyboard.KEY_J, 0) then
        menuOpen = not menuOpen
    end

    if menuOpen then
        itemMenu:SetFrame("Idle", 0) 
        itemMenu:RenderLayer(0, Isaac.WorldToRenderPosition(Vector(70,85)))
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

-- local function initMenu()

-- end

-- Callbacks

mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)
mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, mod.onInput)

