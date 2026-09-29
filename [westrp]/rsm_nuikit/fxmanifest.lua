fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

name 'rsm_nuikit'
description 'NUI Components as a service: notifications, confirms, HUD pieces, plus a studio for layout, colours and modules'
version '0.2.0'

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
