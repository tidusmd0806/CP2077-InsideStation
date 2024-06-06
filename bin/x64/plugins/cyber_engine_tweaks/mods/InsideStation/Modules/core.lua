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
    obj.mappin_check_interval = 2
    obj.teleport_resolution = 0.01
    obj.teleport_division_num = 5
    -- dynamic --
    obj.entry_area_index = 0
    obj.exit_area_index = 0
    return setmetatable(obj, self)
end

function Core:Initialize()

    self.hud_obj:Initialize()

    Observe("PlayerPuppet", "OnAction", function(this, action, consumer)
        local action_name = action:GetName(action).value
		local action_type = action:GetType(action).value
        local action_value = action:GetValue(action)

        self.log_obj:Record(LogLevel.Debug, "Action Name: " .. action_name .. " Type: " .. action_type .. " Value: " .. action_value)

        if not self:IsInChoiceArea() then
            return
        end

        if action_name == "ChoiceApply" and action_type == "BUTTON_PRESSED" then
            self:Teleport()
        end

    end)

    Observe("DataTerm", "OnAreaEnter", function(this, evt)
        self.log_obj:Record(LogLevel.Info, "DataTerm OnAreaEnter")
        this:OpenSubwayGate()
    end)

    Observe("DataTerm", "OnAreaExit", function(this, evt)
        self.log_obj:Record(LogLevel.Info, "DataTerm OnAreaExit")
        this:CloseSubwayGate()
    end)

    -- area check
    Cron.Every(self.area_check_interval, {tick = 1}, function()
        local area_code = self:CheckTeleportAreaType()
        if area_code == Def.TeleportAreaType.EntranceChoice then
            self.hud_obj:ShowChoice(Def.ChoiceVariation.Enter, 1)
        elseif area_code == Def.TeleportAreaType.PlatformChoice then
            self.hud_obj:ShowChoice(Def.ChoiceVariation.Exit, 1)
        else
            self.hud_obj:HideChoice()
        end
    end)

    -- mappin update
    Cron.Every(self.mappin_check_interval, {tick = 1}, function()
        self.hud_obj:UpdateMappins()
    end)

end

function Core:CheckTeleportAreaType()

    local player = Game.GetPlayer()
    local player_pos = player:GetWorldPosition()
    local active_station_id = self:GetStationID()
    for index, area_info in ipairs(Data.EntryArea) do
        if active_station_id == area_info.st_id then
            local distance = Vector4.Distance(player_pos, Vector4.new(area_info.pos.x, area_info.pos.y, area_info.pos.z, 1))
            if distance < area_info.r_1 then
                if area_info.is_choice_ui then
                    self.entry_area_index = index
                    self.exit_area_index = 0
                    self.hud_obj:SetTeleportAreaType(Def.TeleportAreaType.EntranceChoice)
                    return Def.TeleportAreaType.EntranceChoice
                else
                    self.entry_area_index = index
                    self.exit_area_index = 0
                    self.hud_obj:SetTeleportAreaType(Def.TeleportAreaType.EntranceImmediately)
                    self:Teleport()
                    return Def.TeleportAreaType.EntranceImmediately
                end
            end
        end
    end
    for index, area_info in ipairs(Data.ExitArea) do
        if active_station_id == area_info.st_id then
            local distance = Vector4.Distance(player_pos, Vector4.new(area_info.pos.x, area_info.pos.y, area_info.pos.z, 1))
            if distance < area_info.r_1 then
                if area_info.is_choice_ui then
                    self.entry_area_index = 0
                    self.exit_area_index = index
                    self.hud_obj:SetTeleportAreaType(Def.TeleportAreaType.PlatformChoice)
                    return Def.TeleportAreaType.PlatformChoice
                else
                    self.entry_area_index = 0
                    self.exit_area_index = index
                    self.hud_obj:SetTeleportAreaType(Def.TeleportAreaType.PlatformImmediately)
                    self:Teleport()
                    return Def.TeleportAreaType.PlatformImmediately
                end
            end
        end
    end
    self.hud_obj:SetTeleportAreaType(Def.TeleportAreaType.None)
    return Def.TeleportAreaType.None

end

function Core:Teleport()

    local player = Game.GetPlayer()
    local new_pos
    local new_angle
    if self.entry_area_index ~= 0 and self.exit_area_index == 0 then
        new_pos = Vector4.new(Data.EntryArea[self.entry_area_index].telepos.x, Data.EntryArea[self.entry_area_index].telepos.y, Data.EntryArea[self.entry_area_index].telepos.z, 1)
        new_angle = EulerAngles.new(Data.EntryArea[self.entry_area_index].tele_angle.roll, Data.EntryArea[self.entry_area_index].tele_angle.pitch, Data.EntryArea[self.entry_area_index].tele_angle.yaw)
    elseif self.entry_area_index == 0 and self.exit_area_index ~= 0 then
        new_pos = Vector4.new(Data.ExitArea[self.exit_area_index].telepos.x, Data.ExitArea[self.exit_area_index].telepos.y, Data.ExitArea[self.exit_area_index].telepos.z, 1)
        new_angle = EulerAngles.new(Data.ExitArea[self.exit_area_index].tele_angle.roll, Data.ExitArea[self.exit_area_index].tele_angle.pitch, Data.ExitArea[self.exit_area_index].tele_angle.yaw)
    else
        self.log_obj:Record(LogLevel.Critical, "Unexpected teleportation area index")
        return
    end
    local player_pos = player:GetWorldPosition()
    self:PlayFTEffect()
    Cron.After(1, function()
        Cron.Every(self.teleport_resolution, {tick = 1}, function(timer)
            local new_pos_tmp = Vector4.new(timer.tick / self.teleport_division_num * new_pos.x + (1 - timer.tick / self.teleport_division_num) * player_pos.x, timer.tick / self.teleport_division_num * new_pos.y + (1 - timer.tick / self.teleport_division_num) * player_pos.y, timer.tick / self.teleport_division_num * new_pos.z + (1 - timer.tick / self.teleport_division_num) * player_pos.z, 1)
            Game.GetTeleportationFacility():Teleport(player, new_pos_tmp, new_angle)
            if timer.tick == self.teleport_division_num then
                timer:Halt()
                return
            end
            timer.tick = timer.tick + 1
        end)
    end)

end

function Core:PlayFTEffect()
    GameObjectEffectHelper.StartEffectEvent(Game.GetPlayer(), "fast_travel_glitch", true, worldEffectBlackboard.new())
end

function Core:GetStationID()
    return Game.GetQuestsSystem():GetFact(CName.new("ue_metro_active_station"))
end

function Core:IsInChoiceArea()
    if self.hud_obj.teleport_area_type == Def.TeleportAreaType.EntranceChoice or self.hud_obj.teleport_area_type == Def.TeleportAreaType.PlatformChoice then
        return true
    else
        return false
    end
end

return Core