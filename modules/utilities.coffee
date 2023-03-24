tinyduration = require 'tinyduration'
AsciiTable = require 'ascii-table'

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

exports.makeTable = (scores) ->
    t = new AsciiTable()
        .setHeading("Pos", "Score", "Name")
        .setHeadingAlignRight('Pos')
        .setHeadingAlignRight('Score')
        .setHeadingAlignLeft('Name')

    t.addRow(scoreObj.pos, scoreObj.score, scoreObj.name) for scoreObj in scores
    t.toString()

exports.trackCategoryConverter = (abbr) ->
    category = if abbr.endsWith('100') then "100 Points" else "Time Attack"

    track = if abbr.startsWith('cc') then "Coventry Cove"
    else if abbr.startsWith('mmm') then "Mount Mayhem"
    else if abbr.startsWith('ii') then "Inferno Isle"
    else if abbr.startsWith('ss') then "Sunset Sands"
    else if abbr.startsWith('mms') then "Metro Madness"
    else if abbr.startsWith('ww') then "Wicked Woods"
    else null
    return track unless track

    return { category, track }

    