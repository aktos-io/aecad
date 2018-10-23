require! 'prelude-ls': {empty, flatten}

export class Selection
    @instance = null
    ->
        # Make this class Singleton
        return @@instance if @@instance
        @@instance = this

        @selected = []

    deselect: (opts={}) ->
        for @selected
            if ..getClassName! is \Curve
                ..getPath!.selected = no
            else
                ..selected = no
            if ..data?.tmp
                #console.log "removing temporary path: ", ..
                ..remove!

        @selected = []

    add: (items, opts={select: yes}) ->
        for flatten [items]
            try
                switch ..getClassName!
                | \Path => \ok
                | \Curve => \ok
                | \Segment => \ok
                | \Group => \ok
                | \Point => \ok
                |_ =>
                    console.warn "unrecognized", ..
                    throw
            catch
                console.warn ".........unrecognized selection: ", ..
                continue
            if ..id? and find (.id is ..id), @selected
                console.log "duplicate item, not adding: ", ..
                continue
            if ..selected
                console.log "already selected, not adding"
                continue
            @selected.push ..
            if opts.select
                ..selected = yes
        console.log "Selected items so far: #{@selected.length}"

    delete: !->
        for i, item of @selected
            console.log "item is: ", item
            try
                item.remove!
            catch
                item._owner.remove!

        @selected.length = 0 

    get-top-item: ->
        @selected.0
