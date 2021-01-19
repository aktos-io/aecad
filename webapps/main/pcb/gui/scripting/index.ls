require! 'aea'
require! 'dcs/lib': lib
require! 'livescript': lsc
require! 'prelude-ls'
require! 'aea': {create-download, merge}
require! 'aea/do-math': {mm2px}
require! '../../tools/lib': tool-lib
require! '../../kernel': {PaperDraw}
require! 'diff': jsDiff
require! 'mathjs'
require! 'jszip'
require! 'dcs/browser': {SignalBranch}


get-filename = (f) -> f.substr(0, f.lastIndexOf('.'))
get-ext = (f) -> f.substr(f.lastIndexOf('.') + 1)

{text2arr} = tool-lib
{keys, values, map, filter, find} = prelude-ls

export init = (pcb) ->
    # Modules to be included into dynamic scripts
    modules = {aea, lib, lsc, PaperDraw, mm2px, pcb, based-on: aea.based-on, mathjs}
    # include all tools
    modules <<< tool-lib
    # include all prelude-ls functions
    modules <<< prelude-ls
    # modules from pcb
    pcb-modules = """
        Group Path Rectangle PointText Point Shape
        Matrix
        canvas project view
        """ |> text2arr |> map (name) -> modules[name] = pcb[name]

    modules <<< do
        TODO: (markdown) -> 
            PNotify.notice do
                text: markdown
                addClass: 'nonblock'

    runScript = (code, opts={+clear}) ~>
        compiled = no
        @set \output, ''
        try
            if code and typeof! code isnt \String
                throw new Error "Content is not string!"

            libs = []
            for name, src of @get \drawingLs when name.starts-with \lib
                unless @get(\scriptName) is name 
                    libs.push {name, src}
            #console.log "drawingls: ", libs

            # Correctly sort according to their class definitions
            for lib in libs
                for lib.src.split '\n'
                    if ..match /.*\b(class)\s+([^\s]+)\b/
                        _cls = that.2
                        lib.[]exposes.push _cls
                        #console.log "------> #{lib.name} exposes #{_cls}"
                    if ..match /#!\s*requires\s+(.*)\b/
                        lib.[]depends.push that.1
                        #console.log "----> #{lib.name} depends #{that.1}"

            ordered = []
            insert-dep = (lib) !->
                for dep in lib.[]depends
                    unless find (-> dep in it.[]exposes), ordered
                        # currently no lib presents that exposes the dependency
                        if find (-> dep in it.[]exposes), libs
                            # recursively check its dependencies
                            #console.log "inserting sub-dep #{dep}: ", that
                            insert-dep that
                        else
                            debugger
                            throw new Error "Missing dependency: #{dep}"

                unless find (.name is lib.name), ordered
                    ordered.push lib

            #console.log "libs: ", libs
            for libs
                insert-dep ..
    
            # append actual code
            if @get \scriptName
                ordered.push {name: @get('scriptName'), src: '__main__ = yes\n' + code}

            output = []
            for ordered
                output.push "* Using: #{..name}"
            ordered.push "----------------------"
            @set \output, output.join('\n')

            # compile livescript code
            whole-src = [..src for ordered].join('\n')
            js = lsc.compile whole-src, {+bare, -header, map: 'embedded', filename: 'dynamic.ls'}
            compiled = yes
        catch err
            @set \output, "Compile error: #{err.to-string!}"
            @get \vlog .error do
                title: 'Compile Error'
                message: err.to-string!
            console.error "Compile error: #{err.to-string!}"

        if compiled
            try
                layer = pcb.use-layer \scripting
                if opts.clear
                    layer.clear!

                #console.log "Added global modules: ", keys modules
                func = new Function ...(keys modules), js.code
                func.call pcb, ...(values modules)
                #pcb._scope.execute js

                name = opts.name or @get \scriptName
                unless opts.silent
                    PNotify.info do
                        text: """
                            Script: #{name}
                            """
                        addClass: 'nonblock'

            catch
                @set \output, "ERROR: \n\n" + (@get 'output') + "#{e}"
                @get \vlog .error do
                    title: 'Runtime Error'
                    message: e
                console.warn "Use 'Pause on exceptions' checkbox to hit the exception line"
                # See https://github.com/ceremcem/aecad/issues/8

    # Register all classes on app load
    runScript '# placeholder content', {-clear, name: 'Initialization run', +silent}

    h = @observe \editorContent, ((_new) ~>
        if @get \autoCompile
            runScript _new

        sleep 0, ~>
            if @get 'scriptName'
                #console.log "SETTTING NEW!! in @observe editorcontent "
                h.silence!
                @set "drawingLs.#{Ractive.escapeKey that}", _new
                <~ sleep 10
                h.resume!
    ), {-init}



    handlers =
        # gui/scripting.pug
        # ------------------------
        scriptSelected: (ctx, item, progress) ~>
            #console.log "script is selected, app handler called: ", item
            h.silence!
            @set \editorContent, item.content
            h.resume!
            unless item.content
                @get \project.layers.scripting .clear!
            progress!

        compileScript: (ctx) ~>
            runScript @get \editorContent

        clearScriptLayer: (ctx) ~>
            @get \project.layers.scripting .clear!

        newScript: (ctx) ~>
            action, data <~ @get \vlog .yesno do
                title: 'New Script'
                icon: ''
                closable: yes
                template: '''
                    <div class="ui input">
                        <input value="{{filename}}" />
                    </div>
                    '''
                buttons:
                    create:
                        text: 'Create'
                        color: \green
                    cancel:
                        text: \Cancel
                        color: \gray
                        icon: \remove

            if action in [\hidden, \cancel]
                console.log "Cancelled."
                return

            if data.filename?length < 1
                @get \vlog .error "Empty file name, won't add anything."
                return

            if data.filename of (@get 'drawingLs')
                @get \vlog .error "Duplicate filename, won't add anything."
                return


            @set "drawingLs.#{Ractive.escapeKey data.filename}", ''
            @set \scriptName, data.filename

            default-content =
                '''
                # --------------------------------------------------
                # all lib* scripts will be included automatically.

                '''

            if (data.filename.starts-with 'lib')
                default-content +=
                    '''
                    #
                    # This script will also be treated as a library file.

                    '''
            default-content +=
                '''
                # --------------------------------------------------

                '''

            #console.log "default content is: ", default-content
            @set \editorContent, default-content

        removeScript: (ctx) ~>
            script-name = @get \scriptName
            unless script-name
                console.log "No script selected."
                return
            action <~ @get \vlog .yesno do
                title: 'Remove Script'
                icon: 'exclamation triangle'
                message: "Do you want to remove #{script-name}?"
                closable: yes
                buttons:
                    delete:
                        text: 'Delete'
                        color: \red
                        icon: \trash
                    cancel:
                        text: \Cancel
                        color: \green
                        icon: \remove
                    everything:
                        text: \Everything
                        color: \violet
                        icon: \danger 

            if action in [\hidden, \cancel]
                console.log "Cancelled."
                return

            avail = Object.keys(@get 'drawingLs')
            script-pos = avail.index-of script-name
            next-script = avail[if script-pos > 0 then script-pos - 1 else 1]

            # select next script
            @set \editorContent, ''
            if action is \everything
                @set \scriptName, null
                @set \drawingLs, {}
            else 
                @set \scriptName, next-script
                @delete 'drawingLs', script-name

            console.warn "Deleted #{script-name}..."

        downloadScripts: (ctx) ->            
            # workaround: to include JSON (or CSON) files with Browserify
            #content = "export {\n#{content}\n}"
            
            zip = new jszip! 
            for name, content of @get('drawingLs')
                zip.file "#{name}.ls", content

            content <~ zip.generateAsync({type: "blob"}).then
            create-download "scripts.zip", content
            
        uploadScripts: (ctx, file, cb) ->
            try
                b = new SignalBranch
                zip <~ jszip.loadAsync(file.blob).then
                for let file, prop of zip.files
                    if prop.dir 
                        console.log "Directory entry, skipping:", prop.name
                    else if prop.name.starts-with '.'
                        console.log "Skipping hidden file"
                    else
                        console.log "Unpacking #{file}..."
                        s = b.add!
                        contents <~ zip.file(file).async("string").then
                        @get("drawingLs")[get-filename(file)] = contents 
                        s.go!
                <~ b.joined
                # select the first script (TODO: don't change if new scripts include
                # a script with a same name as selected script)
                @set \scriptName, n=(Object.keys @get("drawingLs") .0)
                @set \drawingLs, @get \drawingLs
                console.log "Setting scriptName as #{n}"
                return cb(null)
            catch err
                @get \vlog .error do
                    title: 'Import Error'
                    message: err.to-string!
                cb(err.to-string!)

        restart-diff: (ctx) ->
            action <~ @get \vlog .yesno do
                title: 'Reset Diff Tracking'
                icon: 'exclamation triangle'
                message: '''
                    Do you want to restart scripts diff tracking?

                    This is a safe but verbose action since all server side scripts
                    will be included in scripts window (with "update ..." postfix).
                    '''
                closable: yes
                buttons:
                    yes:
                        text: 'Restart'
                        color: \green
                        icon: \undo
                    cancel:
                        text: \Cancel
                        color: \green
                        icon: \remove

            if action in [\hidden, \cancel]
                console.log "Cancelled."
                return

            pcb.history.reset-script-diffing!
            @get \vlog .info "Done, reload your window. \n\n (TODO: reload shouldn't be needed)"

        showDiff: (ctx, name) ->
            try
                {remote, current} = (@get "drawingLsUpdates")[name]
            catch
                PNotify.error text: "No such diff (#{name}) found."
                return

            sdiff_ = jsDiff.structuredPatch(name, "#{name} (server)", current, remote, "local", "server")
            console.log "scripting: diff: ", sdiff_
            @get \vlog .info do
                template: require('./diff.pug')
                data:
                    diff: sdiff_

    return handlers
