require! 'prelude-ls': {empty, flatten, filter, map}
require! './lib/selection': {Selection}
require! '../kernel': {PaperDraw}
require! './lib/trace/lib': {get-tid, set-tid}

export SelectTool = ->
    # http://paperjs.org/tutorials/project-items/transforming-items/
    scope = new PaperDraw
    selection = new Selection

    select-tool = new scope.Tool!
        ..onMouseDrag = (event) ~>
            # panning
            if event.modifiers.shift
                offset = event.downPoint .subtract event.point
                scope.view.center = scope.view.center .add offset

        ..onMouseDown = (event) ~>
            # TODO: there are many objects overlapped, use .hitTestAll() instead
            hit = scope.project.hitTest event.point
            console.log "Select Tool: Hit result is: ", hit
            unless hit
                selection.deselect!
            else
                if hit.item.data?tmp
                    console.log "...selected a temporary item, doing nothing"
                    return
                scope.project.activeLayer.bringToFront!

                matched = []
                trace-id = get-tid hit.item
                handle-data = {
                    +tmp,
                    role: \handle
                }
                handle-opacity = 0.5
                set-tid handle-data, trace-id

                if trace-id
                    # this is related to a trace, handle specially
                    if event.modifiers.control
                        # select the whole trace
                        console.log "adding whole trace to selection."
                        selection.add hit.item
                    else
                        if hit.segment or hit.item?data?segment
                            # Segment of a trace
                            console.log "...selecting the segment of trace: ", hit

                            # FIXME: the hit item might not be the handle, it's possible
                            # to add duplicate handles.
                            unless hit.item?data?segment
                                selection.add workaround = new scope.Path.Circle do
                                    center: hit.segment.point
                                    radius: 2
                                    data: handle-data <<< {
                                        geo: \c,
                                        segment: hit.segment
                                    }
                                    strokeWidth: 3
                                    strokeColor: \blue
                                    opacity: handle-opacity

                                workaround.bringToFront!


                        else if hit.location
                            # Curve of a trace
                            console.log "...selecting the curve of trace:", hit
                            curve = hit.location.curve

                            # handle
                            selection.add workaround = new scope.Path.Line do
                                from: curve.point1
                                to: curve.point2
                                data: handle-data <<< {
                                    curve: hit.location.curve
                                }
                                strokeWidth: 3
                                strokeColor: \blue
                                opacity: handle-opacity
                            console.log "adding workaround line: id: #{workaround.id}"

                            for part in scope.get-all! when (get-tid part) is trace-id
                                continue if part.data?.role is \handle
                                console.log "found trace part: #{part.id}", part
                                p1 = curve.point1
                                p2 = curve.point2
                                if part.data?.aecad?.type is \via
                                    c = part.bounds.center
                                    if (c.equals p1) or (c.equals p2)
                                        # add this via to selection
                                        selection.add part, {select: no}
                                else
                                    for part.getSegments!
                                        # search in segments
                                        if (p1.equals ..point) or (p2.equals ..point)
                                            console.log "adding coincident: id: #{part.id}"
                                            selection.add ..point, {select: no}
                        else
                            console.log "adding whole trace item: ", hit
                            selection.add hit.item

                else if hit.item
                    if @get('selectAllLayer')
                        matched = hit.item.getLayer().children
                        console.log "...will select all items in current layer", matched
                    else
                        # select the item
                        matched.push if @get \selectGroup
                            hit.item.parent
                        else
                            hit.item
                else
                    console.error "What did we hit?", hit 
                    debugger

                selection.add matched

        ..onKeyDown = (event) ~>
            switch event.key
            | \delete =>
                # delete an item with Delete key
                scope.history.commit!
                selection.delete!

            | \escape =>
                # Press Esc to cancel a cache
                selection.deselect!

            |_ =>
                if event.modifiers.shift
                    scope.cursor \grab

        ..onKeyUp = (event) ->
            scope.cursor \default

    scope.add-tool \select, select-tool
    select-tool
