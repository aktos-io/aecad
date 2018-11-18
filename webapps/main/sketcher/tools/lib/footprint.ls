require! './container': {Container}
require! 'aea/do-math': {mm2px}

export class Footprint extends Container
    (data) ->
        # data:
        #   name: required
        #   position: optional
        #   rotation: optional
        #   init: current drawing
        super ...

    move: (displacement, opts={}) ->
        # Moves the component with a provided amount of displacement. Default: Relative
        # opts:
        #       absolute: [Bool] move absolute amount
        unless opts.absolute
            @g.position.set @g.position.add displacement
        else
            @g.position.set displacement

        for @pads
            # DO NOT USE yadayada here!
            ..on-move ...arguments

    make-border: ->
        if @get-data \border
            @add-part 'border', new @scope.Shape.Rectangle do
                center: @g.bounds.center
                size:
                    x: that.width |> mm2px
                    y: that.height |> mm2px
                stroke-color: 'LightSeaGreen'
                stroke-width: 0.2
                parent: @g
                radius: 0.3

    _loader: (item) ->
        console.warn "We have a stray item, selecting it: ", item
        item.selected = yes
    
