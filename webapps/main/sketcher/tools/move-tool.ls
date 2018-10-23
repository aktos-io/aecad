require! 'prelude-ls': {empty, flatten}
require! './lib/selection': {Selection}
require! '../kernel': {PaperDraw}

export MoveTool = (_scope, layer, canvas) ->
    # http://paperjs.org/tutorials/project-items/transforming-items/
    ractive = this
    selection = new Selection
    scope = new PaperDraw
    move = dragging: null  # total drag vector

    move-tool = new scope.Tool!
        ..onMouseDrag = (event) ~>
            if move.pan
                # panning
                offset = event.downPoint .subtract event.point
                scope.view.center = scope.view.center .add offset
            else
                # move all selected items
                i = 0
                for selection.selected
                    console.log "moving selected: #{++i} ", ..
                    switch ..getClassName!
                    | 'Curve' =>
                        console.log "...moving curve #{i}"
                        for [..segment1, ..segment2]
                            ..point.set (..point .add event.delta)
                    | 'Path' =>
                        console.log "...moving path #{i}..."
                        for ..getSegments!
                            ..point.set (..point .add event.delta)
                    | 'Point' =>
                        ..set (..add event.delta)
                    |_ =>
                        debugger
                        ..position.set (..position .add event.delta)

                # backup the movement vector for a possible cancel
                move.dragging = (move.dragging or new scope.Point(0, 0)) .add event.delta

        ..onMouseUp = (event) ~>
            move.dragging = null
            move.pan = no
            canvas.style.cursor = 'default'

        ..onMouseDown = (event) ~>
            layer.activate!
            scope.get-tool \select .onMouseDown event
            hits = scope.project.hitTestAll event.point
            for flatten hits
                console.log "found hit: ", ..
                if ..item.selected
                    console.log "...found selected on hit."
                    canvas.style.cursor = 'move'
                    return
            move.pan = yes
            canvas.style.cursor = 'grabbing'

        ..onKeyDown = (event) ~>
            # Press Esc to cancel a move
            if event.key is \escape
                if move.dragging?
                    # cancel last movement
                    for selection.selected
                        ..position.set (..position .subtract move.dragging)
                else
                    # activate selection tool
                    ractive.set \currTool, \sl

            if event.key is \ı
                # rotate the top level group
                angle = if event.modifiers.shift => 45 else 90
                selection.getTopItem!.rotate angle

    move-tool
