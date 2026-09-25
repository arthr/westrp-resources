fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'westrp_karma'
author 'WestRP Engineering Team'
description 'Dynamic Morality, Systemic Karma & Combat Self-Defense Engine for WestRP'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

shared_scripts {
    '@westrp_core/init.lua',
    'config.lua',
    'shared/types.lua',
    'shared/tiers.lua',
    'shared/weapons.lua'
}

client_scripts {
    'client/services/state_evaluator.lua',
    'client/controllers/hud.lua',
    'client/pipeline/stages.lua',
    'client/pipeline/engine.lua',
    'client/services/combat_watcher.lua',
    'client/listeners/game_events.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua'
}

dependencies {
    'westrp_core',
    'oxmysql'
}
