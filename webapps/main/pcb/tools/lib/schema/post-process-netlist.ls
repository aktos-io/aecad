require! './deps': {text2arr}
require! './lib': {flatten-obj, net-merge}
require! 'dcs/lib/test-utils': {make-tests}
require! 'prelude-ls': {values, flatten, unique}


export post-process-netlist = ({netlist, iface, labels}) -> 
    _data_netlist = []
    _iface = []
    _netlist = {}
    # -----------------------------------------------------------
    # Post process the netlist 
    # -----------------------------------------------------------
    internal-numeric = (x) -> 
        # convert numeric keys to semi-numeric (underscore prefixed)
        if _rest=(x.match /^[0-9]+(.*)$/)
            # match with numbered nodes
            if _rest.1?match /[a-zA-Z_]/ 
                # "5V" like strings (numbers followed by letters) are not numbers.
                x 
            else 
                # prefix numbers with underscore
                "_#{x}"
        else
            x

    internal-numeric-netid-syntax = new RegExp /^_[0-9]+/

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
                if netid.match internal-numeric-netid-syntax
                    # that's a number  
                    unless netlabel
                        netlabel = netid
                    continue 
                else 
                    # that's an alphanumeric label, replace with current label 
                    if not netlabel or netlabel.match internal-numeric-netid-syntax
                        netlabel = netid 
                        continue 
                    else 
                        # Add additional netlabel's to the net
                        _net.push netid 
                        continue 
            
            if elem.match internal-numeric-netid-syntax
                # no need for numerical netlabels
                continue 

            _net.push elem 

        netid = iface-label or iface or netlabel
        _netlist[netid] = _net.filter (isnt netid) |> unique 
    # ------------------------------------------------
    # End of temporary section

    unconnected = [] # unconnected interface pins 
    all-elems = flatten [[k, ...v] for k, v of _netlist]
    for i in _iface when i not in all-elems
        unconnected.push i

    if unconnected.length > 0
        s = if unconnected.length > 1 => "s" else ""
        throw new Error "Unconnected interface pin#{s}: #{unconnected.join ", "}"

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
        {_netlist} = post-process-netlist do 
            netlist: 
                1: "a.1 b.2 c.1"
                x: "c.2 d.1"
                y: "d.2 x"

        expect _netlist
        .to-equal do 
            _1: <[ a.1 b.2 c.1 ]>
            x: <[ c.2 d.1 y d.2 ]> 

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
            1: <[ d.2 x c.2 d.1 ]>       

    "iface definition with numeric like label": -> 
        {_netlist} = post-process-netlist do         
            netlist: 
                1: "a.1 b.2 c.1"
                "5v": "c.2 d.1"
                2: "d.2 5v"
            iface: "d.1 b.2"

        expect _netlist
        .to-equal do 
            2: <[ a.1 b.2 c.1 ]>
            1: <[ d.2 5v c.2 d.1 ]>       

    "iface definition within the sub-object": -> 
        return false 
        {_netlist} = post-process-netlist do 
            netlist: 
                1: "a.1 b.2 c.1"
                3: 
                    x: "c.2 d.1"
                2: "d.2 x"
            iface: "1 x"

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

    "multiple iface definition for the same net": ->  
        # User wants to assign multiple labels to the same net
        {_netlist, _iface, _data_netlist} = post-process-netlist do 
            iface: "c1.1a,c1.1y,c1.1z,c1.2z,
                c1.2y,c1.2a,c1.3a,c1.3y,c1.3z,
                c1.4z,c1.4y,c1.4a c1.vcc c1.gnd,
                c1.g c1.n_g"

            netlist:
                "vcc": "c1.vcc c2.a"
                "gnd": "c1.gnd c2.c" 
                "n_g": "c1.n_g gnd"
                "g": "c1.g gnd"

        expect _netlist
        .to-equal {
            "vcc":["c1.vcc","c2.a"],
            "n_g":["gnd","c1.gnd","c2.c","c1.n_g","g","c1.g"],
            "1a":["c1.1a"],
            "1y":["c1.1y"],
            "1z":["c1.1z"],
            "2z":["c1.2z"],
            "2y":["c1.2y"],
            "2a":["c1.2a"],
            "3a":["c1.3a"],
            "3y":["c1.3y"],
            "3z":["c1.3z"],
            "4z":["c1.4z"],
            "4y":["c1.4y"],
            "4a":["c1.4a"]
        }

    "unconnected iface": ->  
        func = -> 
            {_netlist, _iface} = post-process-netlist do 
                netlist: 
                    a: "r1.1 r4.2"
                    2: "r3.1 r2.2"
                iface: "a b"

        expect func
        .to-throw 'Unconnected interface pin: b'

    "multiple unconnected iface": ->  
        func = -> 
            {_netlist, _iface} = post-process-netlist do 
                netlist: 
                    a: "r1.1 r4.2"
                    2: "r3.1 r2.2"
                iface: "a b c"

        expect func
        .to-throw 'Unconnected interface pins: b, c'