import 'dotenv/config'

import { Client, GatewayIntentBits, MessageFlags } from 'discord.js'

import * as dbHelper from './modules/dbHelper.js'
import * as commandHelper from './modules/commandHelper.js'
import * as utilities from './modules/utilities.js'
import * as srcomHelper from './modules/srcomHelper.js'

POINT_RANKINGS_DELAY = 60 * 60 * 1000 # 1 hour

client = new Client { intents: [GatewayIntentBits.Guilds] }

pointRankingsTask = (channelId) ->
    channel = client.channels.resolve channelId
    console.log "#{do utilities.getDate}: Checking leaderboards"
    
    runs = await do srcomHelper.getRuns
    await dbHelper.updateUserCache runs
    runsWithNames = dbHelper.getRunsWithUsernames runs
    newRunsString = dbHelper.getNewRunsString runsWithNames

    if newRunsString
        console.log 'New runs found'
        message = [utilities.encloseInCodeBlock newRunsString]
        dbHelper.insertRuns runs
        do dbHelper.updateScores
        scores = do dbHelper.getScores
        table = utilities.makeTable scores
        oldTable = do dbHelper.getPointRankings

        if table is oldTable
            console.log 'But rankings unchanged'
            message.push utilities.encloseInCodeBlock 'But rankings are unchanged'
        else
            console.log 'Point rankings update'
            message.push utilities.encloseInCodeBlock "Point rankings update!\n#{table}"
            dbHelper.saveTable table
        message = message.join ''
        try await channel.send message
        catch then console.log "Failed to send message; it was probably too long. Message was:\n#{message}"
    else console.log 'No new runs'
    
    # schedules itself to run again after delay
    setTimeout pointRankingsTask, POINT_RANKINGS_DELAY, channelId

client.once 'ready', ->
    modeIsProd = process.env.MODE is 'PROD'
    console.log "#{do utilities.getDate}: Logged in as #{client.user.tag}!"
    groovybotChannel = client.channels.cache.find (x) -> x.name is 'groovybot'
    groovytestChannel = client.channels.cache.find (x) -> x.name is 'groovytest'
    
    console.log "Running in #{if modeIsProd then 'production' else 'test'} mode"

    allowedChannelIds = [
        (if modeIsProd then [groovybotChannel.id] else [])...
        groovytestChannel.id
    ]
    
    await pointRankingsTask allowedChannelIds[0]
    # Only add this event handler after pointRankingsTask runs for the first time
    client.on 'interactionCreate', (i) ->
        return unless do i.isCommand 
        unless i.channelId in allowedChannelIds
            return await i.reply
                content: 'I only reply to commands issued in the GroovyBot channel.'
                flags: MessageFlags.Ephemeral
        console.log "#{do utilities.getDate}: Recieved command #{i.commandName} from user #{i.user.username}, options: #{JSON.stringify(i.options.data)}"
        [message, ephemeral] = await switch i.commandName
            when 'newestruns' then commandHelper.newestruns i.options.getInteger 'numruns'
            when 'runsperplayer' then do commandHelper.runsperplayer
            when 'longeststanding' then do commandHelper.longeststanding
            when 'pointrankings' then do commandHelper.pointrankings
            when 'ilranking' then commandHelper.ilranking (i.options.getString 'name'), i.options.getString 'abbr'
        await i.reply {
            content: utilities.encloseInCodeBlock message
            (ephemeral and {flags: MessageFlags.Ephemeral})...
        }
        console.log "#{do utilities.getDate}: Sent reply successfully! Ephemeral: #{ephemeral}"
client.login process.env.DISCORD_TOKEN
