require('dotenv').config()
require 'coffeescript/register'
{ Client, Intents } = require 'discord.js'
fetch = require 'node-fetch'
_ = require 'lodash'
DBHelper = require './groovybotsetup'

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

getruns = ->
    _.flattenDeep (for category, cid of ids.categories
        for track, tid of ids.tracks
            response = await fetch "https://www.speedrun.com/api/v1/leaderboards/#{ids.game}/level/#{tid}/#{cid}"
            throw new Error "Response code #{response.status} with text #{response.statusText}" unless response.ok
            json = await response.json()
            json.data.runs.map (run) ->
                track: track
                category: category
                place: run.place
                userid: run.run.players[0].id
                date: run.run.date
                time: run.run.times.primary
    )

do ->
    dbHelper = new DBHelper
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

client.on 'interactionCreate', (interaction) ->
	return unless interaction.isCommand()

	switch interaction.commandName
		when 'ping' then await interaction.reply 'Pong!' 

client.login process.env.DISCORD_TOKEN
