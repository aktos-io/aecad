require! '../../tools/lib': {get-aecad, get-parent-aecad}
require! 'prelude-ls': {max}
require! 'aea': {create-download, ext}
require! 'dcs/browser': {SignalBranch}

export init = (pcb) ->
    handlers =
        export: (ctx, _filename) ->
            dirty-confirm = new SignalBranch
            if __DEPENDENCIES__.root.dirty
                _sd = dirty-confirm.add!
                <~ pcb.vlog .info do
                    title: "Dirty state of aeCAD"
                    icon: 'warning sign'
                    message: "
                        Project root has uncommitted changes. Saving project with a dirty state of aeCAD may result failure to identify the correct aeCAD version for the project file in the future.
                        \n\n
                        You should really commit your changes and then save your project.
                        "
                _sd.go!
            <~ dirty-confirm.joined

            b = new SignalBranch
            filename = null
            if _filename
                filename = _filename
            else
                s = b.add!
                action, data <~ pcb.vlog .yesno do
                    title: 'Filename'
                    icon: ''
                    closable: yes
                    template: RACTIVE_PREPARSE('./export-dialog.pug')
                    buttons:
                        save:
                            text: 'Save'
                            color: \green
                        cancel:
                            text: \Cancel
                            color: \gray
                            icon: \remove

                if action in [\hidden, \cancel]
                    console.log "Cancelled."
                    b.cancel!
                    return
                filename := data.filename
                s.go!
            <~ b.joined
            format = filename |> ext
            err, res <~ pcb.export {format}
            unless err
                create-download filename, res
            else
                PNotify.error text: err

        import: (ctx, file, next) ->
            # Create a layer with file name and send the contents into this layer
            <~ @fire \activateLayer, ctx, file.basename
            for pcb.project.layers
                switch ..name
                | file.basename, null => ..clear!
            err <~ pcb.import file.raw, do
                format: file.ext.to-lower-case!
                name: file.basename
            next err

        clearActiveLayer: (ctx) ~>
            @get \project.layers .[@get 'activeLayer'] .clear!

        activate-layer: (ctx, name, proceed) ->
            pcb.use-layer name
            proceed!

        undo: (ctx) ->
            pcb.history.back!
            PNotify.info do
                text: "Changes reverted."
                addClass: 'nonblock'

        prototypePrint: (ctx) !->
            pcb.history.commit!

            # layers to print
            layers = ctx.component.get \side .split ',' .map (.trim!)
            mirror = ctx.component.get \mirror
            scale = ctx.component.get \scale
            trace-color = ctx.component.get \trace-color

            aeitems = []
            for pcb.project.layers
                for ..getItems({-recursive})
                    try
                        {item} = get-parent-aecad ..
                    catch
                        # Probably the component is declared within the actual app script.
                        # Try to compile and try again
                        pcb.ractive.fire \compileScript
                        try
                            {item} = get-parent-aecad ..
                        catch
                            pcb.vlog .error message: e
                            pcb.history.back!
                            return
                    if item
                        #console.log "Found ae-obj:", item.data.aecad.type, "name: ", item.data.aecad.name
                        o = get-aecad item
                            ..print-mode {layers, trace-color}
                        aeitems.push o
                    else
                        ..remove!

            for aeitems when ..type is \Trace
                ..g.send-to-back!

            err, svg <~ pcb.export-svg {mirror, scale}
            filename = if ctx.component.get \filename
                that
            else
                "#{layers.join('_')}"

            create-download "#{filename}.svg", svg
            pcb.history.back!

        save: (ctx) ->
            # save project
            #pcb.history.commit! ### No need to bloat the history
            pcb.history.save!
            PNotify.info do
                text: "Saved #{Date!}"
                addClass: 'nonblock'

        clear: (ctx) ->
            pcb.history.commit!
            pcb.clear-canvas!
            PNotify.info do
                text: "Project cleared."
                addClass: 'nonblock'

        showHelp: (ctx) ->
            @get \vlog .info do
                template: RACTIVE_PREPARSE('./help/index.pug')
