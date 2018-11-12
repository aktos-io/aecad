require! 'aea'
require! 'dcs/lib': lib
require! 'livescript': lsc
require! 'prelude-ls'
require! 'aea': {create-download}
require! 'aea/do-math': {mm2px}
require! '../tools/lib': tool-lib
require! '../kernel': {PaperDraw}

{text2arr} = tool-lib
{keys, values, map} = prelude-ls

export init = (pcb) ->
    runScript = (content) ~>
        compiled = no
        @set \output, ''
        try
            if content and typeof! content isnt \String
                throw new Error "Content is not string!"

            _content = ""
            output = []
            for name, script of @get \drawingLs when name.starts-with \lib
                if name is @get 'scriptName'
                    continue
                output.push "* Using library: #{name}"
                _content += script + '\n'

            # append actual content
            output.push "* ...Running script: #{@get 'scriptName'}"
            output.push "-----------------------------------------"
            output.push ""
            output.push ""
            @set \output, output.join('\n')
            _content += content
            js = lsc.compile _content, {+bare, -header}
            compiled = yes
        catch err
            @set \output, "Compile error: #{err.to-string!}"
            @get \vlog .error do
                title: 'Compile Error'
                message: err.to-string!
            console.error "Compile error: #{err.to-string!}"

        if compiled
            try
                pcb.use-layer \scripting
                    ..clear!

                modules = {
                    aea, lib, lsc
                    PaperDraw
                    mm2px
                }

                # include all tools
                modules <<< tool-lib

                # include all prelude-ls functions
                modules <<< prelude-ls

                pcb-modules = """
                    Group Path Rectangle PointText Point Shape
                    Matrix
                    canvas project view
                    """
                    |> text2arr
                    |> map (name) ->
                        modules[name] = pcb[name]

                #console.log "Added global modules: ", keys modules
                func = new Function ...(keys modules), js
                func.call pcb, ...(values modules)
                #pcb._scope.execute js
            catch
                @set \output, "ERROR: \n\n" + (@get 'output') + "#{e}"
                @get \vlog .error do
                    title: 'Runtime Error'
                    message: e
                #throw e
                console.error e

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

            if action in [\hidden, \cancel]
                console.log "Cancelled."
                return

            @set 'scriptName', null # remove selected script first
            @delete 'drawingLs', script-name
            console.warn "Deleted #{script-name}..."

        downloadScripts: (ctx) ->
            scripts = @get \drawingLs
            content = CSON.stringify(scripts, null, 2)
            # workaround: we are not able to include JSON (or CSON) files with Browserify
            # directly require by:
            # require! './path/to/scripts'
            # console.log scripts
            content = "export {\n#{content}\n}"
            create-download 'scripts.ls', content

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
            @get \vlog .info "Done, reload your window."


    return handlers
