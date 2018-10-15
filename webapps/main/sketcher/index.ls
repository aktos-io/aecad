require! 'paper'
window.paper = paper # required for PaperScope to work correctly
require! 'aea': {create-download}
require! './lib/dxfToSvg': {dxfToSvg}
require! './lib/svgToKicadPcb': {svgToKicadPcb}
require! 'svgson'
require! 'dxf-writer'
require! 'svg-path-parser': {parseSVG:parsePath, makeAbsolute}
require! 'dxf'
require! 'livescript': lsc
require('jquery-mousewheel')($);
require! './zooming': {paperZoom}
require! './tools/trace-tool': {TraceTool}
require! './tools/freehand': {Freehand}
require! './tools/move-tool': {MoveTool}
require! './lib/json-to-dxf': {json-to-dxf}

help = """
    Trace:
        Esc: break last segment
        Drag: pan pcb
    """

Ractive.components['sketcher'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug')
    onrender: ->
        # output container
        canvas = @find '#draw'
        canvas.width = 600
        canvas.height = 400

        # scope
        pcb = paper.setup canvas

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
        move-tool = MoveTool.call this, pcb, gui

        @observe \drawingLs, (_new) ~>
            compiled = no
            @set \output, ''
            try
                js = lsc.compile _new, {+bare, -header}
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

        @on do
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
                #paper.project.clear!

            exportKicad: (ctx) ~>
                svg = paper.project.exportSVG {+asString}
                #svgString, title, layer, translationX, translationY, kicadPcbToBeAppended, yAxisInverted)
                try
                    kicad = svgToKicadPcb svg, 'hello', \Edge.Cuts, 0, 0, null, false
                catch
                    return ctx.component.error e.message
                create-download "myexport.kicad_pcb", kicad

    data: ->
        drawingLs: '''
            pad = (point=new Point(10, 10), size=new Size(20,20)) ->
                p = new Rectangle point, size
                pad = new Path.Rectangle p
                pad.fillColor = 'black'
                pad

            mm2px = ( / 25.4 * 96)

            P = (x, y) -> new Point (x |> mm2px), (y |> mm2px)
            S = (a, b) -> new Size (a |> mm2px), (b |> mm2px)

            do ->
                p1 = pad P(4mm, 2mm), S(2mm, 4mm)
                pad P(p1.bounds.left, p1.bounds.bottom + (5 |> mm2px))
            '''

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

        help: help
