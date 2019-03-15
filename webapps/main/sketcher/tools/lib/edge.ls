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
        data.parent = @g

    move: (displacement, opts={}) ->
        # DO NOT MOVE EDGE AT THE MOMENT
        return

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
