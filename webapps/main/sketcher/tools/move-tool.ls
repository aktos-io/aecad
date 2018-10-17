require! 'prelude-ls': {empty}

export MoveTool = (scope, layer) ->
    # http://paperjs.org/tutorials/project-items/transforming-items/

    move =
        selected: []
        dragging: null
        last-drag-point: null

    deselect-all = ->
        for move.selected
            ..selected = no

        move
            ..selected = []
            ..dragging = null
            ..pan = no

    move-tool = new scope.Tool!
        ..onMouseDrag = (event) ~>
            unless empty move.selected
                for move.selected
                    ..position.set (..position .add event.delta)

                move.dragging = (move.dragging or new scope.Point(0, 0)) .add event.delta
            else
                # panning
                if move.pan
                    offset = event.downPoint .subtract event.point
                    scope.view.center = scope.view.center .add offset


        ..onMouseUp = (event) ~>
            move.dragging = null
            move.pan = no

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
            else
                # Pan mode if no hit + drag
                # TODO: change cursor to grab
                move.pan = yes

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
                for move.selected
                    ..position.set (..position .subtract move.dragging)
                deselect-all!


    {move-tool, cache: move}
