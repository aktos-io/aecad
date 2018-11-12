export do
    get-components: (opts={}) ->
        '''
        Returns all aeCAD components in {item, type} form
        '''
        items = []
        for @project.layers
            for item in ..getItems {-recursive}
                if type=(item.data?aecad?type)
                    if opts.exclude
                        if type in that
                            continue
                    name = item.data.aecad.name
                    items.push {item, type, name}
        items
