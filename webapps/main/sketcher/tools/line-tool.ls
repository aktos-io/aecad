require! './lib/snap-move': {snap-move}
require! 'prelude-ls': {empty}

class PolyLine
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
        -> @line?segments[*-2]?.point

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
        if @line.segments.length < 2
            @line.remove!
        @on-end?!

    undo: ->
        @remove-last-segment!
        if @line.segments.length < 2
            @line.remove!

    is-moving-segment: (segment) ->
        segment.path.id is @line.id and segment.index is @moving-point.index


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
