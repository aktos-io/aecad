require! 'paper'
window.paper = paper # required for PaperScope to work correctly
require! 'aea': {create-download, VLogger}
require! 'prelude-ls': {min, ceiling, flatten}
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

mm2px = (/ 25.4 * 96)
px2mm = (* 1 / mm2px it)


Ractive.components['sketcher'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug')
    onrender: (ctx) ->
        # output container
        canvas = @find '#draw'
        canvas.width = 600
        canvas.height = 400

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
        $ canvas .mousewheel (event) ->
            paperZoom pcb, event

        # tools
        trace-tool = TraceTool.call this, pcb, layers.gui, canvas
        freehand = Freehand.call this, pcb, layers.gui, canvas
        move-tool = MoveTool.call this, pcb, layers.gui, canvas
        select-tool = SelectTool.call this, pcb, layers.gui, canvas

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
                    .. `pcb.send-to-layer` layer

            undo: (ctx) ->
                pcb.history.back!
                ctx.component.state \done...

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
