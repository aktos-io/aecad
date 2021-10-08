export class Chronometer
    -> 
        @start-time = null
        @_start_time = {}
        @_pause = {}

    now: ~
        -> 
            new Date! .getTime()

    start: (id) ->
        @start-time = @now
        if id?
            @_start_time[id] = @now

    measure: (id) -> 
        duration = @now - @_start_time[id]
        delete @_start_time[id]
        "#{oneDecimal duration/1000}s" 

    end: -> 
        "#{oneDecimal (@now - @start-time)/1000}s"  

    pause: (id) -> 
        @_pause[id] = @now 

    resume: (id) -> 
        unless id of @_start_time
            @start id 
        else 
            @_start_time[id] += (@now - @_pause[id])


