fx_version 'adamant'

game 'gta5'

author 'Tizas <ESX Framework>'
description 'Taxi job'
lua54 'yes'
version '2.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@es_extended/locale.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/modules/billing.lua',
    'server/modules/npcJob.lua',
    'server/modules/stashes.lua'
}

client_scripts {
    'client/main.lua',
    'client/modules/billing.lua',
    'client/modules/cloakroom.lua',
    'client/modules/npcJob.lua',
    'client/modules/repairKit.lua',
    'client/modules/stashes.lua',
    'client/modules/playerManagement.lua'
}

files {
    'locales/*.lua'
}

dependencies {
   'es_extended',
   'esx_billing',
   'esx_textui',
   'esx_society'
}
