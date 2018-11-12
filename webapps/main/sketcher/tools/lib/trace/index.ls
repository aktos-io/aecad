require! 'prelude-ls': {abs, min}
require! 'shortid'
require! '../selection': {Selection}
require! './helpers': {helpers}
require! './follow': {follow}
require! './lib': {get-tid}
require! 'aea/do-math': {mm2px}
require! '../pad': {Pad}
require! '../container': {Container}
require! '../../../kernel': {PaperDraw}
require! '../get-aecad': {get-parent-aecad, get-aecad}
require! '../schema': {SchemaManager}

/* Trace structure:
    data:
        tid: trace id
        type: Trace

    parts:
        * Path
        * Path
        ...
        * Pad (via)
        ...
*/


export class Trace extends Container implements follow, helpers
    (data) ->
        @paths = [] # used by @_loader
        super ...

        if @init-with-data arguments.0
            # initialize with provided data
            null # no special action needed
        else
            # initialize from scratch
            @data =
                type: @constructor.name
                tid: shortid.generate!

            @data <<<< data
            @g.data = aecad: @data

        @schema = new SchemaManager!
        @line = null
        @modifiers = {}
        @prev-hover = []
        @removed-last-segment = null  # TODO: undo functionality will replace this
        @selection = new Selection
        @helpers = {}
        @corr-point = null # correcting point
        @vias = []
        @tolerance = 10

    moving-point: ~
        # point that *tries* to follow the pointer (might be currently snapped)
        -> @line?.segments[* - 1].point

    last-point: ~
        # last point placed
        ->
            a = if @corr-point? => 1 else 0
            @line?.segments[* - 2 - a].point

    connect: (hit) ->
        # connect to an already existing trace
        {item, tid} = get-parent-aecad hit.item
        tid = get-tid item
        if tid and tid isnt @get-data \tid
            console.log "we hit a trace: item: ", item
            return get-aecad item
        return false

    print-mode: (layers) ->
        super ...
        #console.log "trace is printing for: ", side, @pads
        for @paths
            if ..data.aecad.side not in layers
                ..remove!
            else
                ..stroke-color = 'black'

        # TODO: find a proper way to bring drill holes front
        for @pads
            ..g.bring-to-front!

    _loader: (item) ->
        @paths.push item

    reduce: (line) !->
        to-be-removed = []
        last-index = line.segments.length - 1
        for i in [til last-index]
            if line.segments[i].point.isClose line.segments[i + 1].point, 1
                seg-index = i
                if seg-index is 0
                    console.log "we won't reduce first segment!"
                    if seg-index + 1 is last-index
                        console.log "...but we don't have a choice as segment index:", last-index
                    else
                        seg-index += 1
                if seg-index is last-index
                    console.log "we won't reduce last segment!"
                    if seg-index <= 1
                        console.log "...but we don't have a choice as segment index:", last-index
                    else
                        seg-index -= 1
                to-be-removed.push seg-index
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
            @schema.curr?.guide-all!

        unless @g.hasChildren()
            console.log "empty trace, removing"
            @g.remove!
        else
            #@g.bounds.selected = true
            void

        @line = null
        @removed-last-segment = null
        @remove-helpers!
        @vias.length = 0

    continues: ~
        -> @line?

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

    add-segment: (point, flip-side=false) !->
        if @paused
            console.log "not adding segment as tracing is paused"
            return

        @schema.curr?.clear-guides!
        # Check if we should snap to the hit point
        hits = @scope.hitTestAll point, {
            tolerance: 1,
            -aecad # in order to prevent scope.on-zoom subscription leak
        }
        snap = point.clone! # use the event point as is
        actaul-hit = null
        for hit in hits
            #console.log "trace hit to: ", hit

            # hit only pads
            _item = hit.item
            is-pad = no
            for to 100
                if _item.data?aecad?type is \Pad
                    is-pad = yes
                    break
                break unless _item.parent
                break if _item.parent.getClassName! is \Layer
                _item = _item.parent
            continue unless is-pad
            # end of pad hit

            if hit.segment
                console.log "snapping to segment: ", hit.segment
                snap = hit.segment.point.clone!

                # debug point
                new @scope.Shape.Circle do
                    fill-color: 'yellow'
                    radius: 0.5
                    opacity: 0.5
                    center: snap
                    data: {+tmp}
                    selected: true

            else if hit.location
                # this is a curve, use nearest point on path
                console.log "snapping to curve: ", hit.location
                snap = that.path.getNearestPoint point.clone!
            else
                # this is an item (pad, etc.)
                console.log "snapping to item: ", hit.item
                snap = hit.item.bounds.center.clone!
            actual-hit = hit
            break

        unless @continues or actual-hit
            console.warn "Not a pad, won't connect"
            return
        #console.log "Actual hit is: ", actual-hit
        if actual-hit?item
            snap = that.parent.localToGlobal(snap)

        new-trace = no
        if not @line or flip-side
            unless @line
                new-trace = yes
            else
                # side flipped, reduce previous line
                @reduce @line

            curr =
                layer: @ractive.get \currProps
                trace: @ractive.get \currTrace

            @line = new @scope.Path(snap.clone!)
                ..strokeColor = curr.layer.color
                ..strokeWidth = curr.trace.width |> mm2px
                ..strokeCap = 'round'
                ..strokeJoin = 'round'
                ..selected = yes
                ..data.aecad =
                    side: curr.layer.name
                ..parent = @g

            @line.add snap.clone!

            if new-trace
                @set-helpers snap.clone!
            @update-helpers snap.clone!

            /* for debugging purposes:
            new @scope.Shape.Circle do
                fill-color: 'yellow'
                radius: 0.1
                center: snap.clone!
                data: {+tmp}
            */

            # Paper.js bug: above @line doesn't start in
            # `snap` point
            sleep 300ms, ~>
                @line?.firstSegment.point.set snap

        else
            console.log "about to update helpers"
            @update-helpers (@moving-point)
            console.log "helpers updated"
            @line.add (@moving-point)

        @commit-corr-point!

    add-via: ->
        outer-dia = @ractive.get \currTrace.via.outer
        inner-dia = @ractive.get \currTrace.via.inner

        via = new Pad this, do
            dia: outer-dia
            drill: inner-dia
            color: \orange

        via.g.position = @moving-point

        # Toggle the layers
        # TODO: make this cleaner
        @ractive.set \currLayer, switch @ractive.get \currLayer
        | 'F.Cu' => 'B.Cu'
        | 'B.Cu' => 'F.Cu'
        @add-segment @moving-point, flip-side=true

    set-modifiers: (modifiers) ->
        @modifiers = modifiers
