require! 'paper'
window.paper = paper # required for PaperScope to work correctly
require! 'aea': {create-download, htmlDecode}
require! 'prelude-ls': {min}
require! './lib/dxfToSvg': {dxfToSvg}
require! './lib/svgToKicadPcb': {svgToKicadPcb}
#require! 'svgson'
require! 'svgson-next': svgson
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
require! 'pretty'
require! './tools/lib/selection': {Selection}

Ractive.components['sketcher'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug')
    onrender: ->
        # output container
        canvas = @find '#draw'
        canvas.width = 600
        canvas.height = 400

        # scope
        pcb = paper.setup canvas

        # see https://stackoverflow.com/a/52830469/1952991
        #pcb.view.scaling = 96 / 25.4

        # layers
        layers =
            gui: new pcb.Layer!
            ext: new pcb.Layer!

        for <[ gui scripting import ]>
            @set "project.layers.#{..}", new pcb.Layer!
        @fire \activateLayer, {}, \gui

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
                    pcb.execute js
                catch
                    @set \output, "#{e}\n\n#{js}"

        @observe \editorContent, (_new) ~>
            unless @get \autoCompile => return
            runScript _new

        # workaround for
        @observe \currTool, (tool) ~>
            @fire \changeTool, {}, tool

        @on do
            scriptSelected: (ctx, item, progress) ~>
                @set \editorContent, item.content
                unless item.content
                    @get \project.layers.scripting .clear!
                progress!

            compileScript: (ctx) ~>
                runScript @get \drawingLs

            fitAll: (ctx) !~>
                selection = new Selection
                fit = {}
                for layer in pcb.project.layers
                    selection.add layer, {+select}
                    for item in layer.children
                        for <[ top left ]>
                            if item.bounds[..] < fit[..] or not fit[..]?
                                fit[..] = item.bounds[..]
                        for <[ bottom right ]>
                            if item.bounds[..] > fit[..] or not fit[..]?
                                fit[..] = item.bounds[..]
                console.log "fit bounds: ", fit
                fitRect = new pcb.Rectangle (new pcb.Point fit.left, fit.top), (new pcb.Point fit.right, fit.bottom)
                # set center
                pcb.view.center = fitRect.center

                # set zoom
                curr = pcb.view.bounds
                pcb.view.zoom = 0.8 * min (curr.width / fitRect.width), (curr.height / fitRect.height)

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

            importSVG: (ctx, file, next) ~>
                <~ @fire \activateLayer, ctx, \import
                import-layer = @get \project.layers.import
                    ..clear!
                    ..activate!
                <~ pcb.project.importSVG file.raw
                process-objects = (o) ->
                    if o.hasChildren!
                        for o.children
                            process-objects ..
                    else
                        if project = o.data?project
                            # set the project properties
                            if project.layer
                                layers[project.layer].addChild o

                console.log "svg is imported: ", pcb.project
                #for layer in pcb.project.getItems!
                #    process-objects layer
                next!

            exportSVG: (ctx) ~>
                # VERY IMPORTANT: Might be needed by a bug.
                # changing view.zoom adds <g scale(...) />, so everything
                # is printed scaled
                old-zoom = pcb.view.zoom
                pcb.view.zoom = 1
                _svg = pcb.project.exportSVG {+asString}

                mm2px = (/ 25.4 * 96)
                px2mm = (* 1 / mm2px it)
                transformNode = (node) ->
                    if node.name is \svg
                        attr = node.attributes
                        node.attributes.viewBox = "0 0 #{attr.width} #{attr.height}"
                    if node.attributes["data-paper-data"]
                        node.attributes["data-paper-data"] = htmlDecode that
                    node

                json <~ svgson.parse _svg, {transformNode} .then
                console.log JSON.stringify json, null, 2
                pcb.view.zoom = old-zoom # continue above workaround

                svg = svgson.stringify json |> pretty
                #console.log "SVG format: ", svg

                create-download "project.svg", svg


            exportJSON: (ctx) ~>
                json = pcb.project.exportJSON!
                @set \pjson, json  # for debugging purposes
                create-download "myexport.json", json

            importDXF: (ctx, file, next) ~>
                # FIXME: Splines can not be recognized
                svg = dxfToSvg file.raw
                #paper.project.clear!
                layers.ext
                    ..activate!
                    ..clear!
                pcb.project.importSVG svg
                next!

            importDXF2: (ctx, file, next) ~>
                # FIXME: Implement conversion spline to arc
                parsed = dxf.parseString file.raw
                svg = dxf.toSVG(parsed)
                #paper.project.clear!
                layers.ext
                    ..activate!
                    ..clear!
                pcb.project.importSVG svg
                next!

            exportDXF: (ctx) ~>
                # cleanup me: paper.js already has exportJSON
                svg = pcb.project.exportSVG {+asString}
                res <~ svgson svg, {}
                drawing = new dxf-writer!
                json-to-dxf res, drawing
                dxf-out = drawing.toDxfString!
                create-download "export.dxf", dxf-out

            clearImport: (ctx) ~>
                layers.ext.clear!

            clearScript: (ctx) ~>
                @get \project.layers.scripting .clear!

            exportKicad: (ctx) ~>
                svg = pcb.project.exportSVG {+asString}
                #svgString, title, layer, translationX, translationY, kicadPcbToBeAppended, yAxisInverted)
                try
                    kicad = svgToKicadPcb svg, 'hello', \Edge.Cuts, 0, 0, null, false
                catch
                    return ctx.component.error e.message
                create-download "myexport.kicad_pcb", kicad

            activate-layer: (ctx, name, proceed) ->
                if @get "project.layers.#{name}"
                    that.activate!
                else
                    @set "project.layers.#{name}", new pcb.Layer!
                @set \activeLayer, name
                proceed!

    computed:
        currProps:
            get: ->
                layer = @get('currLayer')
                layer-info = @get('layers')[layer]
                layer-info.name = layer
                layer-info
    data: ->
        autoCompile: yes
        selectAllLayer: yes
        drawingLs: require './example' .script
        layers:
            'F.Cu':
                color: 'red'
            'B.Cu':
                color: 'green'
        project:
            # logical layers
            layers: {}

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
