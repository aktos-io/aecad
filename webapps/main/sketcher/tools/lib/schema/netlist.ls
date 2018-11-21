# global imports
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
    first, tail, unique-by, intersection, union
}

# deps
require! './deps': {find-comp, PaperDraw, text2arr, get-class, get-aecad}
require! './lib': {parse-name}

is-connected = (item, rectangle) ->
    # Check if item is **properly** connected to the rectangle
    for item.children or [] when ..getClassName! is \Path
        for {point} in ..segments
            # check all segments of the path
            if point.is-inside rectangle
                return true
    return false


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

    get-connection-states: ->
        /*
        {
            {{netid}}:
                pads: []
                traces: []
                connected-pads: []
                unconnected-pads: []
        }
        */
        marker = (rect) ~>
            new @scope.Path.Rectangle {
                rectangle: rect
                stroke-color: 'blue'
                stroke-width: 0.1
                opacity: 0.5
                data: {+tmp}
                selected: true
            }

        connection-states = {}
        _traces = @get-traces!
        # Calculate connections
        for netid, net of @connection-list
            state = connection-states.{}[netid]
                ..traces = traces = _traces[netid] or []
                ..total = net.length - 1    # Number of possible connections
                ..unconnected = null
                ..pads = [.. for net]
                ..tree = {}
                ..unconnected-pads = []
                ..log = []

            # create the connection tree branches
            named-branches = {}
            for index, pad of state.pads
                bounds = pad.cu-bounds
                marker bounds               # REMOVEME: for visual inspection of the bounds
                for trace-item in traces
                    if trace-item `is-connected` bounds
                        named-branches[][trace-item.id].push pad
                        msg = ["...netid: #{netid}: found a connection: #{trace-item.id}", trace-item]
                        state.log.push msg

            # build the tree regarding to branches
            # - TODO: https://stackoverflow.com/q/21900713/1952991
            # if mutual pads can be found between two branches, create a new branch with them
            branches = [branch.map((.uname)) for tid, branch of named-branches]
            mbranches = [] # merged branches (mark them in order not to include twice)
            _mindex = [] # merged branch indexes
            for i1, branch1 of branches when i1 not in _mindex
                merged = branch1
                for i2, branch2 of branches when i2 > i1 and i2 not in _mindex
                    # combinations
                    unless empty intersection branch1, branch2
                        merged = union merged, branch2
                        _mindex.push i2
                mbranches.push merged
            
            # There are 3 possibilities here:
            # 1. Reference net (and its pads)
            # 2. Stray nets (and their pads)
            # 3. Stray pads
            #
            # Procedure:
            # 1. If there are stray pads or stray net(s), sample a pad from ref.
            #    and put into unconnected too

            unconn = [] # unconnected pad names
            stray-pads = [..uname for net] `difference` flatten mbranches
            if not empty stray-pads or not mbranches.length > 1
                # we have unconnected pads, use `first ref` as entry point
                if first mbranches
                    unconn.push first that

            for stray-pads
                unconn.push ..

            # add stray nets' first pads as entry point
            for tail mbranches or []
                unconn.push first ..

            # generate pad list
            state.unconnected-pads = [.. for net when ..uname in unconn]

            state.unconn = unconn
            state.mbranches = mbranches

            # report the unconnected count
            state.unconnected = if empty state.unconnected-pads
                0
            else
                state.unconnected-pads.length - 1

        console.log ":::: Connection states: ", connection-states
        return connection-states

    get-traces: ->
        traces = {}
        for trace in @scope.get-components {exclude: '*', include: <[ Trace ]>}
            netid = trace.item.data.aecad.netid
            unless netid
                console.warn "A trace with no netid found. How could this be possible?", trace.item
                trace.item.remove!
                continue

            # TODO: cleanup non-functional traces:
            # * no children
            # * paths with 1 segment

            traces[][netid].push trace.item
        #console.log "Found Traces:", traces
        return traces
