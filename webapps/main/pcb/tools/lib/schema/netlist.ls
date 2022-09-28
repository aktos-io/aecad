# global imports
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
    first, tail, unique-by, intersection, union, reject, map
}

# deps
require! './deps': {find-comp, PaperDraw, text2arr, get-class, get-aecad}
require! './lib': {parse-name, net-merge}

is-connected = (item, pad) ->
    pad-bounds = pad.cu-bounds
    trace-netid = "#{item.data.aecad.netid}"
    trace-netid = trace-netid.replace /[^0-9]/g, ''

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
            if point.transform(item._globalMatrix).is-inside pad-bounds
                # Detect short circuits
                if "#{trace-netid}" isnt "#{pad.netid}"
                    item.selected = true
                    pad.selected = true
                    console.warn "Short circuit item: ", item, item.position, "Pad is:", pad, pad.gpos                   
                    PNotify.notice do
                        hide: yes
                        text: "Short circuit: #{pad.uname} (n:#{pad.netid}) with #{item.data.aecad.tid} (netid:#{trace-netid})"
                else
                    #console.log "Pad #{pad.uname} seems to be connected with Trace tid: #{item.data.aecad.tid}"
                    return true
    return false

export do
    get-netlist-components: ->
        components = []
        for id, conn-list of @_netlist
            for n-name in conn-list # node-name
                {name, link} = parse-name n-name

                if name in @iface
                    # This is an interface reference, not a physical component
                    continue

                if link
                    # this is only a cross reference, ignore it
                    continue

                if name.split('.').0 of @sub-circuits 
                    # this is a sub-circuit element, it has been handled in its Schema
                    #console.log "Handling #{name} with its schema:", @sub-circuits[name]
                    continue

                unless name in components
                    components.push name

        #console.log "netlist raw components found: ", components
        return components

    calc-connection-states: ->
        # see docs/Scheme.md#calc-connection-states
        @chrono-start "@calc-connection-states()"
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
        @chrono-start "@calc-connection-states()/@get-traces()"
        # List of trace items with physically connected states are calculated
        {trace-items: _traces, vias} = @get-traces! 
        @chrono-log "@calc-connection-states()/@get-traces()"

        # Adding vias to connection list
        #console.log "vias:", vias
        for netid, pads of vias 
            @connection-list[][netid] ++= pads 

        # Calculate pad connections
        # ------------------------------------------------
        # 
        #    See: docs/schema-api.md#How the circuits are created
        #
        # ------------------------------------------------
        externally-connected = @_cables_connected.map((.map (.logical-pin)))

        for netid, net of @connection-list
            logical-pin-net = unique [..logical-pin for net]
            state = connection-states.{}[netid]
                ..total = logical-pin-net.length - 1    # Number of possible connections
                ..unconnected-pads = []

            # Find out which traces connect which Pad's. 
            @chrono-resume "@calc-connection-states()/is-connected"
            connected-elements = {}
            for pad in net
                for trace in _traces when trace `is-connected` pad
                    unless connected-elements[trace.phy-netid]
                        connected-elements[trace.phy-netid] = ["trace-id::#{trace.id}"]
                    connected-elements[trace.phy-netid].push pad.logical-pin
            @chrono-pause "@calc-connection-states()/is-connected"

            # Add virtual connections 
            @chrono-resume "@calc-connection-states()/add virtual connections"
            if vtrace=@data.virtual-traces
                for v-trace-id, pad-names of vtrace
                    trace-id = "trace-id::virtual-#{v-trace-id}"
                    unless connected-elements[trace-id]
                        connected-elements[trace-id] = [trace-id]
                    connected-elements[trace-id] ++= (pad-names 
                        |> text2arr
                        |> map (~> @get-pad-from-pin(it).map((.logical-pin)))
                        |> flatten
                        |> unique)

            @chrono-pause "@calc-connection-states()/add virtual connections"

            # create "named-connections" to reduce via `net-merge` function.
            named-connections = values connected-elements

            # Virtually connect the externally connected pins defined in ".cables"
            for cable in externally-connected
                for pin in logical-pin-net when pin in cable
                    named-connections.push cable  

            @chrono-resume "@calc-connection-states()/net-merge"
            state.reduced = net-merge named-connections, [..logical-pin for net]
            @chrono-pause "@calc-connection-states()/net-merge"

            # generate the list of unconnected Pad instances
            # TODO: determine discrete-pads by closest point, not by the first
            # pad in the array (which is somewhat random)
            discrete-pads = [first reject((.match /^trace-id::/), ..) for state.reduced]
            if discrete-pads.length is 1
                discrete-pads.length = 0

            state.unconnected-pads = [.. for net when ..logical-pin in discrete-pads]

            # report the unconnected trace count
            state.unconnected = if empty state.unconnected-pads
                0
            else
                state.unconnected-pads.length - 1

        #console.log ":::: Connection states: ", connection-states
        @_connection_states = connection-states
        @chrono-log "@calc-connection-states()/add virtual connections"
        @chrono-log "@calc-connection-states()/net-merge"
        @chrono-log "@calc-connection-states()/is-connected"
        @chrono-log "@calc-connection-states()"
        return connection-states

    get-traces: ->
        /*
            Get all the trace items with a `phy-netid` property added where this
            property shows that the traces with the same `phy-netid` is physically
            connected with each other.

            1. Find all traces (and make some necessary cleanups)
            2. Find the physically connected traces
            3. Generate a `phy-netid` starting from 1 and assign same `phy-netid`
                for each "physically connected trace network".
            4. Return the array of traces while that `phy-netid` property is assigned.
        */
        traces = {}
        trace-ids = []
        vias = {}
        for {item, aeobj} in @scope.get-components {exclude: '*', include: <[ Trace ]>}
            # Cleanup non-functional traces
            # ------------------------------
            for item.children when ..?getClassName?! is \Path
                if ..segments.length is 1
                    console.log "Removing single segment child of Trace:", ..
                    ..remove!
            if item.children.length is 0
                item.remove!
                continue
            # end of cleanup

            unless item.data.aecad.netid
                console.error "Trace item:", item
                item.selected = true
                throw new Error "A trace with no netid found"
            item.phy-netid = null
            traces[item.id] = item
            trace-ids.push item.id # for performance reasons

            for (item.children or []) when ..data.aecad?type is \Pad
                via = get-aecad .. 
                vias[][via.netid].push via

        # traces is now an object that contains all valid traces

        # detect physically connected traces
        # assign a physical netid (same id for physically connected traces)
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
                                if curr.data.aecad.netid isnt other.data.aecad.netid
                                    PNotify.notice do
                                        hide: yes
                                        text: "Trace short circuit: #{curr.data.aecad.tid} and #{other.data.aecad.tid}"

                                    curr.selected = yes 
                                    other.selected = yes 

                                #console.warn "We found an intersection:", curr.data.aecad.tid, other.data.aecad.tid, isec
                                conn-traces.push ["#{curr.id}", "#{other.id}"]
                                continue search
        reduced = net-merge(conn-traces, trace-ids.map((.to-string!)))
        #console.log "Connected traces:", conn-traces, reduced

        # We have physically connected traces grouped in "reduced" variable
        # at this point.

        # Mark each trace with a temporary "physical connection id". This `phy-netid`
        # will be later used to identify wire group.
        id = 1
        for reduced
            _id = id++
            for ..
                traces[..].phy-netid = _id

        # Return array of simple trace items while a ".phy-netid" property is
        # assigned each of them.
        trace-items = values traces
        #console.log "trace-items: ", trace-items
        return {trace-items, vias}
