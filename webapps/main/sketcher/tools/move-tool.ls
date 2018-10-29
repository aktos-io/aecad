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
        console.log "moving #{item.getClassName!}"
        item.position.set (item.position `op` delta)

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
                    for selection.selected
                        .. `shift-item` event.delta
                    move.dragging `shift-item` event.delta
                else
                    # handle trace movement specially
                    # 1. snap movement direction
                    # 2. preserve left and right curve slope
                    # 3. move touch ends
                    # ----------------------------------
                    snap = snap-move event.downPoint, event.point, do
                        shift: event.modifiers.shift
                        restrict: yes
                        tolerance: 10

                    try
                        {active, rest} = selection.get-selection!
                    catch
                        scope.vlog.error e.message
                        return

                    handle = active
                    #console.log "shifting handle: ", handle
                    handle-p1 = handle.segment1
                    handle-p2 = handle.segment2
                    shift-item handle, snap.delta
                    console.log "rest is: #{rest.length}: ", rest
                    for rest
                        switch ..constructor.name
                        | 'SegmentPoint' =>
                            segment = .._owner
                            prev = segment.getPrevious!
                            next = segment.getNext!

                            _tolerance = 1 + snap.delta.length
                            if segment.point.isClose handle-p1.point, _tolerance
                                close-end = handle-p1
                                far-end = handle-p2
                            else if segment.point.isClose handle-p2.point, _tolerance
                                close-end = handle-p2
                                far-end = handle-p1
                            else
                                console.error "where is it close to? ", segment, handle
                                return

                            unless prev and next
                                # this is tip
                                shift-item segment.point, snap.delta
                            else
                                outer-segment = if far-end.point.isClose next.point, _tolerance
                                    prev
                                else
                                    next

                                outer-line = outer-segment.point.subtract segment.point
                                console.log "outer line angle: ", outer-line.angle
                                snap-to = {}
                                angle = outer-line.angle
                                eequal = (left, right) ->
                                    for right
                                        if .. - 1 < left < .. + 1
                                            return true
                                    return false
                                if angle `eequal` [-90, 90]
                                    snap-to.y = true
                                else if angle `eequal` [ 0, 180 ]
                                    snap-to.x = true
                                else if angle `eequal` [-45, 135]
                                    snap-to.slash = true
                                else if angle `eequal` [45, -135]
                                    snap-to.backslash = true

                                if snap-to.slash
                                    if abs(snap.delta.y) > abs(snap.delta.x)
                                        # movement in y direction
                                        console.log "slash in y direction"
                                        segment.point.y += snap.delta.y
                                        segment.point.x -= snap.delta.y
                                else if snap-to.backslash
                                    console.log "snapping to backslash, ", snap.delta.x, snap.delta.y
                                    if abs(snap.delta.y) >= abs(snap.delta.x)
                                        # movement in y direction
                                        console.log "backslash in y direction"
                                        segment.point.y += snap.delta.y
                                        segment.point.x += snap.delta.y
                                else if snap-to.x
                                    segment.point.x += snap.delta.x
                                else if snap-to.y
                                    segment.point.y += snap.delta.y
                                else
                                    console.warn "we won't move other than 4 directions"

                            # track handle position
                            close-end.point.set segment.point
                        |_ =>
                            console.warn "This is not a part of trace: ", ..constructor.name, ..
                            #shift-item .., snap.delta

                    # backup movement
                    move.dragging `shift-item` snap.delta

        ..onMouseUp = (event) ~>
            move
                ..enabled = no
                ..dragging = null
                ..pan = no
                ..mode = null
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
                    scope.history.commit!
                    return
            move.pan = yes
            scope.cursor \grabbing

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
                    for selection.selected
                        shift-item .., move.dragging, "subtract"
                    move-tool.emit \mouseup
                else
                    # activate selection tool
                    ractive.set \currTool, \sl
            | \ı =>
                # rotate the top level group
                angle = if event.modifiers.shift => 45 else 90
                selection.getTopItem!.rotate angle
            | \z =>
                if event.modifiers.control
                    scope.history.back!



    move-tool
