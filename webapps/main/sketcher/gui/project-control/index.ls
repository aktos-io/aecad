require! '../../tools/lib': {get-aecad, get-parent-aecad}
require! 'prelude-ls': {max}
require! 'aea': {create-download, ext}
require! 'dcs/browser': {SignalBranch}
require! 'jszip'


export init = (pcb) ->
    prototypePrint = (opts, callback) !->
        pcb.history.commit!

        # layers to print
        layers = opts.side.split ',' .map (.trim!)
        mirror = opts.mirror 
        scale = opts.scale
        trace-color = opts.trace-color

        aeitems = []
        for pcb.project.layers
            for ..getItems({-recursive})
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
        pcb.history.back!
        callback err, svg


    handlers =
        exportDrawing: (ctx) -> 
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
            filename = data.filename
            files = []
            format = filename |> ext
            PNotify.info text: "Preparing #{filename}..."
            <~ sleep 100ms 
            err, res <~ pcb.export {format}
            if err
                PNotify.error text: err
                return 
            create-download filename, res

        downloadProject: (ctx, project-name) ->
            files = []
            format = "json"
            output-name = "#{project-name}.zip"

            unless project-name
                pcb.vlog .error do
                    message: "You should supply a project name."
                return 

            dirty-confirm = new SignalBranch
            if __DEPENDENCIES__.root.dirty
                _sd = dirty-confirm.add!
                answer <~ pcb.vlog .info do
                    title: "Dirty state of aeCAD"
                    icon: 'warning sign'
                    message: "
                        Project root has uncommitted changes. Saving project with a dirty state of aeCAD may result failure to identify the correct aeCAD version for the project file in the future.
                        \n\n
                        You should really commit your changes and then save your project.
                        "
                if answer is \ok
                    _sd.go!
                else
                    _sd.cancel! 
                    PNotify.notice text: "Cancelled download."
            <~ dirty-confirm.joined
            PNotify.info text: "Preparing #{output-name}..."
            <~ sleep 100ms 
            err, res <~ pcb.export {format}
            unless err
                files.push ["pcb.#{format}", res]
            else
                PNotify.error text: err
                return 

            # compile once before generating current svg outputs.
            pcb.ractive.fire \compileScript

            # Fabrication
            fabrication = "2_Fabrication"
            err, res <~ prototypePrint {side: "F.Cu, Edge", +mirror}
            unless err 
                filename = "#{fabrication}_F.Cu.svg"
                files.push [filename, res]
            else 
                PNotify.error text: err
                return 

            err, res <~ prototypePrint {side: "B.Cu, Edge"}
            unless err 
                filename = "#{fabrication}_B.Cu.svg"
                files.push [filename, res]
            else 
                PNotify.error text: err
                return 

            # Empty file to invalidate the manually reduced fabrication file
            files.push ["#{fabrication}_merged.svg", ""]


            # Testing
            testing = "1_Testing"
            err, res <~ prototypePrint {side: "F.Cu, Edge"}
            unless err 
                filename = "#{testing}_F.Cu.svg"
                files.push [filename, res]
            else 
                PNotify.error text: err
                return 

            err, res <~ prototypePrint {side: "B.Cu, Edge", +mirror}
            unless err 
                filename = "#{testing}_B.Cu.svg"
                files.push [filename, res]
            else 
                PNotify.error text: err
                return 

            <~ set-immediate
            # Front Assembly
            assembly = "3_Assembly"
            err, res <~ prototypePrint {side: "F.Cu, Edge", scale: 2, trace-color: "lightgray"}
            unless err 
                filename = "#{assembly}_Front.svg"
                files.push [filename, res]
            else 
                PNotify.error text: err
                return 

            <~ set-immediate
            # Back Assembly
            err, res <~ prototypePrint {side: "B.Cu, Edge", scale: 2, trace-color: "lightgray", +mirror}
            unless err 
                filename = "#{assembly}_Back.svg"
                files.push [filename, res]
            else 
                PNotify.error text: err
                return 

            <~ set-immediate
            # Get scripts 
            scripts = pcb.ractive.get \drawingLs
            content = CSON.stringify(scripts, null, 2)
            # workaround: we are not able to include JSON (or CSON) files with Browserify
            # directly require by:
            # require! './path/to/scripts'
            # console.log scripts
            files.push ["scripts.ls", "export {\n#{content}\n}"]

            # README 
            files.push ["README.md", JSON.stringify __DEPENDENCIES__]

            # create a zip file 
            zip = new jszip! 
            for [name, content] in files 
                zip.file name, content 

            content <~ zip.generateAsync({type: "blob"}).then
            create-download output-name, content
    
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
