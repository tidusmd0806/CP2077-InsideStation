local Debug = {}
Debug.__index = Debug

function Debug:New(core_obj)
    local obj = {}
    obj.core_obj = core_obj

    -- set parameters
    obj.is_im_gui_player_local = false
    obj.is_set_observer = false
    obj.is_im_gui_line_info = false
    obj.is_im_gui_station_info = false
    obj.is_im_gui_measurement = false
    obj.is_im_gui_ristrict = false
    return setmetatable(obj, self)
end

function Debug:ImGuiMain()

    ImGui.Begin("InsideStation DEBUG WINDOW")
    ImGui.Text("Debug Mode : On")

    self:SetObserver()
    self:SetLogLevel()
    self:SelectPrintDebug()
    self:ImGuiPlayerPosition()
    self:ImGuiLineInfo()
    self:ImGuiStationInfo()
    self:ImGuiMeasurement()
    self:ImGuiExcuteFunction()

    ImGui.End()

end

function Debug:SetObserver()

    if not self.is_set_observer then
        -- reserved
        -- Observe("DataTerm", "OnAreaEnter", function(this, evt)
        --     print("DataTerm OnAreaEnter")
        --     print(evt.componentName)
        --     this:OpenSubwayGate()
        -- end)

        -- Observe("DataTerm", "OnAreaExit", function(this, evt)
        --     print("DataTerm OnAreaExit")
        --     print(evt.componentName)
        --     this:CloseSubwayGate()
        -- end)

        -- Observe("QuestsSystem", "SetFact", function(this, factName, value)
        --     if string.find(factName.value, "ue_metro") then
        --         print('SetFact')
        --         print(factName.value)
        --         print(value)
        --     end
        -- end)
    end
    self.is_set_observer = true

    if self.is_set_observer then
        ImGui.SameLine()
        ImGui.Text("Observer : On")
    end

end

function Debug:SetLogLevel()
    function GetKeyFromValue(table_, target_value)
        for key, value in pairs(table_) do
            if value == target_value then
                return key
            end
        end
        return nil
    end
    function GetKeys(table_)
        local keys = {}
        for key, _ in pairs(table_) do
            table.insert(keys, key)
        end
        return keys
     end
    local selected = false
    if ImGui.BeginCombo("LogLevel", GetKeyFromValue(LogLevel, MasterLogLevel)) then
		for _, key in ipairs(GetKeys(LogLevel)) do
			if GetKeyFromValue(LogLevel, MasterLogLevel) == key then
				selected = true
			else
				selected = false
			end
			if(ImGui.Selectable(key, selected)) then
				MasterLogLevel = LogLevel[key]
			end
		end
		ImGui.EndCombo()
	end
end

function Debug:SelectPrintDebug()
    PrintDebugMode = ImGui.Checkbox("Print Debug Mode", PrintDebugMode)
end

function Debug:ImGuiPlayerPosition()
    self.is_im_gui_player_local = ImGui.Checkbox("[ImGui] Player Info", self.is_im_gui_player_local)
    if self.is_im_gui_player_local then
        local player = Game.GetPlayer()
        if player == nil then
            return
        end
        local player_pos = player:GetWorldPosition()
        local x_lo = string.format("%.2f", player_pos.x)
        local y_lo = string.format("%.2f", player_pos.y)
        local z_lo = string.format("%.2f", player_pos.z)
        ImGui.Text("Player World Pos : " .. x_lo .. ", " .. y_lo .. ", " .. z_lo)
        local player_angle = player:GetWorldOrientation():ToEulerAngles()
        local roll = string.format("%.2f", player_angle.roll)
        local pitch = string.format("%.2f", player_angle.pitch)
        local yaw = string.format("%.2f", player_angle.yaw)
        ImGui.Text("Player World Angle : " .. roll .. ", " .. pitch .. ", " .. yaw)
    end
end

function Debug:ImGuiLineInfo()
    self.is_im_gui_line_info = ImGui.Checkbox("[ImGui] Line Info", self.is_im_gui_line_info)
    if self.is_im_gui_line_info then
        local active_station = Game.GetQuestsSystem():GetFact(CName.new("ue_metro_active_station"))
        local next_station = Game.GetQuestsSystem():GetFact(CName.new("ue_metro_next_station"))
        local line = Game.GetQuestsSystem():GetFact(CName.new("ue_metro_track_selected"))
        ImGui.Text("Activate Station : " .. active_station)
        ImGui.Text("Next Station : " .. next_station)
        ImGui.Text("Line : " .. line)
    end
