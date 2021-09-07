dbHelper = require './dbHelper'
utilities = require './utilities'

exports.runsperplayer = () ->
    result = await dbHelper.get_number_of_runs_per_player()
    [
        "Number of different IL runs submitted by each player (12 maximum):\n"
        "#{row.name}: #{row.c}" for row from result...
    ].join("\n")

exports.newestruns = (numruns) ->
    invalid_arg = false
    numruns = parseInt(numruns, 10)
    if numruns is NaN or not 1 <= numruns <= 10
        invalid_arg = true
        numruns = 5

    result = await dbHelper.get_newest_runs(numruns)
        
    header = if numruns is 1 then "Here is the newest run on the board"
    else "Here are the #{numruns} newest runs on the board"
    +
    if invalid_arg then "(can display between 1 and 10)" else ''
    +
    ":\n"

    [
        header,
        "#{run.track} - #{run.category} in #{utilities.format_time(run.time)} by #{run.name}, #{utilities.make_ordinal(run.place)} place" for run in result...
    ].join('\n')