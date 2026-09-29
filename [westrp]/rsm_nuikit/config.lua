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

-- Registro de módulos. Cada id precisa bater com um componente do kit.
--   active = estado antes da primeira publicação no estúdio
--   locked = o módulo não pode ser desligado (outros resources dependem dele)
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
