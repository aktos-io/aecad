require! 'prelude-ls': {abs}

export TraceTool = (scope, layer) ->
    # pcb is the scope
    pcb = scope
    gui = layer

    trace =
        line: null
        snap-x: false
        snap-y: false
        seg-count: null
        tolerance: (x) -> 10 / pcb.view.zoom

    trace-tool = new pcb.Tool!
        ..onMouseDrag = (event) ~>
            # panning
            offset = event.downPoint .subtract event.point
            pcb.view.center = pcb.view.center .add offset
            trace.panning = yes

        ..onMouseUp = (event) ~>
            gui.activate!
            unless trace.panning
                unless trace.line
                    snap = event.point
                    # TODO: hitTest is not correct, check if inside the geometry
                    hit = scope.project.hitTest event.point
                    if hit?item
                        snap = new scope.Point that.bounds.center
                        console.log "snapping to ", snap

                    trace.line = new pcb.Path(snap, event.point)
                        ..strokeColor = 'red'
                        ..strokeWidth = 3
                        ..strokeCap = 'round'
                        ..strokeJoin = 'round'
                        ..selected = yes

                else
                    trace.line.add(event.point)
            trace.panning = no

        ..onMouseMove = (event) ~>
            if trace.line
                lp = trace.line.segments[* - 1].point
                l-pinned-p = trace.line.segments[* - 2].point
                y-diff = l-pinned-p.y - event.point.y
                x-diff = l-pinned-p.x - event.point.x
                tolerance = trace.tolerance!

                snap-y = false
                snap-x = false
                if event.modifiers.shift
                    angle = lp.subtract l-pinned-p .angle
                    console.log "angle is: ", angle
                    if angle is 90 or angle is -90
                        snap-y = true
                    else if angle is 0 or angle is 180
                        snap-x = true

                if abs(y-diff) < tolerance or snap-x
                    # x direction
                    lp.x = event.point.x
                    lp.y = l-pinned-p.y
                else if abs(x-diff) < tolerance or snap-y
                    # y direction
                    lp.y = event.point.y
                    lp.x = l-pinned-p.x
                else if abs(x-diff - y-diff) < tolerance
                    # 45 degrees
                    lp.set event.point
                else
                    lp.set event.point

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
                for layer in pcb.project.getItems!
                    for obj in layer.children
                        for hit in event.point `search-hit` obj
                            dist = hit.bounds.center .subtract event.point .length
                            if dist > tolerance
                                console.log "skipping, too far ", dist
                                continue
                            #console.log "Snapping to ", hit
                            if not closest.hit or dist < closest.dist
                                closest
                                    ..hit = hit
                                    ..dist = dist
                if closest.hit
                    console.log "snapped to the closest hit:", that, "zoom: ", pcb.view.zoom
                    lp .set that.bounds.center
                    that.selected = yes

        ..onKeyDown = (event) ~>
            if event.key is \escape
                if trace.line
                    that.removeSegment (trace.line.segments.length - 1)
                    that.selected = no

                trace.last-esc = Date.now!
                trace.line = null


    return trace-tool
