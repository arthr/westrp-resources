Config = Config or {}

-- Idioma do Sistema
Config.Lang = "pt_br"

-- Tecla de Abertura do Hot Menu / Dock (0x3C3DD371 = PGDOWN)
Config.Key = 0x3C3DD371

-- Comandos de Chat/Terminal
Config.CommandAdmin = "admin"       -- Painel Administrativo Completo (Dashboard)
Config.CommandPanel = "adminpanel"  -- Alias secundário do painel
Config.CommandHot = "admhot"        -- Hot Menu / Dock Lateral de Ações Rápidas

-- Identidade Visual e Branding do Painel
Config.Brand = {
    name = "WESTRP SERVER",
    badge = "ADMIN MENU",
    logo = "https://raw.githubusercontent.com/femga/rdr3_discoveries/master/graphics/rdr3_icon.png"
}

-- Posição Padrão do Dock Lateral ('top_left' | 'top_right' | 'mid_left' | 'mid_right' | 'bottom_left' | 'bottom_right')
Config.DefaultDockPosition = "top_left"

-- Permitir abrir o menu quando estiver inconsciente/morto
Config.CanOpenWhenDead = true

--------------------------------------------------------------------------------
-- CATÁLOGO DE AÇÕES RÁPIDAS (HOT MENU / DOCK LATERAL)
--------------------------------------------------------------------------------
Config.QuickActions = {
    {
        id = "noclip",
        label = "Noclip",
        sublabel = "Voo livre e atravessar colisão",
        icon = "fas fa-ghost",
        type = "toggle",
        category = "self",
        defaultEnabled = true
    },
    {
        id = "show_names",
        label = "Show Names",
        sublabel = "ESP 3D de nomes e IDs sobre peds",
        icon = "fas fa-id-badge",
        type = "toggle",
        category = "world",
        defaultEnabled = true
    },
    {
        id = "invis",
        label = "Invisible",
        sublabel = "Ocultar personagem de outros jogadores",
        icon = "fas fa-eye-slash",
        type = "toggle",
        category = "self",
        defaultEnabled = true
    },
    {
        id = "show_blips",
        label = "Show Blips",
        sublabel = "Exibir marcadores de jogadores no radar",
        icon = "fas fa-map-marker-alt",
        type = "toggle",
        category = "world",
        defaultEnabled = true
    },
    {
        id = "dev_laser",
        label = "Dev Laser",
        sublabel = "Inspecionar entidades e hashes com mira",
        icon = "fas fa-crosshairs",
        type = "toggle",
        category = "tools",
        defaultEnabled = true
    },
    {
        id = "self_revive",
        label = "Revive",
        sublabel = "Ressuscita ped se estiver incapacitado",
        icon = "fas fa-heartbeat",
        type = "action",
        category = "self",
        defaultEnabled = true
    },
    {
        id = "freecam",
        label = "Free Cam",
        sublabel = "Câmera livre independente de ped",
        icon = "fas fa-video",
        type = "toggle",
        category = "self",
        defaultEnabled = true
    },
    {
        id = "godmode",
        label = "God Mode",
        sublabel = "Invulnerabilidade a dano e quedas",
        icon = "fas fa-shield-alt",
        type = "toggle",
        category = "self",
        defaultEnabled = true
    },
    {
        id = "superjump",
        label = "Super Jump",
        sublabel = "Multiplicador de salto reforçado",
        icon = "fas fa-arrow-circle-up",
        type = "toggle",
        category = "self",
        defaultEnabled = true
    },
    {
        id = "infiammo",
        label = "Infinite Ammo",
        sublabel = "Disparos sem consumir cartuchos",
        icon = "fas fa-infinity",
        type = "toggle",
        category = "self",
        defaultEnabled = true
    },
    {
        id = "goldencores",
        label = "Lock Cores",
        sublabel = "Vida e estamina no nível máximo",
        icon = "fas fa-lock",
        type = "toggle",
        category = "self",
        defaultEnabled = true
    },
    {
        id = "self_heal",
        label = "Heal",
        sublabel = "Restaura 100% da vida e estamina",
        icon = "fas fa-medkit",
        type = "action",
        category = "self",
        defaultEnabled = true
    },
    {
        id = "tp_waypoint",
        label = "TP Waypoint",
        sublabel = "Desloca ao waypoint no mapa (TPM)",
        icon = "fas fa-map-pin",
        type = "action",
        category = "teleport",
        defaultEnabled = false
    },
    {
        id = "copy_coords",
        label = "Copy Coords",
        sublabel = "Copia vector3/vector4 para a área de transferência",
        icon = "fas fa-copy",
        type = "action",
        category = "tools",
        defaultEnabled = false
    },
    {
        id = "clear_area",
        label = "Clear Area",
        sublabel = "Deleta peds mortos, veículos e rastros num raio de 50m",
        icon = "fas fa-broom",
        type = "action",
        category = "world",
        defaultEnabled = false
    }
}

