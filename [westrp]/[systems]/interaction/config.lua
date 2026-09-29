Config = Config or {}

Config.Debug = true

Config.Points = {
    ['valentine_saloon'] = {
        label = "Atendimento do Saloon",
        coords = vector3(-278.45, 805.34, 119.38),
        radius = 2.0,
        control = 0x760A9C6F, -- [G]
        hold = false,
        cooldown = 1000,
        actionType = "dock_menu"
    },
    ['valentine_water'] = {
        label = "Lavar o Rosto",
        coords = vector3(-282.88, 804.81, 119.38),
        radius = 1.8,
        control = 0x760A9C6F, -- [G]
        hold = true,
        holdTime = 1200,
        cooldown = 5000, -- 5s
        actionType = "wash",
        rewardMessage = "Você lavou o rosto e se sente revigorado!"
    },
    ['rhodes_rest'] = {
        label = "Descansar no Banco",
        coords = vector3(1293.76, -1300.92, 77.06),
        radius = 2.0,
        control = 0x760A9C6F, -- [G]
        hold = false,
        cooldown = 4000,
        actionType = "rest",
        rewardMessage = "Você descansou por alguns instantes."
    },
    ['blackwater_bounty_board'] = {
        label = "Checar Murais",
        coords = vector3(-765.48, -1231.14, 10.78),
        radius = 2.2,
        control = 0x760A9C6F, -- [G]
        hold = false,
        cooldown = 3000,
        actionType = "inspect",
        rewardMessage = "Nenhum aviso novo de procurado no momento."
    }
}
