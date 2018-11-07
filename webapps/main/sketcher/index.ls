require! 'paper'
window.paper = paper # required for PaperScope to work correctly
require! 'aea': {create-download, VLogger}
require! 'prelude-ls': {min, ceiling, flatten, max, keys, values}
require! './lib/svgToKicadPcb': {svgToKicadPcb}
require('jquery-mousewheel')($);
require! './zooming': {paperZoom}
require! './tools/lib/selection': {Selection}
require! './kernel': {PaperDraw}
require! './tools/lib/trace/lib': {is-on-layer}
require! './example'
require! 'dcs/browser': {FpsExec}

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

        @set \vlog, new VLogger this

        pcb.add-layer \scripting
        pcb.use-layer \gui

        # zooming
        $ canvas .mousewheel (event) ~>
            paperZoom pcb, event
            @update \pcb.view.zoom


        handlers =
            scripting: (require './gui/scripting').init.call this, pcb
            canvas: (require './gui/canvas').init.call this, pcb

        @on handlers.scripting <<< handlers.canvas <<< do

            import: require './handlers/import' .import_
            export: require './handlers/export' .export_

            clearActiveLayer: (ctx) ~>
                @get \project.layers .[@get 'activeLayer'] .clear!

            activate-layer: (ctx, name, proceed) ->
                pcb.use-layer name
                proceed!


            undo: (ctx) ->
                pcb.history.back!

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

            showHelp: (ctx) ->
                @get \vlog .info do
                    template: RACTIVE_PREPARSE('gui/help.pug')

    computed:
        currProps:
            get: ->
                layer = @get('currLayer')
                layer-info = @get('layers')[layer]
                layer-info.name = layer
                layer-info
    data: ->
        autoCompile: no
        selectAllLayer: no
        selectGroup: yes
        drawingLs: example.scripts
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
            width: 0.2mm # default width, temporary
            clearance: 0.2mm
            power: 0.4mm
            signal: 0.2mm
            via:
                outer: 1.5mm
                inner: 0.5mm
        pointer: # mouse pointer coordinates
            x: 0
            y: 0
