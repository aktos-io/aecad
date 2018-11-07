require! 'prelude-ls': {flatten, round}
require! './tools/lib/selection': {Selection}
require! 'dcs/lib/keypath': {get-keypath, set-keypath}
require! 'actors': {BrowserStorage}
require! 'aea': {VLogger}

class History
    (opts) ->
        @project = opts.project
        @ractive = opts.ractive
        @selection = opts.selection
        @db = new BrowserStorage opts.name
        @commits = []
        @limit = 200

    commit: ->
        @commits.push @project.exportJSON!
        console.log "added to history"
        if @commits.length > @limit
            console.log "removing old history"
            @commits.shift!

    back: ->
        if @commits.pop!
            console.log "Going back in the history. Left: #{@commits.length}"
            @load-project that
        else
            console.warn "No commits left, sorry."


    load-project: (data) ->
        # data: stringified JSON
        if data
            @project.clear!
            @selection.clear!
            @project.importJSON data

            while true
                needs-rerun = false
                for layer in @project.layers
                    unless layer
                        # workaround for possible Paper.js bug
                        # which can not handle more than a few
                        # hundred layers
                        console.warn "...we have an null layer!"
                        needs-rerun = true
                        continue
                    if layer.getChildren!.length is 0
                        console.log "removing layer..."
                        layer.remove!
                        continue

                    if layer.name
                        @ractive.set "project.layers.#{Ractive.escapeKey layer.name}", layer
                    else
                        layer.selected = yes

                    for layer.getItems!
                        ..selected = no
                        if ..data?.tmp
                            ..remove!
                break unless needs-rerun
                console.warn "Workaround for load-project works."
            #console.log "Loaded project: ", @project

    load-scripts: (data) ->
        @ractive.set \drawingLs, data
        console.log "loaded scripts: ", data

    save: ->
        data = @project.exportJSON!
        @db.set \project, data
        scripts = @ractive.get \drawingLs
        @db.set \scripts, scripts

        # Save settings
        # TODO: provide a proper way for this, its too messy now
        @db.set \settings, do
            scriptName: @ractive.get \scriptName
            projectName: @ractive.get \project.name
            autoCompile: @ractive.get \autoCompile
            currTrace: @ractive.get \currTrace

        console.log "Saved at ", Date!, "project length: #{parseInt(data.length/1024)}KB"

    load: ->
        if @db.get \project
            @load-project that

        if @db.get \scripts
            @load-scripts that

        if @db.get \settings
            # TODO: see save/settings
            @ractive.set \scriptName, that.scriptName
            @ractive.set \project.name, that.projectName
            @ractive.set \autoCompile, that.autoCompile
            @ractive.set \currTrace, that.currTrace


class Line
    (opts, @paper) ->
        @p1 = new @paper.Point(opts.p1)
        @p2 = new @paper.Point(opts.p2 or (@p1.add new @paper.Point(100, 0)))
        if opts.rotate
            @p2.set @p2.rotate that, @p1

        @_line = new @paper.Line(@p1, @p2)
        @opts = opts  # backup the options for later use

    move: (delta1, delta2) ->
        # delta1: delta for p1
        # delta2: delta for p2
        unless delta2
            # move by keeping the angle intact
            delta2 = delta1

        @p1.set @p1.add delta1
        @p2.set @p2.add delta2
        @_line = new @paper.Line(@p1, @p2)

    intersect: (other-line) ->
        @_line.intersect other-line._line, true

    get-angle: ->
        @_line.vector.angle

    rotate: (degree, opts={}) ->
        rotation = degree
        if opts.absolute
            rotation = degree - @_line.vector.angle
        if opts.round
            round-diff = @_line.vector.angle - round @_line.vector.angle
            rotation -= round-diff

        _p2 = @p2.rotate rotation, @p1
        if opts.inplace
            @p2.set _p2

            # TODO: Reuse the paper.Line instance
            @_line = new @paper.Line @p1, @p2
            return this
        else
            return new Line {p1: @p1, p2: _p2}, @paper


