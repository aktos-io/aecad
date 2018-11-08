require! 'aea': {create-download}
require! '../../tools/lib/trace/lib': {is-on-layer}
require! '../../tools/lib': {getAecad}

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

        prototypePrint: (ctx) ->
            pcb.history.commit!
            layers = ctx.component.get \side .split ',' .map (.trim!)
            for pcb.get-all!
                obj = try getAecad ..
                unless obj
                    ..remove!
                else
                    obj.print-mode layers
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
                template: RACTIVE_PREPARSE('./help.pug')
