require! 'prelude-ls': {empty, flatten, filter, map}
require! './lib/selection': {Selection}

export SelectTool = (scope, layer, canvas) ->
    # http://paperjs.org/tutorials/project-items/transforming-items/

    selection = new Selection

    select-tool = new scope.Tool!
        ..onMouseDrag = (event) ~>
            # panning
            if event.modifiers.shift
                offset = event.downPoint .subtract event.point
                scope.view.center = scope.view.center .add offset

        ..onMouseDown = (event) ~>
            layer.activate!
            selection.deselect!
            hit = scope.project.hitTest event.point
            if hit?item
                #console.warn "Hit: ", hit
                if event.modifiers.control and hit.item.data.aecad?tid
                    # select only that specific curve
                    curves = hit.item.getCurves!
                    nearest = null
                    dist = null
                    for i, curve of curves
                        _dist = curve.getNearestPoint(event.point).getDistance(event.point)
                        if _dist < dist or not nearest?
                            nearest = i
                            dist = _dist

                    curve = curves[nearest]
                    selection.add curve
                else
                    matched = []
                    if @get('selectAllLayer')
                        if hit.item.data.aecad?tid
                            # this is a trace, select only segments belong to this trace
                            console.log "Selected a trace with tid: ", that
                            #for layers in scope.project.getItems (.data.aecad?.tid is that)
                            matched = scope.project.getItems!
                                |> map (.children)
                                |> flatten
                                |> filter (.data.aecad?.tid is that)
                            console.log "filtered items:", matched
                        else
                            matched = hit.item.getLayer().children
                            console.log "...will select all items in current layer", matched
                    else
                        matched.push hit.item

                    selection.add matched

        ..onKeyDown = (event) ~>
            # delete an item with Delete key
            if event.key is \delete
                selection.delete!

            # Press Esc to cancel a cache
            if (event.key is \escape)
                selection.deselect!

    select-tool
