require! './lib/trace': {Trace}

export TraceTool = (scope, layer) ->
    ractive = this

    trace = new Trace scope, ractive
    trace-tool = new scope.Tool!
        ..onMouseDrag = (event) ~>
            # panning
            offset = event.downPoint .subtract event.point
            scope.view.center = scope.view.center .add offset
            trace.pause!

        ..onMouseUp = (event) ~>
            layer.activate!
            trace.add-segment event.point
            trace.resume!

        ..onMouseMove = (event) ~>
            if trace.continues
                trace.follow event.point

        ..onKeyDown = (event) ~>
            trace.set-modifiers event.modifiers
            switch event.key
            | \escape =>
                if trace.continues
                    trace.end!
                else
                    # select the move tool
                    @find-id \toolChanger .fire \select, {}, \mv
            | 'v' =>
                trace.add-via!
            | 'e' =>
                trace.remove-last-point!

    return trace-tool
