require! 'actors': {BrowserStorage}
require! 'aea': {hash}
require! 'prelude-ls': {values, difference}

export class History
    (opts) ->
        @project = opts.project
        @ractive = opts.ractive
        @selection = opts.selection
        @db = new BrowserStorage opts.name
        @commits = []
        @limit = 200

    commit: ->
        @commits.push @project.exportJSON!
        console.log "added to history"
        if @commits.length > @limit
            console.log "removing old history"
            @commits.shift!

    back: ->
        if @commits.pop!
            console.log "Going back in the history. Left: #{@commits.length}"
            @load-project that
        else
            console.warn "No commits left, sorry."


    load-project: (data) ->
        # data: stringified JSON
        if data
            @project.clear!
            @selection.clear!
            @project.importJSON data

            while true
                needs-rerun = false
                for layer in @project.layers
                    unless layer
                        # workaround for possible Paper.js bug
                        # which can not handle more than a few
                        # hundred layers
                        console.warn "...we have an null layer!"
                        needs-rerun = true
                        continue
                    if layer.getChildren!.length is 0
                        console.log "removing layer..."
                        layer.remove!
                        continue

                    if layer.name
                        @ractive.set "project.layers.#{Ractive.escapeKey layer.name}", layer
                    else
                        layer.selected = yes

                    for layer.getItems!
                        ..selected = no
                        if ..data?.tmp
                            ..remove!
                break unless needs-rerun
                console.warn "Workaround for load-project works."
            #console.log "Loaded project: ", @project

    load-scripts: (saved) ->
        orig = @ractive.get \drawingLs
        curr-orig-h = @ractive.get \scriptHashes
        prev-orig-h = (@db.get \scriptHashes) or {}
        saved-h = do ->
            x = {}
            for n, c of saved
                x[n] = hash(c)
            return x

        updated-scripts = values(curr-orig-h) `difference` values(prev-orig-h)
        name-of-hash = (x) ->
            for name, h of curr-orig-h
                return name if h is x
        for name in updated-scripts.map name-of-hash
            console.log "Updated script: ", name
            saved["#{name} (update: #{Date.now!})"] = orig[name]

        @ractive.set \drawingLs, saved
        #console.log "loaded scripts: ", data

    save: ->
        # Save history into browser's local storage
        # -----------------------------------------
        # save current project
        data = @project.exportJSON!
        @db.set \project, data

        # save scripts
        scripts = @ractive.get \drawingLs
        @db.set \scripts, scripts
        @db.set \scriptHashes, @ractive.get \scriptHashes

        # Save settings
        # TODO: provide a proper way for this, it's too messy now
        @db.set \settings, do
            scriptName: @ractive.get \scriptName
            projectName: @ractive.get \project.name
            autoCompile: @ractive.get \autoCompile
            currTrace: @ractive.get \currTrace

        # save last 10 commits of history
        @db.set \history, @commits.slice(-10)

        console.log "Saved at ", Date!, "project length: #{parseInt(data.length/1024)}KB"

    load: ->
        # Load from browser's local storage
        # --------------------------------------
        if @db.get \project
            @load-project that

        if @db.get \scripts
            @load-scripts that

        if @db.get \settings
            # TODO: see save/settings
            @ractive.set \scriptName, that.scriptName
            @ractive.set \project.name, that.projectName
            @ractive.set \autoCompile, that.autoCompile
            @ractive.set \currTrace, that.currTrace

        if commits=(@db.get \history)
            if @commits.length is 0 and typeof! commits is \Array
                @commits = commits
            else
                @ractive.get \vlog .error "How come the history isn't empty?"
                console.error "Commit history isn't empty: ", @commits
