require! 'paper'
window.paper = paper # required for PaperScope to work correctly
require! 'prelude-ls': {keys, maximum, map}
require! '../tools/lib/selection': {Selection}
require! 'aea': {VLogger}
require('jquery-mousewheel')($);
require! './zooming': {paperZoom}
require! './history': {History}
require! './canvas-control': {canvas-control}
require! './aecad-methods'
require! './import-export'
require! '../tools/lib/get-aecad': {get-aecad}

export class PaperDraw implements canvas-control, aecad-methods, import-export
    @instance = null
    (opts={}) ->
        # Make this class Singleton
        return @@instance if @@instance
        @@instance = this

        # ref
        on-zoom-change = ->

        if opts.canvas
            @canvas = opts.canvas
            @_scope = paper.setup @canvas
            for k, v of @_scope
                # @project is assigned here
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

            @_active_layout = @ractive.get \project.name
            @layouts = {} # name: Layout

            # zooming
            $ @canvas .mousewheel (event) ~>
                paperZoom @_scope, event, ~>
                    on-zoom-change ...arguments
                @ractive.update \pcb.view.zoom
                @update-zoom-subs!


        if opts.background
            @canvas.style.background = that

        @tools = {}
        observer = null 
        @selection = new Selection
            ..scope = this
            ..on \selected, (items) ~>
                selected = items.0
                return unless selected
                #console.log "Displaying properties of ", selected
                if aeobj=(selected.aeobj)
                    #console.log "selected item's data: ", aeobj.data
                    #console.log "selected item's owner's data: ", aeobj.owner.data
                    unless "userDefined" of aeobj.data
                        aeobj.data.userDefined = ""
                    @ractive.set \aecadData, aeobj.data
                    observer := @ractive.observe \aecadData, (_new, _old) ~> 
                        aeobj.finish?!

                    # DEBUG: Additional data for debugging purposes
                    #@ractive.set \aecadData.grotation, aeobj.grotation

                    if aeobj.parent
                        @ractive.set \aecadOwnerData, aeobj.owner.data

                else
                    # hit is *probably* a trace part (a Curve of a Path)
                    if selected.item?getPath?!
                        selected = that
                    @ractive.set \aecadData, (selected.data?aecad or {})

            ..on \cleared, ~>
                @ractive.set \aecadData, {}
                @ractive.set \aecadOwnerData, {}
                observer?cancel?!

        # visual logger
        @vlog = new VLogger @ractive

        @history = new History {
            @project, @selection, @ractive, name: "sketcher", @vlog, parent: this
        }
        # try to load if a project exists
        @history.load!

        $ window .on \unload, ~>
            @history.save!
            
        do
            @vlog.clog "Starting autosave..."
            <~ :lo(op) ~> 
                period = 2min
                <~ sleep period * 60_000
                @vlog.clog "Running autosave after #{period}mins..."
                @history.save!
                PNotify.info text: "Autosave complete."
                lo(op) 

        # http://paperjs.org/reference/paperscope/#settings
        @_scope.settings
        #    ..handleSize = 8

        # on-zoom subscribers
        @zoom-subs = {}

        move = {}
        pan-style = \speed-drag
        speed-drag-key =
            key: 'alt-graph'
            name: 'AltGr'
        speed-drag =
            inactive: 1.5 # inactive radius
        esc = {} # escape key handler
        _self = this

        on-zoom-change = (offset, newZoom, viewPosition) ~>
            if move.grab-point
                gg = @view.projectToView that
            @view.center = @view.center.add offset
            @view.zoom = newZoom
            if move.grab-point
                move.grab-point = @view.viewToProject gg

        @_scope.view
            ..onFrame = (event) ~>
                if event.count % 2 is 0
                    # skip half of frames
                    return
                if move.speed and move.pan
                    speed-val = 30
                    coeff = @view.zoom / speed-val
                    dead-radius = (speed-drag.inactive / coeff)
                    if (move.speed.length * @view.zoom) > dead-radius
                        ratio = dead-radius / move.speed.length / @view.zoom
                        if ratio > 1
                            ratio = 1
                        dead-vect = move.speed.multiply (ratio)
                        speed = move.speed.subtract(dead-vect) .multiply coeff
                        #console.log "speed len: ", speed.length, "dead radius: ", dead-radius, "move-speed:", move.speed.length
                        @view.center = @view.center.add speed
                        move.grab-point
                            ..set ..add speed
                        @ractive.get 'pointer'
                            ..set ..add speed
                        @ractive.update 'pointer'

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
                            #console.log "global grab point is: ", event.point, move.grab-point
                            move.grab-point = event.point
                        move.speed = (event.point.subtract move.grab-point).divide(@view.zoom)

                @ractive.set \pointer, event.point

            ..onKeyDown = (event) ~>
                console.log "Pressed key: ", event.key, event.modifiers

                switch event.key
                | \delete =>
                    # delete an item with Delete key
                    @history.commit!
                    @selection.delete!
                    @ractive.fire \calcUnconnected, {+silent}  # TODO: Unite this action
                | \z =>
                    if event.modifiers.control
                        # Undo changes 
                        @ractive.fire \undo 

                | speed-drag-key.key =>
                    unless event.modifiers.control
                        #console.log "global pan mode enabled."
                        move.pan = yes
                        if move.pan-locked
                            PNotify.info do
                                text: "Joystick mode disabled"
                                addClass: 'nonblock'

                        move.direction = null
                        move.pan-lock0 = move.pan-lock or 0
                        move.pan-lock = Date.now!
                        #console.log "pan lock diff: ", (move.pan-lock - move.pan-lock0)

            ..onKeyUp = (event) ~>
                switch event.key
                | speed-drag-key.key =>
                    if (move.pan-lock - move.pan-lock0) > 300ms
                        if move.pan
                            #console.log "global pan mode disabled."
                            move.grab-point = null
                            move.pan = null
                            move.speed = null
                            move.pan-locked = null
                    else
                        move.pan-locked = true
                        PNotify.info do
                            text: "Joystick mode enabled. \nPress #{speed-drag-key.name} to disable."
                            addClass: 'nonblock'

                | \escape =>
                    esc.date = Date.now!
                    esc.date0 = esc.date0 or 0
                    if esc.date - esc.date0 < 300ms
                        _self._on_double_esc?!
                    esc.date0 = esc.date

    on-double-esc: (handler) ->
        @_on_double_esc = handler

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
