require! 'prelude-ls': {abs}
require! '../snap-move': {snap-move}

export follow =
    update-corr-point: (point) ->
        unless @corr-point
            # insert a new correction point
            @corr-point = point.clone!
            @line.insert (@line.segments.length - 2), @corr-point
        else
            @line.segments[* - 2].point.set point

    remove-corr-point: ->
        if @corr-point
            @line.removeSegment (@line.segments.length - 2)
            @corr-point = null

    commit-corr-point: ->
        @corr-point = null

    follow: (point) ->
        if @line
            snap = snap-move @last-point, point, {
                tolerance: @tolerance / @scope.view.zoom
            }
            @moving-point.set snap.point
            @update-helpers @moving-point, <[ s bs ]>

            if snap.route-over
                breaking-point = @helpers[that].bounds.center
                @update-corr-point breaking-point
            else
                @remove-corr-point!

            unless @line.selected
                @line.selected = yes

            @curr = event
                ..point = @moving-point
