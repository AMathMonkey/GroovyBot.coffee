tinyduration = require 'tinyduration'

exports.enclose_in_code_block = (message) ->
    "```\n#{message}\n```"

exports.format_time = (time_string) ->
    time_obj = tinyduration.parse time_string
    "#{time_obj.minutes}:#{(time_obj.seconds ? 0).toFixed(2).padStart(5, "0")}"

exports.make_ordinal = (n) ->
    suffix = if 11 <= (n % 100) <= 13 then "th"
    else ["th", "st", "nd", "rd", "th"][Math.min(n % 10, 4)]
    n + suffix

exports.calc_score = (placing) ->
    switch placing
        when 1 then 100
        when 2 then 97
        else Math.max(0, 98 - placing)

exports.days_since = (date_string) ->
    Math.ceil( ((new Date) - (new Date(date_string))) / 8.64e7 )