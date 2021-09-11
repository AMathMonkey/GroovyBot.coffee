tinyduration = require 'tinyduration'

dbHelper = require './dbHelper'

exports.encloseInCodeBlock = (message) ->
    "```\n#{message}\n```"

exports.formatTime = (timeString) ->
    timeObj = tinyduration.parse timeString
    "#{timeObj.minutes}:#{(timeObj.seconds ? 0).toFixed(2).padStart(5, "0")}"

exports.makeOrdinal = (n) ->
    suffix = if 11 <= (n % 100) <= 13 then "th"
    else ["th", "st", "nd", "rd", "th"][Math.min(n % 10, 4)]
    n + suffix

exports.calcScore = (placing) ->
    switch placing
        when 1 then 100
        when 2 then 97
        else Math.max(0, 98 - placing)

exports.daysSince = (dateString) ->
    Math.ceil( ((new Date) - (new Date(dateString))) / 8.64e7 )

exports.getNewRunsString = (runs) ->
    (for run from runs
        runInDB = await dbHelper.runInDB run
        unless runInDB then "New run! #{run.track} - #{run.category} in #{@formatTime(run.time)} by #{run.name}"
        else continue)
    .join('\n')