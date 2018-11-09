require! '../tools/trace-tool': {TraceTool}
require! '../tools/freehand': {Freehand}
require! '../tools/move-tool': {MoveTool}
require! '../tools/select-tool': {SelectTool}
require! '../tools/lib/selection': {Selection}
require! 'prelude-ls': {min}
require! 'dcs/lib/keypath': {set-keypath, get-keypath}
require! '../tools/lib': {getAecad}

export init = (pcb) ->
    # tools
    trace-tool = TraceTool.call this, pcb, (new pcb.Layer)
    freehand = Freehand.call this, pcb, (new pcb.Layer)
    move-tool = MoveTool.call this, pcb, (new pcb.Layer)
    select-tool = SelectTool.call(this)

    # workaround for https://github.com/aktos-io/scada.js/issues/170
    @observe \currTool, (tool) ~>
        @fire \changeTool, {}, tool

    handlers =
        fitAll: (ctx) !~>
            selection = new Selection
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
            proceed?!

        sendTo: (ctx) ->
            pcb.history.commit!
            layer = ctx.component.get \to
            for pcb.selection.selected
                obj = getAecad ..
                if obj
                    obj.set-side layer
                    obj.send-to-layer layer 

                /*
                unless get-keypath .., "data.aecad.name"
                    set-keypath .., 'data.aecad.name', "c_"
                */

        groupSelected: (ctx) ->
            pcb.history.commit!
            g = new pcb.Group pcb.selection.selected
            console.log "Selected items are grouped:", g
            ctx.component.state \done...

    return handlers
