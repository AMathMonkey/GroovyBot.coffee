fetch = require 'node-fetch'
utilities = require './utilities'

ids = {
    game: 'w6j992dj'
    categories: {
        'Time Attack': 'z27w7ok0'
        '100 Points': 'wk6gyrd1'
    }
    tracks: {
        'Coventry Cove': 'rw632nw7'
        'Mount Mayhem': 'n93ok790'
        'Inferno Isle': 'z98np79l'
        'Sunset Sands': 'rdnn3ndm'
        'Metro Madness': 'ldy2qjw3'
        'Wicked Woods': 'gdr2r89z'
    }
}

getOneLeaderboard = (track, category) ->
    fetch "https://www.speedrun.com/api/v1/leaderboards/#{ids.game}/level/#{ids.tracks[track]}/#{ids.categories[category]}"
        .then((response) -> response.json())
        .then((json) ->
            {
                track: track
                category: category
                userid: run.run.players[0].id
                date: run.run.date
                time: utilities.formatTime(run.run.times.primary)
            } for run in json.data.runs
        )

exports.getRuns = ->
    boards = []
    for category of ids.categories
        for track of ids.tracks
            boards.push getOneLeaderboard(track, category)
    (await Promise.all boards).flat()

exports.getUsername = (userid) ->
    fetch "https://www.speedrun.com/api/v1/users/#{userid}"
    .then((response) -> response.json())
    .then((json) -> json.data.names.international)