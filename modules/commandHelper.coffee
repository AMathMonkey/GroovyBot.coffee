dbHelper = require './dbHelper'
utilities = require './utilities'

exports.runsperplayer = ->
    result = await dbHelper.getNumberOfRunsPerPlayer()
    [
        "Number of different IL runs submitted by each player (12 maximum):\n"
        "#{row.name}: #{row.count}" for row in result...
    ].join("\n")

exports.newestruns = (numruns) ->
    unless numruns? and (1 <= numruns <= 10)
        invalidArg = true
        numruns = 5

    result = await dbHelper.getNewestRuns(numruns)
        
    header =
        if numruns is 1 then "Here is the newest run on the board"
        else "Here are the #{numruns} newest runs on the board"

    [
        "#{header}#{if invalidArg then " (can display between 1 and 10)" else ''}:\n",
        "#{run.track} - #{run.category} in #{run.time}
        by #{run.name}, #{utilities.makeOrdinal run.place} place" for run in result...
    ].join('\n')

exports.longeststanding = ->
    wrRuns = await dbHelper.getLongestStandingWRRuns()
    [
        "WR runs sorted by longest standing:\n"
        "#{run.track} - #{run.category} in #{run.time} by #{run.name},
        #{run.age} day#{if run.age is 1 then '' else 's'} old" for run in wrRuns...
    ].join('\n')
    
exports.pointrankings = dbHelper.getPointRankings

exports.ilranking = (name, abbr) ->
    name = (name ? '').trim().toLowerCase()
    abbr = (abbr ? '').trim().toLowerCase()

    trackAndCategory = utilities.trackCategoryConverter abbr
    return "Invalid category - please use track initials like cc or MMm100" unless trackAndCategory?

    run = await dbHelper.getOneRunForILRanking({ name, trackAndCategory... })

    if run then "#{run.track} - #{run.category} in #{run.time}
    by #{run.name}, #{utilities.makeOrdinal run.place} place"
    else "No run matching that username"