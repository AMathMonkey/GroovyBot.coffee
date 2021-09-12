require('dotenv').config()
require 'coffeescript/register'

{ Client, Intents } = require 'discord.js'

dbHelper = require './modules/dbHelper'
commandHelper = require './modules/commandHelper'
utilities = require './modules/utilities'
srcomHelper = require './modules/srcomHelper'

client = new Client(intents: [Intents.FLAGS.GUILDS])

pointRankingsTask = (channelID) ->
    channel = client.channels.resolve channelID

    console.log "Checking leaderboards @ #{new Date().toLocaleString()}"
    
    runs = await srcomHelper.getruns()
    await dbHelper.updateUserCache runs
    runsWithNames = await dbHelper.addUsernames runs
    newRunsString = await utilities.getNewRunsString runsWithNames

    unless newRunsString
        console.log "No new runs"
        return
    
    console.log "New runs found"
    message = utilities.encloseInCodeBlock newRunsString
    await dbHelper.insertRuns runs
    await dbHelper.updateScores()
    scores = await dbHelper.getScores()
    table = utilities.makeTable scores
    oldTable = await dbHelper.getOldTable()

    if table is oldTable
        console.log "But rankings unchanged"
        message += utilities.encloseInCodeBlock "But rankings are unchanged"
    else
        console.log "Point rankings update"
        message += utilities.encloseInCodeBlock "Point rankings update!\n" + table
        await dbHelper.saveTable table

    try
        await channel.send message
    catch error
        console.log "Failed to send message; it was probably too long"
        console.log message
    
    # message = await commandHelper.runsperplayer()
    # console.log utilities.encloseInCodeBlock message
    # message = await commandHelper.newestruns(3)
    # console.log utilities.encloseInCodeBlock message
    # message = await commandHelper.longeststanding()
    # console.log utilities.encloseInCodeBlock message

GROOVYBOT_CHANNEL_IDS = []
client.once 'ready', () -> 
    console.log "Logged in as #{client.user.tag}!"
    groovybotChannel = client.channels.cache.find((x) -> x.name is "groovybot")
    groovytestChannel = client.channels.cache.find((x) -> x.name is "groovytest")
    
    if process.env.MODE is "PROD"
        console.log "Running in production mode"
        GROOVYBOT_CHANNEL_IDS.push groovybotChannel.id
    else console.log "Running in test mode"

    GROOVYBOT_CHANNEL_IDS.push groovytestChannel.id
    
    pointRankingsChannel = GROOVYBOT_CHANNEL_IDS[0]
    pointRankingsTask pointRankingsChannel
    setInterval pointRankingsTask, 1.2e6 ### 20 minutes ###, pointRankingsChannel

client.on 'interactionCreate', (i) ->
    return unless i.isCommand() and i.channelId in GROOVYBOT_CHANNEL_IDS

    switch i.commandName
        when 'ping' then await i.reply 'Pong!' 

        when 'runsperplayer'
            message = await commandHelper.getNumberOfRunsPerPlayer()
            i.reply(utilities.encloseInCodeBlock message)
        
client.login process.env.DISCORD_TOKEN
