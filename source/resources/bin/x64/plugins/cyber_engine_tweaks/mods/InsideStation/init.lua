--------------------------------------------------------
-- CopyRight (C) 2024, tidusmd. All rights reserved.
-- This mod is under the MIT License.
-- https://opensource.org/licenses/mit-license.php
--------------------------------------------------------

Cron = require('External/Cron.lua')
Data = require("Etc/data.lua")
Def = require('Etc/def.lua')
GameUI = require('External/GameUI.lua')
Log = require("Etc/log.lua")

local Core = require('Modules/core.lua')
local Debug = require('Debug/debug.lua')

InsideStation = {
	description = "Inside The Station",
	version = "2.1.1",
    is_debug_mode = false,
    -- version check
    cet_required_version = 36.0, -- 1.36.0
    cet_version_num = 0,
}

registerForEvent('onInit', function()
    if not InsideStation:CheckDependencies() then
        print('[Error] Inside The Station Mod failed to load due to missing dependencies.')
        return
    end

    InsideStation.core_obj = Core:New()
    InsideStation.debug_obj = Debug:New(InsideStation.core_obj)

    InsideStation.core_obj:Initialize()

    print('Inside The Station Mod is ready!')
end)

registerForEvent("onDraw", function()
    if InsideStation.is_debug_mode then
        if InsideStation.debug_obj ~= nil then
            InsideStation.debug_obj:ImGuiMain()
        end
    end
end)

registerForEvent('onUpdate', function(delta)
    Cron.Update(delta)
end)

function InsideStation:CheckDependencies()
    -- Check Cyber Engine Tweaks Version
    local cet_version_str = GetVersion()
    local cet_version_major, cet_version_minor = cet_version_str:match("1.(%d+)%.*(%d*)")
    InsideStation.cet_version_num = tonumber(cet_version_major .. "." .. cet_version_minor)

    if InsideStation.cet_version_num < InsideStation.cet_required_version then
        print("Inside The Station Mod requires Cyber Engine Tweaks version 1." .. InsideStation.cet_required_version .. " or higher.")
        return false
    end
    return true
end

function InsideStation:ToggleDebugMode()
    self.is_debug_mode = not self.is_debug_mode
    if self.is_debug_mode then
        print("[Inside The Station] Debug Mode Enabled")
    else
        print("[Inside The Station] Debug Mode Disabled")
    end
end

return InsideStation