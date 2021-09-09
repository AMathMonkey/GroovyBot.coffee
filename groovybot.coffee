require('dotenv').config()
require 'coffeescript/register'

{ Client, Intents } = require 'discord.js'

dbHelper = require './modules/dbHelper'
commandHelper = require './modules/commandHelper'
utilities = require './modules/utilities'
srcomHelper = require './modules/srcomHelper'

do () ->
    runs = await srcomHelper.getruns()
    await dbHelper.insert_runs runs
    await dbHelper.update_user_cache()
    message = await commandHelper.runsperplayer()
    console.log utilities.enclose_in_code_block message
    message = await commandHelper.newestruns(3)
    console.log utilities.enclose_in_code_block message
    message = await commandHelper.longeststanding()
    console.log utilities.enclose_in_code_block message



client = new Client(intents: [Intents.FLAGS.GUILDS])

GROOVYBOT_CHANNEL_IDS
if process.env.MODE is "PROD"
    console.log "Running in production mode"
    GROOVYBOT_CHANNEL_IDS = [760197170686328842, 797386043024343090]
else
    console.log "Running in test mode"
    GROOVYBOT_CHANNEL_IDS = [797386043024343090]

client.once 'ready', () -> 
    console.log "Logged in as #{client.user.tag}!"

client.on 'interactionCreate', (i) ->
    return unless i.isCommand() and i in GROOVYBOT_CHANNEL_IDS

    switch i.commandName
        when 'ping' then await i.reply 'Pong!' 

        when 'runsperplayer'
            message = await commandHelper.get_number_of_runs_per_player()
            i.reply(utilities.enclose_in_code_block message)
        
client.login process.env.DISCORD_TOKEN
