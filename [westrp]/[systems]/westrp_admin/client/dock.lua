WestRP = WestRP or {}
WestRP.Admin = WestRP.Admin or {}
WestRP.Admin.Dock = {}

local isDockOpen = false

---Gera o esquema atualizado do menu lateral
---@return table
local function BuildDockSchema()
    local bStates = WestRP.Admin.Boosters.GetStates()

    return {
        id = "admin_dock",
        title = "PAINEL STAFF",
        tag = "WESTRP • OPERAÇÕES & COMANDO",
        keepInput = true,
        tabs = {
            -- Aba 1: Boosters
            {
                id = "boosters",
                name = "BOOSTERS",
                items = {
                    {
                        id = "noclip",
                        label = "Modo Voo (NoClip)",
                        type = "toggle",
                        checked = bStates.noclip,
                        badge = bStates.noclip and "LIGADO" or "DESLIGADO",
                        badgeType = bStates.noclip and "on" or "off",
                        description = "Permite voar livremente e atravessar paredes sem colisão física. Pressione [L-SHIFT] para mudar a velocidade."
                    },
                    {
                        id = "godmode",
                        label = "Modo Deus (GodMode)",
                        type = "toggle",
                        checked = bStates.godmode,
                        badge = bStates.godmode and "IMUNE" or "NORMAL",
                        badgeType = bStates.godmode and "on" or "off",
                        description = "Torna o operador e sua montaria totalmente invulneráveis a tiros, fogo e quedas (Proofs 511)."
                    },
                    {
                        id = "invis",
                        label = "Invisibilidade",
                        type = "toggle",
                        checked = bStates.invis,
                        badge = bStates.invis and "OCULTO" or "VISÍVEL",
                        badgeType = bStates.invis and "on" or "off",
                        description = "Oculta a renderização do corpo do operador dos demais jogadores."
                    },
                    {
                        id = "goldencores",
                        label = "Núcleos Dourados",
                        type = "toggle",
                        checked = bStates.goldencores,
                        badge = bStates.goldencores and "MAX" or "PADRÃO",
                        badgeType = bStates.goldencores and "gold" or "off",
                        description = "Preenche e doura todos os núcleos e anéis externos de vida e estamina."
                    },
                    {
                        id = "infiammo",
                        label = "Munição Infinita",
                        type = "toggle",
                        checked = bStates.infiammo,
                        badge = bStates.infiammo and "ILIMITADO" or "NORMAL",
                        badgeType = bStates.infiammo and "gold" or "off",
                        description = "Mantém a arma em mãos com munição constante sem necessidade de recarga."
                    },
                    {
                        id = "selfheal",
                        label = "Auto Cura & Fome/Sede",
                        badge = "RESTAURAR",
                        badgeType = "gold",
                        description = "Cura 100% da vida, recupera fôlego e restaura metabolismo."
                    },
                    {
                        id = "selfrevive",
                        label = "Auto Reviver",
                        badge = "REANIMAR",
                        badgeType = "danger",
                        danger = true,
                        description = "Reanima o operador imediatamente caso esteja incapacitado ou em coma."
                    }
                }
            },
            -- Aba 2: Teleportes
            {
                id = "teleports",
                name = "TELEPORTES",
                items = {
                    {
                        id = "tpm",
                        label = "Ir para Marcador (TPM)",
                        badge = "WAYPOINT",
                        badgeType = "gold",
                        description = "Teleporta o operador para o ponto atualmente marcado no mapa com detecção de solo."
                    },
                    {
                        id = "autotpm",
                        label = "Auto-TPM ao Marcar",
                        type = "toggle",
                        checked = false,
                        description = "Sempre que definir um novo marcador no mapa, será teleportado instantaneamente."
                    },
                    {
                        id = "goback",
                        label = "Voltar Posição Anterior",
                        badge = "RETORNO",
                        badgeType = "gold",
                        description = "Retorna à localização salva antes do último teleporte ou ação de GoTo/Bring."
                    },
                    {
                        id = "guarma",
                        label = "Zarpar / Voltar de Guarma",
                        badge = "EXPEDIÇÃO",
                        badgeType = "gold",
                        description = "Viaja diretamente para a ilha caribenha de Guarma ou retorna à terra firme."
                    }
                }
            },
            -- Aba 3: DevTools
            {
                id = "devtools",
                name = "DEV TOOLS",
                items = {
                    {
                        id = "devlaser",
                        label = "Laser Inspecionador Raycast",
                        type = "toggle",
                        checked = false,
                        badge = "3D SCAN",
                        badgeType = "gold",
                        description = "Desenha mira laser 3D identificando modelos, hashes, coordenadas e rotações de entidades."
                    },
                    {
                        id = "copy_v3",
                        label = "Copiar vector3(x, y, z)",
                        badge = "VETOR",
                        badgeType = "gold",
                        description = "Copia as coordenadas tridimensionais exatas para sua área de transferência."
                    },
                    {
                        id = "copy_v4",
                        label = "Copiar vector4(x, y, z, h)",
                        badge = "VETOR 4",
                        badgeType = "gold",
                        description = "Copia coordenadas e direção do olhar para criação rápida de spawns de veículos e NPCs."
                    },
                    {
                        id = "copy_heading",
                        label = "Copiar Heading Atual",
                        badge = "ÂNGULO",
                        badgeType = "gold",
                        description = "Copia o ângulo de orientação (Heading) para o clipboard."
                    },
                    {
                        id = "interior_id",
                        label = "Copiar ID do Interior",
                        badge = "MUNDO",
                        badgeType = "gold",
                        description = "Identifica o ID do interior da construção onde o operador se encontra."
                    },
                    {
                        id = "del_object",
                        label = "Deletar Objeto Mais Próximo",
                        badge = "EXCLUIR",
                        badgeType = "danger",
                        danger = true,
                        description = "Remove a entidade mais próxima (objeto/prop/veículo) à frente do operador."
                    },
                    {
                        id = "open_panel",
                        label = "Mesa de Trabalho Completa",
                        badge = "PAINEL [ENTER]",
                        badgeType = "gold",
                        description = "Abre o Painel Central multimodal com gestão de jogadores, catálogo de itens e registros de punições."
                    }
                }
            }
        },
        onSelect = function(item, tabId)
            if item.id == "selfheal" then
                WestRP.Admin.Boosters.SelfHeal()
            elseif item.id == "selfrevive" then
                WestRP.Admin.Boosters.SelfRevive()
            elseif item.id == "tpm" then
                WestRP.Admin.Teleport.TeleportToWaypoint()
            elseif item.id == "goback" then
                WestRP.Admin.Teleport.GoBack()
            elseif item.id == "guarma" then
                WestRP.Admin.Teleport.ToggleGuarma()
            elseif item.id == "copy_v3" then
                WestRP.Admin.DevTools.CopyCoords("v3")
            elseif item.id == "copy_v4" then
                WestRP.Admin.DevTools.CopyCoords("v4")
            elseif item.id == "copy_heading" then
                WestRP.Admin.DevTools.CopyCoords("heading")
            elseif item.id == "interior_id" then
                WestRP.Admin.DevTools.CopyCoords("interior")
            elseif item.id == "del_object" then
                WestRP.Admin.DevTools.DeleteClosestObject()
            elseif item.id == "open_panel" then
                WestRP.Admin.Dock.Close()
                Wait(150)
                WestRP.Admin.Panel.Open()
            end
        end,
        onChange = function(item, newVal, tabId)
            if item.id == "noclip" then
                local res = WestRP.Admin.Boosters.ToggleNoClip()
                WestRP.Client.UI.UpdateItem("noclip", { checked = res, badge = res and "LIGADO" or "DESLIGADO", badgeType = res and "on" or "off" })
            elseif item.id == "godmode" then
                local res = WestRP.Admin.Boosters.ToggleGodMode()
                WestRP.Client.UI.UpdateItem("godmode", { checked = res, badge = res and "IMUNE" or "NORMAL", badgeType = res and "on" or "off" })
            elseif item.id == "invis" then
                local res = WestRP.Admin.Boosters.ToggleInvis()
                WestRP.Client.UI.UpdateItem("invis", { checked = res, badge = res and "OCULTO" or "VISÍVEL", badgeType = res and "on" or "off" })
            elseif item.id == "goldencores" then
                local res = WestRP.Admin.Boosters.ToggleGoldenCores()
                WestRP.Client.UI.UpdateItem("goldencores", { checked = res, badge = res and "MAX" or "PADRÃO", badgeType = res and "gold" or "off" })
            elseif item.id == "infiammo" then
                local res = WestRP.Admin.Boosters.ToggleInfiniteAmmo()
                WestRP.Client.UI.UpdateItem("infiammo", { checked = res, badge = res and "ILIMITADO" or "NORMAL", badgeType = res and "gold" or "off" })
            elseif item.id == "autotpm" then
                local res = WestRP.Admin.Teleport.ToggleAutoTPM()
                WestRP.Client.UI.UpdateItem("autotpm", { checked = res })
            elseif item.id == "devlaser" then
                local res = WestRP.Admin.DevTools.ToggleLaser()
                WestRP.Client.UI.UpdateItem("devlaser", { checked = res })
            end
        end,
        onClose = function()
            isDockOpen = false
        end
    }
end

---Abre o menu lateral do dock
function WestRP.Admin.Dock.Open()
    local schema = BuildDockSchema()
    WestRP.Client.UI.OpenDock(schema)
    isDockOpen = true
end

---Fecha o menu lateral
function WestRP.Admin.Dock.Close()
    if isDockOpen then
        WestRP.Client.UI.CloseDock()
        isDockOpen = false
    end
end

---Alterna a exibição do menu lateral
function WestRP.Admin.Dock.Toggle()
    if isDockOpen then
        WestRP.Admin.Dock.Close()
    else
        WestRP.Admin.Dock.Open()
    end
end
