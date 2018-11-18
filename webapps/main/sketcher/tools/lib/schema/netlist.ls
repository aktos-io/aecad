# global imports
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
}

# deps
require! './deps': {find-comp, PaperDraw, text2arr, get-class, get-aecad}
require! './lib': {parse-name}

export do
    get-netlist-components: ->
        components = []
        for id, conn-list of @data.netlist
            for n-name in text2arr conn-list # node-name
                {name, link} = parse-name n-name

                if name in text2arr @data.iface
                    # This is an interface reference, not a physical component
                    continue

                if link
                    # this is only a cross reference, ignore it
                    continue

                if name in keys @sub-circuits
                    # this is a sub-circuit element, it has been handled in its Schema
                    continue

                unless name in components
                    components.push name

        #console.log "netlist raw components found: ", components
        return components
