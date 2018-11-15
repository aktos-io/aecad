require! './container': {Container}

export class Footprint extends Container
    (data) ->
        # data:
        #   name: required
        #   position: optional
        #   rotation: optional
        #   init: current drawing
        super ...
        unless @init-with-data arguments.0
            # initialize from scratch
            @data = {type: @constructor.name}
            @data <<<< data
            @parent = @data.parent
            try delete @data.parent
            @g.data = aecad: @data

    move: (displacement, opts={}) ->
        # Moves the component with a provided amount of displacement. Default: Relative
        # opts:
        #       absolute: [Bool] move absolute amount
        unless opts.absolute
            @g.position.set @g.position.add displacement
        else
            @g.position.set displacement
        super ...
