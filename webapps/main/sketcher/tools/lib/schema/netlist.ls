# global imports
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
    first, tail, unique-by, intersection, union
}

# deps
require! './deps': {find-comp, PaperDraw, text2arr, get-class, get-aecad}
require! './lib': {parse-name, net-merge}

is-connected = (item, pad) ->
    pad-bounds = pad.cu-bounds
    trace-netid = item.data.aecad.netid
    # Check if item is **properly** connected to the rectangle
    for item.children or []
        unless ..getClassName! is \Path
            continue
        trace-side = ..data?.aecad?.side
        unless pad.side-match trace-side
            #console.warn "Not on the same side, won't count as a connection: ", pad, item
            continue
        for {point} in ..segments
            # check all segments of the path
            if point.is-inside pad-bounds
                # Detect short circuits
                if "#{trace-netid}" isnt pad.netid
                    item.selected = true
                    pad.selected = true
                    throw new Error "Short circuit: #{pad.uname} (n:#{pad.netid}) with #{item.data.aecad.tid} (n:#{trace-netid})"
                else
                    #console.log "Pad #{pad.uname} seems to be connected with Trace tid: #{item.data.aecad.tid}"
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
            console.warn "Placing a tmp marker:", rect
            new @scope.Path.Rectangle {
                rectangle: rect
                stroke-color: 'white'
                stroke-width: 0.2
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
                ..total = unique [..pin for net] .length - 1    # Number of possible connections
                ..unconnected-pads = []

            # create the connection tree
            connected-pads = {}
            for pad in net
                for trace-item in _traces
                    if trace-item `is-connected` pad
                        connected-pads[][trace-item.phy-netid].push pad

            # merge connection tree
            named-connections = [v.map (.pin) for k, v of connected-pads]
            state.reduced = net-merge named-connections, [..pin for net]

            # generate Pad object list
            state.unconnected-pads = [.. for net when ..pin in state.reduced.stray]

            # report the unconnected count
            state.unconnected = if empty state.unconnected-pads
                0
            else
                state.unconnected-pads.length - 1

        console.log ":::: Connection states: ", connection-states
        return connection-states

    get-traces: ->
        traces = {}
        for {item} in @scope.get-components {exclude: '*', include: <[ Trace ]>}
            # Cleanup non-functional traces
            for item.children when ..getClassName?! is \Path
                if ..segments.length is 1
                    ..remove!
            if item.children.length is 0
                item.remove!
                continue

            unless item.data.aecad.netid
                console.error "Trace item:", item
                throw new Error "A trace with no netid found"
            item.phy-netid = null
            traces[item.id] = item

        # detect physically connected traces
        # assign a physical netid: same id for physically connected traces
        trace-ids = keys traces
        count = trace-ids.length
        conn-traces = []
        for i from 0 til count-1
            curr = traces[trace-ids[i]]
            :search for j from 1 til count when j > i
                other = traces[trace-ids[j]]
                # if curr physically connected with other, assign other's
                # phy-netid same with this one
                for c in curr.children when c.getClassName?! is \Path
                    for o in other.children when o.getClassName?! is \Path
                        if c.data.aecad.side is o.data.aecad.side
                            # they are physically on the same side
                            isec = c.getIntersections o
                            if isec.length > 0
                                #console.warn "We found an intersection:", curr.data.aecad.tid, other.data.aecad.tid, isec
                                conn-traces.push ["#{curr.id}", "#{other.id}"]
                                continue search
        reduced = net-merge(conn-traces, trace-ids.map((.to-string!)))
        #console.log "Connected traces:", conn-traces, reduced
        id = 1
        for reduced.stray
            traces[..].phy-netid = id++
        for reduced.merged
            _id = id++
            for ..
                traces[..].phy-netid = _id

        #console.log "Found Traces:", traces
        return values traces
