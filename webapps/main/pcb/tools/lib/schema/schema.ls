# global imports
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
    first, unique-by, compact, map, intersection, reject, or-list, Obj
}

require! 'aea': {merge}

# deps
require! './deps': {find-comp, PaperDraw, text2arr, get-class, get-aecad, parse-params}
require! './lib': {parse-name, next-id}
require! './post-process-netlist': {post-process-netlist}

# Class parts
require! './bom'
require! './footprints'
require! './netlist'
require! './guide'
require! './schema-manager': {SchemaManager}
require! '../text2arr': {text2arr}
require! '../../../lib/chronometer': {Chronometer}

# Recursively walk through links
get-net = (netlist, id, included=[], mark) ~>
    #console.log "...getting net for #{id}"
    reduced = []
    included.push id
    if find (.remove), netlist[id]
        #console.warn "Netlist(#{id}) is marked to be removed (already merged?)"
        return []
    for netlist[id]
        if ..link
            # follow the link
            unless ..target in included
                linked = get-net netlist, ..target, included, {+remove}
                for linked
                    unless ..uname in reduced
                        reduced.push ..
                    else
                        console.warn "Skipping duplicate pads from linked net"
        else
            reduced ++= ..pads
    if mark
        # do not include this net in further lookups
        netlist[id].push mark
    reduced

the-one-in = (arr) ->
    # expect only one truthy value in the array
    # and return it
    the-only-value = null
    for id in arr
        id = parse-int id 
        if id 
            unless the-only-value
                the-only-value = id
            else if "#{id}" isnt "#{the-only-value}"
                console.error "the-one-in: ", arr
                throw new Error "We have multiple values in this array"
    the-only-value

prefix-value = (o, pfx) ->
    res = {}
    for k, v of o 
        if typeof! v is \Object 
            v2 = prefix-value v, pfx
            res[k] = v2 
        else 
            res[k] = text2arr v .map ((x) -> "#{pfx}#{x}")
    return res 


