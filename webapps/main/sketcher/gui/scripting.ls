require! 'aea'
require! 'dcs/lib': lib
require! '../example'
require! 'livescript': lsc
require! 'prelude-ls': {keys, values}
require! 'aea': {create-download}
require! '../tools/lib': {Container, Footprint, Pad, find-comp}

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
                    Container, Footprint, Pad, find-comp
                }
                pcb-modules = """
                    Group Path Rectangle PointText Point Shape
                    Matrix
                    canvas project view
                    """.replace /\n/g, ' ' .split " "
                #console.log "Loaded Paper.js modules: ", pcb-modules
                for pcb-modules
                    modules[..] = pcb[..]

                #console.log "Added global modules: ", keys modules
                func = new Function ...(keys modules), js
                func.call pcb, ...(values modules)
                #pcb._scope.execute js
            catch
                @set \output, (@get 'output') + "#{e}\n\n#{js}"
                @get \vlog .error do
                    title: 'Runtime Error'
                    message: e
                throw e

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
            create-download 'scripts.cson', CSON.stringify(scripts, null, 2)

        # ------------------------
        # end of gui/scripting.pug

    return handlers
