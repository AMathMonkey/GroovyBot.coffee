tinyduration = require 'tinyduration'
{ AsciiTable3, AlignmentEnum } = require 'ascii-table3'

TRACK_ABBR_MAPPINGS = [
    ['cc', 'Coventry Cove'],
    ['mmm', 'Mount Mayhem'],
    ['ii', 'Inferno Isle'],
    ['ss', 'Sunset Sands'],
    ['mms', 'Metro Madness'],
    ['ww', "Wicked Woods"]
]

exports.encloseInCodeBlock = (message) -> "```\n#{message}\n```"

exports.formatTime = (timeString) ->
    timeObj = tinyduration.parse timeString
    "#{timeObj.minutes}:#{(timeObj.seconds ? 0).toFixed(2).padStart(5, "0")}"

exports.makeOrdinal = (n) ->
    suffix = if 11 <= (n % 100) <= 13 then "th"
    else ["th", "st", "nd", "rd", "th"][Math.min(n % 10, 4)]
    String(n).concat(suffix)

exports.calcScore = (placing) ->
    switch placing
        when 1 then 100
        when 2 then 97
        else Math.max(0, 98 - placing)

exports.makeTable = (scores) ->
    new AsciiTable3()
        .setHeading("Pos", "Score", "Name")
        .setAligns([AlignmentEnum.RIGHT, AlignmentEnum.RIGHT, AlignmentEnum.LEFT])
        .addRowMatrix([s.pos, s.score, s.name] for s in scores)
        .toString()

exports.trackCategoryConverter = (abbr) ->
    category = if abbr.endsWith('100') then "100 Points" else "Time Attack"

    mapping = TRACK_ABBR_MAPPINGS.find (m) -> abbr.startsWith m[0]

    { category, track: mapping[1] } if mapping?
