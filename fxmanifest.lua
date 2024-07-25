fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

description 'Body Disposal Script'
version '1.0.0'
author 'Phil'

client_scripts {
    'config.lua',
    'client.lua'
}

server_scripts {
    'server.lua'
}


dependencies {
    'rsg-core'
}