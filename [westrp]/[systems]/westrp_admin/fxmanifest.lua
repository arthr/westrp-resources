fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'westrp_admin'
author 'WestRP Engineering Team'
description 'High Performance Zero-Trust Administration & Operations Engine for WestRP'
version '1.0.0'

shared_scripts {
    '@westrp_core/init.lua',
    'config.lua',
    'shared/permissions.lua'
}

client_scripts {
    'client/data/datapeds.lua',
    'client/data/dataprops.lua',
    'client/boosters.lua',
    'client/teleport.lua',
    'client/devtools.lua',
    'client/spectate.lua',
    'client/dock.lua',
    'client/panel.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/security.lua',
    'server/logger.lua',
    'server/players.lua',
    'server/bans.lua',
    'server/items.lua',
    'server/world.lua',
    'server/main.lua'
}

dependencies {
    'westrp_core',
    'westrp_ui',
    'westrp_assets'
}
