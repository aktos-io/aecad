Ractive.decorators.drag = (node, keypath) ->
    ractive = this
    startPos = begin = {}

    node.addEventListener \mousedown, start, false

    listenOnDocument = ->
        document.addEventListener \mousemove, move, false
        document.addEventListener \mouseup, end, false

    unlistenOnDocument = ->
        document.removeEventListener \mousemove, move, false
        document.removeEventListener \mouseup, end, false

    function start (e)
        begin := {x: e.x, y: e.y}
        that = ractive.get keypath
        startPos := {x: that.left, y: that.top}
        ractive.set \dragging, yes
        listenOnDocument!
        e.preventDefault!
        e.stopPropagation!

    function move (e)
        ractive.set keypath, do
            left: startPos.x + e.x - begin.x
            top: startPos.y + e.y - begin.y

        e.preventDefault!
        e.stopPropagation!

    function end
        console.log "end is called, dragging is ended"
        unlistenOnDocument!
        ractive.set \dragging, no

    return do
        update: (pos) ->
            console.log pos
            position = pos
        teardown: ->
            node.removeEventListener \mousedown, start, false
            end!
