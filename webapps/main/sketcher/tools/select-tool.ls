require! 'prelude-ls': {empty, flatten, filter, map, compact}
require! './lib/selection': {Selection}
require! '../kernel': {PaperDraw}
require! './lib/trace/lib': {get-tid, set-tid}

export SelectTool = ->
    # http://paperjs.org/tutorials/project-items/transforming-items/
    scope = new PaperDraw
    selection = new Selection

    sel =
        box: null

    select-tool = new scope.Tool!
        ..onMouseMove = (event) ~>
            scope.ractive.set \pointer, event.point

        ..onMouseDrag = (event) ~>
            # panning
            if event.modifiers.shift
                offset = event.downPoint .subtract event.point
                scope.view.center = scope.view.center .add offset
            else
                if sel.box
                    sel.box.segments
                        ..1.point.y = event.point.y
                        ..2.point.set event.point
                        ..3.point.x = event.point.x
                    sel.box.selected = yes

        ..onMouseUp = (event) ->
            if sel.box
                s = that.segments
                opts = {}
                if s.0.point.subtract s.2.point .length > 10
                    if s.0.point.x < s.2.point.x
                        # selection is left to right
                        opts.inside = sel.box.bounds
                    else
                        # selection is right to left
                        opts.overlapping = sel.box.bounds

                    selection.add scope.project.getItems opts
                sel.box.remove!

        ..onMouseDown = (event) ~>
            # TODO: there are many objects overlapped, use .hitTestAll() instead
            hit = scope.project.hitTest event.point
            console.log "Select Tool: Hit result is: ", hit
            unless event.modifiers.control
                selection.clear!

            unless hit
                # Create the selection box
                sel.box = new scope.Path.Rectangle do
                    from: event.point
                    to: event.point
                    fill-color: \white
                    opacity: 0.4
                    stroke-width: 0
                    data:
                        tmp: \true
                        role: \selection

            else
                # Select the clicked item
                if hit.item.data?tmp
                    console.log "...selected a temporary item, doing nothing"
                    return
                scope.project.activeLayer.bringToFront!

                select-item = ~>
                    selection.add if @get \selectGroup
                        # select the top level group
                        item = hit.item
                        for dig in  [0 to 100]
                            if item.parent.getClassName! is \Layer
                                break
                            item = item.parent
                        console.log "Dig level: ", dig
                        item
                    else
                        hit.item

                if get-tid hit.item
                    # this is related to a trace, handle specially
                    if event.modifiers.control
                        # select the whole trace
                        console.log "adding whole trace to selection because Ctrl is pressed."
                        select-item!
                    else
                        if hit.item.data.aecad.type is \via-part
                            via = hit.item.parent
                            selection.add via
                        else if hit.segment
                            # Segment of a trace
                            segment = hit.segment
                            #console.log "...selecting the segment of trace: ", hit
                            selection.add {
                                name: \left,
                                strength: \strong,
                                role: \single-segment
                                item: segment.point}

                        else if hit.location
                            # Curve of a trace
                            curve = hit.location.curve
                            #console.log "...selecting the curve of trace:", hit

                            selection.add {name: \tmp, role: \handle, item: curve} # for visualization

                            handle =
                                left: curve.point1
                                right: curve.point2

                            other-side = (side) -> [.. for Object.keys handle when .. isnt side].0
                            #console.log "Handle is: ", handle

                            # silently select all parts which are touching to the ends
                            __tolerance__ = 0.1
                            for part in hit.item.parent.children
                                #console.log "examining trace part: ", part
                                if part.data?.aecad?.type in <[ via ]>
                                    #console.log "...found via: ", part
                                    for name, point of handle
                                        if point.isClose part.bounds.center, __tolerance__
                                            strength = \weak
                                            #console.log "adding via to #{name} (#{strength})", part
                                            selection.add {
                                                name,
                                                strength,
                                                role: \via
                                                item: part}
                                                , {-select}
                                else
                                    # find mate segments
                                    for mate-seg in part.getSegments!
                                        #console.log "Examining Path: #{mate-seg.getPath().id}, segment: #{mate-seg.index}"
                                        for name, hpoint of handle when mate-seg.point.isClose hpoint, __tolerance__
                                            strength = \weak
                                            #console.log "...adding #{name} mate close point:", mate-seg.point
                                            selection.add {
                                                name,
                                                strength,
                                                role: \mate-mpoint
                                                item: mate-seg.point}
                                                , {-select}

                                            # add the solver
                                            # -----------------------------------
                                            mate-fp = null # mate far point
                                            for compact [mate-seg.next, mate-seg.previous]
                                                unless handle[other-side name].equals ..point
                                                    #console.warn "#{name} mate far point:", ..point, "is not equal to handle[#{other-side name}]: ", handle[other-side name]
                                                    mate-fp = ..point

                                            unless mate-fp
                                                # this is handler tip
                                                #console.log "..................this is handler tip: ", mate-seg.point
                                                continue

                                            #console.log "found #{name} mate far point: (id: #{mate-fp._owner.getPath().id}) ", mate-fp, "will add a solver."
                                            marker = (center, color, tooltip) ->
                                                radius = 4
                                                new scope.Path.Circle({
                                                    center, radius
                                                    fill-color: color
                                                    data: {+tmp}
                                                    opacity: 0.3
                                                    stroke-color: color
                                                    })

                                            get-solver = (m1, m2, h1, h2) ->
                                                hline = scope._Line {p1: h1, p2: h2}
                                                    ..rotate 0, {+inplace, +round}

                                                mline = scope._Line {p1: m1, p2: m2}
                                                    ..rotate 0, {+inplace, +round}
                                                #console.log "Adding solver for #{name} mate: ", mline.getAngle(), m1, m2
                                                #marker m1, \red
                                                #marker m2, \blue
                                                return solver = (delta) ->
                                                    #console.log "solving #{name} side for delta: ", delta
                                                    hline.move delta
                                                    isec = hline.intersect mline
                                                    isec.subtract m1

                                            selection.add {
                                                name,
                                                role: \solver,
                                                solver: get-solver(mate-seg.point, mate-fp, handle.left, handle.right)
                                                }
                                                , {-select}

                            #console.log "selected everything needed: ", selection.selected
                            for side in <[ left right ]>
                                _sel = selection.filter (.name is side)
                                #console.log "...#{side}: ", _sel
                                if [.. for _sel when ..solver?].length > 1
                                    scope.vlog.error "#{side} shouldn't have more than one solver!"

                        else
                            scope.vlog.error "What did you select of trace id #{get-tid hit.item}"


                else if hit.item
                    # select normally
                    select-item!
                else
                    console.error "What did we hit?", hit
                    debugger

        ..onKeyDown = (event) ~>
            switch event.key
            | \delete =>
                # delete an item with Delete key
                scope.history.commit!
                selection.delete!
            | \escape =>
                # Press Esc to cancel a cache
                selection.deselect!
            | \a =>
                if event.modifiers.control
                    selection.add scope.get-all!
                    event.preventDefault!
            | \z =>
                if event.modifiers.control
                    scope.history.back!
            |_ =>
                if event.modifiers.shift
                    scope.cursor \grab

        ..onKeyUp = (event) ->
            scope.cursor \default

    scope.add-tool \select, select-tool
    select-tool
