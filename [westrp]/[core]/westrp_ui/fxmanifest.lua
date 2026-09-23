fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'westrp_ui'
author 'WestRP Engineering Team'
description 'Centralized NUI Lateral Dock & UI Engine for WestRP'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js'
}

client_scripts {
    'client/main.lua'
}

exports {
    'OpenDock',
    'CloseDock',
    'IsDockOpen',
    'UpdateItem',
    'ShowToast',
    'OpenPanel',
    'ClosePanel',
    'IsPanelOpen'
}
