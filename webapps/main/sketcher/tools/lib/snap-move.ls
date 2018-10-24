require! 'prelude-ls': {abs}

# returns the snapped movement
session = null
prev = null

export snap-move = (start-point, curr, opts={}) ->
    _defaults =
        tolerance: 20

    opts = _defaults <<< opts

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

    if opts.shift and prev
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
    if snap-x or sdir.x < opts.tolerance
        moving-point.x = curr.x
        moving-point.y = start-point.y
    else if snap-y or sdir.y < opts.tolerance
        moving-point.y = curr.y
        moving-point.x = start-point.x
    else if snap-backslash or sdir.backslash < opts.tolerance
        d = start-point.x - curr.x
        moving-point
            ..x = curr.x
            ..y = start-point.y - d
    else if snap-slash or sdir.slash < opts.tolerance
        d = start-point.x - curr.x
        moving-point
            ..x = curr.x
            ..y = start-point.y + d
    else
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

    return {delta, route-over, snapped: moving-point}
