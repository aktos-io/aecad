require! '../../tools/lib': {get-aecad, get-parent-aecad}
require! 'prelude-ls': {max, sort, join}
require! 'aea': {create-download, ext}
require! 'dcs/browser': {SignalBranch}
require! 'jszip'
require! '../../kernel/gerber-plotter': {GerberReducer}
require! '../../tools/lib/schema/tests': {schema-tests}
require! '../../tools/lib/schema/schema-manager': {SchemaManager}

require! 'sha.js': shajs
 
class GenMultiFingerprint
    @hash = (input) -> 
        sha = shajs \sha256
        sha.update input, 'utf-8' .digest \hex .substring 0, 8

    -> 
        @checksums = []

    add: (content) -> 
        @checksums.push @@hash content

    get: -> 
        @checksums 
            |> sort 
            |> join '\n' 
            |> @@hash 


export init = (pcb) ->
    prototypePrint = (opts, callback) !->
        pcb.history.commit!

        # layers to print
        layers = opts.side.split ',' .map (.trim!)
        mirror = opts.mirror 
        scale = opts.scale
        trace-color = opts.trace-color
        border-color = opts.border-color

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
                        ..print-mode {layers, trace-color, border-color}
                    aeitems.push o
                else
                    ..remove!

        for aeitems when ..type is \Trace
            ..g.send-to-back!

        err, svg <~ pcb.export-svg {mirror, scale}
        pcb.history.back!
        callback err, svg


    handlers =
        runTests: (ctx, callback) -> 
            schema-tests (err) ->
                unless err
                    PNotify.success text: "All schema tests are passed."
                else
                    PNotify.error hide: no, text: """
                        Failed Schema test: #{err.test-name}

                        #{err.message or 'Check console'}
                        """
                    console.error err

                if typeof! callback is \Function 
                    callback err 
           
        exportDrawing: (ctx) -> 
            action, data <~ pcb.vlog .yesno do
                title: 'Filename'
                icon: ''
                closable: yes
                template: require('./export-dialog.pug')
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
            unless project-name
                pcb.vlog .error do
                    message: "You should supply a project name."
                return 

            dirty-confirm = new SignalBranch
            if require('app-version.json').dirty
                _sd = dirty-confirm.add!
                answer <~ pcb.vlog .info do
                    title: "Dirty state of aeCAD"
                    icon: 'warning sign'
                    message: "
                        aeCAD has uncommitted changes. 
                        \n\n
                        If your project depends on a new feature, you can't compile the same project 
                        in the future by using the version information embedded into the project's README.
                        "
                if answer is \ok
                    _sd.go!
                else
                    _sd.cancel! 
                    PNotify.notice text: "Cancelled download."
            <~ dirty-confirm.joined


            PNotify.info text: "Preparing project file of #{project-name}..."
            <~ sleep 100ms 

            # create a zip file 
            zip = new jszip! 

            # Filename map 
            filename-map = f = 
                v1:
                    "layout": "layout.json"
                    "scriptName": "script-name"
                    "bom": "BOM.txt"
                    "type": "type"

            # Save scripts 
            scripts = zip.folder "scripts"
            for name, content of (pcb.ractive.get \drawingLs)
                scripts.file "#{name}.ls", content

            # README 
            zip.file "README.md", JSON.stringify require('app-version.json')

            layouts-dir = zip.folder "layouts"    
            layouts = Object.keys pcb.layouts 
            current-layout = pcb.active-layout 
            <~ :lo(op) ~> 
                while true
                    return op! if layouts.length is 0 
                    layout = layouts.shift!
                    if pcb.layouts[layout].scriptName
                        scriptName = that 
                        if scriptName of pcb.ractive.get('drawingLs')
                            break 
                        else
                            console.log "Skipping layout: No script named \"#{scriptName}\" can be found."
                    else 
                        console.log "Skipping layout: #{layout} has no scriptName."

                # Switch to appropriate layout 
                pcb.switch-layout layout 

                layout-dir = layouts-dir.folder layout 

                for key in <[ bom scriptName type ]> 
                    if pcb.layouts[layout][key]
                        layout-dir.file f.v1[key], that

                format = "json"
                err, res <~ pcb.export {format}
                unless err
                    layout-dir.file f.v1.layout, res
                else
                    PNotify.error text: err
                    return 

                # Fabrication
                fabrication = "2_Fabrication"
                err, res <~ prototypePrint {side: "F.Cu, Edge", +mirror}
                unless err
                    layout-dir.file "#{fabrication}_F.Cu.svg", res
                else 
                    PNotify.error text: err
                    return 

                err, res <~ prototypePrint {side: "B.Cu, Edge"}
                unless err 
                    layout-dir.file "#{fabrication}_B.Cu.svg", res
                else 
                    PNotify.error text: err
                    return 

                # Empty file to invalidate the manually reduced fabrication file
                layout-dir.file "#{fabrication}_merged.svg", """
                    <?xml version="1.0" encoding="UTF-8" standalone="no"?>
                    <svg
                       viewBox="0 0 210 297"
                       height="297mm"
                       width="210mm">
                    </svg>
                    """

                # Generate Gerbv project files for more visual inspection
                # Usage: gerbv -p file.gvp
                gen-gvp = (layers={}) -> 
                    '''
                    (gerbv-file-version! "2.0A")
                    (define-layer! 5 (cons 'filename "gerber/'''+layers.cu+'''")
                        (cons 'visible #t)
                        (cons 'color #(65535 65535 65535))
                        (cons 'alpha #(51400))
                    )
                    (define-layer! 4 (cons 'filename "gerber/'''+layers.mask+'''")
                        (cons 'inverted #t)
                        (cons 'visible #t)
                        (cons 'color #(34983 0 428))
                        (cons 'alpha #(54741))
                    )
                    (define-layer! 3 (cons 'filename "gerber/Cut.Edge.GKO")
                        (cons 'visible #t)
                        (cons 'color #(65535 40745 0))
                    )
                    (define-layer! 0 (cons 'filename "gerber/drill.XLN")
                        (cons 'visible #t)
                        (cons 'color #(0 0 0))
                        (cons 'attribs (list
                            (list 'autodetect 'Boolean 1)
                            (list 'zero_suppression 'Enum 1)
                            (list 'units 'Enum 1)
                            (list 'digits 'Integer 3)
                        ))
                    )
                    (set-render-type! 3)
                    '''

                sides = 
                    front: 
                        cu: "F.Cu.GTL"
                        mask: "F.Mask.GTS"
                    back: 
                        cu: "B.Cu.GBL"
                        mask: "B.Mask.GBS"

                for side, f of sides
                    layout-dir.file "gerber-#{side}.gvp", gen-gvp(f)

                # Testing
                testing = "1_Testing"
                err, res <~ prototypePrint {side: "F.Cu, Edge"}
                unless err 
                    filename = "#{testing}_F.Cu.svg"
                    layout-dir.file filename, res
                else 
                    PNotify.error text: err
                    return 

                err, res <~ prototypePrint {side: "B.Cu, Edge", +mirror}
                unless err 
                    filename = "#{testing}_B.Cu.svg"
                    layout-dir.file filename, res
                else 
                    PNotify.error text: err
                    return 

                BORDER_COLOR = "black"

                <~ set-immediate
                # Front Assembly
                assembly = "3_Assembly"
                err, res <~ prototypePrint {
                    side: "F.Cu, Edge", 
                    scale: 2, 
                    trace-color: "lightgray", 
                    border-color: BORDER_COLOR}
                unless err 
                    filename = "#{assembly}_Front.svg"
                    layout-dir.file filename, res
                else 
                    PNotify.error text: err
                    return 

                <~ set-immediate
                # Back Assembly
                err, res <~ prototypePrint {
                    side: "B.Cu, Edge", 
                    scale: 2, 
                    trace-color: "lightgray", 
                    border-color: BORDER_COLOR, 
                    +mirror}
                unless err 
                    filename = "#{assembly}_Back.svg"
                    layout-dir.file filename, res
                else 
                    PNotify.error text: err
                    return 

                <~ set-immediate

                # Create Gerber 
                # -------------
                gerb = new GerberReducer
                gerb.reset!
                gerb-version = new GenMultiFingerprint
                
                # Every aeObj is responsible for registering its own 
                # Gerber data. 
                #console.log "aeObjs: ", pcb.get-aeobjs!
                for aeobj in pcb.get-aeobjs!
                    aeobj.trigger \export-gerber

                gerbers = layout-dir.folder \gerber
                for name, {content, ext} of gerb.export! 
                    gerbers.file "#{name}.#{ext}", content 
                    gerb-version.add content 

                layout-dir.file "gerber-version", gerb-version.get!

                lo(op)

            pcb.switch-layout current-layout

            content <~ zip.generateAsync({type: "blob"}).then
            create-download "#{project-name}.zip", content

        uploadProject: (ctx, file, cb) ->
            try 
                project-name = file.basename.split('.')[0]
                console.log "project name is: ", project-name
                pcb.history.commit!
                pcb.clear-canvas!
                # Backup current scripts just in case 
                console.log "Backup of current scripts:"
                console.log "--------------------------------------------"
                for name, content of pcb.ractive.get('drawingLs')
                    console.log """
                        # Script: #{name}
                        #{content}
                        """
                console.log "--------------------------------------------"
                pcb.ractive.set \editorContent, ""
                pcb.ractive.set \scriptName, null

                b = new SignalBranch
                zip <~ jszip.loadAsync(file.blob).then
                if Boolean(zip.file("#{project-name}/pcb.json"))
                    pfx = "#{project-name}/"
                else 
                    pfx = ""

                # import drawing 
                signal = b.add!
                zip.file("#{pfx}pcb.json").async("string").then (contents) ~> 
                    err <~ pcb.import contents, do
                        format: "json"
                        name: "pcb"
                    <~ pcb.ractive.fire \activateLayer, ctx, "gui"
                    signal.go err

                get-filename = (f) -> 
                    x = f.split('/').pop()
                    x.substr(0, x.lastIndexOf('.'))

                # import scripts
                drawingLs = {}   
                for let file, prop of zip.files
                    if prop.dir 
                        console.log "Directory entry, skipping:", prop.name
                    else if prop.name.starts-with '.'
                        console.log "Skipping hidden file"
                    else if get-filename(file).trim() is ""
                        console.warn "SKIPPING EMPTY FILENAME"
                    else
                        if file.starts-with "#{pfx}scripts/" 
                            console.log "Unpacking #{file}..."
                            signal = b.add!
                            contents <~ zip.file(file).async("string").then
                            drawingLs[get-filename(file)] = contents 
                            signal.go!
                <~ b.joined
                # Assign relevant objects
                pcb.ractive.set 'project.name', project-name
                pcb.ractive.set \drawingLs, drawingLs
                pcb.ractive.set \scriptName, project-name

                return cb(null)
            catch err
                @get \vlog .error do
                    title: 'Import Error'
                    message: err.to-string!
                cb(err.to-string!)
    
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
            err, res <~ pcb.history.back
            unless err 
                PNotify.info do
                    text: "Changes reverted. (left: #{res.left})"
                    addClass: 'nonblock'
                pcb.ractive.fire \calcUnconnected, {+silent}  # TODO: Unite this action
            else 
                PNotify.notice do 
                    text: "No commits left."
                    addClass: "nonblock"

        save: (ctx) ->
            # save project
            #pcb.history.commit! ### No need to bloat the history
            err, res <~ pcb.history.save
            PNotify.info do
                text: res.message
                addClass: 'nonblock'

        clear: (ctx) ->
            pcb.history.commit!
            pcb.clear-canvas!
            PNotify.info do
                text: "Project cleared."
                addClass: 'nonblock'

        showHelp: (ctx) ->
            @get \vlog .info do
                template: require('./help/index.pug')
