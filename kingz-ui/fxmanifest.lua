fx_version 'cerulean'
game 'gta5'

author 'File Agent'
description 'A simple and clean weed growing script, integrated with kingz-drugs.'
version '1.1.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'qb-core',
    'qb-target',
    'qb-menu',
    'kingz-drugs' -- Ensures kingz-drugs loads first
}
