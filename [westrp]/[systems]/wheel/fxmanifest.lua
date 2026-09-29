fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'wheel'
author 'WestRP Engineering Team'
description 'Native InputWheel & Quick Select System for WestRP'
version '1.0.0'

shared_scripts {
    '@core/init.lua',
    'config.lua'
}

client_scripts {
    'client/lib/dataview.lua',
    'client/buffer_pool.lua',
    'client/native_mirror.lua',
    'client/main.lua'
}

server_scripts {
    'server/sync_manager.lua',
    'server/main.lua'
}

dependencies {
    'westrp_core'
}
