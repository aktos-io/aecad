require! 'paper'
window.paper = paper # required for PaperScope to work correctly
require! 'aea': {create-download}
require! './lib/dxfToSvg': {dxfToSvg}
require! './lib/svgToKicadPcb': {svgToKicadPcb}
require! 'svgson'
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
        gui = new pcb.Layer!
        script-layer = new pcb.Layer!
        external = new pcb.Layer!


        # zooming
        $ canvas .mousewheel (event) ->
            paperZoom pcb, event

        # tools
        trace-tool = TraceTool.call this, pcb, gui
        freehand = Freehand.call this, pcb, gui
        {move-tool, cache} = MoveTool.call this, pcb, gui

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
                    script-layer
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
                | \mp =>
                    move-tool.activate!
                    canvas.style.cursor = \default
                proceed!

            importSVG: (ctx, file, next) ~>
                #paper.project.clear!
                external
                    ..activate!
                    ..clear!
                <~ pcb.project.importSVG file.raw
                next!

            importDXF: (ctx, file, next) ~>
                # FIXME: Splines can not be recognized
                svg = dxfToSvg file.raw
                #paper.project.clear!
                external
                    ..activate!
                    ..clear!
                pcb.project.importSVG svg
                next!

            importDXF2: (ctx, file, next) ~>
                # FIXME: Implement conversion spline to arc
                parsed = dxf.parseString file.raw
                svg = dxf.toSVG(parsed)
                #paper.project.clear!
                external
                    ..activate!
                    ..clear!
                pcb.project.importSVG svg
                next!

            exportSVG: (ctx) ~>
                svg = paper.project.exportSVG {+asString}
                create-download "myexport.svg", svg

            exportDXF: (ctx) ~>
                svg = paper.project.exportSVG {+asString}
                res <~ svgson svg, {}
                drawing = new dxf-writer!
                json-to-dxf res, drawing
                dxf-out = drawing.toDxfString!
                create-download "export.dxf", dxf-out

            clear: (ctx) ~>
                gui.clear!

            clearImport: (ctx) ~>
                external.clear!

            clearScript: (ctx) ~>
                script-layer.clear!

            exportKicad: (ctx) ~>
                svg = paper.project.exportSVG {+asString}
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
