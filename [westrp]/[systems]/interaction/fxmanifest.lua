fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'westrp_interaction'
author 'WestRP Engineering Team'
description 'Sistema de Interação Espacial com Dynamic Sleep (0.00ms) e Validação Server-Authoritative'
version '1.0.0'

shared_scripts {
    '@westrp_core/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}
