require! 'aea': {VLogger, hash}
require! './kernel': {PaperDraw}

Ractive.components['pcb'] = Ractive.extend do
    template: require('./index.pug')
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

        _handlers =
            require './gui/scripting' .init.call this, pcb
            require './gui/canvas' .init.call this, pcb
            require './gui/project-control' .init.call this, pcb
            require './gui/tree-view' .init.call this, pcb

        handlers = {}
        for part in _handlers
            handlers <<< part

        @on handlers
        pcb.view.center = [0,0]
        @fire 'fitAll'

        @fire 'runTests'

    computed:
        currProps:
            get: ->
                layer = @get('currLayer')
                layer-info = @get('layers')[layer]
                layer-info.name = layer
                layer-info

        activeLayout: 
            get: -> 
                @get \pcb .active-layout 

        layouts: 
            get: -> 
                @get \pcb .layouts |> Object.keys 

    data: ->
        autoCompile: no
        selectAllLayer: no
        selectGroup: yes
        drawingLs: {}
        scriptName: ''
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
