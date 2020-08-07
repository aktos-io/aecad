require! './container': {Container}
require! 'aea/do-math': {mm2px, px2mm}

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

    on: (event, ...args) ->
        switch event
        | 'export-gerber' => 
            @paths = @g.children
            side = our-side = @owner.side or @side
            stroke-width = 0.2mm
            
            coord-to-gerber = (-> (it * 1e5) |>  parse-int)
            vertex-coord = (vertex) ~> 
                mirror-offset = 200mm # FIXME: remove this offset properly
                p = @g.localToGlobal vertex.getPoint()
                return do
                    x: coord-to-gerber (px2mm p.x)
                    y: coord-to-gerber (mirror-offset - px2mm p.y)

            for path in @paths
                #if path.data.aecad.side not in layers

                vertex = path.getFirstSegment()
                {x, y} = vertex-coord vertex

                gerb = []
                gerb.push """
                    %ADD10C,#{stroke-width}*%
                    %LPD*%
                    D10*
                    X#{x}Y#{y}D02*
                    G01*
                    """
                while vertex=vertex.getNext()
                    {x, y} = vertex-coord vertex
                    gerb.push "X#{x}Y#{y}D01*"
                @gerber-reducer.append side, gerb.join('\n')

