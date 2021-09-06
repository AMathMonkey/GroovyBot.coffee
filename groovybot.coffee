require('dotenv').config()
require 'coffeescript/register'
{ Client, Intents } = require 'discord.js'
fetch = require 'node-fetch'
_ = require 'lodash'
dbHelper = new (require './DBhelper')
commandHelper = new (require './CommandHelper')
tinyduration = require 'tinyduration'

ids = 
    game: 'w6j992dj'
    categories:
        'Time Attack': 'z27w7ok0'
        '100 Points': 'wk6gyrd1'
    tracks: 
        'Coventry Cove': 'rw632nw7'
        'Mount Mayhem': 'n93ok790'
        'Inferno Isle': 'z98np79l'
        'Sunset Sands': 'rdnn3ndm'
        'Metro Madness': 'ldy2qjw3'
        'Wicked Woods': 'gdr2r89z'

getruns = () ->
    leaderboards = _.flatten(for category, cid of ids.categories
        for track, tid of ids.tracks
            {
                track
                category
                req:
                    fetch "https://www.speedrun.com/api/v1/leaderboards/#{ids.game}/level/#{tid}/#{cid}"
                    .then((response) => response.json())
            }
    )
    return _.flatten(for leaderboard from leaderboards
        for run from (await leaderboard.req).data.runs
            {
                track: leaderboard.track
                category: leaderboard.category
                place: run.place
                userid: run.run.players[0].id
                date: run.run.date
                time: run.run.times.primary
            }
    )

enclose_in_code_block = (message) ->
    "```\n#{message}\n```"

format_time = (time_string) ->
    time_obj = tinyduration.parse time_string
    "#{time_obj.minutes}:#{(time_obj.seconds ? 0).toFixed(2).padStart(5, "0")}"

make_ordinal = (n) ->
    suffix = if 11 <= (n % 100) <= 13 then "th"
    else ["th", "st", "nd", "rd", "th"][Math.min(n % 10, 4)]
    n + suffix

calc_score = (placing) ->
    switch placing
        when 1 then 100
        when 2 then 97
        else Math.max(0, 98 - placing)


do () ->
    runs = await getruns()
    await dbHelper.insert_runs(runs)


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
    return unless i.isCommand() and i of GROOVYBOT_CHANNEL_IDS

    switch i.commandName
        when 'ping' then await i.reply 'Pong!' 

        when 'runsperplayer'
            message = await commandHelper.get_number_of_runs_per_player()
            i.reply(enclose_in_code_block message)
        


client.login process.env.DISCORD_TOKEN
