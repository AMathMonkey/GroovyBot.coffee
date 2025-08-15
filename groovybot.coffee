import 'dotenv/config'

import ReadwriteLock from 'readwrite-lock'
import { Client, GatewayIntentBits  } from 'discord.js'

import * as dbHelper from './modules/dbHelper.js'
import * as commandHelper from './modules/commandHelper.js'
import * as utilities from './modules/utilities.js'
import * as srcomHelper from './modules/srcomHelper.js'

POINT_RANKINGS_DELAY = 60 * 60 * 1000 # 1 hour

lock = new ReadwriteLock()

client = new Client({ intents: [GatewayIntentBits.Guilds] })

getDate = -> new Date().toISOString()

pointRankingsTask = (channelId) ->
    channel = client.channels.resolve channelId
    console.log "#{getDate()}: Checking leaderboards"
    
    runs = await srcomHelper.getRuns()
    await lock.acquireWrite('db', () ->
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
            message = message.join ''
            try await channel.send message
            catch then console.log "Failed to send message; it was probably too long. Message was:\n#{message}"
        else console.log "No new runs"
    )
    
    # schedules itself to run again after delay
    setTimeout pointRankingsTask, POINT_RANKINGS_DELAY, channelId

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
    
    await pointRankingsTask allowedChannelIds[0]
    # Only add this event handler after pointRankingsTask runs for the first time
    client.on 'interactionCreate', (i) ->
        return unless i.isCommand() 
        unless i.channelId in allowedChannelIds
            return await i.reply(
                content: 'I only reply to commands issued in the GroovyBot channel.'
                ephemeral: true
            )
        console.log "#{getDate()}: Recieved command #{i.commandName} from user #{i.user.username}, options: #{JSON.stringify(i.options.data)}"
        await lock.acquireRead('db', () ->
            [message, ephemeral] = await switch i.commandName
                when 'newestruns' then commandHelper.newestruns(i.options.getInteger('numruns'))
                when 'runsperplayer' then commandHelper.runsperplayer()
                when 'longeststanding' then commandHelper.longeststanding()
                when 'pointrankings' then commandHelper.pointrankings()
                when 'ilranking' then commandHelper.ilranking(
                    i.options.getString('name')
                    i.options.getString('abbr')
                )
            await i.reply(
                content: utilities.encloseInCodeBlock message
                ephemeral: ephemeral
            )
            console.log "#{getDate()}: Sent reply successfully! Ephemeral: #{ephemeral}"
        )
client.login process.env.DISCORD_TOKEN
