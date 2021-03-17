require! './container': {Container}
require! 'aea/do-math': {mm2px, px2mm}

export class Footprint extends Container
    ->
        super ...
        unless @resuming
            <~ sleep 2ms
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
        -> @get-data('_iface') or {}
        (val) -> 
            if typeof! val is \Array
                # convert it to 1 to 1 object 
                val = val.reduce ((o, key) -> o[key] = key; o), {}
            @set-data '_iface', val

    iface-add: (pin-or-definition, label-or-null) ->
        # Expand existing interface.
        #
        # Usage: iface-add 1, 'a'
        #        iface-add {1: 'a', 2: 'b'}
        curr-iface = @get-data('_iface') or {}
        if typeof! pin-or-definition isnt \Object
            # Single assignment mode 
            pin-or-definition = {"#{pin-or-definition}": label-or-null}

        for pin, label of pin-or-definition
            curr-iface[pin] = label or pin 

        @set-data '_iface', curr-iface


    move: (displacement, opts={}) ->
        # Moves the component with a provided amount of displacement. Default: Relative
        # displacement: unit: pixels
        # opts:
        #       absolute: [Bool] move absolute amount
        unless opts.absolute
            @g.position.set @g.position.add displacement
        else
            @g.position.set displacement

        for @pads
            # DO NOT USE yadayada here! TODO: explain why.
            ..on-move ...arguments

    make-border: (data) ->
        opts=data?.border
        if opts
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

            center = @g.bounds.center
            if (typeof! opts.centered is \Boolean) and not opts.centered
                if type is \Rectangle
                    pos = 
                        x: dimensions.size.x/2
                        y: dimensions.size.y/2
                else
                    pos: {x:0, y: 0}
            else
                # centered 
                pos = {x: center.x, y: center.y}



            if opts.offset-x?
                pos.x += that |> mm2px
            
            if opts.offset-y?
                pos.y += that |> mm2px

            @add-part 'border', new @scope.Shape[type] dimensions <<< {position: pos} <<< center <<< do
                stroke-color: 'DeepPink'
                stroke-width: 0.2
                parent: @g

    mirror: ->
        super ...
        @border?.stroke-color = switch @side2
            | 'F' => 'DeepPink'
            | 'B' => 'LightSeaGreen'

    _loader: (item) ->
        console.warn "We have a stray item, selecting it: ", item
        item.selected = yes

    print-mode: ->
        @border?.remove!
        super ...

    on: (event, ...args) ->
        super ...
        switch event
        | 'export-gerber' => 
            # Export Gerber Silkscreen data
            _round2 = -> it * 100 |> Math.round |> (/100)
            if border=@owner.border
                w = px2mm border.size.width |> _round2
                h = px2mm border.size.height |> _round2
                t = border.type 
                console.log "TODO: export-gerber border size: #{w}mm, #{h}mm, #t", border
            return