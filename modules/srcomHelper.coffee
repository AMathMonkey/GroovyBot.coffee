fetch = require 'node-fetch'
utilities = require './utilities'

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

getOneLeaderboard = (track, category) ->
    response = await fetch "https://www.speedrun.com/api/v1/leaderboards/#{ids.game}/level/#{ids.tracks[track]}/#{ids.categories[category]}"
    json = await response.json()
    runs = entry.run for entry in json.data.runs
    for run in runs
        track: track
        category: category
        userid: run.players[0].id
        date: run.date
        time: utilities.formatTime(run.times.primary)

exports.getRuns = ->
    boardsGen = ->
        for category of ids.categories
            for track of ids.tracks
                yield getOneLeaderboard(track, category)
    (await Promise.all [boardsGen()...]).flat()

exports.getUsername = (userid) ->
    response = await fetch "https://www.speedrun.com/api/v1/users/#{userid}"
    json = await response.json()
    json.data.names.international
