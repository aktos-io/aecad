require! 'prelude-ls': {empty, flatten, filter, map}
require! './lib/selection': {Selection}
require! '../kernel': {PaperDraw}
require! './lib/trace/lib': {get-tid, set-tid}

export SelectTool = (_scope, layer, canvas) ->
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
            hit = scope.project.hitTest event.point
            console.log "hit result is: ", hit
            unless hit
                selection.deselect!
            else
                if hit.item.data?tmp
                    return

                matched = []
                trace-id = get-tid hit.item
                handle-data = {+tmp, role: \handle}
                handle-opacity = 0.5
                set-tid handle-data, trace-id

                
                if (hit.segment or hit.item?data?segment) and trace-id
                    # segment of a trace
                    unless hit.item?data?segment
                        workaround = new scope.Path.Circle do
                            center: hit.segment.point
                            radius: 4
                            data: handle-data <<< {geo: \c, segment: hit.segment}
                            strokeWidth: 3
                            strokeColor: \blue
                            opacity: handle-opacity

                        selection.add workaround

                else if hit.location and trace-id
                    # select only that specific curve of the trace
                    curve = hit.location.curve

                    console.log "................................adding curve with this hit:", hit
                    # handle
                    workaround = new scope.Path.Line do
                        from: curve.point1
                        to: curve.point2
                        data: handle-data <<< {curve: hit.location.curve}
                        strokeWidth: 3
                        strokeColor: \blue
                        opacity: handle-opacity
                    console.log "adding workaround line: id: #{workaround.id}"
                    selection.add workaround

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
                else if hit.item
                    console.warn "Hit: will select everything", hit

                    if @get('selectAllLayer')
                        matched = hit.item.getLayer().children
                        console.log "...will select all items in current layer", matched
                    else
                        # select the item
                        matched.push if @get \selectGroup
                            hit.item.parent
                        else
                            hit.item

                selection.add matched

        ..onKeyDown = (event) ~>
            # delete an item with Delete key
            if event.key is \delete
                scope.history.commit!
                selection.delete!

            # Press Esc to cancel a cache
            if (event.key is \escape)
                selection.deselect!

    scope.add-tool \select, select-tool
    select-tool
