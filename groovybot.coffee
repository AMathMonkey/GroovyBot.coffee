require('dotenv').config()
require 'coffeescript/register'

{ Client, Intents } = require 'discord.js'

dbHelper = require './modules/dbHelper'
commandHelper = require './modules/commandHelper'
utilities = require './modules/utilities'
srcomHelper = require './modules/srcomHelper'

client = new Client({ intents: [Intents.FLAGS.GUILDS] })

getDate = -> new Date().toUTCString()

POINT_RANKINGS_DELAY = 60 * 60 * 1000 # 1 hour

pointRankingsTask = (channelID) ->
    channel = client.channels.resolve channelID
    console.log "#{getDate()}: Checking leaderboards"
    
    runs = await srcomHelper.getRuns()
    await dbHelper.updateUserCache runs
    runsWithNames = await dbHelper.getRunsWithUsernames runs
    newRunsString = await dbHelper.getNewRunsString runsWithNames

    if newRunsString
        console.log "New runs found"
        message = [utilities.encloseInCodeBlock newRunsString]
        await dbHelper.insertRuns runs
        await dbHelper.updateScores()
        scores = await dbHelper.getScores()
        table = utilities.makeTable scores
        oldTable = await dbHelper.getPointRankings()

        if table is oldTable
            console.log "But rankings unchanged"
            message.push utilities.encloseInCodeBlock "But rankings are unchanged"
        else
            console.log "Point rankings update"
            message.push utilities.encloseInCodeBlock "Point rankings update!\n#{table}"
            await dbHelper.saveTable table

        try await channel.send message.join ''
        catch then console.log "Failed to send message; it was probably too long. Message was:\n#{message}"
        
    else console.log "No new runs"

    # schedules itself to run again after delay
    setTimeout pointRankingsTask, POINT_RANKINGS_DELAY, channelID
    return

GROOVYBOT_CHANNEL_IDS = []
client.once 'ready', ->
    modeIsProd = process.env.MODE is 'PROD'
    console.log "#{getDate()}: Logged in as #{client.user.tag}!"
    groovybotChannel = client.channels.cache.find (x) -> x.name is "groovybot"
    groovytestChannel = client.channels.cache.find (x) -> x.name is "groovytest"
    
    console.log "Running in #{if modeIsProd then 'production' else 'test'} mode"

    GROOVYBOT_CHANNEL_IDS = [
        (if modeIsProd then [groovybotChannel] else [])...
        groovytestChannel
    ]
    
    pointRankingsTask GROOVYBOT_CHANNEL_IDS[0]
    

client.on 'interactionCreate', (i) ->
    return unless i.isCommand() and i.channelId in GROOVYBOT_CHANNEL_IDS
    console.log "#{getDate()}: Recieved command #{i.commandName} from user #{i.user.username}"

    message = await switch i.commandName
        when 'newestruns' then commandHelper.newestruns(i.options.getInteger('numruns'))
        when 'runsperplayer' then commandHelper.runsperplayer()
        when 'longeststanding' then commandHelper.longeststanding()
        when 'pointrankings' then commandHelper.pointrankings()
        when 'ilranking' then commandHelper.ilranking(
            i.options.getString('name') or ''
            i.options.getString('abbr') or ''
        )
    
    i.reply(utilities.encloseInCodeBlock message)
    return

client.login process.env.DISCORD_TOKEN
