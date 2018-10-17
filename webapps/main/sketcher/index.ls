require! 'paper'
window.paper = paper # required for PaperScope to work correctly
require! 'aea': {create-download, htmlDecode}
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
require! './lib/json-to-dxf': {json-to-dxf}

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
            scripting: new pcb.Layer!
            ext: new pcb.Layer!

        # zooming
        $ canvas .mousewheel (event) ->
            paperZoom pcb, event

        # tools
        trace-tool = TraceTool.call this, pcb, layers.gui
        freehand = Freehand.call this, pcb, layers.gui
        {move-tool, cache} = MoveTool.call this, pcb, layers.gui

        move-tool.on 'mousedrag', (event) ~>
            @set \moving, cache.selected.0
            @set \d, JSON.stringify(cache.selected.0)

        runScript = (content) ~>
            compiled = no
            @set \output, ''
            try
                js = lsc.compile content, {+bare, -header}
                compiled = yes
            catch err
                @set \output, err.to-string!

            if compiled
                try
                    #pcb.project.clear!
                    layers.scripting
                        ..activate!
                        ..clear!
                    pcb.execute js
                catch
                    @set \output, "#{e}\n\n#{js}"

        @observe \drawingLs, (_new) ~>
            unless @get \autoCompile => return
            runScript _new

        @on do
            compileScript: (ctx) ~>
                runScript @get \drawingLs

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
                    canvas.style.cursor = \default # \move
                proceed?!

            importSVG: (ctx, file, next) ~>
                #paper.project.clear!
                layers.ext
                    ..activate!
                    ..clear!
                json <~ pcb.project.importSVG file.raw
                process-objects = (o) ->
                    if o.hasChildren!
                        for o.children
                            process-objects ..
                    else
                        if project = o.data?project
                            # set the project properties
                            if project.layer
                                layers[project.layer].addChild o
                for layer in pcb.project.getItems!
                    process-objects layer
                next!

            exportSVG: (ctx) ~>
                # VERY IMPORTANT: Might be needed by a bug.
                # changing view.zoom adds <g scale(...) />, so everything
                # is printed scaled
                old-zoom = pcb.view.zoom
                pcb.view.zoom = 1
                svg = pcb.project.exportSVG {+asString}

                mm2px = (/ 25.4 * 96)
                px2mm = (* 1 / mm2px it)
                transformNode = (node) ->
                    if node.name is \svg
                        attr = node.attributes
                        node.attributes.viewBox = "0 0 #{attr.width} #{attr.height}"
                    # Do something with entity specific data if needed
                    #if node.attributes["data-paper-data"]
                    #    node.attributes["data-paper-data"] = JSON.parse htmlDecode that
                    #console.log node
                    node

                json <~ svgson.parse svg, {transformNode} .then
                pcb.view.zoom = old-zoom # continue above workaround

                svg2 = svgson.stringify json
                #console.log "JSON format: ", JSON.stringify json
                #console.log "SVG format: ", svg2
                create-download "project.svg", svg2


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

            clear: (ctx) ~>
                layers.gui.clear!

            clearImport: (ctx) ~>
                layers.ext.clear!

            clearScript: (ctx) ~>
                layers.scripting.clear!

            exportKicad: (ctx) ~>
                svg = pcb.project.exportSVG {+asString}
                #svgString, title, layer, translationX, translationY, kicadPcbToBeAppended, yAxisInverted)
                try
                    kicad = svgToKicadPcb svg, 'hello', \Edge.Cuts, 0, 0, null, false
                catch
                    return ctx.component.error e.message
                create-download "myexport.kicad_pcb", kicad

    data: ->
        autoCompile: yes
        selectAllLayer: yes
        drawingLs: require './example' .script
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
