local HUD = {}
HUD.__index = HUD

function HUD:New()
    -- instance --
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "HUD")
    -- static --
    obj.mappin_pos_offset_z = 2.0
    -- dynamic --
    obj.interaction_ui_base = nil
    obj.interaction_hub = nil
    obj.selected_choice_index = 1
    obj.teleport_area_type = Def.TeleportAreaType.None
    obj.mappin_id_list = {}
    return setmetatable(obj, self)
end

function HUD:Initialize()

    Observe("InteractionUIBase", "OnInitialize", function(this)
        self.interaction_ui_base = this
    end)

    Observe("InteractionUIBase", "OnDialogsData", function(this)
        self.interaction_ui_base = this
    end)

    -- Overside choice ui (refer to https://www.nexusmods.com/cyberpunk2077/mods/7299)
    Override("InteractionUIBase", "OnDialogsData", function(_, value, wrapped_method)
        if self:IsEnableChoiceUI() then
            local data = FromVariant(value)
            local hubs = data.choiceHubs
            table.insert(hubs, self.interaction_hub)
            data.choiceHubs = hubs
            wrapped_method(ToVariant(data))
        else
            wrapped_method(value)
        end
    end)

    Override("InteractionUIBase", "OnDialogsSelectIndex", function(_, index, wrapped_method)
        if self:IsEnableChoiceUI() then
            wrapped_method(self.selected_choice_index - 1)
        else
            self.selected_choice_index = index + 1
            wrapped_method(index)
        end
    end)

    Override("dialogWidgetGameController", "OnDialogsActivateHub", function(_, id, wrapped_metthod) -- Avoid interaction getting overriden by game
        if self:IsEnableChoiceUI() then
            local id_
            if self.interaction_hub == nil then
                id_ = id
            else
                id_ = self.interaction_hub.id
            end
            return wrapped_metthod(id_)
        else
            return wrapped_metthod(id)
        end
    end)
end

function HUD:SetTeleportAreaType(area_type)
    self.teleport_area_type = area_type
end

function HUD:GetTeleportAreaType()
    return self.teleport_area_type
end

function HUD:IsEnableChoiceUI()
    if self.teleport_area_type == Def.TeleportAreaType.EntranceChoice or self.teleport_area_type == Def.TeleportAreaType.PlatformChoice then
        return true
    else
        return false
    end
end

function HUD:SetChoice(variation)

    local tmp_list = {}

    local hub = gameinteractionsvisListChoiceHubData.new()
    hub.title = GetLocalizedText("LocKey#83821")
    hub.activityState = gameinteractionsvisEVisualizerActivityState.Active
    hub.hubPriority = 1
    hub.id = 69420 + math.random(99999)

    if variation == Def.ChoiceVariation.Enter then
        local icon = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.GetInIcon")
        local caption_part = gameinteractionsChoiceCaption.new()
        local choice_type = gameinteractionsChoiceTypeWrapper.new()
        caption_part:AddPartFromRecord(icon)
        choice_type:SetType(gameinteractionsChoiceType.Selected)

        local choice = gameinteractionsvisListChoiceData.new()

        local lockey = GetLocalizedText("LocKey#36926")
        choice.localizedName = lockey
        choice.inputActionName = CName.new("None")
        choice.captionParts = caption_part
        choice.type = choice_type
        table.insert(tmp_list, choice)
    elseif variation == Def.ChoiceVariation.Exit then
        local icon = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.GetInIcon")
        local caption_part = gameinteractionsChoiceCaption.new()
        local choice_type = gameinteractionsChoiceTypeWrapper.new()
        caption_part:AddPartFromRecord(icon)
        choice_type:SetType(gameinteractionsChoiceType.Selected)

        local choice = gameinteractionsvisListChoiceData.new()

        local lockey = GetLocalizedText("LocKey#36500")
        choice.localizedName = lockey
        choice.inputActionName = CName.new("None")
        choice.captionParts = caption_part
        choice.type = choice_type
        table.insert(tmp_list, choice)
    end

    hub.choices = tmp_list

    self.interaction_hub = hub
end

function HUD:ShowChoice(variation, selected_index)

    if self.is_showing_choice then
        return
    end

    self.is_showing_choice = true

    self.selected_choice_index = selected_index

    self:SetChoice(variation)

    local ui_interaction_define = GetAllBlackboardDefs().UIInteractions
    local interaction_blackboard = Game.GetBlackboardSystem():Get(ui_interaction_define)

    interaction_blackboard:SetInt(ui_interaction_define.ActiveChoiceHubID, self.interaction_hub.id)
    local data = interaction_blackboard:GetVariant(ui_interaction_define.DialogChoiceHubs)
    self.interaction_ui_base:OnDialogsSelectIndex(selected_index - 1)
    self.interaction_ui_base:OnDialogsData(data)
    self.interaction_ui_base:OnInteractionsChanged()
    self.interaction_ui_base:UpdateListBlackboard()
    self.interaction_ui_base:OnDialogsActivateHub(self.interaction_hub.id)

end

function HUD:GetStationID()
    return Game.GetQuestsSystem():GetFact(CName.new("ue_metro_active_station"))
end

function HUD:HideChoice()

    if not self.is_showing_choice then
        return
    end

    self.is_showing_choice = false

    self.interaction_hub = nil

    local ui_interaction_define = GetAllBlackboardDefs().UIInteractions;
    local interaction_blackboard = Game.GetBlackboardSystem():Get(ui_interaction_define)

    local data = interaction_blackboard:GetVariant(ui_interaction_define.DialogChoiceHubs)

    if self.interaction_ui_base == nil then
        return
    end
    self.interaction_ui_base:OnDialogsData(data)

end

function HUD:UpdateMappins()

    self:RemoveMappins()
    local player = Game.GetPlayer()
    if player == nil then
        return
    end
    for _, area_info in ipairs(Data.EntryArea) do
        if self:GetStationID() == area_info.st_id then
            local position = Vector4.new(area_info.pos.x, area_info.pos.y, area_info.pos.z + self.mappin_pos_offset_z, 1)
            local distance = Vector4.Distance(player:GetWorldPosition(), position)
            if distance < area_info.r_2 then
                local mappin_data = MappinData.new()
                mappin_data.mappinType = TweakDBID.new('Mappins.InteractionMappinDefinition')
                mappin_data.variant = gamedataMappinVariant.GetInVariant
                mappin_data.visibleThroughWalls = true
                table.insert(self.mappin_id_list ,Game.GetMappinSystem():RegisterMappin(mappin_data, position))
            end
        end
    end
    for _, area_info in ipairs(Data.ExitArea) do
        if self:GetStationID() == area_info.st_id then
            local position = Vector4.new(area_info.pos.x, area_info.pos.y, area_info.pos.z + self.mappin_pos_offset_z, 1)
            local distance = Vector4.Distance(player:GetWorldPosition(), position)
            if distance < area_info.r_2 then
                local mappin_data = MappinData.new()
                mappin_data.mappinType = TweakDBID.new('Mappins.InteractionMappinDefinition')
                mappin_data.variant = gamedataMappinVariant.GetInVariant
                mappin_data.visibleThroughWalls = true
                table.insert(self.mappin_id_list ,Game.GetMappinSystem():RegisterMappin(mappin_data, position))
            end
        end
    end

end

function HUD:RemoveMappins()

    if #self.mappin_id_list ~= 0 then
        for _, mappin_id in ipairs(self.mappin_id_list) do
            Game.GetMappinSystem():UnregisterMappin(mappin_id)
        end
        self.mappin_id_list = {}
    end

end

return HUD