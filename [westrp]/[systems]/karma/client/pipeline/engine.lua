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
            lines[#lines + 1] = string.format("  |-- [OK] %s", CombatStages.Names[j])
        else
            lines[#lines + 1] = string.format("  \\-- [X]  %s: %s -> Pipeline interrompida.", CombatStages.Names[j], reason or "Condição não satisfeita")
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
        local extraInfo = ""
        if j == 4 and ctx.ballistic and ctx.ballistic.weaponCategory then
            extraInfo = string.format(" (%s | Família: %s)", ctx.weaponLabel, ctx.ballistic.weaponCategory)
        elseif j == 5 and ctx.ballistic then
            local tags = {}
            if ctx.ballistic.isHeadshot then tags[#tags + 1] = "HEADSHOT" end
            if ctx.ballistic.isBleedoutPromotion then tags[#tags + 1] = "BLEEDOUT" end
            if ctx.ballistic.distanceMeters and ctx.ballistic.distanceMeters > 0 then
                tags[#tags + 1] = string.format("%.1fm", ctx.ballistic.distanceMeters)
            end
            if #tags > 0 then
                extraInfo = string.format(" [%s]", table.concat(tags, " | "))
            end
        end
        lines[#lines + 1] = string.format("  |-- [OK] %s%s", CombatStages.Names[j], extraInfo)
    end

    local ballisticSummary = ""
    if ctx.ballistic and ctx.ballistic.distanceMeters and ctx.ballistic.distanceMeters > 0 then
        ballisticSummary = string.format(" | %.1fm", ctx.ballistic.distanceMeters)
    end
    if ctx.ballistic and ctx.ballistic.isHeadshot then
        ballisticSummary = ballisticSummary .. " | HEADSHOT"
    end

    lines[#lines + 1] = string.format("  \\-- [>>] 8. Despacho: %s (Ped: %d%s) | Ação: %s | %s | %s%s | %s",
        ctx.targetType, ctx.victim, ctx.victimServerId and (" | ServerID: " .. ctx.victimServerId) or "",
        ctx.actionType, ctx.initiative, ctx.weaponLabel, ballisticSummary, deltaFormatted)
    LogInfo("KARMA_PIPE", table.concat(lines, "\n"))
end

---Executa sequencialmente a pipeline linear de confronto
---@param ctx CombatContext
---@return boolean success, string? abortReason
function CombatPipeline.Run(ctx)
    local stages = CombatStages.List
    if not stages or #stages == 0 then
        return false, "Nenhum estágio registrado na pipeline"
    end

    for i = 1, #stages do
        local success, ok, abortReason, isSilentHalt = pcall(stages[i], ctx)
        if not success then
            local errMsg = tostring(ok)
            print(string.format("^1[ERROR] [KARMA_PIPE] Exceção crítica no Estágio %d (%s): %s^0",
                i, (CombatStages.Names and CombatStages.Names[i]) or "Desconhecido", errMsg))
            TriggerServerEvent('westrp_karma:server:relayClientDebug', 'KARMA_PIPE_ERR',
                string.format("Exceção crítica no Estágio %d (%s): %s", i, (CombatStages.Names and CombatStages.Names[i]) or "?", errMsg))
            return false, errMsg
        end

        if not ok then
            -- Se o jogador estiver envolvido no confronto ou for o autor
            local isRelevant = ctx.isAuthor
                or ctx.culprit == ctx.playerPed
                or (ctx.killerSource and ctx.killerSource == ctx.playerPed)
                or (KarmaState.bleedingVictims[ctx.victim] and KarmaState.bleedingVictims[ctx.victim].author == ctx.playerPed)
                or (i > 1 and KarmaHUD:GetPlayerCurrentTarget(ctx.playerPed) == ctx.victim)

            if isRelevant and not isSilentHalt then
                if Config.Debug then
                    CombatPipeline.PrintHalt(ctx, i, abortReason)
                end

                if KarmaHUD:IsVisible() then
                    KarmaHUD:PushLog(
                        "pipe_halt",
                        "PIPE HALT",
                        string.format("Ped #%d | Parou em: %s (%s)", ctx.victim, (CombatStages.Names and CombatStages.Names[i]) or tostring(i), abortReason or "Filtro acionado"),
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
