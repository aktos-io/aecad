require! '../../tools/trace-tool': {TraceTool}
require! '../../tools/freehand': {Freehand}
require! '../../tools/move-tool': {MoveTool}
require! '../../tools/line-tool': {LineTool}
require! '../../tools/select-tool': {SelectTool}
require! '../../tools/lib/selection': {Selection}
require! 'prelude-ls': {min, empty, abs, keys}
require! 'dcs/lib/keypath': {set-keypath, get-keypath}
require! '../../tools/lib': {getAecad}
require! 'aea/do-math': {px2mm}
require! '../../tools/lib/schema/schema-manager': {SchemaManager}

export init = (pcb) ->
    # tools
    trace-tool = TraceTool.call this, pcb
    freehand = Freehand.call this, pcb
    line-tool = LineTool.call this, pcb
    move-tool = MoveTool.call(this)
    select-tool = SelectTool.call(this)

    # workaround for https://github.com/aktos-io/scada.js/issues/170
    @observe \currTool, (tool) ~>
        @fire \changeTool, {}, tool

    selection = new Selection
    schema-manager = new SchemaManager

    # double-tap to Esc switches to select tool
    pcb.on-double-esc ~>
        # TODO: send signal to the radio-button group only
        <~ @fire \changeTool, {}, \sl
        @set \currTool, \sl

    handlers =
        upgradeComponents: (ctx) ->
            upgrade-count = 0
            unless sch=(schema-manager.active)
                PNotify.notice text: "No active schema found, can not upgrade."
                return
            unless empty upgrades=(sch.get-upgrades!)
                for upg in upgrades
                    for sel in selection.selected when upg.component.name is sel.aeobj.owner.name
                        upgrade-count++
                        upg.component.upgrade {type: upg.type}
            selection.clear!
            PNotify.info text: "Upgraded #{upgrade-count} component(s)."


        switchLayer: (ctx, layer, proceed) ->
            @set \currLayer, layer
            for pcb.get-components!
                try
                    get-aecad ..item .trigger \focus, layer
                catch
                    console.error "Something went wrong here."
            proceed!

        calcUnconnected: (ctx) ->
            console.log "------------ Performing DRC ------------"
            if schema-manager.active
                try
                    conn-states = that.get-connection-states!
                catch
                    PNotify.error hide: no, text: e.message
                    pcb.ractive.set 'totalConnections', "--"
                    pcb.ractive.set 'unconnectedCount', "--"
                    return
                unconnected = 0
                total = 0
                for netid, state of conn-states
                    unconnected += state.unconnected
                    total += state.total
                pcb.ractive.set 'totalConnections', total
                pcb.ractive.set 'unconnectedCount', unconnected
            else
                PNotify.notice text: "No schema present at the moment."
            console.log "------------ End of DRC ------------"

        fitAll: (ctx) !~>
            for layer in pcb.project.layers
                selection.add layer, {+select}
            #console.log "fit bounds: ", fit
            fit = pcb.get-bounds!
            if fit
                # set center
                pcb.view.center = fit.center

                # set zoom
                if fit.width > 0 and fit.height > 0
                    curr = pcb.view.bounds
                    padding = 0.8
                    pcb.view.zoom *= padding * min(
                        (curr.width / fit.width),
                        (curr.height / fit.height))

                    @update \pcb.view.zoom

        changeTool: (ctx, tool, proceed) ~>
            console.log "Changing tool to: #{tool}"
            switch tool
            | \tr =>
                trace-tool.activate!
                pcb.cursor \cell
            | \fh =>
                freehand.activate!
                pcb.cursor \default
            | \mv =>
                move-tool.activate!
                pcb.cursor \default
            | \sl =>
                select-tool.activate!
                pcb.cursor \default
            | \ln =>
                line-tool.activate!
                pcb.cursor \default
            proceed?!

        sendTo: (ctx) ->
            pcb.history.commit!
            layer = ctx.component.get \to
            for pcb.selection.selected
                console.log "sending selected: ", .., "to: ", layer
                if ..aeobj
                    that.owner
                        ..set-side layer
                        ..send-to-layer 'gui' # TODO: find a more beautiful name

        groupSelected: (ctx) ->
            pcb.history.commit!
            g = new pcb.Group pcb.selection.selected
            console.log "Selected items are grouped:", g
            ctx.component.state \done...

        cleanupDrawing: (ctx) !->
            pcb.history.commit!
            i = 0
            for pcb.search!
                if ..item.getClassName?! in <[ Group Layer ]>
                    for ..item.children or []
                        if ..getClassName! is \Path and ..segments.length < 2
                            ..remove!
                    if empty ..item.[]children
                        console.log "#{..keypath.join('.')} should be deleted. (\##{++i})"
                        ..item.remove!
            pcb.vlog.info "Removed #{i} items. Use Ctrl+Z for undo."

        explode: (ctx) ->
            exploded = pcb.explode {+recursive}, pcb.selection.selected
            # WIP

        saveBounds: (ctx) ->
            if empty selection.selected
                PNotify.notice do
                    text: "No selection found (last saved coordinates are intact)."
                    addClass: 'nonblock'
                return

            bounds = selection.bounds!
            pcb.ractive.set \lastBounds, bounds
            #console.log "last bounds: ", bounds
            selection.clear!
            PNotify.info do
                text: "Saved last bounds: (x:#{bounds.center.x |> oneDecimal}, y:#{bounds.center.y |> oneDecimal})"
                addClass: 'nonblock'

        moveToCenter: (ctx) ->
            bounds = pcb.ractive.get \lastBounds
            if bounds and not empty selection.selected
                pcb.history.commit!
                for selection.selected
                    # FIXME: Selection holds lots of formats, reduce this!
                    if ..aeobj
                        that.owner.position.set bounds.center
                    else
                        ..position.set bounds.center
            else
                PNotify.notice text: "Not possible."

        measureDistance: (ctx) ->
            bounds = pcb.ractive.get \lastBounds
            unless bounds or empty selection.selected
                PNotify.notice text: "Not possible."
            else
                prev = bounds.center
                curr = selection.bounds!.center
                selection.clear!

                line = new pcb.Path.Line do
                    from: prev
                    to: curr
                    stroke-color: 'yellow'
                    stroke-width: 3
                    selected: yes
                    data: {+tmp, +guide}
                    opacity: 0.5

                format = (x) ->
                    "#{oneDecimal (x |> px2mm), 2} mm"

                dist = prev.subtract(curr).length |> format
                dx = prev.x - curr.x |> abs |> format
                dy = prev.y - curr.y |> abs |> format

                ttip = new pcb.PointText do
                    point: line.bounds.center
                    content: """
                        dist: #{dist}
                        dx  : #{dx}
                        dy  : #{dy}
                        """
                    fill-color: 'white'
                    font-size: 8
                    position: line.bounds.center
                    justification: 'center'
                    data: {+tmp}
                    shadowColor: 'black'
                    shadowOffset: [0.5,0.5]
                    shadowBlur: 1



    return handlers
