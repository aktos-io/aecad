require! 'aea': {create-download}
require! '../../tools/lib/trace/lib': {is-on-layer}
require! '../../tools/lib': {get-aecad, get-parent-aecad}
require! 'prelude-ls': {max}


export init = (pcb) ->

    handlers =
        import: require './import' .import_
        export: require './export' .export_

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
