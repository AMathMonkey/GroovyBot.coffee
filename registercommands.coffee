require('dotenv').config()
token = process.env.DISCORD_TOKEN

{ REST } = require('@discordjs/rest')
{ Routes } = require('discord-api-types/v9')
{ SlashCommandBuilder } = require('@discordjs/builders')

commands = [
    new SlashCommandBuilder()
        .setName('runsperplayer')
        .setDescription('Returns how many of the 12 IL runs each player has submitted')
    new SlashCommandBuilder()
        .setName('newestruns')
        .setDescription('Returns the newest runs on the board')
        .addIntegerOption((option) ->
            option
                .setName('numruns')
                .setDescription('Number of runs to display, between 1 and 10')),
    new SlashCommandBuilder()
        .setName('longeststanding')
        .setDescription('Returns all WR runs in oldest to newest order')
    new SlashCommandBuilder()
        .setName('pointrankings')
        .setDescription('Returns the point rankings table on-demand')
    new SlashCommandBuilder()
        .setName('ilranking')
        .setDescription('Returns the details of a specific run you specify by username and track/category abbreviation')
        .addStringOption((option) ->
            option
                .setName('name')
                .setDescription('SRC username of the runner')
                .setRequired(true)
        )
        .addStringOption((option) ->
            option
                .setName('abbr')
                .setDescription("Two- or three-letter track code, optionally followed by '100' if 100 Points")
                .setRequired(true)
        )
]

clientId = '760174542961770519'
guildId = '292711577566707715'

rest = new REST({ version: '9' }).setToken(token)

do ->
	try
		console.log 'Started refreshing application (/) commands.'
		await rest.put(Routes.applicationGuildCommands(clientId, guildId), { body: commands })
		console.log 'Successfully reloaded application (/) commands.'
	catch error then console.error error
