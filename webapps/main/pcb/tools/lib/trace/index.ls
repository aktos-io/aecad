require! 'prelude-ls': {abs, min}
require! 'shortid'
require! '../selection': {Selection}
require! './helpers': {helpers}
require! './follow': {follow}
require! './lib': {get-tid}
require! 'aea/do-math': {mm2px, px2mm}
require! '../pad': {Pad}
require! '../container': {Container}
require! '../../../kernel': {PaperDraw}
require! '../get-aecad': {get-aecad}
require! './end'

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


export class Trace extends Container implements follow, helpers, end
    (data) ->
        @paths = [] # used by @_loader
        super ...

        unless @resuming
            # initialize from scratch
            @set-data 'tid', shortid.generate!
            @routes = [[]]

        # common actions
        @line = null
        @modifiers = {}
        @prev-hover = []
        @removed-last-segment = null  # TODO: undo functionality will replace this
        @selection = new Selection
        @helpers = {}
        @corr-point = null # correcting point
        @vias = []
        @tolerance = 10

    tid: ~
        -> @get-data \tid

    moving-point: ~
        # point that *tries* to follow the pointer (might be currently snapped)
        -> @line?.segments[* - 1].point

    last-point: ~
        # last point placed
        ->
            a = if @corr-point? => 1 else 0
            @line?.segments[* - 2 - a].point

    trigger: ->
        @on ...

    on: (event, ...args) ->
        switch event
        | 'focus' =>
            for @paths
                if ..data.aecad.side is args.0
                    ..opacity = 1
                else
                    ..opacity = @blur-opacity

        | 'export-gerber' => 
            for @pads
                ..trigger \export-gerber

            coord-to-gerber = (-> (it * 1e5) |>  parse-int)
            vertex-coord = (vertex) ~> 
                mirror-offset = 200mm # FIXME: remove this offset properly
                p = @g.localToGlobal vertex.getPoint()
                return do
                    x: coord-to-gerber (px2mm p.x)
                    y: coord-to-gerber (mirror-offset - px2mm p.y)
            gerb-stroke-width = (path) ->
                path.getStrokeWidth() 
                    |> px2mm
                    |> (* 10)
                    |> Math.round
                    |> (/ 10)

            userDefined = (try CSON.parse @data["userDefined"])

            for path in @paths
                #if path.data.aecad.side not in layers
                [side2, layer] = path.data.aecad.side.split '.' # eg. ["F", "Cu"]
                stroke-width = gerb-stroke-width path

                vertex = path.getFirstSegment()
                unless vertex?
                    console.warn "Skipping empty path:", path
                    continue 
                {x, y} = vertex-coord vertex

                gerb = []
                gerb.push """
                    %ADD10C,#{stroke-width}*%
                    %LPD*%
                    D10*
                    X#{x}Y#{y}D02*
                    G01*
                    """
                while vertex=vertex.getNext()
                    {x, y} = vertex-coord vertex
                    gerb.push "X#{x}Y#{y}D01*"
                
                @gerber-reducer.append do
                    layer: layer 
                    side: side2
                    gerber: gerb.join('\n')

                if userDefined?unmask
                    # Remove the soldermask
                    console.log "Removing soldermask of: ", this
                    @gerber-reducer.append do
                        layer: "Mask" 
                        side: side2
                        gerber: gerb.join('\n')


    print-mode: ({layers, trace-color, border-color}) ->
        super ...
        #console.log "trace is printing for: ", side, @pads
        for @paths
            if ..data.aecad.side not in layers
                ..remove!
            else
                ..stroke-color = trace-color or 'black'
                ..opacity = 1

        # TODO: find a proper way to bring drill holes front
        for @pads
            ..g.bring-to-front!

    _loader: (item) ->
        @paths.push item

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

    netid: ~
        -> "#{(@get-data \netid) or ''}"
        (val) -> @set-data \netid, "#{val}"

    net: ~
        ->
            # list of pads which this trace is related with
            @schema?connection-list[@netid] or []

    clear-guides: ->
        # Clear highlighting targets
        for @net
            ..selected = false

    show-guides: !->
        # Highlight possible target pads without highlighting @first-target and
        # the elements that are already connected to it
        if @schema
            uncoupled = []
            sections = @schema._connection_states[@netid].reduced
            for elements in sections
                switch @first-target.type
                | 'Pad' =>
                    continue if @first-target.logical-pin in elements
                | 'Trace'
                    continue if "trace-id::#{@first-target.g.id}" in elements
                uncoupled ++= elements

            for @net when ..logical-pin in uncoupled
                ..selected = true


    add-segment: (point, flip-side=false) !->
        if @paused
            console.log "not adding segment as tracing is paused"
            return

        unless @continues
            @scope.selection.clear!
            snap = point.clone! # use the event point as is
        else
            snap = @moving-point

        if @line?segments.length > 2 and snap.isClose @line.segments[*-2].point, 0.1
            console.warn "Skipping: too close segments.", Date.now!
            return

        # Check if we should snap to the hit point
        curr-layer = @ractive.get('currLayer')
        hits = @scope.hitTestAll snap, {
            tolerance: 1,
            exclude: @g
            filter: (hit) ~>
                # connect only if the target is on the same layer
                if hit.item.data?aecad?side is curr-layer
                    return true
                aeobj=(get-aecad hit.item)
                if aeobj
                    return aeobj.side-match?(curr-layer)
                console.log "won't hit to item on different layer: ", hit, aeobj
                return false
        }
        reached-target = no
        target = null
        valid-hit = null
        for hit in hits
            unless target
                target = hit.aeobj
                valid-hit = hit # for trace to trace connections
            else
                PNotify.notice text: "Multiple hits? (See console)"
                console.warn "Multiple hits on trace start:", hit

        unless @continues
            unless target
                @scope.cursor \not-allowed
                sleep 300ms, ~> @scope.restore-cursor!
                console.warn "Not a pad, won't connect"
                return

        if target
            unless target.netid
                @scope.vlog.error """
                    We can't connect to an object that has
                    no "netid" property.

                    1. Did you compile your schema?

                    2. Does this pad seem to connectable?
                    """
                return

            unless @netid
                @netid = target.netid
            if @netid isnt target.netid
                PNotify.notice do
                    text: """
                        We can't connect to a different netid:
                        Expected: #{@netid}, got: #{target.netid}
                        """
                return
            console.log "Connected to netid: #{@netid}"

            unless @first-target
                @first-target = target

            switch target.type
            | 'Trace' =>
                # No special action is needed
                hit = valid-hit
                if hit.segment
                    console.log "snapping to segment: ", hit.segment
                    snap = hit.segment.point.clone!
                else if hit.location
                    # this is a curve, use nearest point on path
                    console.log "snapping to curve: ", hit.location
                    snap = (x=that.path.clone!).transform(hit.item._globalMatrix).getNearestPoint point.clone! 
                    x.remove!
                else
                    # this is an item (pad, etc.)
                    console.log "snapping to item: ", hit.item
                    snap = hit.item.bounds.center.clone!
            | 'Pad' =>
                # Snap to this pad
                snap = target.gpos
            # auto-end the trace when we reached to a target
            if @continues
                reached-target = yes
            @show-guides!
        else
            # we are placing a trace segment (vertex), no-hit is normal.
            # leave snap as is

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

            if /[^0-9\\.]+/.exec curr.trace.width
                @scope.vlog.error "Unrecognized trace width: #{curr.trace.width}"
                @ractive.set \currTrace.width, 0.2
                return 
            trace-width = curr.trace.width |> parse-float |> mm2px
            @line = new @scope.Path(snap)
                ..strokeColor = curr.layer.color
                ..strokeWidth = trace-width
                ..strokeCap = 'round'
                ..strokeJoin = 'round'
                ..selected = yes
                ..data.aecad =
                    side: curr.layer.name
                ..parent = @g
                ..send-to-back! # send trace parts below to via's

            @line.add snap

            if new-trace
                @set-helpers snap
            @update-helpers snap

        else
            @update-helpers snap
            @line.add snap

        @commit-corr-point!

        if reached-target
            @end target


    add-via: ->
        outer-dia = @ractive.get \currTrace.via.outer
        inner-dia = @ractive.get \currTrace.via.inner

        if /[^0-9\\.]+/.exec outer-dia
            @scope.vlog.error "Unrecognized via outer dia: #{outer-dia}"
            return 

        via = new Pad do
            dia: outer-dia
            drill: inner-dia
            color: \orange
            parent: this

        via.g.position = @moving-point

        # Toggle the layers
        # TODO: make this cleaner
        <~ @ractive.fire \switchLayer, {}, switch @ractive.get \currLayer
            | 'F.Cu' => 'B.Cu'
            | 'B.Cu' => 'F.Cu'
        @add-segment @moving-point, flip-side=true

    set-modifiers: (modifiers) ->
        @modifiers = modifiers

    move: (displacement, opts={}) ->
        # Moves the component with a provided amount of displacement. Default: Relative
        # opts:
        #       absolute: [Bool] move absolute amount
        unless opts.absolute
            @g.position.set @g.position.add displacement
        else
            @g.position.set displacement

        console.warn "FIXME: trace moves must break traces at selection boundaries."