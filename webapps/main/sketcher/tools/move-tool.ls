require! 'prelude-ls': {empty, flatten, partition}
require! './lib/selection': {Selection}
require! '../kernel': {PaperDraw}
require! './lib/snap-move': {snap-move}
require! './lib/trace/lib': {is-trace}

shift-items = (items, delta, op="add") ->
    for items
        shift-item .., delta, op

movement = (operand, left, right) -->
    if operand in <[ add subtract ]>
        left.[operand] right
    else
        console.log "returning right as is: ", right
        right

shift-item = (item, delta, type="add") ->
    op = movement type

    for [item]
        switch ..getClassName!
        | 'Curve' =>
            for [..segment1, ..segment2]
                ..point.set (..point `op` delta)
        | 'Path' =>
            for ..getSegments!
                ..point.set (..point `op` delta)
        | 'Point' =>
            ..set (.. `op` delta)
        |_ =>
            console.log "moving #{..getClassName!}"
            ..position.set (..position `op` delta)

export MoveTool = (_scope, layer, canvas) ->
    # http://paperjs.org/tutorials/project-items/transforming-items/
    ractive = this
    selection = new Selection
    scope = new PaperDraw
    move =
        dragging: null  # total drag vector
        mode: null
        enabled: no

    move-tool = new scope.Tool!
        ..onMouseDrag = (event) ~>
            return unless move.enabled
            if move.pan
                # panning
                offset = event.downPoint .subtract event.point
                scope.view.center = scope.view.center .add offset
            else
                # backup the movement vector for a possible cancel
                move.dragging = move.dragging or new scope.Point(0, 0)

                unless move.mode is \trace
                    # move an item regularly
                    shift-items selection.selected, event.delta
                    move.dragging `shift-item` event.delta
                else
                    # handle trace movement specially
                    [sel, rest] = partition (.data?.role is \handle), selection.selected
                    console.log "sel: ", sel
                    snap = snap-move event.downPoint, event.point, {shift: event.modifiers.shift}
                    console.log "rest: ", rest, "delta: ", event.delta, snap.delta
                    shift-items sel, snap.delta
                    shift-items rest, snap.delta
                    move.dragging `shift-item` snap.delta

        ..onMouseUp = (event) ~>
            move.enabled = no
            move.dragging = null
            move.pan = no
            move.mode = null
            canvas.style.cursor = 'default'

        ..onMouseDown = (event) ~>
            move.enabled = yes
            layer.activate!
            scope.get-tool \select .onMouseDown event
            hits = scope.project.hitTestAll event.point
            for flatten hits
                console.log "found hit: ", ..
                if ..item.selected
                    if is-trace ..item
                        #console.warn "this is trace."
                        move.mode = \trace
                    #console.log "...found selected on hit."
                    scope.cursor \move
                    return
            move.pan = yes
            scope.cursor \grabbing

        ..onKeyDown = (event) ~>
            # Press Esc to cancel a move
            if event.key is \escape
                if move.dragging?
                    # cancel last movement
                    shift-items selection.selected, move.dragging, "subtract"
                    move-tool.emit \mouseup
                else
                    # activate selection tool
                    ractive.set \currTool, \sl

            if event.key is \ı
                # rotate the top level group
                angle = if event.modifiers.shift => 45 else 90
                selection.getTopItem!.rotate angle

    move-tool