--------------------------------------------------------------------------------
-- CONFIGURAÇÕES DE NOCLIP
--------------------------------------------------------------------------------
Config.NoClip = {
    Controls = {
        goUp        = 0xF84FA74F, -- Q
        goDown      = 0x07CE1E61, -- Z
        turnLeft    = 0x7065027D, -- A
        turnRight   = 0xB4E465B4, -- D
        goForward   = 0x8FD015D8, -- W
        goBackward  = 0xD27782E3, -- S
        changeSpeed = 0x8FFC75D6, -- L-Shift
        Cancel      = 0x4AF4D473  -- Delete
    },
    Speeds = {
        { label = "Muito Lento", speed = 0.1 },
        { label = "Lento",       speed = 0.5 },
        { label = "Normal",      speed = 2.0 },
        { label = "Rápido",      speed = 8.0 },
        { label = "Voando",      speed = 20.0 }
    },
    Offsets = {
        y = 0.2, -- Multiplicador frontal/traseiro
        z = 0.1, -- Multiplicador de elevação
        h = 1.0  -- Multiplicador de rotação
    }
}

--------------------------------------------------------------------------------
-- COORDENADAS ESPECIAIS (GUARMA & CONTINENTE)
--------------------------------------------------------------------------------
Config.Guarma = {
    Coords = vector3(1269.724, -6855.158, 43.168),
    MainLandCoords = vector3(2717.04, -1435.52, 46.22),
    AreaHashes = {
        [joaat("GuarmaD")] = true,
        [joaat("Guarma")] = true
    }
}

--------------------------------------------------------------------------------
-- CONTROLE DE ACESSO BASEADO EM CARGOS (RBAC)
--------------------------------------------------------------------------------
-- Permissões suportadas:
-- 'all' (libera tudo)
-- 'noclip', 'godmode', 'invis', 'goldencores', 'infiammo', 'selfheal', 'selfrevive'
-- 'tp_to_waypoint', 'autotpm', 'tp_to_coords', 'tp_to_player', 'bring_player', 'send_back', 'guarma'
-- 'dev_laser', 'copy_coords', 'delete_object'
-- 'players_list', 'freeze_player', 'spectate', 'respawn_player', 'heal_player', 'revive_player'
-- 'kick_player', 'ban_player', 'unban_player', 'ban_offline', 'whitelist_player'
-- 'set_group', 'set_job', 'give_item', 'give_weapon', 'give_currency', 'give_mount', 'clear_inventory', 'clear_currency'
-- 'troll_actions', 'announce', 'server_logs'

Config.Roles = {
    ["root"] = {
        label = "Super Administrador",
        hierarchy = 100,
        actions = { all = true }
    },
    ["admin"] = {
        label = "Administrador",
        hierarchy = 80,
        actions = {
            all = true
        }
    },
    ["moderator"] = {
        label = "Moderador",
        hierarchy = 50,
        actions = {
            noclip = true,
            godmode = true,
            invis = true,
            goldencores = true,
            infiammo = true,
            selfheal = true,
            selfrevive = true,
            tp_to_waypoint = true,
            autotpm = true,
            tp_to_coords = true,
            tp_to_player = true,
            bring_player = true,
            send_back = true,
            guarma = true,
            dev_laser = true,
            copy_coords = true,
            delete_object = true,
            players_list = true,
            freeze_player = true,
            spectate = true,
            respawn_player = true,
            heal_player = true,
            revive_player = true,
            kick_player = true,
            ban_player = true,
            whitelist_player = true,
            give_item = true,
            give_weapon = true,
            inspect_inventory = true,
            confiscate_item = true,
            confiscate_weapon = true,
            announce = true
        }
    },
    ["support"] = {
        label = "Suporte",
        hierarchy = 20,
        actions = {
            noclip = true,
            godmode = true,
            invis = true,
            selfheal = true,
            selfrevive = true,
            tp_to_waypoint = true,
            tp_to_player = true,
            bring_player = true,
            send_back = true,
            players_list = true,
            spectate = true,
            heal_player = true,
            revive_player = true,
            freeze_player = true,
            inspect_inventory = true,
            announce = true
        }
    }
}


--------------------------------------------------------------------------------
-- AUDITORIA & DISCORD WEBHOOKS
--------------------------------------------------------------------------------
Config.Webhooks = {
    Enabled = true,
    Author = "WestRP Staff Sentinel",
    AvatarUrl = "https://raw.githubusercontent.com/femga/rdr3_discoveries/master/graphics/rdr3_icon.png",
    Colors = {
        Default = 13610842, -- Dourado WestRP
        Danger  = 13382218, -- Vermelho
        Success = 3066993,  -- Verde
        Info    = 3447003   -- Azul
    },
    Urls = {
        General    = "", -- Webhook geral de ações
        Punishe    = "", -- Kicks e bans
        Teleport   = "", -- Deslocamentos de staff
        Spawner    = "", -- Concessão de itens/armas/moedas
        DevTools   = ""  -- Inspecionador dev e exclusão de objetos
    }
}
