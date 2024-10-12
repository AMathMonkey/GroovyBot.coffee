import tinyduration from 'tinyduration'
import { AsciiTable3, AlignmentEnum } from 'ascii-table3'

TRACK_ABBR_MAPPINGS = [
    ['cc', 'Coventry Cove'],
    ['mmm', 'Mount Mayhem'],
    ['ii', 'Inferno Isle'],
    ['ss', 'Sunset Sands'],
    ['mms', 'Metro Madness'],
    ['ww', "Wicked Woods"]
]

export encloseInCodeBlock = (message) -> "```\n#{message}\n```"

export formatTime = (timeString) ->
    timeObj = tinyduration.parse timeString
    "#{timeObj.minutes}:#{(timeObj.seconds ? 0).toFixed(2).padStart(5, '0')}"

export makeOrdinal = (n) ->
    String(n).concat(
        if 11 <= (n % 100) <= 13 then 'th'
        else ['th', 'st', 'nd', 'rd', 'th'][Math.min(n % 10, 4)]
    )

export calcScore = (placing) ->
    switch placing
        when 1 then 100
        when 2 then 97
        else Math.max(0, 98 - placing)

export makeTable = (scores) ->
    new AsciiTable3()
        .setHeading('Pos', 'Score', 'Name')
        .setAligns([AlignmentEnum.RIGHT, AlignmentEnum.RIGHT, AlignmentEnum.LEFT])
        .addRowMatrix([s.pos, s.score, s.name] for s in scores)
        .toString()

export trackCategoryConverter = (abbr) ->
    category = if abbr.endsWith('100') then '100 Points' else 'Time Attack'
    mapping = TRACK_ABBR_MAPPINGS.find (m) -> abbr.startsWith m[0]
    { category, track: mapping[1] } if mapping?
