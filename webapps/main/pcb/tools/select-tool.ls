require! 'prelude-ls': {empty, flatten, filter, map, compact, unique}
require! './lib/selection': {Selection}
require! '../kernel': {PaperDraw}
require! './lib/get-aecad': {get-aecad}

export SelectTool = ->
    # http://paperjs.org/tutorials/project-items/transforming-items/
    scope = new PaperDraw
    selection = new Selection

    sel =
        box: null

    select-tool = new scope.Tool!
        ..onMouseDrag = (event) ~>
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

                    items = scope.project.getItems opts
                    console.log "Selection box includes items: ", items
                    console.log "Selected items in layer:", unique ["#{..layer?.id} (#{..layer?.name})" for items]
                    selection.add items
                sel.box.remove!

        ..onMouseDown = (event) ~>
            # TODO: there are many objects overlapped, use .hitTestAll() instead
            hit = scope.hitTest event.point, do
                tolerance: 2
                filter: (hit) ->
                    #console.log "Filtering hit test:", hit
                    if hit.item.data.guide
                        return false
                    else if side=hit.item.data?.aecad?.side isnt scope.ractive.get \currLayer
                        # allow selecting components in scripting layer 
                        if hit.aeobj?.side not in <[ F.Cu B.Cu Edge ]>
                            return true 

                        # do not allow selecting components in different physical layers
                        if hit.aeobj.side is scope.ractive.get \currLayer
                            return true 

                        # still allow selecting through hole elements 
                        if hit.aeobj?type is "Pad" and hit.aeobj.drill?
                            return true 
                        return false
                    else 
                        return true
            console.log "Select Tool: Hit result is: ", hit

            # Ctrl modifier is used for multiple selection
            unless event.modifiers.control
                selection.clear!
                sel.box?.remove!
                sel.box = null

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
                if (aeobj=hit.aeobj) and not event.modifiers.shift
                    if aeobj.owner@@name is \Trace
                        # this is related to a trace, handle specially
                        #PNotify.info text: "We hit a trace. This is: #{aeobj@@name}"
                        if event.modifiers.control
                            # select the whole trace
                            console.log "adding whole trace to selection because Ctrl is pressed."
                            selection.add {item: hit.item, aeobj}
                        else
                            if aeobj@@name is \Pad
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
                                same-net-traces = []                                
                                for scope.get-components {include: ['Trace'], exclude: ['*']} 
                                    if ..item.data.aecad.netid is hit.item.parent.data.aecad.netid
                                        same-net-traces.push ..item
                                for part in flatten same-net-traces.map (.children)
                                    #console.log "examining trace part: ", part
                                    if part.data?.aecad?.type in <[ Pad ]>
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
                                        # find mate segments and add an appropriate solver 
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
                                                        if isec 
                                                            isec.subtract m1
                                                        else
                                                            # lines are not intersecting, they are parallel
                                                            throw new Error "Unimplemented feature: Handle moving the lines when they are parallel"


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
                                throw new Error "Unrecognized trace part."
                    else
                        # non-trace aecad object
                        console.log "Non-trace aeCAD object:", get-aecad hit.item
                        selection.add {item: hit.item, aeobj}
                else if hit.item
                    # any regular item
                    console.log "Standard Paper.js object:", hit.item
                    selection.add scope.get-top-item hit.item

        ..onKeyDown = (event) ~>
            switch event.key
            | \escape =>
                # Press Esc to cancel a cache
                selection.deselect!
            | \a =>
                if event.modifiers.control
                    selection.add scope.get-all!
                    event.preventDefault!

    scope.add-tool \select, select-tool
    select-tool
