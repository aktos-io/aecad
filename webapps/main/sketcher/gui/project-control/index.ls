require! 'aea': {create-download}
require! '../../tools/lib/trace/lib': {is-on-layer}
require! '../../tools/lib': {get-aecad, get-parent-aecad}

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

        prototypePrint: (ctx) !->
            pcb.history.commit!

            # layers to print
            layers = ctx.component.get \side .split ',' .map (.trim!)

            for pcb.project.layers
                for ..getItems({-recursive})
                    {item} = get-parent-aecad ..
                    unless item
                        ..remove!
                    else
                        #console.log "Found ae-obj:", item.data.aecad.type
                        get-aecad item
                            ..print-mode layers

            create-download "#{layers.join('_')}.svg", pcb.export-svg!
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
                template: RACTIVE_PREPARSE('./help/index.pug')
