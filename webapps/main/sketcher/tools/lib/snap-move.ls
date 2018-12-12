require! 'prelude-ls': {abs}
require! '../../kernel': {PaperDraw}

# returns the snapped movement
session = null # indicates if the same movement continues
prev = null  # previously provided snap point

export snap-move = (start-point, curr, opts={}) ->
    '''
    Args:
        start-point : [Point] Start point
        curr        : [Point] Current point
        opts        : [Object] Snap options
            shift or lock   : [Bool] lock axis
            tolerance       : [Number] normalized tolerance

    Returns: Object:
        point, snapped: [Point] Absolute value of the snapped point
        delta: [Point] The delta between previously calculated (`prev`) snap `point`
        route-over: [String] "a-b" formatted string that indicates which axis' the route
            should follow in order to have cut-off corners

    '''
    _defaults =
        tolerance: 10

    opts = _defaults <<< opts
    lock = opts.lock or opts.shift

    scope = new PaperDraw
    tolerance = opts.tolerance / scope.view.zoom

    if not session or not session.equals start-point
        session := start-point.clone!
        prev := null
    unless prev?
        prev := start-point.clone!

    moving-point = curr.clone!

    y-diff = curr.y - start-point.y
    x-diff = curr.x - start-point.x

    snap-y = false
    snap-x = false
    snap-slash = false
    snap-backslash = false

    if lock and prev
        # lock into current snap
        angle = prev.subtract start-point .angle
        console.log "angle is: ", angle
        if angle is 90 or angle is -90
            snap-y = true
        else if angle is 0 or angle is 180
            snap-x = true
        else if angle is -45 or angle is 135
            snap-slash = true
        else if angle is 45 or angle is -135
            snap-backslash = true

    sdir =
        x: abs(y-diff)
        y: abs(x-diff)
        backslash: abs(x-diff - y-diff)
        slash: abs(x-diff + y-diff)

    # decide snap axis
    if sdir.x < tolerance and sdir.y < tolerance
        # snap to original point
        moving-point = start-point
    else if snap-x or sdir.x < tolerance
        moving-point.x = curr.x
        moving-point.y = start-point.y
    else if snap-y or sdir.y < tolerance
        moving-point.y = curr.y
        moving-point.x = start-point.x
    else if snap-backslash or sdir.backslash < tolerance
        d = start-point.x - curr.x
        moving-point
            ..x = curr.x
            ..y = start-point.y - d
    else if snap-slash or sdir.slash < tolerance
        d = start-point.x - curr.x
        moving-point
            ..x = curr.x
            ..y = start-point.y + d
    else
        unless opts.restrict
            moving-point.set curr

    # calculate correction path
    route-over = if abs(x-diff) > abs(y-diff)
        if x-diff * y-diff > 0
            "x-s"
        else
            "x-bs"
    else if abs(y-diff) > abs(x-diff)
        if x-diff * y-diff > 0
            "y-s"
        else
            "y-bs"
    else
        null

    delta = moving-point.subtract prev
    prev := moving-point.clone!

    return {delta, route-over, snapped: moving-point, point: moving-point}
