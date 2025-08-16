import * as dbHelper from './dbHelper.js'
import * as utilities from './utilities.js'

export runsperplayer = ->
    result = await do dbHelper.getNumberOfRunsPerPlayer
    message = [
        'Number of different IL runs submitted by each player (12 maximum):\n'
        "#{row.name}: #{row.count}" for row in result...
    ].join '\n'
    [message, false]

export newestruns = (numruns) ->
    unless numruns? and (1 <= numruns <= 10)
        invalidArg = true
        numruns = 5

    result = await dbHelper.getNewestRuns numruns
        
    header =
        if numruns is 1 then 'Here is the newest run on the board'
        else "Here are the #{numruns} newest runs on the board"

    message = [
        "#{header}#{if invalidArg then " (can display between 1 and 10)" else ''}:\n",
        "#{run.track} - #{run.category} in #{run.time}
        by #{run.name}, #{utilities.makeOrdinal run.place} place" for run in result...
    ].join '\n'
    [message, false]

export longeststanding = ->
    strs = for run in await do dbHelper.getLongestStandingWRRuns
        years = Math.floor run.age / 365
        yearPart = if years then "#{years} year#{if years is 1 then '' else 's'} and " else ''
        days = run.age % 365
        dayPart = "#{days} day#{if days is 1 then '' else 's'}"
        "#{run.track} - #{run.category} in #{run.time} by #{run.name}, #{yearPart}#{dayPart} old"
    message = ['WR runs sorted by longest standing:\n', strs...].join '\n'
    [message, false]
    
export pointrankings = -> [await do dbHelper.getPointRankings, false]

export ilranking = (name, abbr) ->
    name = do (do (name ? '').trim).toLowerCase
    abbr = do (do (abbr ? '').trim).toLowerCase

    trackAndCategory = utilities.trackCategoryConverter abbr
    return ['Invalid category - please use track initials like cc or MMm100', true] unless trackAndCategory?

    run = await dbHelper.getOneRunForILRanking { name, trackAndCategory... }

    if run then [
        "#{run.track} - #{run.category} in #{run.time}
        by #{run.name}, #{utilities.makeOrdinal run.place} place"
        false
    ] else ['No run matching that username', true]