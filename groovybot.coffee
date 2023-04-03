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

pointRankingsTask = (channelId) ->
    channel = client.channels.resolve channelId
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
    setTimeout pointRankingsTask, POINT_RANKINGS_DELAY, channelId
    return

allowedChannelIds = []
client.once 'ready', ->
    modeIsProd = process.env.MODE is 'PROD'
    console.log "#{getDate()}: Logged in as #{client.user.tag}!"
    groovybotChannel = client.channels.cache.find (x) -> x.name is "groovybot"
    groovytestChannel = client.channels.cache.find (x) -> x.name is "groovytest"
    
    console.log "Running in #{if modeIsProd then 'production' else 'test'} mode"

    allowedChannelIds = [
        (if modeIsProd then [groovybotChannel.id] else [])...
        groovytestChannel.id
    ]
    
    pointRankingsTask allowedChannelIds[0]
    

client.on 'interactionCreate', (i) ->
    return unless i.isCommand() and i.channelId in allowedChannelIds
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
    
    i.reply utilities.encloseInCodeBlock message
    return

client.login process.env.DISCORD_TOKEN
