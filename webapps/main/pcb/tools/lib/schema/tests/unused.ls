require! '../schema': {Schema}

export do
    "unused pads": ->
        open-collector =
            # open collector output
            iface: "Input, Output, gnd"
            bom:
                NPN: 'Q1'
                "SMD1206": "R1"
            netlist:
                Input: 'R1.1'
                2: 'Q1.b' # R1.2
                gnd: 'Q1.e'
                Output: 'Q1.c'

        sch = new Schema {name: 'test', data: open-collector,  namespace: 'test'}

        expect (-> sch.compile!)
        .to-throw "Unused pads: test.R1.2"

        # cleanup canvas
        sch.remove-footprints!

    "in sub-circuit": ->
        open-collector =
            # open collector output
            iface: "Input, Output, gnd"
            bom:
                NPN: 'Q1'
                "SMD1206": "R1"
            netlist:
                1: "Q1.b R1.1"
                in: "R1.2"
                gnd: "Q1.e"
                out: "Q1.c"

        some-parent =
            schemas: {open-collector}
            netlist:
                1: "A.in"
            bom:
                open-collector: 'A'


        sch = new Schema {name: 'test', data: some-parent,  namespace: 'test'}

        expect (-> sch.compile!)
        .to-throw "Unconnected iface: test.A.Input, test.A.Output"

        # cleanup canvas
        sch.remove-footprints!

    "in sub-circuit unused": ->
        open-collector =
            # open collector output
            iface: "Input, Output, gnd"
            bom:
                NPN: 'Q1'
                "SMD1206": "R1"
            netlist:
                1: "Q1.b R1.1"
                Input: "R1.2"
                gnd: "Q1.e"
                Output: "Q1.c"

        some-parent =
            schemas: {open-collector}
            netlist:
                1: "A.Input"
            bom:
                open-collector: 'A'


        sch = new Schema {name: 'test', data: some-parent,  namespace: 'test'}

        expect (-> sch.compile!)
        .to-throw "Unused pads: test.A.Output, test.A.gnd"

        # cleanup canvas
        sch.remove-footprints!

    "false unused pads": ->
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
            no-connect: 
                'R1.2'

        sch = new Schema {name: 'test', data: open-collector,  namespace: 'test'}

        expect (-> sch.compile!)
        .to-throw "False unused pads: test.R1.2"

        # cleanup canvas
        sch.remove-footprints!
