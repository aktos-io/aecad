require! 'prelude-ls': {abs}
require! '../snap-move': {snap-move}

export follow =
    update-corr-point: (point) ->
        #console.warn "disabled update corr point"
        unless @corr-point
            # insert a new correction point
            @corr-point = point.clone!
            @line.insert (@line.segments.length - 1), @corr-point
        else
            console.log "Updating the correction point."
            @line.segments[* - 2].point.set point

    remove-corr-point: ->
        if @corr-point
            if @line.segments.length > 2
                console.log "Removing the correction point."
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
