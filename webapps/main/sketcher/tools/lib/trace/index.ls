require! 'prelude-ls': {abs, min}
require! 'shortid'
require! '../selection': {Selection}
require! './helpers': {_default: helpers}
require! './follow': {_default: follow}
require! './lib': {get-tid}
require! 'aea/do-math': {mm2px}

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

        @vias = []
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
        group = segment?.getPath!.parent
        if get-tid group
            @group = group
            @trace-id = that
            return true
        return false

    reduce: (line) !->
        to-be-removed = []
        for i in [til line.segments.length - 1]
            if line.segments[i].point.isClose line.segments[i + 1].point, 1
                to-be-removed.push i
        for i, s of to-be-removed
            line.segments[s - i].remove!

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

            @reduce @line

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
        @vias.length = 0
        @group = null

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
            else
                # side flipped
                @reduce @line
                
            unless @group
                console.error "No group can be found!"
                return
                debugger


            # TODO: hitTest is not the correct way to go,
            # check if inside the geometry
            hits = @scope.project.hitTestAll point
            snap = point.clone!
            for hit in hits
                console.log "trace hit to: ", hit
                if hit.item.data.tmp
                    # this is a temporary object, do not snap to it
                    continue
                if hit?segment
                    snap = hit.segment.point.clone!
                    break
                else if hit?item and hit.item.data?.aecad?.tid isnt @trace-id
                    snap = hit.item.bounds.center.clone!
                    console.log "snapping to ", snap
                    break

            curr =
                layer: @ractive.get \currProps
                trace: @ractive.get \currTrace

            @line = new @scope.Path(snap)
                ..strokeColor = curr.layer.color
                ..strokeWidth = curr.trace.width |> mm2px
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
            # prevent duplicate segments
            @line.add (@moving-point or point)

        @corr-point = null
        @continues = yes
        @update-vias!

        # TODO: reduce the path geometry
        # 1. remove coincident segments
        # 2. remove segments on a curve
        #@line.reduce! # DO NOT REDUCE AT THE BEGINNING

    update-vias: ->
        for @vias
            ..bringToFront!

    add-via: ->
        outer-dia = @ractive.get \currTrace.via.outer
        inner-dia = @ractive.get \currTrace.via.inner

        @vias.push via = new @scope.Group do
            parent: @group
            data:
                aecad:
                    tid: @trace-id
                    type: \via
                    outer-dia: outer-dia
                    drill-dia: inner-dia

        # FIXME: remove this redundant data
        _tmp_ =
            aecad:
                tid: @trace-id
                type: \via-part

        # add outer pad
        new @scope.Path.Circle do
            center: @moving-point
            radius: outer-dia/2 |> mm2px
            fill-color: \orange
            stroke-width: 0
            parent: via
            # FIXME: remove this redundant data
            data: _tmp_

        # add drill
        new @scope.Path.Circle do
            center: @moving-point
            radius: inner-dia/2 |> mm2px
            fill-color: \white
            stroke-width: 0
            parent: via
            # FIXME: remove this redundant data
            data: _tmp_


        @update-vias!

        # Toggle the layers
        # TODO: make this cleaner
        @ractive.set \currLayer, switch @ractive.get \currLayer
        | 'F.Cu' => 'B.Cu'
        | 'B.Cu' => 'F.Cu'
        @flip-side = true
        @add-segment @moving-point

    set-modifiers: (modifiers) ->
        @modifiers = modifiers