export class Schema implements bom, footprints, netlist, guide
    (@opts) !->
        '''
        opts:
            name: Name of schema
            prefix: *Optional* Prefix of components
            data: (see docs/schema-usage.md)
        '''
        opts = @opts 
        unless opts
            throw new Error "Data should be provided on init."

        @name = if @opts.parent
            "#{that}-#{@opts.name}"
        else 
            @opts.name or "main"

        @data = if typeof! @opts.data is \Function 
            @opts.data(@opts.value, @opts.labels) 
        else 
            @opts.data 
            
        @data.bom `merge` (opts.bom or {})
        @debug = @opts.debug or @data.debug

        @prefix = @opts.prefix or ''

        @parent = opts.parent
        @scope = new PaperDraw
        @manager = new SchemaManager
            ..register this
        @compiled = false
        @connection-list = {}           # key: netid, value: array of related Pads
        @sub-circuits = {}              # sub-circuits if @data.bom contains a component defined in @data.schemas.
                                        # {type_declared_in_BOM: Schema Object} 

        @netlist = []                   # array of "array of `Pad` objects (aeobj) on the same net"
        @_netlist = {}                  # cached and post-processed version of original .netlist {CONN_ID: [pad_names...]}
        @_data_netlist = []             # Post processed and array version of @data.netlist
        @_labels = @opts.labels
        @_cables = @data.cables or {}
        @_cables_connected = []         # Virtual connections
        @_iface = []                    # array of interface pins

        @_chrono = new Chronometer

    chrono-start: (id) -> 
        if @debug 
            @_chrono.start id 

    chrono-reset: (id) -> 
        @chrono-start(id)

    chrono-log: (id, message) ->      
        if @debug 
            unless message
                message = id 
            console.log "#{@name}: Chronometer #{message}: took #{@_chrono.measure id}"

    chrono-pause: (id) -> 
        @_chrono.pause id 

    chrono-resume: (id) -> 
        @_chrono.resume id 

    external-components: ~
        # Current schema's external components
        -> 
            Object.keys @sub-circuits

    flatten-netlist: ~
        ->
            /* 
            `flatten-obj` like function that returns flatten version of 
            current @_netlist and all sub-circuits' @_netlist's. 
            Simple components of sub-circuits are '@prefix'ed. 
            */
            @chrono-start 'flatten-netlist'
            netlist = @_netlist
            # unconnected interface pins will be treated as null nets
            for @iface
                unless .. of netlist
                    netlist[..] = []

            for instance, circuit of @sub-circuits
                #console.log "adding sub-circuit #{instance} to netlist:", circuit
                for netid, net of circuit.flatten-netlist
                    netlist["#{instance}.#{netid}"] = net .map (-> "#{instance}.#{it}")

                for circuit.iface
                    # interfaces are null nets
                    prefixed = "#{instance}.#{..}"
                    unless prefixed of netlist
                        netlist[prefixed] = []   
            @chrono-log "flatten-netlist"       
            netlist

    components-by-name: ~
        ->
            unless @_components_by_name
                # fill the cache
                @_components_by_name = {}
                for @components
                    if ..component 
                        @_components_by_name[..component.name] = ..component
                    else 
                        console.error "No component object was found:", ..
            return @_components_by_name

    iface: ~
        -> @_iface
            
    no-connect: ~
        -> text2arr @data.no-connect

    get-pad-from-pin: (pin-name) -> 
        [_, component, pin] = pin-name.match /^([^.]+)\.(.+)$/
        try
            @components-by-name["#{@prefix}#{component}"].get({pin})
        catch 
            debugger 
            throw e 

    compile: !->
        @compiled = true
        @chrono-start "@compile()"


        {@_data_netlist, @_iface, @_netlist} = post-process-netlist {@data.netlist, @data.iface, @opts.labels}

        if @debug 
            console.log "#{@name}: -----------------------------------------"
            console.log "#{@name}: @_data_netlist: ", @_data_netlist
            console.log "#{@name}: @_iface: ", @_iface
            console.log "#{@name}: @_netlist: ", @_netlist
            console.log "#{@name}: @flatten-netlist: ", @flatten-netlist
            console.log "#{@name}: -----------------------------------------"


        @calc-bom!

        # Compile sub-circuits first
        for instance-name, schema of @bom when schema.data
            #console.log "Initializing sub-circuit: #{sch.name} ", sch
            @sub-circuits[instance-name] = new Schema (schema <<< {debug: (@debug is \all)})
                ..compile!

        # add needed footprints
        @chrono-start "@compile/add-footprints"
        @add-footprints!
        @chrono-log "@compile/add-footprints"

        # Component list is created at this moment. 
        # Process the `cables` property. 

        @chrono-start "@compile/cable-connections"
        cable-connections = []
        for i, j of @_cables 
            connection = text2arr j
                ..push i 
            # if this is a simple pin-to-pin connection, just append it
            if or-list connection.map (.match /^[a-zA-Z_][^.]*\.[^.]+$/)
                cable-connections.push connection 
            else 
                # this is a whole connector match, reveal all pins 
                _connectors = connection.map (~> @components-by-name[it])
                _reference_conn = _connectors.shift!
                for _connectors
                    if Object.keys(..iface).length isnt Object.keys(_reference_conn.iface).length
                            throw new Error "Pin counts of cable interfaces do not match: #{..name} and #{_reference_conn.name}" 

                for pin-num, pin-name of _reference_conn.iface
                    _connection = ["#{_reference_conn.name}.#{pin-name}"]
                    for conn in _connectors
                        _connection.push "#{conn.name}.#{conn.iface[pin-num]}"
                    cable-connections.push _connection

        for jumpers in cable-connections
            injection-point = null 
            for k, net of @_netlist
                unless empty intersection ([k] ++ net), jumpers 
                    unless injection-point?
                        injection-point = k 
                        @_netlist[k] = unique (net ++ jumpers)
                        @_cables_connected.push flatten jumpers.map(~> @get-pad-from-pin it) 
                    else
                        # cables are already injected, "re-reduce" the netlist
                        @_netlist[injection-point] = unique (@_netlist[injection-point] ++ @_netlist[k] ++ [k])
                        delete @_netlist[k]
        @chrono-log "@compile/cable-connections"

        # Detect unconnected pins and false unused pins
        @chrono-start "@compile/find-unused"
        @find-unused @bom
        @chrono-log "@compile/find-unused"


        # compile netlist
        # -----------------
        @chrono-start "@compile/generate @netlist"

        netlist = {}
        #console.log "* Compiling schema: #{@name}"
        for id, conn-list of _flatten_netlist=@flatten-netlist
            # TODO: performance improvement:
            # use find-comp for each component only one time
            net = [] # cache (list of connected nodes)
            for full-name in conn-list
                {name, pin, link, raw} = parse-name full-name, do
                    prefix: @prefix
                    external: @external-components
                #console.log "Searching for entity: #{name} and pin: #{pin}, pfx: #{@prefix}"
                if full-name of _flatten_netlist
                    # Merge into parent net
                    # IMPORTANT: Links must be key of netlist in order to prevent accidental namings
                    #console.warn "HANDLE LINK: #{full-name}"
                    net.push {link: yes, target: full-name}

                    # create a cross link
                    unless full-name of netlist
                        netlist[full-name] = []
                    netlist[full-name].push {link: yes, target: id, type: \cross-link}
                    continue
                else
                    comp = @components-by-name[name]
                    unless comp
                        if name in @iface
                            console.log "Found an interface handle: #{name}. Silently skipping."
                            continue
                        else if name.match /^_[0-9]+/
                            # This is an internal connection name, silently skip it 
                            continue
                        else
                            console.error "#{name} can not be found within current components: ", @components-by-name
                            console.warn "Current flatten netlist: ", @flatten-netlist
                            if @debug 
                                debugger 
                            throw new Error "No such component found: '#{name}' (full name: #{full-name}), pfx: #{@prefix}"

                    pads = (comp.get {pin}) or []
                    if empty pads
                        if comp.type not in flatten [[..type, ..component.type] for @get-upgrades!]
                            console.error "Current iface:", comp, comp.iface
                            err = "No such pin found: '#{pin}' of '#{name}'"
                            console.error err 
                            throw new Error  "#{err} (check the console output)"

                    uses-quick-labels = @bom[(full-name.replace /\..+/, '')].labels?

                    unless comp.allow-duplicate-labels or uses-quick-labels
                        if pads.length > 1
                            if comp.type not in [..type for @get-upgrades!]
                                throw new Error "Multiple pins found: '#{pin}' of '#{name}' (#{comp.type}) in #{@name}"

                    # find duplicate pads (shouldn't be)
                    if (unique-by (.uname), pads).length isnt pads.length
                        console.info "INFO: FOUND DUPLICATE PADS in ", name

                    net.push {name, pads}
            unless id of netlist
                netlist[id] = []
            netlist[id] ++= net  # it might be already created by cross-link

        @chrono-log "@compile/generate @netlist"

        unless @parent
            # Create the cleaned up @netlist (arrays of arrays of Pad objects)
            @netlist.length = 0
            for id of netlist
                net = get-net netlist, id
                unless empty net
                    @netlist.push net

            # build the @connection-list
            @chrono-start "@compile/@build-connection-list!"
            @build-connection-list!
            @chrono-log "@compile/@build-connection-list!"

            # Check errors
            @post-check!

            # Output the generated report
            #console.log "... Schema: #{@name}, Connection list:", @connection-list
            #console.log "... Schema: #{@name}, Netlist:", @netlist

        @chrono-log "@compile()"

    get-required-pads: ->
        all-pads = {}
        for @components
            # request all connectable pads from components
            for ..component.get {+connectable}
                all-pads[..pin] = null
        return all-pads

    build-connection-list: !->
        # Re/Build the connection name table for the net
        # ------------------------------------------------
        # see docs/Schema.md/Schema.connection-list for documentation.
        #
        @connection-list = {}
        # Collect already assigned netid's

        # double-check the @netlist. it shouldn't contain same uname in different nets:
        # TODO: Remove this precaution on v1.0
        _used_uname = []
        for net in @netlist
            for pad in unique-by (.uname), net
                if pad.uname in _used_uname
                    console.warn "Problematic Netlist is: ", @netlist
                    console.warn "...Nets: ", [..map((.uname)) for @netlist when pad.uname in ..map((.uname))]
                    throw "This pad appears (#{pad.uname}) on another net.
                        Is 'tests/simple/indirect connection' test passing?"
                else
                    _used_uname.push pad.uname
        # end of double check

        newly-created = []
        for net in @netlist
            try
                existing-netid = '' + the-one-in [pad.netid for pad in net]
            catch
                # error if there are conflicting netid's already existing
                dump = "#{net.map ((p) -> "#{p.uname}[#{p.netid}]") .join ', '}"
                console.error dump
                throw new Error "Multiple netid's assigned to the pads in the same net (#{unique compact [pad.netid for pad in net] .join ','}): (format: pin-name(pin-no)[netid] ) \n\n #{dump}"

            # use existing netid extracted from one of the pads
            if existing-netid?.match /[0-9]+/
                if existing-netid of @connection-list and "duplicate-netid" not in text2arr @data.disable-drc
                    # this netid seems already occupied.
                    existing = @connection-list[existing-netid].map (.uname) .join ', '
                    curr = net.map (.uname) .join ', '
                    throw new Error "Duplicate netid found: #{existing-netid} (
                        #{curr} already occupied by #{existing}"
                else
                    # create the connection list with that existing netid
                    @connection-list[existing-netid] = net
                    # Propagate existing-netid to all pads in the same net
                    for pad in net
                        pad.netid = existing-netid
            else
                # this net is newly created, take your note to assign
                # next possible netid.
                newly-created.push net

        # Assign newly created net's netid's
        for til newly-created.length
            net = newly-created.pop!
            # generate the next netid
            netid = next-id @connection-list
            @connection-list[netid] = net
            for pad in net
                pad.netid = netid

    connection-list-txt: ~
        # For debugging purposes
        -> 
            txt = {}
            # For debugging purposes
            for netid, net of @connection-list
                for pad in net when not pad.is-via
                    txt[][netid].push pad.uname
            return txt

    netlist_txt: ~
        -> 
            netlist-txt = []
            for net in @netlist
                netlist-txt.push net.map (.uname)
            return netlist-txt

    connection-states-reduced: ~
        -> 
            out = {}
            for netid, state of @_connection_states
                if state.reduced.length > 1 
                    out[netid] = state.reduced
                else 
                    out[netid] = state.reduced.0
            out

    post-check: ->
        # Error report (will stay while aeCAD is in Alpha stage)
        for index, pads of @netlist
            # Check for duplicate pads in the same net
            for _i1, p1 of pads
                for _i2, p2 of pads when _i2 > _i1
                    if p1.uname and p2.uname and p1.uname is p2.uname
                        console.error "Duplicate pads found: #{p1.cid} and #{p2.cid}: in #{_i1} and #{_i2} ", p1.uname, p1

            # Find unmerged nets
            for _i, _pads of @netlist when _i > index
                for p1 in pads
                    for p2 in _pads
                        if p1.uname is p2.uname
                            console.error "Unmerged nets found
                            : Netlist(#{index}) and Netlist(#{_i}) both contains #{p1.uname}"
