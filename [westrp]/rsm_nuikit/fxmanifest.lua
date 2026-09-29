fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

name 'rsm_nuikit'
description 'NUI Components as a service: notifications, confirms and HUD pieces placed through rsm_hud /hudlayout, plus a studio for colours and modules'
version '0.3.0'

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/**/*',
}

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/client.lua',
}

server_scripts {
    'server/server.lua',
}
