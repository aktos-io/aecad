require! 'prelude-ls': {empty, flatten, partition, abs, max, sqrt}
require! './lib/selection': {Selection}
require! '../kernel': {PaperDraw}
require! './lib/snap-move': {snap-move}
require! './lib/trace/lib': {is-trace}

movement = (operand, left, right) -->
    if operand in <[ add subtract ]>
        left.[operand] right
    else
        right

shift-item = (item, delta, type="add") ->
    op = movement type
    switch item.getClassName!
    | 'Curve' =>
        for [item.segment1, item.segment2]
            ..point.set (..point `op` delta)
    | 'Path' =>
        for item.getSegments!
            ..point.set (..point `op` delta)
    | 'Segment' =>
        item.point.set (item.point `op` delta)
    | 'Point' =>
        item.set (item `op` delta)
    |_ =>
        # Possibly Group
        console.log "moving #{item.getClassName!}"
        item.position.set (item.position `op` delta)


eequal = (left, right) ->
    for right
        if .. - 1 < left < .. + 1
            return true
    return false

export MoveTool = (_scope, layer, canvas) ->
    # http://paperjs.org/tutorials/project-items/transforming-items/
    ractive = this
    selection = new Selection
    scope = new PaperDraw
    move =
        dragging: null  # total drag vector
        mode: null
        enabled: no
        about-to-move: no

    move-tool = new scope.Tool!
        ..onMouseDrag = (event) ~>
            return unless move.enabled
            if move.pan
                # panning
                offset = event.downPoint .subtract event.point
                scope.view.center = scope.view.center .add offset
            else
                # backup the movement vector for a possible cancel
                move.dragging = true

                # commit to history
                if move.about-to-move
                    move.about-to-move = no
                    scope.history.commit!


                snap = snap-move event.downPoint, event.point, do
                    shift: event.modifiers.shift
                    restrict: yes
                    tolerance: 10

                unless move.mode is \trace
                    # move an item regularly
                    for selection.selected
                        .. `shift-item` snap.delta
                else
                    # handle trace movement specially
                    # 1. preserve left and right curve slope
                    # 2. move touch ends
                    # ----------------------------------
                    items = []
                    for side in <[ left right ]>
                        items.length = 0
                        solver = (-> it)
                        for selection.selected when ..name is side
                            if ..solver?
                                solver = ..solver
                            else
                                items.push ..item
                        try
                            delta = solver snap.delta
                        catch
                            return scope.vlog.error e.message
                        #console.log "Moving #{side} side:", delta
                        for items
                            .. `shift-item` delta


        ..onMouseUp = (event) ~>
            move
                ..enabled = no
                ..dragging = null
                ..pan = no
                ..mode = null
                ..about-to-move = no

            scope.cursor 'default'


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
                    move.about-to-move = yes
                    return
            move.pan = yes
            scope.cursor \grabbing

        ..onMouseMove = (event) ~>
            scope.ractive.set \pointer, event.point

        ..onKeyDown = (event) ~>
            # Press Esc to cancel a move
            switch event.key
            | \delete =>
                # delete an item with Delete key
                scope.history.commit!
                selection.delete!
            | \escape =>
                if move.dragging?
                    # cancel last movement
                    move-tool.emit \mouseup
                    scope.history.back!
            | \ı =>
                # rotate the top level group
                angle = if event.modifiers.shift => 45 else 90
                selection.getTopItem!.rotate angle
            | \z =>
                if event.modifiers.control
                    scope.history.back!



    move-tool
