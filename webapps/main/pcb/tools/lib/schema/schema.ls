# global imports
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
    first, unique-by, compact, map, intersection, reject, or-list, Obj
}

require! 'aea': {merge}

# deps
require! './deps': {find-comp, PaperDraw, text2arr, get-class, get-aecad, parse-params}
require! './lib': {parse-name, next-id, flatten-obj, net-merge}

# Class parts
require! './bom'
require! './footprints'
require! './netlist'
require! './guide'
require! './schema-manager': {SchemaManager}
require! '../text2arr': {text2arr}

require! 'dcs/lib/test-utils': {make-tests}


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


post-process-netlist = ({netlist, iface, labels}) -> 
    _data_netlist = []
    _iface = []
    _netlist = {}
    # -----------------------------------------------------------
    # Post process the netlist 
    # -----------------------------------------------------------
    internal-numeric = (x) -> 
        # convert numeric keys to semi-numeric (underscore prefixed)
        if x.match /^[0-9]+/
            "_#{x}"
        else
            x


    # Check for netlist errors
    for key, _net of flatten-obj netlist 
        # LABEL's can be numeric or alphanumeric and MUST be declared 
        # within the key section of @data.netlist. 
        # Component pads should only follow "COMPONENT.PIN" syntax.

        net = ["__netid:#{internal-numeric key}", internal-numeric key]
        for text2arr _net
            if ..match /([^.]+)\.$/
                # PIN is forgotten
                throw new Error "Netlist Error: Pin declaration is forgotten. 
                    Check \"#{..}\" component at netlist[\"#{key}\"] connection."
            net.push .. 
        _data_netlist.push net 

    # Build interface
    for iface-pin in text2arr iface
        if iface-pin.match /([^.]+)\.(.+)/
            # {{COMPONENT}}.{{PIN}} syntax 
            pad = that.0 # pad is {{COMPONENT}}.{{PIN}}
            component = that.1
            pin = that.2

            # Connect the interface pin to the corresponding net  
            # and expose this pin as an interface:
            _data_netlist.push ["__iface:#{pad}", pin, pad]
            _iface.push pin 
        else 
            if iface-pin of netlist 
                _data_netlist.push ["__iface:#{iface-pin}", internal-numeric iface-pin]
            _iface.push iface-pin

    # if labels are declared, replace @_iface with @_labels 
    if labels? 
        for orig-iface, new-label of labels 
            _data_netlist.push ["__iface:#{orig-iface}", "__label:#{new-label}"]
        _iface = values labels 

    # TEMPORARY SECTION: Create a @_netlist object now
    # ------------------------------------------------
    for net in x=(net-merge _data_netlist)
        # We no longer need numeric labels and interface descriptions.
        netlabel = null     # only one label is allowed for a net 
        iface = null 
        iface-label = null 
        _net = []
        for elem in net 
            if label=(elem.match /^__label:(.+)$/)?.1
                # Use labels if labels are present
                iface-label = label
                continue 

            if i=(elem.match /^__iface:[^.]+\.(.+)$/)?.1
                # Remove temporary interface entries
                iface = i 
                continue 

            if i=(elem.match /^__iface:(.+)$/)?.1
                # Remove temporary interface entries
                iface = i 
                continue 

            if netid=(elem.match /^__netid:(.+)$/)?.1
                # this is an alphanumeric label 
                if netid.match /^_[0-9]+/
                    # that's a number  
                    unless netlabel
                        netlabel = netid
                    continue 
                else 
                    # that's an alphanumeric label, replace with current label 
                    if not netlabel or netlabel.match /^_[0-9]+/
                        netlabel = netid 
                        continue 
                    else 
                        throw new Error "Only one netlabel is allowed for a logical net. You should choose \"#{netid}\" or \"#{netlabel}\"."
            
            if elem.match /^_[0-9]+/
                # no need for numerical netlabels
                continue 

            unless elem.match /\./
                # no need for labels 
                continue

            _net.push elem 
        _netlist[iface-label or iface or netlabel] = _net
    # ------------------------------------------------
    # End of temporary section

    return {_data_netlist, _iface, _netlist}

