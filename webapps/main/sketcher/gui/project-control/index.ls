require! 'aea': {create-download}
require! '../../tools/lib/trace/lib': {is-on-layer}

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
                template: RACTIVE_PREPARSE('./help.pug')
