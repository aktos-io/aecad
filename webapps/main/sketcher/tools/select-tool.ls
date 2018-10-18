require! 'prelude-ls': {empty, flatten, filter, map}
require! './lib/selection': {Selection}

export SelectTool = (scope, layer) ->
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
                if event.modifiers.control and hit.item.data.aecad?tid
                    # select only that specific segment
                    curves = hit.item.getCurves!
                    nearest = null
                    dist = null
                    for i, curve of curves
                        _dist = curve.getNearestPoint(event.point).getDistance(event.point)
                        if _dist < dist or not nearest?
                            nearest = i
                            dist = _dist

                    curve = curves[nearest]
                        ..selected = yes

                    selection.add curve
                else
                    hit.item.selected = yes
                    selection.add hit.item
                    #console.warn "Hit: ", hit
                    if @get('selectAllLayer')
                        matched = []
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

                        # mark selected items
                        matched.for-each (.selected = yes)
                        selection.add matched

        ..onKeyDown = (event) ~>
            # delete an item with Delete key
            if event.key is \delete
                selection.delete!

            # Press Esc to cancel a cache
            if (event.key is \escape)
                selection.deselect!

    {select-tool}
