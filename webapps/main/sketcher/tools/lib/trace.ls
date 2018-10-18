require! 'prelude-ls': {abs, min}

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
        @uuid = 0
        @moving-point = null    # point that *tries* to follow the pointer (might be currently snapped)
        @last-point = null      # last point which is placed
        @continues = no         # trace is continuing or not
        @modifiers = {}
        @history = []

    get-tolerance: ->
        20 / @scope.view.zoom

    end: ->
        if @line
            that.removeSegment (@line.segments.length - 1)
            that.selected = no

        @line = null
        @continues = no
        @snap-x = false             # snap to -- direction
        @snap-y = false             # snap to | direction
        @snap-slash = false         # snap to / direction
        @snap-backslash = false     # snap to \ direction
        @flip-side = false
        @uuid = null

    remove-last-point: ->
        last-pinned = @line.segments.length - 2
        if last-pinned > 0
            @line.removeSegment last-pinned
        else
            @end!

    undo: ->
        # to be implemented

    pause: ->
        @paused = yes

    resume: ->
        @paused = no

    add-segment: (point) ->
        if not @line or @flip-side
            @flip-side = false
            unless @line
                # starting a new trace
                null

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

            @line = new @scope.Path(snap, point)
                ..strokeColor = curr.layer.color
                ..strokeWidth = curr.trace.width
                ..strokeCap = 'round'
                ..strokeJoin = 'round'
                ..selected = yes
                ..data.project =
                    layer: curr.layer.name

        else
            @line.add(point)
        @continues = yes

    add-via: ->
        via = new @scope.Path.Circle(@moving-point, 5)
            ..fill-color = \orange

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

            if abs(y-diff) < tolerance or snap-x
                # x direction
                @moving-point.x = point.x
                @moving-point.y = @last-point.y
            else if abs(x-diff) < tolerance or snap-y
                # y direction
                @moving-point.y = point.y
                @moving-point.x = @last-point.x
            else if abs(x-diff - y-diff) < tolerance or snap-backslash
                # backslash
                d = @last-point.x - point.x
                @moving-point
                    ..x = point.x
                    ..y = @last-point.y - d

            else if abs(x-diff + y-diff) < tolerance or snap-slash
                # slash
                d = @last-point.x - point.x
                @moving-point
                    ..x = point.x
                    ..y = @last-point.y + d
            else
                @moving-point.set point

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
                            console.log "Skipped hit because of type not ok:", target
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
                that.selected = yes

            @line.selected = yes
            @curr = event
                ..point = @moving-point

    set-modifiers: (modifiers) ->
        @modifiers = modifiers
