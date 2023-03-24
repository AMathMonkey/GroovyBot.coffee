dbHelper = require './dbHelper'
utilities = require './utilities'

exports.runsperplayer = ->
    result = await dbHelper.getNumberOfRunsPerPlayer()
    [
        "Number of different IL runs submitted by each player (12 maximum):\n"
        "#{row.name}: #{row.c}" for row in result...
    ].join("\n")

exports.newestruns = (numruns) ->
    invalidArg = false
    numruns = parseInt(numruns, 10)
    if numruns is NaN or not (1 <= numruns <= 10)
        invalidArg = true
        numruns = 5

    result = await dbHelper.getNewestRuns(numruns)
        
    header = (if numruns is 1 then "Here is the newest run on the board"
    else "Here are the #{numruns} newest runs on the board") +
    (if invalidArg then " (can display between 1 and 10)" else '') + ":\n"

    [
        header,
        "#{run.track} - #{run.category} in #{utilities.formatTime(run.time)} by #{run.name}, #{utilities.makeOrdinal(run.place)} place" for run in result...
    ].join('\n')

exports.longeststanding = ->
    wrRuns = await dbHelper.getWRRuns()
    for run in wrRuns
        run.age = utilities.daysSince(run.date)
    wrRuns.sort((run1, run2) -> run2.age - run1.age)

    [
        "WR runs sorted by longest standing:\n"
        "#{run.track} - #{run.category} in #{utilities.formatTime(run.time)} by #{run.name}, #{run.age} day#{if run.age is 1 then '' else 's'} old" for run in wrRuns...
    ].join('\n')
    
exports.pointrankings = ->
    dbHelper.getPointRankings()

exports.ilranking = (name, abbr) ->
    return "Missing arguments! Need a user and a track/category abbreviation" unless name and abbr
    name = name.trim().toLowerCase()
    abbr = abbr.trim().toLowerCase()

    trackAndCategory = utilities.trackCategoryConverter(abbr)
    return "Invalid category - please use track initials like cc or MMm100" unless trackAndCategory?

    run = await dbHelper.getOneRunForILRanking({ name, trackAndCategory... })

    if run then "#{run.track} - #{run.category} in #{utilities.formatTime(run.time)} by #{run.name}, #{utilities.makeOrdinal(run.place)} place"
    else "No run matching that username"