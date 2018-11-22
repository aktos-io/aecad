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
    # Check if item is **properly** connected to the rectangle
    for item.children or []
        unless ..getClassName! is \Path
            continue
        if ..segments.length is 1
            console.warn "Removing 1 segment path:", ..
            ..remove!
            continue
        trace-side = ..data?.aecad?.side
        unless pad.side-match trace-side
            #console.warn "Not on the same side, won't count as a connection: ", pad, item
            continue
        for {point} in ..segments
            # check all segments of the path
            if point.is-inside pad-bounds
                return true
    unless item.hasChildren()
        console.warn "Removing empty item", item
        item.remove!
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
                for trace-item in traces
                    if trace-item `is-connected` pad
                        # many traces may be connected to the same pad
                        connected-pads[][trace-item.id].push pad
                        #console.log "...netid: #{netid}: found a connection with trace: #{trace-item.id}", trace-item, pad

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
