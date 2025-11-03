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
	version = "2.4.0",
    is_debug_mode = false,
    -- version check
    cet_required_version = 36.0, -- 1.36.0
    cet_version_num = 0,
}

registerForEvent('onInit', function()
    if not InsideStation:CheckDependencies() then
        print('[ITS][Error] Inside The Station Mod failed to load due to missing dependencies.')
        return
    end

    -- InsideStation.core_obj = Core:New()
    InsideStation.debug_obj = Debug:New()
    InsideStation.log_obj = Log:New()
    InsideStation.log_obj:SetLevel(LogLevel.Info, "Core")

    -- InsideStation.core_obj:Initialize()
    Observe("DataTerm", "OnAreaEnter", function(this, evt)
        InsideStation.log_obj:Record(LogLevel.Trace, "DataTerm OnAreaEnter")
        local tags = this.tags.tags
        if tags ~= nil and #tags > 0 then
            local tag_str = ""
            tag_str = tags[1].value
            if tag_str == "MetroGateNoOpen" then
                InsideStation.log_obj:Record(LogLevel.Trace, "MetroGateNoOpen tag detected, skipping gate open")
                return
            end
        end
        this:OpenSubwayGate()
    end)

    Observe("DataTerm", "OnAreaExit", function(this, evt)
        InsideStation.log_obj:Record(LogLevel.Trace, "DataTerm OnAreaExit")
        local tags = this.tags.tags
        if tags ~= nil and #tags > 0 then
            local tag_str = ""
            tag_str = tags[1].value
            if tag_str == "MetroGateNoOpen" then
                InsideStation.log_obj:Record(LogLevel.Trace, "MetroGateNoOpen tag detected, skipping gate close")
                return
            end
        end
        this:CloseSubwayGate()
    end)

    print('[ITS][INFO] Inside The Station Mod is ready!')
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
        print("[ITS][Error] Inside The Station Mod requires Cyber Engine Tweaks version 1." .. InsideStation.cet_required_version .. " or higher.")
        return false
    end
    return true
end

function InsideStation:ToggleDebugMode()
    self.is_debug_mode = not self.is_debug_mode
    if self.is_debug_mode then
        print("[ITS][INFO] Debug Mode Enabled")
    else
        print("[ITS][INFO] Debug Mode Disabled")
    end
end

return InsideStation