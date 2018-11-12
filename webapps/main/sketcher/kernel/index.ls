require! 'paper'
window.paper = paper # required for PaperScope to work correctly
require! 'prelude-ls': {keys, maximum, map}
require! '../tools/lib/selection': {Selection}
require! 'aea': {VLogger}
require('jquery-mousewheel')($);
require! './zooming': {paperZoom}
require! './history': {History}
require! './canvas-control': {canvas-control}

export class PaperDraw implements canvas-control
    @instance = null
    (opts={}) ->
        # Make this class Singleton
        return @@instance if @@instance
        @@instance = this

        if opts.canvas
            @canvas = opts.canvas
            @_scope = paper.setup @canvas
            for k, v of @_scope
                this[k] = v

            do resizeCanvas = ~>
                container = $ @canvas.parentNode
                pl = parse-int container.css("padding-left")
                pr = parse-int container.css("padding-right")
                width = container.innerWidth! - pr - pl
                #height = container.innerHeight!
                @canvas.width = width
                @canvas.height = opts.height

                # taken from https://gist.github.com/campsjos/b561023e453aba2d9c31
                @_scope.view.setViewSize(new @_scope.Size(@canvas.width, @canvas.height))
                console.log "canvas is resized!", @canvas.width, @canvas.height

                # workaround for view.update(force=true)
                @_scope.view.center = @_scope.view.center.add [1, 0]
                @_scope.view.center = @_scope.view.center.subtract [1, 0]

            window.addEventListener('resize', resizeCanvas, false);

            @ractive = opts.ractive

            # zooming
            $ @canvas .mousewheel (event) ~>
                paperZoom @_scope, event
                @ractive.update \pcb.view.zoom
                @update-zoom-subs!


        if opts.background
            @canvas.style.background = that

        @tools = {}
        @selection = new Selection
            ..scope = this
            ..on \selected, (items) ~>
                selected = items.0
                return unless selected
                #console.log "Displaying properties of ", selected
                if selected.item?getPath?!
                    selected = that
                @ractive.set \aecadData, (selected.data?aecad or {})

            ..on \cleared, ~>
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
        #    ..handleSize = 8

        # visual logger
        @vlog = new VLogger @ractive

        # on-zoom subscribers
        @zoom-subs = {}

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

                        # set pan speed to zero if it's too slow
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

    on-zoom: (handler) ->
        # normalize the source values according to zoom value and pass them
        # to handler on zoom change
        #
        # Returns: control object with a "remove()" method
        #
        id = (@zoom-subs |> keys |> map parse-int |> maximum) or 0 |> (+ 1)
        @zoom-subs[id] = (zoom) ~>
            hb = sleep 1000ms, ~>
                try delete @zoom-subs[id]
                console.warn "No heartbeat for #{id}, removing handler. curr:", @zoom-subs

            handler (1 / zoom), heartbeat = ->
                clear-timeout hb

        # run on first subscription
        @update-zoom-subs id

        console.log "installed zoom handler: ", id, "curr: ", @zoom-subs

        return ctrl =
            remove: ~> @remove-zoom-subs id
            id: id

    remove-zoom-subs: (id) ->
        delete @zoom-subs[id]
        console.log "Deleted zoom handler: id: #{id}, curr:", @zoom-subs

    update-zoom-subs: (id) ->
        for _id, handler of @zoom-subs
            if id? and "#{id}" isnt _id
                # update only the specific id
                continue
            #console.log "Updating zoom subscriber: #{_id}"
            handler(@view.zoom)
