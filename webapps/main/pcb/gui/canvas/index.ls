require! '../../tools/trace-tool': {TraceTool}
require! '../../tools/freehand': {Freehand}
require! '../../tools/move-tool': {MoveTool}
require! '../../tools/line-tool': {LineTool}
require! '../../tools/select-tool': {SelectTool}
require! '../../tools/lib/selection': {Selection}
require! 'prelude-ls': {min, empty, abs, keys, unique-by}
require! 'dcs/lib/keypath': {set-keypath, get-keypath}
require! '../../tools/lib': {getAecad, Edge}
require! 'aea/do-math': {px2mm}
require! 'aea': {merge}
require! '../../tools/lib/schema/schema-manager': {SchemaManager}

format = (x) ->
    "#{oneDecimal (x |> px2mm), 2} mm"

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
        
    move-selection = (override={}) -> 
        bounds = pcb.ractive.get \lastBounds
        if bounds and not empty selection.selected
            pcb.history.commit!

            # test if this is a complex selection
            # FIXME: multiple formats in selection "[ITEM] or [{item: ITEM, aeobj, ...}]"
            # adds unnecessary complexity 
            delta = bounds.center.subtract selection.bounds!.center
            d = displacement = delta `merge` override
            console.log "Moving source by #{d.x |> format}mm, #{d.y |> format}mm"
            for selection.get-as-aeobj!
                console.log "...moving aeobj:", ..
                ..move displacement
        else
            PNotify.notice text: "Not possible."


    handlers =
        upgradeComponents: (ctx) ->
            upgrade-count = 0
            unless sch=(schema-manager.active)
                PNotify.notice text: "No active schema found, can not upgrade."
                return
            unless empty upgrades=(sch.get-upgrades!)
                for upg in upgrades
                    for sel in selection.selected when upg.component.name is sel.aeobj.owner.name
                        try 
                            upg.component.upgrade {type: upg.type, value: upg.value}
                            upgrade-count++
                        catch 
                            PNotify.error do 
                                text: "Error upgrading components: #{e}"
                                hide: no
            selection.clear!
            PNotify.info text: "Upgraded #{upgrade-count} component(s)."

        refreshLayer: (ctx, proceed) ->
            curr-side = @get \currLayer
            traces-on-far-side = []
            components = pcb.get-components!

            for components when ..type isnt \Trace
                if ..item.data.aecad.side isnt curr-side
                    ..item.send-to-back!

            for components when ..type is \Trace
                # Send all traces to the back so that drill holes can be exposed
                # correctly
                ..item.send-to-back!
                trace-layer = ..item.parent
                trace-layer.send-to-back!

                # TODO: Fix trace z-index correction here.
                # ------------------------------------------
                # NOTICE: A design change is required: Since a Trace component may
                # include trace paths for both sides, no proper action can be taken at
                # this point of design.
                # In order to fix this, a trace must consist of separate components
                # so that we could send "far-side-components" (the components that doesn't)
                # belong to current side.
                #
                # However, we can do our best by sending any trace which includes
                # the other side's path to the back
                for path in ..item.children when path.side isnt curr-side
                    traces-on-far-side.push ..item

            for traces-on-far-side
                #console.log "Sending trace to back: ", ..data.aecad, ..
                ..send-to-back!

            proceed?!

        switchLayer: (ctx, layer, proceed) ->
            @set \currLayer, layer
            for pcb.get-components!
                try
                    get-aecad ..item ?.trigger \focus, layer
                catch
                    console.error "Something went wrong here.", e

            <~ @fire \refreshLayer, {}
            proceed?!

        calcUnconnected: (ctx, opts={}) ->
            console.log "------------ Performing DRC (opts: #{JSON.stringify opts}) ------------"
            if sch=schema-manager.active
                try
                    unless opts.cached 
                        sch.calc-connection-states!
                    conn-states = sch._connection_states 
                    sch.clear-guides!
                    unconnected-nets = sch.get-unconnected-pads {+cached}
                    if empty selection.selected
                        sch.guide-for null, unconnected-nets
                    else 
                        selection-object-ids = selection.get-as-aeobj!.map (.gcid)

                        selected-unconnected-nets = []
                        for net in unconnected-nets 
                            pads-in-selection = []
                            for pad in net when pad.owner.gcid in selection-object-ids
                                pads-in-selection.push pad 
                            unless empty pads-in-selection
                                # filter out too many guides, probably for gnd and vcc connections 
                                connection-guide-extra-pads-limit = 2
                                for pad in net when pad.gcid not in pads-in-selection.map((.gcid))
                                    pads-in-selection.push pad 
                                    if pads-in-selection.length >= connection-guide-extra-pads-limit
                                        break
                                selected-unconnected-nets.push pads-in-selection
                        # calculated pads in selection. 
                        sch.guide-for null, selected-unconnected-nets



                catch
                    PNotify.error text: e.message
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

                pcb.ractive.fire \refreshLayer

            else if not opts.silent
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

        sendTo: (ctx) !->
            pcb.history.commit!
            layer = ctx.component.get \to
            aeobjs = []
            for selected in pcb.selection.selected
                console.log "sending selected: ", selected, "to: ", layer
                aeobj = selected.aeobj
                try
                    if aeobj
                        aeobjs.push aeobj.owner
                    else                    
                        aeobj = get-aecad selected .owner
                        aeobjs.push aeobj unless aeobj.gcid in [..gcid for aeobjs]

                unless aeobj 
                    # convert the selected items into Edge aeobj
                    edge = new Edge
                        ..import selected
                    aeobjs.push edge 

            for aeobj in aeobjs
                aeobj.set-side layer
                if layer isnt \Edge
                    aeobj.send-to-layer 'gui' # TODO: find a more beautiful name

        groupSelected: (ctx) ->
            PNotify.info text: "Grouping is WIP ATM. UX should be decided."
            return 
            pcb.history.commit!
            g = new pcb.Group pcb.selection.get-as-aeobj().map((.g))
            console.log "Selected items are grouped:", g

        explode: (ctx) ->
            # Ungroup may be done by this: https://groups.google.com/g/paperjs/c/DOf1vxTfM50/m/ya0BKSDGswsJ

        saveBounds: (ctx) ->
            if empty selection.selected
                bounds = pcb.ractive.get \lastBounds
                PNotify.notice do
                    text: "No selection found (last saved coordinates are intact)."
                    addClass: 'nonblock'
                pcb.vertex-marker bounds.center
                return

            bounds = selection.bounds!
            pcb.ractive.set \lastBounds, bounds
            #console.log "last bounds: ", bounds
            selection.clear!
            pcb.vertex-marker bounds.center
            PNotify.info do
                text: "Saved last bounds: (x:#{bounds.center.x |> oneDecimal}, y:#{bounds.center.y |> oneDecimal})"
                addClass: 'nonblock'

        moveToCenter: (ctx) ->
            move-selection!

        alignVertical: (ctx) -> 
            move-selection {y: 0}

        alignHorizontal: (ctx) -> 
            move-selection {x: 0}
            
        measureDistance: (ctx) ->
            bounds = pcb.ractive.get \lastBounds

            if not bounds or empty selection.selected 
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


        selectComponent: (ctx, item, proceed) -> 
            if item.id 
                for pcb.get-components! when ..?name is item.id
                    pcb.selection.add {item: ..item}
                    break
            proceed!

        switchLayout: (ctx, item, proceed) -> 
            if item.id
                if that isnt pcb.active-layout
                    pcb.switchLayout item.id 
                    #ctx.ractive.fire 'fitAll' # <- this brings an overhead while performing download pre-processes
            proceed!

        addLayout: (ctx, newKey, proceed) ->
            # newKey is the search term
            btn = ctx.button  # ack-button instance
            pcb.switchLayout newKey
            pcb.layouts[newKey]?.type = "manual"
            btn.state \done...
            proceed!

        selectStrayComponents: (ctx) -> 
            canvas-components = pcb.get-components {exclude: <[ Trace Edge RefCross ]>} 
            if schema-manager.active?.components-by-name
                schema-components = Object.keys that
            else 
                return PNotify.notice text: "No schema components found. Did you compile your schema?"

            selected-any-comp = no 
            for canvas-components when ..name not in schema-components
                pcb.selection.add {item: ..item}
                selected-any-comp = yes

            unless selected-any-comp
                PNotify.info text: "No stray components found." 


    return handlers
