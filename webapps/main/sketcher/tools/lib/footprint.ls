require! './container': {Container}
require! 'aea/do-math': {mm2px}
require! 'aea/merge': {based-on}

export class Footprint extends Container
    ->
        super ...
        unless @resuming
            <~ sleep 20ms
            data = @data
            # set side if present
            if data.side
                @set-data \side, ''
                @set-side that
                @send-to-layer \gui

            # FIXME: rotation must be after set-side at the moment
            if data.rotation
                @set-data \rotation, 0
                @rotate that

    iface: ~
        # Interface settings should actually be static (they are declared
        # as the first thing in a component/circuit. However, as this information
        # might be generated dynamically on creation time, it is useful to
        # provide a caching mechanism)
        -> @get-data('_iface')
        (val) -> @set-data '_iface', val

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

    make-border: (data) ->
        if opts=data?.border
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
                stroke-color: 'DeepPink'
                stroke-width: 0.2
                parent: @g

    mirror: ->
        super ...
        @border?.stroke-color = switch @side.0
            | 'F' => 'DeepPink'
            | 'B' => 'LightSeaGreen'

    _loader: (item) ->
        console.warn "We have a stray item, selecting it: ", item
        item.selected = yes

    print-mode: ->
        @border?.remove!
        super ...
