import * as dbHelper from './dbHelper.js'
import * as utilities from './utilities.js'
import { MessageFlags } from 'discord.js'

CATEGORY_ORDERING = ['Time Attack', '100 Points']
TRACK_ORDERING = ['Coventry Cove', 'Mount Mayhem', 'Inferno Isle', 'Sunset Sands', 'Metro Madness', 'Wicked Woods']

export runsperplayer = ->
    result = do dbHelper.getNumberOfRunsPerPlayer
    message: [
        'Number of different IL runs submitted by each player (12 maximum):\n'
        "#{row.name}: #{row.count}" for row in result...
    ].join '\n'

export newestruns = (numruns) ->
    unless numruns? and (1 <= numruns <= 10)
        invalidArg = true
        numruns = 5

    result = dbHelper.getNewestRuns numruns
        
    header =
        if numruns is 1 then 'Here is the newest run on the board'
        else "Here are the #{numruns} newest runs on the board"

    message: [
        "#{header}#{if invalidArg then " (can display between 1 and 10)" else ''}:\n",
        utilities.formatRun run for run in result...
    ].join '\n'

export longeststanding = ->
    strs = for run in do dbHelper.getLongestStandingWRRuns
        years = Math.floor run.age / 365
        yearPart = if years then "#{years} year#{if years is 1 then '' else 's'} and " else ''
        days = run.age % 365
        dayPart = "#{days} day#{if days is 1 then '' else 's'}"
        "#{run.track} - #{run.category} in #{run.time} by #{run.name}, #{yearPart}#{dayPart} old"
    message: ['WR runs sorted by longest standing:\n', strs...].join '\n'
    
export pointrankings = -> {message: do dbHelper.getTable}

export ilranking = (name, abbr) ->
    name = do (name ? '').trim
    abbr = do (abbr ? '').trim().toLowerCase

    trackAndCategory = utilities.trackCategoryConverter abbr
    return {message: 'Invalid category - please use track initials like cc or MMm100'} unless trackAndCategory?

    run = dbHelper.getOneRunForILRanking { name, trackAndCategory... }
    if run then {message: utilities.formatRun run} else {message: 'No run matching that username', flags: MessageFlags.Ephemeral}

export runsforuser = (name) ->
    name = do (name ? '').trim
    runs = dbHelper.getRunsForUser name
    runs.sort (a, b) ->
        if (a1 = CATEGORY_ORDERING.indexOf a.category) isnt (b1 = CATEGORY_ORDERING.indexOf b.category) then a1 - b1
        else (TRACK_ORDERING.indexOf a.track) - (TRACK_ORDERING.indexOf b.track)
    if runs.length then {message: (utilities.formatRun run for run in runs).join '\n'}
    else {message: 'No runs matching that username', flags: MessageFlags.Ephemeral}
