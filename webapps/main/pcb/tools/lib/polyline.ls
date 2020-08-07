require! './snap-move': {snap-move}

export class PolyLine
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
