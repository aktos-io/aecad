require! 'prelude-ls': {empty}
require! './lib/selection': {Selection}

export MoveTool = (scope, layer, canvas) ->
    # http://paperjs.org/tutorials/project-items/transforming-items/

    selection = new Selection
    move =
        dragging: null  # total drag vector

    move-tool = new scope.Tool!
        ..onMouseDrag = (event) ~>
            if move.pan
                # panning
                offset = event.downPoint .subtract event.point
                scope.view.center = scope.view.center .add offset
            else
                # move all selected items
                for selection.selected
                    ..position.set (..position .add event.delta)

                # backup the movement vector for a possible cancel
                move.dragging = (move.dragging or new scope.Point(0, 0)) .add event.delta
    
        ..onMouseUp = (event) ~>
            move.dragging = null
            move.pan = no
            canvas.style.cursor = 'default'

        ..onMouseDown = (event) ~>
            layer.activate!
            hit = scope.project.hitTest event.point
            if hit?.item.selected
                # we are going to move these items
                canvas.style.cursor = 'move'
            else
                move.pan = yes
                canvas.style.cursor = 'grabbing'

        ..onKeyDown = (event) ~>
            # Press Esc to cancel a move
            if (event.key is \escape) and move.dragging?
                for selection.selected
                    ..position.set (..position .subtract move.dragging)

    move-tool
