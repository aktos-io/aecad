require! 'prelude-ls': {abs, min}
require! 'shortid'
require! './selection': {Selection}

export class Trace
    @instance = null
    (scope, ractive) ->
        # Make this class Singleton
        return @@instance if @@instance
        @@instance = this

        @scope = scope
        @ractive = ractive

        @line = null
        @snap-x = false
        @snap-y = false
        @flip-side = false
        @moving-point = null    # point that *tries* to follow the pointer (might be currently snapped)
        @last-point = null      # last point which is placed
        @continues = no         # trace is continuing or not
        @modifiers = {}
        @history = []
        @trace-id = null
        @prev-hover = []
        @removed-last-segment = null  # TODO: undo functionality will replace this
        @selection = new Selection
        @helpers = {}
        @corr-point = null # correcting point


    get-tolerance: ->
        20 / @scope.view.zoom

    end: ->
        if @line
            that.removeSegment (@line.segments.length - 1)
            that.selected = no

        if @line.segments.length is 1
            @line.remove!

        @line = null
        @continues = no
        @snap-x = false             # snap to -- direction
        @snap-y = false             # snap to | direction
        @snap-slash = false         # snap to / direction
        @snap-backslash = false     # snap to \ direction
        @flip-side = false
        @removed-last-segment = null
        @remove-helpers!

    remove-last-point: (undo) ->
        if undo
            if @removed-last-segment
                @line.insert(@removed-last-segment.0, @removed-last-segment.1)
                @removed-last-segment = null
        else
            last-pinned = @line.segments.length - 2
            if last-pinned > 0
                @removed-last-segment = [last-pinned, @line.segments[last-pinned]]
                @line.removeSegment last-pinned
            else
                @end!

    undo: ->
        # to be implemented

    pause: ->
        @paused = yes

    resume: ->
        @paused = no

    highlight-target: (point) ->
        hit = @scope.project.hitTestAll point

        for @prev-hover
            @prev-hover.pop!
                ..selected = no
        #console.log "hit: ", hit
        for hit
            if ..item.hasChildren!
                for ..item.children
                    if ..hitTest point
                        ..selected = yes
                        @prev-hover.push ..
            else
                ..item.selected = yes
                @prev-hover.push ..item

    set-helpers: (point) ->
        @remove-helpers!

        helper-opts =
            from: point
            to: point
            data: {+tmp}
            strokeWidth: 1
            strokeColor: \blue
            opacity: 0.8
            dashArray: [10, 4]

        for axis in <[ x y s bs ]>
            @helpers[axis] = new @scope.Path.Line helper-opts


        for axis in <[ x y ]>
            for axis2 in <[ s bs ]>
                # create intersections
                @helpers["#{axis}-#{axis2}"] = new @scope.Path.Circle do
                    center: point
                    radius: 5
                    stroke-width: 3
                    stroke-color: \green

    remove-helpers: ->
        for h, p of @helpers
            p.remove!

    update-helpers: (point, names=<[ x y s bs ]>) ->
        for name, h of @helpers when name in names
            switch name
            | 'x' =>
                h
                    ..firstSegment.point
                        ..x = -1000
                        ..y = point.y
                    ..lastSegment.point
                        ..x = 1000
                        ..y = point.y
            | 'y' =>
                h
                    ..firstSegment.point
                        ..x = point.x
                        ..y = -1000
                    ..lastSegment.point
                        ..x = point.x
                        ..y = 1000
            | 's' =>
                h
                    ..firstSegment.point
                        ..x = -1000
                        ..y = point.y
                    ..lastSegment.point
                        ..x = 1000
                        ..y = point.y

                    ..rotate(45, point)
            | 'bs' =>
                h
                    ..firstSegment.point
                        ..x = -1000
                        ..y = point.y
                    ..lastSegment.point
                        ..x = 1000
                        ..y = point.y

                    ..rotate(-45, point)

        for axis in <[ x y ]>
            for axis2 in <[ s bs ]>
                name = "#{axis}-#{axis2}"
                isec = @helpers[axis].getIntersections @helpers[axis2]
                if isec.length > 1
                    console.warn "how come: ", isec
                @helpers[name].position = isec.0?.point

    add-segment: (point) ->
        new-trace = no
        if not @line or @flip-side
            @flip-side = false
            unless @line
                # starting a new trace
                # assign a new trace id for next trace
                @trace-id = shortid.generate!
                new-trace = yes

            # TODO: hitTest is not the correct way to go,
            # check if inside the geometry
            hit = @scope.project.hitTest point
            snap = point
            if hit?item
                snap = new @scope.Point that.bounds.center
                console.log "snapping to ", snap

            curr =
                layer: @ractive.get \currProps
                trace: @ractive.get \currTrace

            @line = new @scope.Path(snap)
                ..strokeColor = curr.layer.color
                ..strokeWidth = curr.trace.width
                ..strokeCap = 'round'
                ..strokeJoin = 'round'
                ..selected = yes
                ..data.aecad =
                    layer: curr.layer.name
                    tid: @trace-id

            #@line.add new @scope.Point snap
            @line.add point

            if new-trace
                @set-helpers snap
            @update-helpers snap

        else
            @line.add(point)
            @update-helpers point

        @continues = yes

    add-via: ->
        via = new @scope.Path.Circle(@moving-point, 5)
            ..fill-color = \orange
            ..data.aecad =
                tid: @trace-id
                type: \via

        # Toggle the layers
        # TODO: make this cleaner
        @ractive.set \currLayer, switch @ractive.get \currLayer
        | 'F.Cu' => 'B.Cu'
        | 'B.Cu' => 'F.Cu'
        @flip-side = true
        @add-segment @moving-point

    follow: (point) ->
        if @line
            @moving-point = @line.segments[* - 1].point
            @last-point = @line.segments[* - 2].point
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

            min-dist = 0
            direction = null
            for dir, dist of sdir
                if not direction or dist < min-dist
                    direction = dir
                    min-dist = dist
            #console.log "most likely direction is #{direction}"
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

            @update-helpers @moving-point, <[ s bs ]>

            if route-over
                # update correction point
                c = @helpers[that].bounds.center
                #@corr-point.set c
                console.log "setting correction point to #{that}:", c

            # collision detection
            search-hit = (src, target) ->
                hits = []
                if target.hasChildren!
                    for target.children
                        if search-hit src, ..
                            hits ++= that
                else
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

            unless @line.selected
                @selection.add @line
            @curr = event
                ..point = @moving-point

    set-modifiers: (modifiers) ->
        @modifiers = modifiers
