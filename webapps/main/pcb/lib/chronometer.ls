export class Chronometer
    -> 
        @start-time = null
        @duration = null 

    start: ->
        @start-time = new Date! .getTime()

    end: -> 
        @duration = (new Date! .getTime()) - @start-time 
        return @measurement

    measurement: ~
        -> 
            "#{oneDecimal @duration/1000}s" 
