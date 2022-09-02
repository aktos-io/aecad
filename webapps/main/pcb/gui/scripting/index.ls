require! 'aea'
require! 'dcs/lib': lib
require! 'livescript': lsc
require! 'prelude-ls'
require! 'aea': {create-download, merge}
require! 'aea/do-math': {mm2px, px2mm}
require! '../../tools/lib': tool-lib
require! '../../kernel': {PaperDraw}
require! 'diff': jsDiff
require! 'mathjs'
require! 'jszip'
require! 'dcs/browser': {SignalBranch}
require! '../../tools/lib/schema/lib/flatten-obj': {flatten-obj}
require! '../../lib/chronometer': {Chronometer}

get-filename = (f) -> f.substr(0, f.lastIndexOf('.'))
get-ext = (f) -> f.substr(f.lastIndexOf('.') + 1)

{text2arr} = tool-lib
{keys, values, map, filter, find} = prelude-ls

export init = (pcb) ->
    chrono = new Chronometer

    # Modules to be included into dynamic scripts
    modules = {aea, lib, lsc, PaperDraw, mm2px, pcb, based-on: aea.based-on, mathjs, px2mm}
    # include all tools
    modules <<< tool-lib
    # include all prelude-ls functions
    modules <<< prelude-ls

    modules <<< {flatten-obj}
    # modules from pcb
    pcb-modules = """
        Group Path Rectangle PointText Point Shape
        Matrix
        canvas project view
        """ |> text2arr |> map (name) -> modules[name] = pcb[name]

    unit-tests-passed = false 
    modules <<< do
        TODO: (markdown) -> 
            console.warn "TODO Handler: #{markdown}" 
            PNotify.notice do
                text: markdown
                addClass: 'nonblock'

        layout: (name) -> 
            pcb.switch-layout name

        standard: (opts, sch) ->  
            # This function performs the "standard" actions for a given Schema instance. 
            # Use this function within the scripting window.
            unless sch 
                sch = opts  
                opts = {}  

            chrono.start!
            sch.clear-guides!
            console.log "standard new Schema: clear-guides() took: #{chrono.end!}"
            chrono.start!
            sch.compile!
            console.log "standard new Schema: compile() took: #{chrono.end!}"
            chrono.start!
            sch.guide-unconnected!  
            console.log "standard new Schema: guide-unconnected() took: #{chrono.end!}"
            
            # Calculate unconnected count
            pcb.ractive.fire 'calcUnconnected', {}, {+cached}

            # Populate component-selection dropdown
            # Any component can be highlighted by selecting it
            # from the "component selection dropdown", located above of drawing area:
            pcb.ractive.set \currComponentNames, [{id: v.name, name: v.name} for k, v of sch.components]

            # Detect and mark component upgrades
            unless modules.empty upgrades=(sch.get-upgrades!)
                pcb.selection.clear!
                msg = ''
                for upgrades
                    msg += ..reason + '\n\n'
                    pcb.selection.add do
                        aeobj: ..component
                # display a visual message
                pcb.vlog.info msg

            if sch.data.disable-drc
                PNotify.notice text: "DRC Disabled: #{that}"

            bom = []
            bom.push "; count, type: value [instances...]"
            bom.push "; ---------------------------------"
            for sch.get-bom-list!
                bom.push "#{..count},\t#{..type}:\t#{..value}\t[#{..instances}]"
            pcb.layouts{}[pcb.active-layout].bom = bom.join '\n'

            connectionListTxt = []
            for k, v of sch.connectionListTxt
                connectionListTxt.push v.join ',\t'
            pcb.layouts{}[pcb.active-layout].connectionList = connectionListTxt.join '\n'

            # debug output 
            if sch.debug 
                console.log "Connection List: {netid: pads-to-be-connected}"
                console.log "----------------------------------------------"
                console.log sch.connectionListTxt
                console.log ""

                console.log "Connection States (Reduced): {netid: currently-connected-pads[, stray pads]}"
                console.log "----------------------------------------------"
                console.log sch.connection-states-reduced

            return sch

        run-unit-tests: -> 
            unless unit-tests-passed
                err <~ pcb.ractive.fire \runTests, {}
                unit-tests-passed := not err 




    runScript = (script-name, opts={+clear}) ~>
        start-time = new Date! .getTime()
        compiled = no
        @set \output, ''
        c1 = new Chronometer
        try
            libs = []
            for name, src of @get \drawingLs
                libs.push do
                    name: name, 
                    src: """
                        __main__ = #{name is script-name}
                        __name__ = "#{name}"
                        #{src}
                        """

            #console.log "drawingls (main script: #{script-name}): ", libs
            c1.start!

            # Determine dependencies and provisions 
            for lib in libs
                for lib.src.split '\n'
                    if ..match /^[^#]*\b(class)\s+([^\s]+)\b/
                        _cls = that.2
                        lib.[]exposes.push _cls
                        #console.log "------> #{lib.name} exposes #{_cls}"
                    # handle `... # provides: this` line
                    if ..match /^([^=]+)\b.+\s#\s*provides:?\s*this\b/
                        lib.[]exposes.push that.1 
                        #console.log "------> #{lib.name} exposes/provides #{that.1}"
                    if (a=..match /^#!?\s*[Rr]equires:?\s*(.+)\b/) or (b=..match /^#\s*[Dd]epends:?\s*(.+)\b/)
                        lib.[]depends ++= (a or b).1.split(',').map (.trim!)
                        #console.log "----> #{lib.name} depends #{that.1}"
            console.log "runScript: dependency determination took: #{c1.end!}"

            # Sort by dependency order
            ordered = []
            main-script = find (-> it.name is script-name), libs

            insert-dep = (lib) !->
                for dep in lib.[]depends
                    if dep in main-script.[]exposes
                        console.log "INFO: Skipping processing #{lib.name} 
                            because it depends \"#{dep}\" from the main script (#{script-name})."
                        return

                for dep in lib.[]depends
                    console.log "Dependency resolution: #{lib.name} depends on #{dep}."
                    unless ordered |> find (-> dep in it.[]exposes)
                        if libs |> find (-> dep in it.[]exposes)
                            # recursively check its dependencies
                            console.log "...resolving #{that.name} because it's required by #{lib.name}"
                            insert-dep that
                        else
                            throw new Error "Missing definition: \"#{dep}\". Required by #{lib.name}"

                unless find (.name is lib.name), ordered
                    if lib.name isnt main-script.name 
                        ordered.push lib
                        console.log "...inserting #{lib.name} to the ordered list."

            c1.start!
            #console.log "libs: ", libs
            for ([main-script] ++ libs)
                insert-dep .. if .. 
            console.log "runScript: dependency insertion took: #{c1.end!}"

            # add main script
            if main-script
                ordered.push that

            # This is a debug output
            debug = no; if debug
                output = []
                for ordered
                    output.push "* Using: #{..name}"
                ordered.push "----------------------"
                @set \output, output.join('\n')
            
            # compile livescript code
            whole-src = [..src for ordered].join('\n')
            c1.start!
            js = lsc.compile whole-src, {+bare, -header, map: 'embedded', filename: 'dynamic.ls'}
            console.log "runScript: lsc.compile(whole-src) took: #{c1.end!}"
            compiled = yes
        catch err
            try 
                i = 1
                problematic = []
                files = []
                :outer for {name, src} in ordered 
                    for line in src.split '\n'
                        if err.hash.loc.first_line <= i
                            problematic.push line 
                            files.push name unless name in files 
                        if err.hash.loc.last_line < i 
                            break outer
                        i++
            catch
                problematic = <[ NA ]> 
                responsible = <[ NA ]> 
                console.error err 
                debugger 


            @set \output, "Compile error: #{err.to-string!}"
            @get \vlog .error do
                title: 'Compile Error'
                message: """
                    #{err.to-string!}
                    ----------------------
                    Responsible: "#{files.join ','}"
                    Code: #{problematic.join '\n'}
                    """
            console.error "Compile error: #{err.to-string!}"
            console.log whole-src

        if compiled
            try
                c1.start!
                layer = pcb.use-layer \scripting
                if opts.clear
                    layer.clear!
                console.log "runScript: layer cleared: #{c1.end!}"


                #console.log "Added global modules: ", keys modules
                c1.start!
                func = new Function ...(keys modules), js.code
                console.log "runScript: new Function creation took: #{c1.end!}"
                c1.start!
                func.call pcb, ...(values modules)
                console.log "runScript: func.call() took: #{c1.end!}"
                #pcb._scope.execute js


                name = opts.name or @get \scriptName
                unless opts.silent
                    end-time = new Date! .getTime()

                    PNotify.success do
                        text: """
                            Compiled schema: #{name} in #{oneDecimal (end-time - start-time)/1000}s
                            """
                        addClass: 'nonblock'

            catch err 
                @set \output, "ERROR: \n\n" + (@get 'output') + "#{err}"
                @get \vlog .error do
                    title: 'Runtime Error'
                    message: err.message
                console.warn "Use 'Pause on exceptions' checkbox to hit the exception line"
                # See https://github.com/ceremcem/aecad/issues/8

    h = @observe \editorContent, ((_new) ~>
        if @get 'scriptName'
            #console.log "SETTING NEW!! in @observe editorcontent "
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
                @get \project.layers.scripting ?.clear!
            unless pcb.layouts[pcb.active-layout]?type is "manual"
                unless pcb.active-layout is item.id   
                    pcb.switch-layout item.id   
            progress!

        compileScript: (ctx, name, opts={+clear}) ~>
            name = name or @get 'scriptName' 
            runScript name, opts 
            pcb.layouts{}[pcb.active-layout].script-name = name 

        clearScriptLayer: (ctx) ~>
            @get \project.layers.scripting ?.clear!

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
                # Use "# depends: foo" for dependencies 
                # Use "foo = # provides:this" for manual provisions
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
            if action is \everything
                @set \scriptName, null
                @set \editorContent, ''
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
