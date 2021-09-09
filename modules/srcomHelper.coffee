fetch = require 'node-fetch'
_ = require 'lodash'

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

get_one_leaderboard = (track, category) ->
    fetch "https://www.speedrun.com/api/v1/leaderboards/#{ids.game}/level/#{ids.tracks[track]}/#{ids.categories[category]}"
        .then((response) => response.json())
        .then((json) => 
            for run from json.data.runs
                {
                    track: track
                    category: category
                    place: run.place
                    userid: run.run.players[0].id
                    date: run.run.date
                    time: run.run.times.primary
                }
        )

exports.getruns = () ->
    boards = []
    for category of ids.categories
        for track of ids.tracks
            boards.push get_one_leaderboard(track, category)
    _.flatten await Promise.all boards

exports.get_username = (userid) ->
    fetch "https://www.speedrun.com/api/v1/users/#{userid}"
    .then((response) => response.json())
    .then((json) => json.data.names.international)