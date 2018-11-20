
# dig item untill it has no children or it's an aeCAD object
dig-for-aecad = (item) ->

export do
    get-components: (opts={}) ->
        '''
        Returns all aeCAD components in {item, type, name, version} form
        '''
        items = []
        for @project.layers
            for item in ..getItems {-recursive}
                if type=(item.data?aecad?type)
                    skip-exclude = no
                    if opts.include
                        if type in that
                            skip-exclude = yes
                    if not skip-exclude and opts.exclude
                        if that is '*' or type in that
                            continue
                    name = item.data.aecad.name
                    version = item.data.aecad.version
                    items.push {item, type, name, version}
        items
