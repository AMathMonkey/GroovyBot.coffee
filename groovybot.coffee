require('dotenv').config()
require 'coffeescript/register'

{ Client, Intents } = require 'discord.js'

dbHelper = require './modules/dbHelper'
commandHelper = require './modules/commandHelper'
utilities = require './modules/utilities'
srcomHelper = require './modules/srcomHelper'

client = new Client({ intents: [Intents.FLAGS.GUILDS] })

getDate = -> new Date().toUTCString()

pointRankingsTask = (channelID) ->
    channel = client.channels.resolve channelID
    console.log "#{getDate()}: Checking leaderboards"
    
    runs = await srcomHelper.getRuns()
    await dbHelper.updateUserCache runs
    runsWithNames = await dbHelper.addUsernames runs
    newRunsString = await dbHelper.getNewRunsString runsWithNames

    unless newRunsString
        console.log "No new runs"
        return
    
    console.log "New runs found"
    message = utilities.encloseInCodeBlock newRunsString
    await dbHelper.insertRuns runs
    await dbHelper.updateScores()
    scores = await dbHelper.getScores()
    table = utilities.makeTable scores
    oldTable = await dbHelper.getPointRankings()

    if table is oldTable
        console.log "But rankings unchanged"
        message += utilities.encloseInCodeBlock "But rankings are unchanged"
    else
        console.log "Point rankings update"
        message += utilities.encloseInCodeBlock "Point rankings update!\n#{table}"
        await dbHelper.saveTable table

    try await channel.send message
    catch error then console.log "Failed to send message; it was probably too long. Message was:\n#{message}"

    # schedules itself to run again in 20 minutes
    setInterval pointRankingsTask, 1.2e6 ### 20 minutes ###, channelID

GROOVYBOT_CHANNEL_IDS = []
client.once 'ready', ->
    console.log "#{getDate()}: Logged in as #{client.user.tag}!"
    groovybotChannel = client.channels.cache.find((x) -> x.name is "groovybot")
    groovytestChannel = client.channels.cache.find((x) -> x.name is "groovytest")
    
    if process.env.MODE is 'PROD'
        console.log 'Running in production mode'
        GROOVYBOT_CHANNEL_IDS.push groovybotChannel.id
    else console.log 'Running in test mode'

    GROOVYBOT_CHANNEL_IDS.push groovytestChannel.id
    
    pointRankingsChannel = GROOVYBOT_CHANNEL_IDS[0]
    pointRankingsTask pointRankingsChannel
    

client.on 'interactionCreate', (i) ->
    return unless i.isCommand() and i.channelId in GROOVYBOT_CHANNEL_IDS
    console.log "#{getDate()}: Recieved command #{i.commandName} from user #{i.user.username}"

    switch i.commandName
        when 'newestruns'
            message = await commandHelper.newestruns(i.options.getInteger('numruns'))
            i.reply(utilities.encloseInCodeBlock message)

        when 'runsperplayer'
            message = await commandHelper.runsperplayer()
            i.reply(utilities.encloseInCodeBlock message)

        when 'longeststanding'
            message = await commandHelper.longeststanding()
            i.reply(utilities.encloseInCodeBlock message)

        when 'pointrankings'
            message = await commandHelper.pointrankings()
            i.reply(utilities.encloseInCodeBlock message)

        when 'ilranking'
            message = await commandHelper.ilranking(
                i.options.getString('name') or ''
                i.options.getString('abbr') or ''
            )
            i.reply(utilities.encloseInCodeBlock message)
        
client.login process.env.DISCORD_TOKEN
