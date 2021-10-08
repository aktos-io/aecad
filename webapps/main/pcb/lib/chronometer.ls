export class Chronometer
    -> 
        @start-time = null
        @duration = null 
        @_start_time = {}

    start: (id) ->
        @start-time = new Date! .getTime()
        if id?
            @_start_time[id] = @start-time

    measure: (id) -> 
        duration = (new Date! .getTime()) - @_start_time[id]
        delete @_start_time[id]
        "#{oneDecimal duration/1000}s" 

    end: -> 
        @duration = (new Date! .getTime()) - @start-time 
        return @measurement

    measurement: ~
        -> 
            "#{oneDecimal @duration/1000}s" 
