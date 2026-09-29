fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'westrp_core'
author 'WestRP Engineering Team'
description 'Core SDK & Shared Infrastructure for WestRP'
version '1.0.0'

shared_scripts {
    'shared/config.lua',
    'shared/logger.lua',
    'shared/utils.lua',
    'shared/callback.lua',
    'shared/bridge/vorp/player.lua',
    'shared/bridge/vorp/inventory.lua',
    'shared/bridge/vorp/world.lua',
    'shared/bridge/bridge.lua'
}

client_scripts {
    'client/lib/dataview.lua',
    'client/feed.lua',
    'client/tick_manager.lua',
    'client/prompt_manager.lua',
    'client/ui_bridge.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/security.lua',
    'server/feed.lua',
    'server/main.lua'
}

files {
    'init.lua'
}

exports {
    'GetCoreObject'
}
