fx_version 'cerulean'
game 'gta5'

author 'SanTy'
description 'Mechanic npc job for QBCORE/ESX'

lua54 'yes'



-- Shared knižnice a konfigurácia
shared_scripts {
    'config.lua',
    '@ox_lib/init.lua'
}

-- Klientské skripty
client_scripts {
    'client/*.lua'
}

-- Serverové skripty
server_scripts {
    'server/*.lua'
}


