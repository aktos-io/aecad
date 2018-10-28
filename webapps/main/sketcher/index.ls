require! 'paper'
window.paper = paper # required for PaperScope to work correctly
require! 'aea': {create-download, VLogger}
require! 'prelude-ls': {min, ceiling, flatten, max}
require! './lib/svgToKicadPcb': {svgToKicadPcb}
require! 'dxf-writer'
require! 'dxf'
require! 'livescript': lsc
require('jquery-mousewheel')($);
require! './zooming': {paperZoom}
require! './tools/trace-tool': {TraceTool}
require! './tools/freehand': {Freehand}
require! './tools/move-tool': {MoveTool}
require! './tools/select-tool': {SelectTool}
require! './lib/json-to-dxf': {json-to-dxf}
require! './tools/lib/selection': {Selection}
require! './kernel': {PaperDraw}
require! './tools/lib/trace/lib': {is-on-layer}

mm2px = (/ 25.4 * 96)
px2mm = (* 1 / mm2px it)


Ractive.components['sketcher'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug')
    onrender: (ctx) ->
        # output container
        canvas = @find '#draw'
            ..style.background = '#252525'

        do resizeCanvas = ->
            container = $ canvas.parentNode
            pl = parse-int container.css("padding-left")
            pr = parse-int container.css("padding-right")
            width = container.innerWidth! - pr - pl
            height = container.innerHeight!
            canvas.width = width
            canvas.height = 400

        window.addEventListener('resize', resizeCanvas, false);

        # scope
        pcb = new PaperDraw do
            scope: paper.setup canvas
            ractive: this
            canvas: canvas

        @set \pcb, pcb

        # see https://stackoverflow.com/a/52830469/1952991
        #pcb.view.scaling = 96 / 25.4

        # layers
        layers =
            gui: new pcb.Layer!

        @set \vlog, new VLogger this

        pcb.add-layer \scripting
        pcb.use-layer \gui

        # zooming
        $ canvas .mousewheel (event) ~>
            paperZoom pcb, event
            @update \pcb.view.zoom

        # tools
        trace-tool = TraceTool.call this, pcb, layers.gui, canvas
        freehand = Freehand.call this, pcb, layers.gui, canvas
        move-tool = MoveTool.call this, pcb, layers.gui, canvas
        select-tool = SelectTool.call(this)

        runScript = (content) ~>
            compiled = no
            @set \output, ''
            try
                if content and typeof! content isnt \String
                    throw new Error "Content is not string!"
                js = lsc.compile content, {+bare, -header}
                compiled = yes
            catch err
                @set \output, "Compile error: #{err.to-string!}"
                console.error "Compile error: #{err.to-string!}"

            if compiled
                try
                    @get \project.layers.scripting
                        ..activate!
                        ..clear!
                    pcb._scope.execute js
                catch
                    @set \output, "#{e}\n\n#{js}"

        @observe \editorContent, (_new) ~>
            unless @get \autoCompile => return
            runScript _new

        # workaround for
        @observe \currTool, (tool) ~>
            @fire \changeTool, {}, tool

        calc-bounds = (scope) ->
            items = flatten [..getItems! for scope.project.layers]
            bounds = items.reduce ((bbox, item) ->
                unless bbox => item.bounds else bbox.unite item.bounds
                ), null
            console.log "found items: ", items.length, "bounds: #{bounds?.width}, #{bounds?.height}"
            return bounds

        @on do
            scriptSelected: (ctx, item, progress) ~>
                @set \editorContent, item.content
                unless item.content
                    @get \project.layers.scripting .clear!
                progress!

            compileScript: (ctx) ~>
                runScript @get \editorContent

            fitAll: (ctx) !~>
                selection = new Selection
                for layer in pcb.project.layers
                    selection.add layer, {+select}
                #console.log "fit bounds: ", fit
                fit = calc-bounds pcb
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
                    canvas.style.cursor = \cell
                | \fh =>
                    freehand.activate!
                    canvas.style.cursor = \default
                | \mv =>
                    move-tool.activate!
                    canvas.style.cursor = \default
                | \sl =>
                    select-tool.activate!
                    canvas.style.cursor = \default
                proceed?!

            import: require './handlers/import' .import_
            export: require './handlers/export' .export_

            clearActiveLayer: (ctx) ~>
                @get \project.layers .[@get 'activeLayer'] .clear!

            clearScript: (ctx) ~>
                @get \project.layers.scripting .clear!

            activate-layer: (ctx, name, proceed) ->
                pcb.use-layer name
                proceed!

            sendTo: (ctx) ->
                pcb.history.commit!
                layer = ctx.component.get \to
                color = @get \layers .[layer] .color
                for pcb.selection.selected
                    ..fill-color = color
                    ..stroke-color = color
                    .. `pcb.send-to-layer` layer

            undo: (ctx) ->
                pcb.history.back!

            groupSelected: (ctx) ->
                pcb.history.commit!
                new pcb.Group [.. for pcb.get-flatten! when ..selected]

            prototypePrint: (ctx) ->
                pcb.history.commit!
                layer = ctx.component.get \side
                for pcb.get-all!
                    if .. `is-on-layer` layer
                        ..visible = true

                        # a workaround for drills
                        unless ..data?aecad?type is \drill
                            ..stroke-color = \black
                            if ..data?aecad?tid and ..data?aecad?type not in <[ drill via ]>
                                # do not fill the lines
                                null
                            else
                                ..fill-color = \black
                        else
                            ..stroke-color = null
                            ..fill-color = \white
                            ..bringToFront!

                    else
                        ..visible = false

                create-download "#{layer}.svg", pcb.export-svg!
                pcb.history.back!

            save: (ctx) ->
                # save project
                pcb.history.commit!
                pcb.history.save!

            load: (ctx) ->
                pcb.history.commit!
                pcb.history.load!

            clear: (ctx) ->
                pcb.history.commit!
                pcb.project.clear!

    computed:
        currProps:
            get: ->
                layer = @get('currLayer')
                layer-info = @get('layers')[layer]
                layer-info.name = layer
                layer-info
    data: ->
        autoCompile: yes
        selectAllLayer: no
        selectGroup: yes
        drawingLs: require './example' .script
        layers:
            'F.Cu':
                color: 'red'
            'B.Cu':
                color: 'green'
            'Edge':
                color: 'orange'
        project:
            # logical layers
            layers: {}
            name: 'Project'

        activeLayer: 'gui'
        currLayer: 'F.Cu'
        currTrace:
            width: 3
        kicadLayers:
            \F.Cu
            \B.Cu
            \B.Adhes
            \F.Adhes
            \B.Paste
            \F.Paste
            \B.SilkS
            \F.SilkS
            \B.Mask
            \F.Mask
            \Dwgs.User
            \Cmts.User
            \Eco1.User
            \Eco2.User
            \Edge.Cuts
