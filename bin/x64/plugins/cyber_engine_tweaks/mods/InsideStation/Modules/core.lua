local HUD = require('Modules/hud.lua')

local Core = {}
Core.__index = Core

function Core:New()
    -- instance --
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "Core")
    obj.hud_obj = HUD:New()
    -- static --
    obj.area_check_interval = 0.2
    -- dynamic --
    return setmetatable(obj, self)
end

function Core:Initialize()

    Observe("DataTerm", "OnAreaEnter", function(this, evt)
        self.log_obj:Record(LogLevel.Info, "DataTerm OnAreaEnter")
        this:OpenSubwayGate()
    end)

    Observe("DataTerm", "OnAreaExit", function(this, evt)
        self.log_obj:Record(LogLevel.Info, "DataTerm OnAreaExit")
        this:CloseSubwayGate()
    end)

    Cron.Every(self.area_check_interval, {tick = 1}, function()
        local area_code = self:CheckArea()
        if area_code == Def.AreaCodeInSt.Entrance then
            self.hud_obj:ShowChoice(Def.ChoiceVariation.Enter, 1)
        elseif area_code == Def.AreaCodeInSt.Platform then
            self.hud_obj:ShowChoice(Def.ChoiceVariation.Exit, 1)
        else 
            self.hud_obj:HideChoice()
        end
    end)

end

function Core:CheckArea()

    local player = Game.GetPlayer()
    local player_pos = player:GetWorldPosition()
    local active_station_id = self:GetStationID()
    for _, area_info in ipairs(Data.EntryArea) do
        if active_station_id == area_info.st_id then
            local distance = Vector4.Distance(player_pos, Vector4.new(area_info.pos.x, area_info.pos.y, area_info.pos.z, 1))
            if distance < area_info.r then
                return Def.AreaCodeInSt.Entrance
            end
        end
    end
    for _, area_info in ipairs(Data.ExitArea) do
        if active_station_id == area_info.st_id then
            local distance = Vector4.Distance(player_pos, Vector4.new(area_info.pos.x, area_info.pos.y, area_info.pos.z, 1))
            if distance < area_info.r then
                return Def.AreaCodeInSt.Platform
            end
        end
    end
    return Def.AreaCodeInSt.None

end

function Core:GetStationID()
    return Game.GetQuestsSystem():GetFact(CName.new("ue_metro_active_station"))
end

return Core