end

function Debug:ImGuiStationInfo()
    self.is_im_gui_station_info = ImGui.Checkbox("[ImGui] Station Info", self.is_im_gui_station_info)
    if self.is_im_gui_station_info then
        local telep_area_type = self.core_obj.hud_obj.teleport_area_type
        ImGui.Text("Teleport Area Type : " .. telep_area_type)
    end
end

function Debug:ImGuiMeasurement()
    self.is_im_gui_measurement = ImGui.Checkbox("[ImGui] Measurement", self.is_im_gui_measurement)
    if self.is_im_gui_measurement then
        local res_x, res_y = GetDisplayResolution()
        ImGui.SetNextWindowPos((res_x / 2) - 20, (res_y / 2) - 20)
        ImGui.SetNextWindowSize(40, 40)
        ImGui.SetNextWindowSizeConstraints(40, 40, 40, 40)
        ---
        ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 10)
        ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 5)
        ---
        ImGui.Begin("Crosshair", ImGuiWindowFlags.NoMove + ImGuiWindowFlags.NoCollapse + ImGuiWindowFlags.NoTitleBar + ImGuiWindowFlags.NoResize)
        ImGui.End()
        ---
        ImGui.PopStyleVar(2)
        ImGui.PopStyleColor(1)
        local look_at_pos = Game.GetTargetingSystem():GetLookAtPosition(Game.GetPlayer())
        local pos_x = string.format("%.2f", look_at_pos.x)
        local pos_y = string.format("%.2f", look_at_pos.y)
        local pos_z = string.format("%.2f", look_at_pos.z)
        ImGui.Text("[LookAt]X:" .. pos_x .. ", Y:" .. pos_y .. ", Z:" .. pos_z)
    end
end

function Debug:ImGuiExcuteFunction()
    if ImGui.Button("TF1") then
        local player = Game.GetPlayer()
        local player_pos = player:GetWorldPosition()
        local forward = player:GetWorldForward()
        local new_pos = Vector4.new(player_pos.x + 3 * forward.x, player_pos.y + 3 * forward.y, player_pos.z + 3 * forward.z, player_pos.w)
        local angle = player:GetWorldOrientation():ToEulerAngles()
        Game.GetTeleportationFacility():Teleport(player, new_pos, angle)
        print("Excute Test Function 1")
    end
    ImGui.SameLine()
    if ImGui.Button("TF2") then
        local player = Game.GetPlayer()
        local player_pos = player:GetWorldPosition()
        local forward = player:GetWorldForward()
        local new_pos = Vector4.new(player_pos.x + 3 * forward.x, player_pos.y + 3 * forward.y, player_pos.z + 3 * forward.z, player_pos.w)
        local angle = player:GetWorldOrientation():ToEulerAngles()
        Game.GetTeleportationFacility():Teleport(player, new_pos, angle)
        print("Excute Test Function 2")
    end
    ImGui.SameLine()
    if ImGui.Button("TF3") then
        local event = gameuiDeleteInputHintBySourceEvent.new()
        event.source = CName.new("UI_DPad")
        event.targetHintContainer = CName.new("GameplayInputHelper")
        Game.GetUISystem():QueueEvent(event)
        print("Excute Test Function 3")
    end
    ImGui.SameLine()
    if ImGui.Button("TF4") then
        local system = Game.GetQuestsSystem()
        system:SetFact(CName.new("ue_metro_next_station"), 1) 
        print("Excute Test Function 4")
    end
    ImGui.SameLine()
    if ImGui.Button("TF5") then
        print(Game.GetQuestsSystem():SetFact(CName.new("ue_metro_free_roam_get_up"), 1))
        print("Excute Test Function 5")
    end
    ImGui.SameLine()
    if ImGui.Button("TF6") then
        local current_pos = Game.GetPlayer():GetWorldPosition()
        print(current_pos.x .. ", " .. current_pos.y .. ", " .. current_pos.z)
        print("Excute Test Function 6")
    end

end

return Debug
