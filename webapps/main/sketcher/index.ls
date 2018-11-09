require! 'paper'
window.paper = paper # required for PaperScope to work correctly
require! 'aea': {VLogger}
require('jquery-mousewheel')($);
require! './zooming': {paperZoom}
require! './kernel': {PaperDraw}
require! './example'

Ractive.components['sketcher'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug')
    onrender: (ctx) ->
        # output container
        canvas = @find '#draw'

        # scope
        pcb = new PaperDraw do
            ractive: this
            canvas: canvas
            background: '#252525'
            height: 400

        @set \pcb, pcb

        # Visual Logger client
        @set \vlog, new VLogger this

        # Initial layers
        pcb.add-layer \scripting
        pcb.use-layer \gui

        # zooming
        $ canvas .mousewheel (event) ~>
            paperZoom pcb, event
            @update \pcb.view.zoom

        _handlers =
            require './gui/scripting' .init.call this, pcb
            require './gui/canvas' .init.call this, pcb
            require './gui/project-control' .init.call this, pcb

        handlers = {}
        for part in _handlers
            handlers <<< part

        @on handlers

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
                # appears both sides
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
