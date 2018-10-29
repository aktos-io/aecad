require! 'prelude-ls': {abs, min}
require! 'shortid'
require! '../selection': {Selection}
require! './helpers': {_default: helpers}
require! './follow': {_default: follow}
require! './lib': {get-tid}

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

        @_stable_date = 0
        @drills = []
        @group = null

    get-tolerance: ->
        20 / @scope.view.zoom

    load: (segment) ->
        # continue from this segment
        path = segment?.getPath!
        if get-tid path
            @trace-id = that
            @continues = yes
            @line = path
            @set-helpers segment.point
            @update-helpers segment.point
            return true
        return false

    connect: (segment) ->
        path = segment?.getPath!
        if get-tid path
            @trace-id = that
            return true
        return false

    end: ->
        if @line
            # remove moving point
            @line.removeSegment (@line.segments.length - 1)
            if @corr-point
                @line.removeSegment (@line.segments.length - 1)
                @corr-point = null
            @line.selected = no

        if @line.segments.length is 1
            @line.remove!

        @line = null
        @continues = no
        @trace-id = null
        @snap-x = false             # snap to -- direction
        @snap-y = false             # snap to | direction
        @snap-slash = false         # snap to / direction
        @snap-backslash = false     # snap to \ direction
        @flip-side = false
        @removed-last-segment = null
        @remove-helpers!
        @drills.length = 0

    remove-last-point: (undo) ->
        a = if @corr-point => 1 else 0
        if undo
            if @removed-last-segment
                @line.insert(@removed-last-segment.0, @removed-last-segment.1)
                @removed-last-segment = null
                @update-helpers @line.segments[* - 2 - a].point
        else
            last-pinned = @line.segments.length - 2 - a
            if last-pinned > 0
                @removed-last-segment = [last-pinned, @line.segments[last-pinned]]
                @line.removeSegment last-pinned
                @update-helpers @line.segments[last-pinned - 1].point
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

    set-helpers: helpers.set-helpers
    update-helpers: helpers.update-helpers
    remove-helpers: helpers.remove-helpers
    follow: follow.follow

    add-segment: (point) ->
        if Date.now! < @_stable_date + 500ms
            console.warn "Too frequent, skipping this segment."
            return
        else
            @_stable_date = Date.now!

        new-trace = no
        if not @line or @flip-side
            @flip-side = false
            unless @line
                # starting a new trace
                # assign a new trace id for next trace
                unless @trace-id
                    @trace-id = shortid.generate!
                    @group = new @scope.Group do
                        data:
                            aecad:
                                tid: @trace-id
                new-trace = yes

            # TODO: hitTest is not the correct way to go,
            # check if inside the geometry
            hits = @scope.project.hitTestAll point
            snap = point.clone!
            for hit in hits
                console.log "trace hit to: ", hit
                if hit.item.data.tmp
                    continue
                if hit?segment
                    snap = hit.segment.point.clone!
                    break 
                else if hit?item and hit.item.data.aecad.tid isnt @trace-id
                    snap = hit.item.bounds.center.clone!
                    console.log "snapping to ", snap
                    break
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
                ..parent = @group

            @line.add snap

            if new-trace
                @set-helpers point
            @update-helpers snap

        else
            @update-helpers (@moving-point or point)
            @line.add(@moving-point or point)

        @corr-point = null
        @continues = yes
        @update-drills!

    add-drill: (center, dia) ->
        @drills.push new @scope.Path.Circle do
            center: center
            radius: dia/2
            fill-color: \white
            stroke-width: 0
            data:
                aecad:
                    tid: @trace-id
                    type: \drill
                    dia: dia
            parent: @group
        @update-drills!

    update-drills: ->
        for @drills
            ..bringToFront!

    add-via: ->
        outer-dia = 10
        inner-dia = 3
        via = new @scope.Path.Circle do
            center: @moving-point
            radius: outer-dia/2
            fill-color: \orange
            stroke-width: 0
            data:
                aecad:
                    tid: @trace-id
                    type: \via
                    outer-dia: outer-dia
            parent: @group

        @add-drill @moving-point, inner-dia

        # Toggle the layers
        # TODO: make this cleaner
        @ractive.set \currLayer, switch @ractive.get \currLayer
        | 'F.Cu' => 'B.Cu'
        | 'B.Cu' => 'F.Cu'
        @flip-side = true
        @add-segment @moving-point

    set-modifiers: (modifiers) ->
        @modifiers = modifiers
