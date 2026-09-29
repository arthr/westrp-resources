fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

name 'rsm_hud'
description 'Frontier roleplay HUD: cores, horse, needs, money, clock, location, voice, weapon, bounty, with an in-game Layout Manager'
version '0.1.0'

-- The interface is built from web/ (npm run build) into web/dist.
ui_page 'web/dist/index.html'

files {
  'web/dist/index.html',
  'web/dist/**/*',
}

dependencies {
  'vorp_core',
}

shared_scripts {
  'config.lua',
}

-- client.lua define RSMHud, então vem antes dos outros dois
client_scripts {
  'client/client.lua',
  'client/status.lua',
  'client/vorp.lua',
}

server_scripts {
  'server/server.lua',
}
