require! 'prelude-ls': {abs, min}
require! 'shortid'
require! '../selection': {Selection}
require! './helpers': {_default: helpers}
require! './follow': {_default: follow}

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

    set-helpers: helpers.set-helpers
    update-helpers: helpers.update-helpers
    remove-helpers: helpers.remove-helpers
    follow: follow.follow

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

            @line.add snap 

            if new-trace
                @set-helpers snap
            @update-helpers snap

        else
            @update-helpers (@moving-point or point)
            @line.add(point)

        @corr-point = null
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

    set-modifiers: (modifiers) ->
        @modifiers = modifiers
