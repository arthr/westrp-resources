-- ====================================================================
-- WestRP Karma — Client: HonorPresenter (Native DataBinding HUD)
-- File: client/honor_presenter.lua
-- ====================================================================

---@class HonorPresenter
HonorPresenter = {
    container = nil,
    iconContainer = nil,
    stateData = nil,
    hideTimer = nil
}

---Inicializa os contêineres do DataBinding nativo para a barra de honra do RDR2
function HonorPresenter.Init()
    local ok, rpgContainer, icon, state = pcall(function()
        local container = DatabindingGetDataContainerFromPath("RPGStatusIcons")
        if container == 0 then
            container = DatabindingAddDataContainerFromPath("", "RPGStatusIcons")
        end

        local iconContainer = DatabindingAddDataContainer(container, "HonorIcon")
        local stateData = DatabindingAddDataInt(iconContainer, "State", 8)

        return container, iconContainer, stateData
    end)
    if ok then
        HonorPresenter.container = rpgContainer
        HonorPresenter.iconContainer = icon
        HonorPresenter.stateData = state
    end
end

---Exibe a barra nativa de honra com o estado moral atualizado e áudio característico
---@param karma integer
---@param delta integer
function HonorPresenter.Show(karma, delta)
    if not Config.UI.UseNativeHonorBar then return end

    local nativeState = TierEvaluator.CalculateNativeState(karma)

    -- Atualiza o valor no DataBinding do jogo
    pcall(function()
        if not HonorPresenter.iconContainer then
            local RPGStatusIcons = DatabindingAddDataContainerFromPath("", "RPGStatusIcons")
            HonorPresenter.iconContainer = DatabindingAddDataContainer(RPGStatusIcons, "HonorIcon")
        end
        DatabindingWriteDataInt(HonorPresenter.iconContainer, "State", nativeState)
    end)

    -- Efeitos Sonoros Originais do RDR2
    if Config.UI.PlayNativeAudio and delta ~= 0 then
        if delta > 0 then
            PlaySoundFrontend("Honor_Increase_Small", "Honor_Display_Sounds", true, 0)
        else
            PlaySoundFrontend("Honor_Decrease_Small", "Honor_Display_Sounds", true, 0)
        end
    end
end

CreateThread(function()
    HonorPresenter.Init()
end)
