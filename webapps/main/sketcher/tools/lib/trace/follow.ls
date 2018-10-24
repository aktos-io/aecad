require! 'prelude-ls': {abs}

export _default =
    follow: (point) ->
        if @line
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



            # only for visualization
            for <[ x-s x-bs y-s y-bs ]>
                if route-over and .. is route-over
                    @helpers[..]
                        ..stroke-color = 'red'
                        ..stroke-width = 3
                else
                    @helpers[..].stroke-width = 0

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


            # collision detection
            search-hit = (src, target) ->
                hits = []
                if target.hasChildren!
                    for target.children
                        if search-hit src, ..
                            hits ++= that
                else
                    # FIXME: this prevents trace selection!!
                    target.selected = no

                    type-ok = if target.type is \circle
                        yes
                    else if target.closed
                        yes
                    else
                        no
                    if src .is-close target.bounds.center, 10
                        if type-ok
                            # http://paperjs.org/reference/shape/
                            #console.warn "Hit! ", target
                            hits.push target
                        else
                            #console.log "Skipped hit because of type not ok:", target
                            null
                hits

            closest = {}
            for layer in @scope.project.getItems!
                for obj in layer.children
                    for hit in point `search-hit` obj
                        dist = hit.bounds.center .subtract point .length
                        if dist > tolerance
                            console.log "skipping, too far ", dist
                            continue
                        #console.log "Snapping to ", hit
                        if not closest.hit or dist < closest.dist
                            closest
                                ..hit = hit
                                ..dist = dist
            if closest.hit
                console.log "snapped to the closest hit:", that, "zoom: ", @scope.view.zoom
                @moving-point .set that.bounds.center
                @selection.add that

            @update-helpers @moving-point, <[ s bs ]>

            unless @line.selected
                @selection.add @line

            @curr = event
                ..point = @moving-point
