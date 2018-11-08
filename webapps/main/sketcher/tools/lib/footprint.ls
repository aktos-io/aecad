require! './container': {Container}
require! './get-class': {add-class}

export class Footprint extends Container
    (data) ->
        # data:
        #   name: required
        #   position: optional
        #   rotation: optional
        #   init: current drawing
        add-class @constructor
        super {init: data.init}
        unless data.init
            # initialize from scratch
            @data =
                type: @constructor.name

            @data <<<< data
        else
            # initialize with provided data
            @data = data.init.data.aecad

        @g.data = aecad: @data
