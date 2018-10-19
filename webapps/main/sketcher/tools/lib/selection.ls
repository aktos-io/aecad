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

        @selected = []

    add: (items, opts={}) ->
        for flatten [items]
            @selected.push .. unless ..selected
            ..selected = yes
        console.log "Selected items so far: ", @selected

    delete: ->
        for i in [til @selected.length]
            item = @selected.pop!
            if item.remove!
                console.log ".........deleted: ", item
            else
                console.error "couldn't recache item: ", item
                @selected.push item

        unless empty @selected
            console.error "Why didn't we erase those selected items?: ", @selected
            debugger
