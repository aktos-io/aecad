require! './container': {Container}
require! 'aea/do-math': {mm2px}

export class Edge extends Container
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

    import: (data) ->
        # imports a Paper.js data to turn that into an aeObj
        # TODO:
        # ---------
        # Add this Edge object into the layer that the "data" belongs to. This way we could 
        # move any "Edge" part along with its layer. 
        #console.log "Edge is importing data from layer: ", data.layer?.id, data.layer?.name
        data.parent = @g

    move: (displacement, opts={}) ->
        # Moves the component with a provided amount of displacement. Default: Relative
        # opts:
        #       absolute: [Bool] move absolute amount

        console.warn "FIXME: Not moving edge item"
        return 

        # TODO: Move all items in the same layer
        unless opts.absolute
            for @g.layer.children 
                ..position.set ..position.add displacement
        else
            for @g.layer.children 
                ..position.set displacement

    color: ~
        (val) ->
            for @g.children
                ..fillColor = val
                ..strokeColor = val
                ..strokeWidth = 0.2mm |> mm2px

    print-mode: (opts, our-side) ->
        if \Edge in opts.layers
            @color = \black
        else
            @g.remove!


    _loader: (item) ->
        # no special action needs to be taken, (remove the default warning)
