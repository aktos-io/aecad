# global imports
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
    first, tail
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
                # Number of total connections (edges) we should have
                ..total = net.length - 1
                ..unconnected = -1
                ..pads = [.. for net]
                ..tree = {}
                ..unconnected-pads = []

            # build connection tree
            for index, pad of state.pads
                bounds = pad.cu-bounds
                marker bounds # for visual inspection of the bounds
                for trace-item in traces
                    if trace-item `is-connected` bounds
                        state.tree[][trace-item.id].push pad
                        #console.log "...found a connection: ", trace-item

            # reduce the connection tree
            ref = []
            :reduce for index, pads of state.tree
                # first net is the reference
                if empty ref
                    ref = pads
                    continue
                # try to merge rest of tree branches into first one (the ref branch)
                for pad in pads
                    refs = ref.map (.cid)
                    if pad.cid in refs
                        #console.log "...they have mutual pads, merge this branch (#{index}) into ref: #{pad.cid}"
                        for pads when pad.cid not in refs
                            ref.push ..
                        delete state.tree[index]
                        continue reduce

                # at this point, we have multiple branches. (which means unconnected nets)
                if empty state.unconnected-pads
                    # add first ref pad as unconnected
                    #console.log "...adding first pad of reference tree"
                    state.unconnected-pads.push first ref

                # take the inspected net's first pad as "unconnected pad"
                state.[]unconnected-pads.push first pads

            # we reduced the state.tree in state.unconnected-pads.
            # add any stray pads that is not present in the tree into the unconnected-pads
            if ref.length is 1
                # we can't consider this as a reference "connection" (it's not a connection)
                state.unconnected-pads.push ref.pop!

            for pad in net when pad.cid not in ref.map (.cid)
                if empty state.unconnected-pads
                    # add first ref pad as unconnected
                    if first ref
                        state.unconnected-pads.push that

                # prevent duplicate entries
                if pad.cid in state.unconnected-pads.map (.cid)
                    # we might insert this pad if ref had 1 pad in it
                    continue

                # add the pad into unconnected pad list
                state.unconnected-pads.push pad

            # report the unconnected count
            state.unconnected = if empty state.unconnected-pads
                0
            else
                state.unconnected-pads.length - 1

        #console.log ":::: Connection states: ", connection-states
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
