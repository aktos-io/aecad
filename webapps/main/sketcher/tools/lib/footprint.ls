require! './container': {Container}
require! 'aea/do-math': {mm2px}

export class Footprint extends Container
    iface: ~
        -> @get-data('labels')
        (val) -> @set-data 'labels', val

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
        if opts=(@get-data \border)
            if opts.dia
                type = 'Circle'
                dimensions =
                    radius: mm2px opts.dia / 2
            else
                type = 'Rectangle'
                dimensions =
                    size:
                        x: mm2px opts.width
                        y: mm2px opts.height
                    radius: 0.3

            @add-part 'border', new @scope.Shape[type] dimensions <<< do
                center: @g.bounds.center
                stroke-color: 'LightSeaGreen'
                stroke-width: 0.2
                parent: @g

    _loader: (item) ->
        console.warn "We have a stray item, selecting it: ", item
        item.selected = yes

    print-mode: ->
        @border?.remove!
        super ...