export class PaperDraw
    @instance = null
    (opts={}) ->
        # Make this class Singleton
        return @@instance if @@instance
        @@instance = this

        if opts.scope
            @_scope = opts.scope
            for k, v of that
                this[k] = v
            @canvas = opts.scope.view._element

        @ractive = that if opts.ractive
        @tools = {}
        @selection = new Selection
            ..scope = this
            ..on \selected, (items) ~>
                selected = items.0
                return unless selected
                #console.log "Displaying properties of ", selected
                @ractive.set \selectedProps, selected
                @ractive.set \propKeys, do
                    fillColor: \color
                    strokeWidth: \number
                    strokeColor: \color
                @ractive.set \aecadData, (selected.data?aecad or {})

            ..on \cleared, ~>
                @ractive.set \propKeys, {}
                @ractive.set \aecadData, {}

        @history = new History {
            @project, @selection, @ractive, name: "sketcher"
        }
        # try to load if a project exists
        @history.load!

        $ window .on \unload, ~>
            @history.save!

        # http://paperjs.org/reference/paperscope/#settings
        @_scope.settings
            ..handleSize = 8

        # visual logger
        @vlog = new VLogger @ractive

        move = {}
        pan-style = \speed-drag
        @_scope.view
            ..onFrame = (event) ~>
                if move.speed and move.pan
                    @_scope.view.center = @_scope.view.center.add move.speed
                    move.grab-point.set move.grab-point.add move.speed

            ..onMouseMove = (event) ~>
                if move.pan
                    switch pan-style
                    | \drag-n-drop =>
                        unless move.grab-point
                            #console.log "global grab point is: ", event.point
                            move.grab-point = event.point
                        # drag and drop style panning
                        offset = move.grab-point .subtract event.point
                        @_scope.view.center = @_scope.view.center .add offset
                    | \speed-drag =>
                        # speed based panning
                        unless move.grab-point?
                            move.grab-point = event.point

                        move.speed = event.point.subtract move.grab-point .divide(20)

                        # snap to center:
                        if @_scope.view.zoom * move.speed.length < 0.5
                            move.speed = null
                        #console.log "Move speed is: ", move.speed?.length

                @ractive.set \pointer, event.point

            ..onKeyDown = (event) ~>
                # Press Esc to cancel a move
                switch event.key
                | \delete =>
                    # delete an item with Delete key
                    @history.commit!
                    @selection.delete!
                | \z =>
                    if event.modifiers.control
                        @history.back!

                | \shift =>
                    unless event.modifiers.control
                        #console.log "global pan mode enabled."
                        move.pan = yes
                        unless move.pan-locked
                            move.prev-cursor = if pan-style is \drag-n-drop
                                @cursor \grabbing
                            else
                                @cursor \all-scroll
                        move.direction = null
                        move.pan-lock0 = move.pan-lock or 0
                        move.pan-lock = Date.now!
                        #console.log "pan lock diff: ", (move.pan-lock - move.pan-lock0)

            ..onKeyUp = (event) ~>
                switch event.key
                | \shift =>
                    if (move.pan-lock - move.pan-lock0) > 300ms
                        if move.pan
                            #console.log "global pan mode disabled."
                            move.grab-point = null
                            move.pan = null
                            move.speed = null
                            move.pan-locked = null
                            @cursor move.prev-cursor
                    else
                        move.pan-locked = true

    _Line: (opts) ->
        new Line opts, @_scope

    get-all: ->
        # returns all items
        flatten [..getItems! for @project.layers]

    get-flatten: (opts={}) ->
        '''
        opts:
            containers: [bool] If true, "Group"s and "Layers" are also included
        '''
        items = []
        make-flatten = (item) ->
            r = []
            if item.hasChildren!
                for item.children
                    if ..hasChildren!
                        if opts.containers
                            r.push ..
                        r ++= make-flatten ..
                    else
                        r.push ..
            else
                r.push item
            return r

        for @project.layers
            items ++= make-flatten ..
        items

    clean-tmp: ->
        for @get-all! when ..data?tmp
            ..remove!

    add-layer: (name) ->
        @use-layer name

    use-layer: (name) ->
        layer = null
        if @ractive.get "project.layers.#{Ractive.escapeKey name}"
            layer = that
                ..activate!
        else
            layer = new @Layer!
                ..name = name
            @ractive.set "project.layers.#{Ractive.escapeKey name}", layer
        @ractive.set \activeLayer, name
        layer

    send-to-layer: (item, name) ->
        set-keypath item, 'data.aecad.layer', name
        @add-layer name  # add the layer if it doesn't exist
        layer = @ractive.get "project.layers.#{Ractive.escapeKey name}"
        layer.addChild item

    add-tool: (name, tool) ->
        @tools[name] = tool

    get-tool: (name) ->
        @tools[name]

    cursor: (name) ->
        prev = @canvas.style.cursor
        @canvas.style.cursor = name
        prev

    export-svg: ->
        old-zoom = @view.zoom
        @view.zoom = 1
        svg = @project.exportSVG do
            asString: true
            bounds: 'content'
        @view.zoom = old-zoom # for above workaround
        return svg

    export-json: ->
        old-zoom = @view.zoom
        @view.zoom = 1
        json = @project.exportJSON!
        @view.zoom = old-zoom # for above workaround
        return json
