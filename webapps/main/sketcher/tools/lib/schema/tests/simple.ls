require! '../schema': {Schema}

open-collector =
    # open collector output
    iface: "Input, Output, gnd"
    bom:
        NPN: 'Q1'
        "SMD1206": "R1"
    netlist:
        1: 'R1.1 Input'
        2: 'Q1.b R1.2'
        gnd: 'Q1.e'
        3: 'Q1.c Output'

push-pull =
    iface: "Input, Output, Vcc, gnd"
    schemas: {open-collector}
    bom:
        PNP: 'Q1'
        open-collector: 'C1'
        "SMD1206": "R1, R2"
    netlist:
        gnd: 'C1.gnd'
        1: "C1.Input R1.1 R2.2 Input"
        2: "R1.2 Vcc"
        3: "Q1.e Output C1.Output"
        4: "Q1.b R2.1"

export do
    1: ->
        sch = new Schema {name: 'test', data: open-collector, prefix: 'test.'}
            ..compile!

        flatten-netlist =
            1: <[ R1.1 Input ]>
            2: <[ Q1.b R1.2 ]>
            3: <[ Q1.c Output ]>
            gnd: <[ Q1.e ]>
            Input: []
            Output: []

        expect sch.flatten-netlist
        .to-equal flatten-netlist

        # cleanup canvas
        sch.remove-footprints!

    'sub-circuit': ->
        sch = new Schema {name: 'test', data: push-pull, prefix: 'test.'}
            ..compile!

        flatten-netlist =
            gnd: <[ C1.gnd ]>
            1: <[ C1.Input R1.1 R2.2 Input ]>
            2: <[ R1.2 Vcc ]>
            3: <[ Q1.e Output C1.Output ]>
            4: <[ Q1.b R2.1 ]>
            Input: []
            Output: []
            Vcc: []

            # sub-circuit netlist
            "C1.1": <[ C1.R1.1 C1.Input ]>
            "C1.2": <[ C1.Q1.b C1.R1.2 ]>
            "C1.3": <[ C1.Q1.c C1.Output ]>
            "C1.gnd": <[ C1.Q1.e ]>
            "C1.Input": []
            "C1.Output": []

        expect sch.flatten-netlist
        .to-equal flatten-netlist

        # cleanup canvas
        sch.remove-footprints!
