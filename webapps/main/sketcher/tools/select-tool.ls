require! 'prelude-ls': {empty, flatten, filter, map}
require! './lib/selection': {Selection}
require! '../kernel': {PaperDraw}

get-tid = (.data?.aecad?.tid)

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
            selection.deselect!
            matched = []
            hit = scope.project.hitTest event.point, do
                tolerance: 0
                fill: true
                stroke: true
                segments: true

            if hit?location and (trace-id=(get-tid hit.item))
                # select only that specific curve of the trace
                curve = hit.location.curve
                console.log "actual curve parent: #{hit.item.id}"
                #selection.add curve, {select: no} # we don't want to highlight
                workaround = new scope.Path.Line do
                    from: curve.point1
                    to: curve.point2
                    data: {+tmp, for: \trace}
                    strokeWidth: 3
                    strokeColor: \blue
                    opacity: 0.01
                console.log "adding workaround line: id: #{workaround.id}"
                selection.add workaround

                items = flatten [..getItems! for scope.project.layers]
                i = 1
                for part in items when (get-tid part) is trace-id
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
                                console.log "adding coincident: #{i++}, id: #{part.id}"
                                selection.add ..point, {select: no}


            else if hit?item
                #console.warn "Hit: ", hit
                if @get('selectAllLayer')
                    matched = hit.item.getLayer().children
                    console.log "...will select all items in current layer", matched
                else
                    # select the item
                    matched.push hit.item

            selection.add matched

        ..onKeyDown = (event) ~>
            # delete an item with Delete key
            if event.key is \delete
                selection.delete!

            # Press Esc to cancel a cache
            if (event.key is \escape)
                selection.deselect!

    scope.add-tool \select, select-tool
    select-tool
