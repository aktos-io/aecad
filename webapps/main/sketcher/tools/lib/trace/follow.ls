require! 'prelude-ls': {abs}

export _default =
    follow: (point) ->
        if @line
            # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            # TODO: Replace with snap-move
            # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            @moving-point = @line.segments[* - 1].point
            a = if @corr-point? => 1 else 0
            @last-point = @line.segments[* - 2 - a].point
            y-diff = @last-point.y - point.y
            x-diff = @last-point.x - point.x
            tolerance = @get-tolerance!

            snap-y = false
            snap-x = false
            snap-slash = false
            snap-backslash = false

            if @modifiers.shift
                # lock into current snap
                angle = @moving-point.subtract @last-point .angle
                console.log "angle is: ", angle
                if angle is 90 or angle is -90
                    snap-y = true
                else if angle is 0 or angle is 180
                    snap-x = true
                else if angle is -45 or angle is 135
                    snap-slash = true
                else if angle is 45 or angle is -135
                    snap-backslash = true

            # find the most likely snap direction
            sdir =
                x: abs(y-diff)
                y: abs(x-diff)
                backslash: abs(x-diff - y-diff)
                slash: abs(x-diff + y-diff)

            route-over = null
            # decide snap axis
            if snap-x or sdir.x < tolerance
                @moving-point.x = point.x
                @moving-point.y = @last-point.y
            else if snap-y or sdir.y < tolerance
                @moving-point.y = point.y
                @moving-point.x = @last-point.x
            else if snap-backslash or sdir.backslash < tolerance
                d = @last-point.x - point.x
                @moving-point
                    ..x = point.x
                    ..y = @last-point.y - d
            else if snap-slash or sdir.slash < tolerance
                d = @last-point.x - point.x
                @moving-point
                    ..x = point.x
                    ..y = @last-point.y + d
            else
                @moving-point.set point
                # calculate correction path
            route-over = if abs(x-diff) > abs(y-diff)
                if x-diff * y-diff > 0
                    "x-s"
                else
                    "x-bs"
            else if abs(y-diff) > abs(x-diff)
                if x-diff * y-diff > 0
                    "y-s"
                else
                    "y-bs"
            else
                null

            @update-helpers @moving-point, <[ s bs ]>

            if route-over
                bpoint = @helpers[that].bounds.center
                unless @corr-point
                    # insert a new correction point
                    @corr-point = bpoint.clone!
                    @line.insert (@line.segments.length - 2), @corr-point
                else
                    @line.segments[* - 2].point.set bpoint
            else if @corr-point
                @line.removeSegment (@line.segments.length - 2)
                @corr-point = null

            unless @line.selected
                @line.selected = yes
                #@selection.add @line

            @curr = event
                ..point = @moving-point
