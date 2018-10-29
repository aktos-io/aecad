require! 'prelude-ls': {empty, flatten, filter, map}
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
        ..onMouseDrag = (event) ~>
            # panning
            if event.modifiers.shift
                offset = event.downPoint .subtract event.point
                scope.view.center = scope.view.center .add offset
            else
                if sel.box
                    console.log "selection box: ", sel.box
                    sel.box.segments
                        ..1.point.y = event.point.y
                        ..2.point.set event.point
                        ..3.point.x = event.point.x

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
                    fill-color: \aliceblue
                    opacity: 0.4
                    stroke-width: 0.5
                    stroke-color: \cyan
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
                        hit.item.parent
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
                            console.log "...selecting the segment of trace: ", hit
                            selection.add segment
                        else if hit.location
                            # Curve of a trace
                            curve = hit.location.curve
                            console.log "...selecting the curve of trace:", hit

                            selection.add curve
                            # silently select all parts touching to ends
                            p1 = curve.point1
                            p2 = curve.point2
                            for part in hit.item.parent.children
                                if part.data?.aecad?.type in <[ via drill ]>
                                    c = part.bounds.center
                                    if (c.equals p1) or (c.equals p2)
                                        # add this via to selection
                                        selection.add part, {select: no}
                                else
                                    # this should be a Path
                                    # FIXME: Add check
                                    for part.getSegments!
                                        # search in segments
                                        if (p1.equals ..point) or (p2.equals ..point)
                                            console.log "adding coincident: id: #{part.id}"
                                            selection.add ..point, {select: no}
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
