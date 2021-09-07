dbHelper = new (require './DBHelper.coffee')

class CommandHelper
    runsperplayer: () ->
        result = await dbHelper.get_number_of_runs_per_player()
        [
            "Number of different IL runs submitted by each player (12 maximum):\n"
            "#{row.name}: #{row.c}" for row from result...
        ].join("\n")
    
    


module.exports = CommandHelper