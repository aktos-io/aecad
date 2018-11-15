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
