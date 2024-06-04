local HUD = {}
HUD.__index = HUD

function HUD:New()
    -- instance --
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "HUD")
    -- dynamic --
    obj.interaction_hub = nil
    obj.selected_choice_index = 0
    return setmetatable(obj, self)
end

function HUD:Initialize()
    self:SetChoice()
end

function HUD:SetChoice(variation)

    local tmp_list = {}

    local hub = gameinteractionsvisListChoiceHubData.new()
    hub.title = GetLocalizedText("LocKey#83821")
    hub.activityState = gameinteractionsvisEVisualizerActivityState.Active
    hub.hubPriority = 1
    hub.id = 69420 + math.random(99999)

    if variation == Def.ChoiceVariation.Enter then
        local icon = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.MetroIcon")
        local caption_part = gameinteractionsChoiceCaption.new()
        local choice_type = gameinteractionsChoiceTypeWrapper.new()
        caption_part:AddPartFromRecord(icon)
        choice_type:SetType(gameinteractionsChoiceType.Selected)

        local choice = gameinteractionsvisListChoiceData.new()

        local lockey = GetLocalizedText("LocKey#37918")
        choice.localizedName = lockey
        choice.inputActionName = CName.new("None")
        choice.captionParts = caption_part
        choice.type = choice_type
        table.insert(tmp_list, choice)
    elseif variation == Def.ChoiceVariation.Exit then
        local icon = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.SitIcon")
        local caption_part = gameinteractionsChoiceCaption.new()
        local choice_type = gameinteractionsChoiceTypeWrapper.new()
        caption_part:AddPartFromRecord(icon)
        choice_type:SetType(gameinteractionsChoiceType.Selected)

        local choice = gameinteractionsvisListChoiceData.new()

        local lockey = GetLocalizedText("LocKey#522")
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

    self.selected_choice_index = selected_index

    self:SetChoice(variation)

    local ui_interaction_define = GetAllBlackboardDefs().UIInteractions
    local interaction_blackboard = Game.GetBlackboardSystem():Get(ui_interaction_define)

    interaction_blackboard:SetInt(ui_interaction_define.ActiveChoiceHubID, self.interaction_hub.id)
    local data = interaction_blackboard:GetVariant(ui_interaction_define.DialogChoiceHubs)
    self.dialogIsScrollable = true
    self.interaction_ui_base:OnDialogsSelectIndex(selected_index - 1)
    self.interaction_ui_base:OnDialogsData(data)
    self.interaction_ui_base:OnInteractionsChanged()
    self.interaction_ui_base:UpdateListBlackboard()
    self.interaction_ui_base:OnDialogsActivateHub(self.interaction_hub.id)

end

function HUD:HideChoice()

    self.interaction_hub = nil

    local ui_interaction_define = GetAllBlackboardDefs().UIInteractions;
    local interaction_blackboard = Game.GetBlackboardSystem():Get(ui_interaction_define)

    local data = interaction_blackboard:GetVariant(ui_interaction_define.DialogChoiceHubs)
    if self.interaction_ui_base == nil then
        return
    end
    self.interaction_ui_base:OnDialogsData(data)

end

return HUD