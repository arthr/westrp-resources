-- ====================================================================
-- WestRP Karma — Infrastructure: FrameworkAdapter (VORP Bridge)
-- File: server/infrastructure/framework_adapter.lua
-- ====================================================================

---@class FrameworkAdapter
FrameworkAdapter = {
    VorpCore = nil
}

---Inicializa a conexão segura com o VORP Core
function FrameworkAdapter.Init()
    local ok, core = pcall(function()
        return exports.vorp_core:GetCore()
    end)
    if ok and core then
        FrameworkAdapter.VorpCore = core
    else
        print("^3[westrp_karma] AVISO: Falha ao obter VORP Core via exports. Aguardando inicialização...^0")
    end
end

---Obtém o charIdentifier de uma sessão de jogador ativa
---@param source integer
---@return integer? charIdentifier
function FrameworkAdapter.GetCharIdentifier(source)
    if not FrameworkAdapter.VorpCore then
        FrameworkAdapter.Init()
    end

    if not FrameworkAdapter.VorpCore then
        return nil
    end

    local user = FrameworkAdapter.VorpCore.getUser(source)
    if not user then return nil end

    local char = user.getUsedCharacter
    if not char then return nil end

    return char.charIdentifier
end

---Emite uma notificação na interface do jogador (VORP Notify ou WestRP Toast)
---@param source integer
---@param message string
---@param type string? 'success' | 'warning' | 'error' | 'info'
function FrameworkAdapter.Notify(source, message, type)
    if not FrameworkAdapter.VorpCore then return end
    
    local duration = 4000
    FrameworkAdapter.VorpCore.NotifyRightTip(source, message, duration)
end

-- Inicializa no start do resource
CreateThread(function()
    FrameworkAdapter.Init()
end)
