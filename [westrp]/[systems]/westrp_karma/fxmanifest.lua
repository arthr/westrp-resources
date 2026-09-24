fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'westrp_karma'
author 'WestRP Engineering Team'
description 'Dynamic Morality, Systemic Karma & Combat Self-Defense Engine for WestRP'
version '1.0.0'

shared_scripts {
    '@westrp_core/init.lua',
    'config.lua',
    'shared/types.lua',
    'shared/tiers.lua'
}

client_scripts {
    'client/combat_detector.lua',
    'client/honor_presenter.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/domain/karma_entity.lua',
    'server/domain/self_defense_pool.lua',
    'server/security/combat_verifier.lua',
    'server/infrastructure/database_adapter.lua',
    'server/infrastructure/framework_adapter.lua',
    'server/services/karma_service.lua',
    'server/main.lua'
}

dependencies {
    'westrp_core',
    'oxmysql'
}
