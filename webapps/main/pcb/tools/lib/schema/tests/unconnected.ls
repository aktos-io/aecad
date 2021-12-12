require! '../schema': {Schema}

export do
    "simple unconnected": ->
        open-collector =
            # open collector output
            iface: "Input, Output, gnd"
            bom:
                NPN: 'Q1'
                "SMD1206": "R1"
            netlist:
                Input: 'R1.1'
                2: 'Q1.b R1.2'
                gnd: 'Q1.e'
                Output: 'Q1.c'

        sch = new Schema {name: 'test', data: open-collector, prefix: 'test.'}

        sch.compile!

        unconnected = 0 
        for netid, state of sch.calc-connection-states!
            unconnected += state.unconnected

        expect unconnected
        .to-equal 1

        # cleanup canvas
        sch.remove-footprints!

    "connected one trace": ->
        open-collector =
            # open collector output
            iface: "Input, Output, gnd"
            bom:
                NPN: 'Q1'
                "SMD1206": "R1"
            netlist:
                Input: 'R1.1'
                2: 'Q1.b R1.2'
                gnd: 'Q1.e'
                Output: 'Q1.c'
            virtual-traces: 
                1: "Q1.b R1.2"

        sch = new Schema {name: 'test', data: open-collector, prefix: 'test.'}

        sch.compile!

        unconnected = 0 
        for netid, state of sch.calc-connection-states!
            unconnected += state.unconnected

        expect unconnected
        .to-equal 0

        # cleanup canvas
        sch.remove-footprints!