make-tests "post-process-netlist", do 
    "simple": -> 
        {_netlist} = post-process-netlist do 
            netlist: 
                1: "a.1 b.2 c.1"
                x: "c.2 d.1"
                2: "d.2 x"

        expect _netlist
        .to-equal do 
            _1: <[ a.1 b.2 c.1 ]>
            x: <[ d.2 c.2 d.1 ]>

    "simple with sub-object": -> 
        # same as "simple" but uses sub-object
        {_netlist} = post-process-netlist do 
            netlist: 
                1: "a.1 b.2 c.1"
                x: "c.2 d.1"
                2: 
                    1: "d.2 x"

        expect _netlist
        .to-equal do 
            _1: <[ a.1 b.2 c.1 ]>
            x: <[ c.2 d.1 d.2 ]>


    "conflicting netlabel": -> 
        func = ->  
            {_netlist} = post-process-netlist do 
                netlist: 
                    1: "a.1 b.2 c.1"
                    x: "c.2 d.1"
                    y: "d.2 x"

        expect func
        .to-throw 'Only one netlabel is allowed for a logical net. You should choose "y" or "x".'

    "iface definition": -> 
        {_netlist} = post-process-netlist do 
            netlist: 
                1: "a.1 b.2 c.1"
                x: "c.2 d.1"
                2: "d.2 x"
            iface: "d.1 b.2"

        expect _netlist
        .to-equal do 
            2: <[ a.1 b.2 c.1 ]>
            1: <[ d.2 c.2 d.1 ]>       

    "numeric iface": ->  
        {_netlist} = post-process-netlist do 
            netlist: 
                1: "r1.1 r4.2"
                2: "r3.1 r2.2"
            iface: "1 2"

        expect _netlist
        .to-equal do 
            1: <[ r1.1 r4.2 ]>
            2: <[ r3.1 r2.2 ]>

    "undeclared iface pin": ->  
        {_netlist, _iface} = post-process-netlist do 
            netlist: 
                a: "x.1 y.1"
                2: "z.1 t.1"
            iface: "a c"

        expect _netlist
        .to-equal do 
            a: <[ x.1 y.1 ]>
            _2: <[ z.1 t.1 ]> 

        expect _iface
        .to-equal <[ a c ]>            
         
    "labels": ->  
        {_netlist, _iface} = post-process-netlist do 
            netlist: 
                1: "r1.1 r4.2"
                2: "r3.1 r2.2"
            iface: "1 2"
            labels: 
                1: "aa"
                2: "bb"

        expect {_netlist, _iface}
        .to-equal do
            _netlist: 
                aa: <[ r1.1 r4.2 ]>
                bb: <[ r3.1 r2.2 ]>
            _iface: <[ aa bb ]> 


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

        @name = opts.schema-name or opts.name or "main"

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
        @connection-list = {}           # key: trace-id, value: array of related Pads
        @sub-circuits = {}              # sub-circuits if @data.bom contains a component defined in @data.schemas.
                                        # {type_declared_in_BOM: Schema Object} 

        @netlist = []                   # array of "array of `Pad` objects (aeobj) on the same net"
        @_netlist = {}                  # cached and post-processed version of original .netlist {CONN_ID: [pad_names...]}
        @_data_netlist = []             # Post processed and array version of @data.netlist
        @_labels = @opts.labels
        @_cables = @data.cables or {}
        @_cables_connected = []         # Virtual connections
        @_iface = []                    # array of interface pins
                

    external-components: ~
        # Current schema's external components
        -> [.. for values @bom when ..data]

    flatten-netlist: ~
        ->
            /* 
            `flatten-obj` like function that returns flatten version of 
            all sub-circuits' netlists. Simple components of sub-circuits are 
            prefixed with their parent circuit name. 
            */

            netlist = @_netlist

            # unconnected interface pins will be treated as null nets
            for @iface
                unless .. of netlist
                    netlist[..] = []

            for circuit-name, circuit of @sub-circuits
                #console.log "adding sub-circuit #{circuit-name} to netlist:", circuit
                for trace-id, net of circuit.flatten-netlist
                    prefixed = "#{circuit-name}.#{trace-id}"
                    #console.log "...added #{trace-id} as #{prefixed}: ", net
                    netlist[prefixed] = net .map (-> "#{circuit-name}.#{it}")

                for circuit.iface
                    # interfaces are null nets
                    prefixed = "#{circuit-name}.#{..}"
                    unless prefixed of netlist
                        netlist[prefixed] = []
            #console.log "FLATTEN NETLIST: ", netlist
            netlist


    prefixed-netlist: ~
        -> 
            for netid, net of @_netlist 
                "#{@prefix2}#{netid}": net.map (~> "#{@prefix2}#{it}") 

    prefix2: ~
        -> 
            if @parent => "#{@parent}." else ''

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

    is-link: (name) ->
        if name of @flatten-netlist
            yes
        else
            no

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

        {@_data_netlist, @_iface, @_netlist} = post-process-netlist {@data.netlist, @data.iface, @opts.labels}

        # Compile sub-circuits first
        for sch in values @get-bom! when sch.data
            #console.log "Initializing sub-circuit: #{sch.name} ", sch
            @sub-circuits[sch.name] = new Schema (sch <<<< {@debug})
                ..compile!

        # add needed footprints
        @add-footprints!

        # Component list is created at this moment. 
        # Process the `cables` property. 
        cable-connections = []
        for i, j of @_cables 
            connection = text2arr j
                ..push i 
            # if this is a simple pin-to-pin connection, just append it
            if or-list connection.map (.match /^[a-zA-Z_][^.]*\.[^.]+$/)
                cable-connections.push connection 
            else 
                # this is a connector match
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

        # Detect unconnected pins and false unused pins
        @find-unused @bom

        # compile netlist
        # -----------------
        netlist = {}
        #console.log "* Compiling schema: #{@name}"
        for id, conn-list of @flatten-netlist
            # TODO: performance improvement:
            # use find-comp for each component only one time
            net = [] # cache (list of connected nodes)
            for full-name in conn-list
                {name, pin, link, raw} = parse-name full-name, do
                    prefix: @prefix
                    external: @external-components
                #console.log "Searching for entity: #{name} and pin: #{pin}, pfx: #{@prefix}"
                if @is-link full-name
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
                        else if name of @data.netlist
                            # This is a connection name, silently skip it 
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

        unless @parent
            #console.log "Flatten netlist:", @flatten-netlist
            #console.log "Netlist (raw) (includes links and cross-links): ", netlist

            # Create the cleaned up @netlist (arrays of arrays of Pad objects)
            @netlist.length = 0
            for id of netlist
                net = get-net netlist, id
                unless empty net
                    @netlist.push net

            # build the @connection-list
            @build-connection-list!

            # Check errors
            @post-check!

            # Output the generated report
            #console.log "... Schema: #{@name}, Connection list:", @connection-list
            #console.log "... Schema: #{@name}, Netlist:", @netlist

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
