require! './lib/snap-move': {snap-move}
require! 'prelude-ls': {empty}

class Line
    (@scope, point) ->
        @line = new @scope.Path do
            stroke-cap: 'round'
            stroke-end: 'round'
            stroke-width: 2

        if point
            @line.add(point)
        @tolerance = 5
        @color = 'white'

    moving-point: ~
        -> @line?segments[*-1].point

    last-point: ~
        -> @line?segments[*-2].point

    color: ~
        (val) -> @line.strokeColor = val;

    add-segment: (point) ->
        @line.add point

    follow: (point) ->
        snap = snap-move @last-point, point, {
            tolerance: @tolerance / @scope.view.zoom
            lock: @lock
        }
        @moving-point.set snap.point

    remove-last-segment: ->
        @line?.segments[*-1].remove!

    end: ->
        @undo!

    snap: (point) ->
        @moving-point.set point

    undo: ->
        @remove-last-segment!
        if @line.segments.length < 2
            @line.remove!

export LineTool = (scope) ->
    line = null

    freehand = new scope.Tool!
        ..onMouseDown = (event) ~>
            scope.use-layer \gui
            unless line
                line := new Line scope, event.point
            line.add-segment event.point

        ..onMouseMove = (event) ->
            line?.follow event.point
            marker-put = no
            for scope.hitTestAll event.point, {exclude: [line?line]}
                console.log "hit: ", ..
                spoint = ..segment?point or ..location?segment.point
                if spoint
                    console.log "spoint: #{spoint}"
                    line?snap that
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
