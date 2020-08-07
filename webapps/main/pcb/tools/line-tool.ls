require! './lib/polyline': {PolyLine}

export LineTool = (scope) ->
    line = null

    freehand = new scope.Tool!
        ..onMouseDown = (event) ~>
            scope.use-layer \gui
            point = scope.marker-point! or event.point
            unless line
                scope.history.commit!
                line := new PolyLine scope, point
                    ..on-end = ->
                        line := null

            line.add-segment point

        ..onMouseMove = (event) ->
            line?.follow event.point
            marker-put = no
            for scope.hitTestAll event.point
                if ..segment and line.is-moving-segment ..segment
                    continue
                console.log "hit: ", .., ..segment?parent
                spoint = ..segment?point or ..location?segment.point
                if spoint
                    console.log "spoint: #{spoint}"
                    line?follow that
                    scope.vertex-marker that
                    marker-put = yes
            unless marker-put
                scope.marker-clear!

        ..onKeyDown = (event) ~>
            switch event.key
            | \escape =>
                # Press Esc to cancel a cache
                line?.end!
                line := null
            | \shift =>
                line?lock = yes
            | \ü, \g =>
                line?undo!

        ..onKeyUp = (event) ->
            switch event.key
            | \shift =>
                line?lock = no
