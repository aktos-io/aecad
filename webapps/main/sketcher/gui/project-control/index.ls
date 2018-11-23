require! '../../tools/lib': {get-aecad, get-parent-aecad}
require! 'prelude-ls': {max}
require! 'aea': {create-download, ext}
require! 'dcs/browser': {SignalBranch}

export init = (pcb) ->
    handlers =
        export: (ctx, _filename) ->
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

            for pcb.project.layers
                for ..getItems({-recursive})
                    {item} = get-parent-aecad ..
                    if item
                        #console.log "Found ae-obj:", item.data.aecad.type
                        get-aecad item
                            ..print-mode layers
                    else if ..data?aecad?layer in layers
                        # TODO: provide a proper way
                        ..stroke-color = \black
                        ..stroke-width = max ..stroke-width, pcb.ractive.get('currTrace.signal')
                    else
                        ..remove!
            err, svg <~ pcb.export-svg {mirror}
            create-download "#{layers.join('_')}.svg", svg
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
            pcb.project.clear!
            PNotify.info do
                text: "Cleared."
                addClass: 'nonblock'

        showHelp: (ctx) ->
            @get \vlog .info do
                template: RACTIVE_PREPARSE('./help/index.pug')
