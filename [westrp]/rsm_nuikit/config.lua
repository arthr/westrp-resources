Config = {}

-- Quem pode abrir o estúdio e publicar mudanças para o servidor inteiro.
-- Dê a permissão no server.cfg, por exemplo:
--   add_ace group.admin rsm_nuikit.admin allow
Config.AdminAce = "rsm_nuikit.admin"

-- Comando de chat que abre o estúdio (só funciona para quem tem a permissão acima)
Config.Command = "nuikit"

-- Arquivo, dentro deste resource, onde as configurações publicadas ficam salvas.
-- A pasta data/ já vem com o resource; o arquivo é reescrito a cada publicação.
Config.SaveFile = "data/studio.json"

-- Duração padrão das notificações, em milissegundos (cada Notify pode passar a sua)
Config.NotifyDuration = 5200

-- Quanto tempo, em segundos, um Confirm aberto pelo SERVIDOR espera a resposta
-- do jogador. Passou disso, a resposta conta como "não".
Config.ConfirmTimeout = 60

-- ─────────────────────────────────────────────────────────────────────────────
-- Integração com o HUD
--   Com o rsm_hud rodando, Notificações, Texto de Ajuda e Objetivo entram no
--   /hudlayout dele: cada jogador arrasta essas peças junto com o resto do HUD
--   e a posição fica salva no personagem. Cores e dinheiro passam a ser só do
--   rsm_hud (o kit não desenha os dele, para nada aparecer duplicado).
--   Sem o rsm_hud, o kit funciona sozinho com as posições de Config.Layout.
-- ─────────────────────────────────────────────────────────────────────────────
Config.HostHud = {
    resource = "rsm_hud", -- nome da pasta do HUD no servidor; "" desliga a integração
}

-- Posição de cada peça do HUD do kit.
--   x / y  0 = encostada à esquerda / no topo, 1 = à direita / embaixo. A peça
--          nunca sai da tela, em qualquer resolução (mesma conta do rsm_hud).
--   scale  0.5 a 1.6
--   label / hint  como a peça aparece na lista do /hudlayout
-- Com o rsm_hud, estes valores são só o ponto de partida (e o que o "Redefinir"
-- do editor devolve); os padrões abaixo ficam livres dos elementos do rsm_hud
-- nas três predefinições dele (Fronteira, Compacto e Mínimo).
Config.Layout = {
    toasts    = { x = 0.99, y = 0.58,  scale = 1, label = "Notificações",   hint = "Avisos dos resources" },
    help      = { x = 0.01, y = 0.25,  scale = 1, label = "Texto de Ajuda", hint = "Dicas com tecla" },
    objective = { x = 0.50, y = 0.12,  scale = 1, label = "Objetivo",       hint = "Missão ou trabalho atual" },
    -- só usadas SEM o rsm_hud (com ele, cores e dinheiro são do próprio HUD)
    cores     = { x = 0.20, y = 0.975, scale = 1 },
    money     = { x = 0.99, y = 0.025, scale = 1 },
}

-- Registro de módulos. Cada id precisa bater com um componente do kit.
--   active = estado antes da primeira publicação no estúdio
--   locked = o módulo não pode ser desligado (outros resources dependem dele)
--   cores e money ficam desligados enquanto o rsm_hud estiver rodando
Config.Modules = {
    { id = "menus",     active = true,  locked = true },
    { id = "prompts",   active = true,  locked = true },
    { id = "dialogs",   active = true,  locked = true },  -- Confirm precisa sempre poder responder
    { id = "cores",     active = true,  locked = false },
    { id = "toasts",    active = true,  locked = false },
    { id = "help",      active = true,  locked = false },
    { id = "money",     active = false, locked = false },
    { id = "objective", active = false, locked = false },
    { id = "slots",     active = true,  locked = false },
    { id = "selectors", active = true,  locked = false },
    { id = "sliders",   active = true,  locked = false },
    { id = "inputs",    active = false, locked = false },
}
