fx_version 'cerulean'
game "rdr3"

rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."

lua54 'yes'

author 'West RP'
description 'Tela de carregamento oficial do West RP'
version '2.0.0'

loadscreen_manual_shutdown "yes"
loadscreen 'html/index.html'

client_script "client.lua"

files {
    'html/index.html',
    'html/config.js',
    'html/assets/js/**',
    'html/assets/css/**',
    'html/assets/img/**'
}
