require! 'prelude-ls': {empty}

export MoveTool = (scope, layer) ->
    # http://paperjs.org/tutorials/project-items/transforming-items/

    move =
        selected: []
        dragging: null
        last-drag-point: null

    deselect-all = ->
        for move.selected => ..selected = no
        move.selected = []
        move.dragging = null

    move-tool = new scope.Tool!
        ..onMouseDrag = (event) ~>
            for move.selected
                ..position
                    ..x += event.delta.x
                    ..y += event.delta.y

            move.dragging =
                origin: event.downPoint
                diff: (move.dragging?diff or new scope.Point(0, 0)) .add event.delta

        ..onMouseUp = (event) ~>
            move.dragging = null

        ..onMouseDown = (event) ~>
            layer.activate!
            deselect-all!

            hit = scope.project.hitTest event.point
            if hit?item
                that.selected = yes
                move.selected.push that
                console.warn "Hit: ", hit

                if @get \selectAllLayer
                    all = hit.item.getLayer().children
                    console.log "...will select all items in current layer", all
                    all.for-each (.selected = yes)
                    move.selected = all

        ..onKeyDown = (event) ~>
            # delete an item with Delete key
            if event.key is \delete
                for i in [til move.selected.length]
                    item = move.selected.pop!
                    if item.remove!
                        console.log ".........deleted: ", item
                    else
                        console.error "couldn't remove item: ", item
                        move.selected.push item

                unless empty move.selected
                    console.error "Why didn't we erase those selected items?: ", move.selected
                    debugger

            # Press Esc to cancel a move
            if (event.key is \escape) and move.dragging?
                try
                    for move.selected
                        ..position
                            ..x -= move.dragging.diff.x
                            ..y -= move.dragging.diff.y

                    deselect-all!
                catch
                    debugger


    {move-tool, cache: move}
