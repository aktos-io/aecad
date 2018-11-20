require! './lib/trace': {Trace}

export TraceTool = (scope) ->
    ractive = this

    trace = null
    trace-tool = new scope.Tool!
        ..onMouseDrag = (event) ~>
            # panning
            offset = event.downPoint .subtract event.point
            scope.view.center = scope.view.center .add offset
            #scope.cursor 'grabbing'
            trace?.pause!

        ..onMouseUp = (event) ~>
            # Start a trace
            # ---------------------------------
            unless trace
                scope.use-layer \gui
                scope.history.commit!
                trace := new Trace
                    ..on-end = ~>
                        <~ sleep 10ms
                        trace := null

            if hit=(scope.hitTest event.point, {tolerance: 1, -aecad, exclude: [trace.g]})
                if trace.connect hit
                    console.log "we are continuing!"
                    trace.end! # do the cleanup, at least
                    trace := null # TODO: is it enough to garbage collect current trace object?
                    trace := that
            trace.add-segment event.point
            scope.default-cursor 'cell'
            trace.resume!

        ..onMouseMove = (event) ~>
            if trace?.continues
                trace.follow event.point

        ..onKeyDown = (event) ~>
            trace?.set-modifiers event.modifiers
            switch event.key
            | \escape =>
                trace?.end!
            | 'v' =>
                trace?.add-via!
            | 'ü' =>
                unless event.modifiers.shift
                    trace?.remove-last-point!
                else
                    trace?.remove-last-point \undo

    return trace-tool
