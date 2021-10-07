require! './deps': {text2arr}
require! './lib': {flatten-obj, net-merge}
require! 'dcs/lib/test-utils': {make-tests}
require! 'prelude-ls': {values}


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
            # match with numbered nodes, like 
            if _rest.1?match /[a-zA-Z_]/ 
                x 
            else 
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

    "iface definition with numeric like label": -> 
        debugger 
        {_netlist} = post-process-netlist do         
            netlist: 
                1: "a.1 b.2 c.1"
                "5v": "c.2 d.1"
                2: "d.2 5v"
            iface: "d.1 b.2"

        expect _netlist
        .to-equal do 
            2: <[ a.1 b.2 c.1 ]>
            1: <[ d.2 c.2 d.1 ]>       

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

    "multiple iface definition for the same net": ->  
        # TODO: 
        # ------
        # What should be the correct behavior when user wanted to 
        # assign multiple labels to the same net?
        return false 

        {_netlist, _iface, _data_netlist} = post-process-netlist do 
            iface: "c1.1a,c1.1y,c1.1z,c1.2z,
                c1.2y,c1.2a,c1.3a,c1.3y,c1.3z,
                c1.4z,c1.4y,c1.4a c1.vcc c1.gnd,
                c1.g c1.n_g"

            netlist:
                "vcc": "c1.vcc c2.a"
                "gnd": "c1.gnd c2.c c1.g c1.n_g" 