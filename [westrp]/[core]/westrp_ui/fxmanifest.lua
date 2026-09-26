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
    'html/test.html',
    'html/css/variables.css',
    'html/css/base.css',
    'html/css/dock.css',
    'html/css/panel.css',
    'html/css/dialog.css',
    'html/css/progress.css',
    'html/css/toast.css',
    'html/js/audio.js',
    'html/js/components/toast.js',
    'html/js/components/progress.js',
    'html/js/components/dialog.js',
    'html/js/components/dock.js',
    'html/js/components/panel.js',
    'html/js/app.js',
    'html/assets/fonts/chinese_rocks.otf',
    'html/assets/fonts/Hapna_Slab_Serif.ttf',
    'html/assets/fonts/RDR_Lino_Regular.ttf',
    'html/assets/textures/arrow_left.png',
    'html/assets/textures/arrow_right.png',
    'html/assets/textures/bg.png',
    'html/assets/textures/bg-red.png',
    'html/assets/textures/box.png',
    'html/assets/textures/box-red.png',
    'html/assets/textures/crafting_outline.png',
    'html/assets/textures/divider.png',
    'html/assets/textures/selector.png',
    'html/assets/textures/tick.png',
    'html/assets/textures/nav_decrease.png',
    'html/assets/textures/nav_increase.png',
    'html/assets/textures/nav_close.png'
}

client_scripts {
    'client/native_hud.lua',
    'client/main.lua',
    'client/showcase.lua'
}

exports {
    'OpenDock',
    'CloseDock',
    'IsDockOpen',
    'UpdateItem',
    'ShowToast',
    'OpenPanel',
    'UpdatePanel',
    'ClosePanel',
    'IsPanelOpen',
    'OpenDialog',
    'CloseDialog',
    'IsDialogOpen',
    'PromptInput',
    'OpenConfirm',
    'CloseConfirm',
    'IsConfirmOpen',
    'StartProgressBar',
    'CancelProgressBar',
    'IsProgressBarActive',
    'NativeHUD_SetHonor',
    'NativeHUD_StartTimer',
    'NativeHUD_StopTimer',
    'NativeHUD_ShowCash',
    'NativeHUD_SetRank',
    'NativeHUD_SetBounty'
}


