-- ====================================================================
-- WestRP Karma — Client Pipeline: Execution Engine & Step Ladder Logger
-- File: client/pipeline/engine.lua
-- ====================================================================

---@class CombatPipeline
CombatPipeline = {}

-- ====================================================================
-- SISTEMA DE LOGGING PADRONIZADO E RELAY PARA O SERVIDOR
-- ====================================================================
local function LogDebug(tag, msg, ...)
    local formatted = (select('#', ...) > 0) and string.format(msg, ...) or tostring(msg)
    if WestRP and WestRP.Shared and WestRP.Shared.Logger and WestRP.Shared.Logger.Debug then
        pcall(WestRP.Shared.Logger.Debug, tag, formatted)
    end
    if Config.Debug then
        print(string.format("^5[DEBUG]^7 [^3%s^7] %s^0", tag, formatted))
        TriggerServerEvent('westrp_karma:server:relayClientDebug', tag, formatted)
    end
end

local function LogInfo(tag, msg, ...)
    local formatted = (select('#', ...) > 0) and string.format(msg, ...) or tostring(msg)
    if WestRP and WestRP.Shared and WestRP.Shared.Logger and WestRP.Shared.Logger.Info then
        pcall(WestRP.Shared.Logger.Info, tag, formatted)
    end
    print(string.format("^2[INFO]^7 [^3%s^7] %s^0", tag, formatted))
    if Config.Debug then
        TriggerServerEvent('westrp_karma:server:relayClientDebug', tag, formatted)
    end
end

---Gera o log em escada (Step Ladder) quando a pipeline é interrompida
---@param ctx CombatContext
---@param failedStageIndex integer
---@param reason string?
function CombatPipeline.PrintHalt(ctx, failedStageIndex, reason)
    local lines = {}
    lines[#lines + 1] = string.format("Avaliando confronto em Ped #%d (Culprit: %s):", ctx.victim, tostring(ctx.culprit))
    for j = 1, failedStageIndex do
        if j < failedStageIndex then
            lines[#lines + 1] = string.format("  ├─ [✓] %s", CombatStages.Names[j])
        else
            lines[#lines + 1] = string.format("  └─ [✗] %s: %s -> Pipeline interrompida.", CombatStages.Names[j], reason or "Condição não satisfeita")
        end
    end
    LogDebug("KARMA_PIPE", table.concat(lines, "\n"))
end

---Gera o log em escada completo quando todos os 8 estágios passam com sucesso
---@param ctx CombatContext
---@param deltaFormatted string
function CombatPipeline.PrintSuccess(ctx, deltaFormatted)
    local lines = {}
    lines[#lines + 1] = string.format("Confronto em Ped #%d (Culprit: %s) -> %s CONFIRMADO:",
        ctx.victim, tostring(ctx.culprit), ctx.actionType)
    for j = 1, 7 do
        lines[#lines + 1] = string.format("  ├─ [✓] %s", CombatStages.Names[j])
    end
    lines[#lines + 1] = string.format("  └─ [🚀] 8. Despacho: %s (Ped: %d%s) | Ação: %s | %s | %s | %s",
        ctx.targetType, ctx.victim, ctx.victimServerId and (" | ServerID: " .. ctx.victimServerId) or "",
        ctx.actionType, ctx.initiative, ctx.weaponLabel, deltaFormatted)
    LogInfo("KARMA_PIPE", table.concat(lines, "\n"))
end

---Executa sequencialmente a pipeline linear de confronto
---@param ctx CombatContext
---@return boolean success, string? abortReason
function CombatPipeline.Run(ctx)
    local stages = CombatStages.List
    for i = 1, #stages do
        local ok, abortReason = stages[i](ctx)
        if not ok then
            -- Se o jogador estiver envolvido no confronto ou for o autor
            if ctx.isAuthor or ctx.culprit == ctx.playerPed or (ctx.killerSource and ctx.killerSource == ctx.playerPed) then
                if Config.Debug then
                    CombatPipeline.PrintHalt(ctx, i, abortReason)
                end

                if KarmaHUD:IsVisible() then
                    KarmaHUD:PushLog(
                        "pipe_halt",
                        "PIPE HALT",
                        string.format("Ped #%d | Parou em: %s (%s)", ctx.victim, CombatStages.Names[i], abortReason or "Filtro acionado"),
                        "0 pts",
                        0
                    )
                end
            end
            return false, abortReason
        end
    end
    return true
end
