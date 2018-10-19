require! 'prelude-ls': {empty}

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
        if typeof! items is \Array
            @selected ++= items
        else
            @selected.push items

        if opts.select
            for @selected
                ..selected = yes

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
