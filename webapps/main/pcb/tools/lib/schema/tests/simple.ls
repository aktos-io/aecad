require! '../schema': {Schema}

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

push-pull =
    iface: "Input, Output, Vcc, gnd"
    schemas: {open-collector}
    bom:
        PNP: 'Q1'
        open-collector: 'C1'
        "SMD1206": "R1, R2"
    netlist:
        gnd: 'C1.gnd'
        Input: "C1.Input R1.1 R2.2"
        Vcc: "R1.2 Vcc Q1.c"
        Output: "Q1.e C1.Output"
        4: "Q1.b R2.1"

export do
    "correct bom report": -> 
        sch = new Schema do 
            name: "test"
            data: 
                bom: 
                    x: "c1, c2"
                netlist: 
                    1: "c1.1 c2.a"
                    gnd: "c1.2"

        sch.calc-bom!
        
        expect sch.bom
        .to-equal {
            "c1": {
                "data": undefined, 
                "labels": null, 
                "name": "c1", 
                "parent": "test", 
                "type": "x", 
                "value": ""
            }, 
            "c2": {
                "data": undefined, 
                "labels": null, "
                name": "c2", 
                "parent": "test", 
                "type": "x", 
                "value": ""
            }
        }

    "flatten netlist": ->
        sch = new Schema {name: 'test', data: open-collector,  namespace: 'test'}
            ..compile!

        flatten-netlist =
            Input: <[ R1.1 ]>
            _2: <[ Q1.b R1.2 ]>
            Output: <[ Q1.c ]>
            gnd: <[ Q1.e ]>

        expect sch.flatten-netlist
        .to-equal flatten-netlist

        # cleanup canvas
        sch.remove-footprints!

    'sub-circuit': ->
        sch = new Schema {name: 'test', data: push-pull,  namespace: 'test'}
            ..compile!

        expect sch.flatten-netlist
        .to-equal {
            "C1.Input": ["C1.R1.1"], 
            "C1.Output": ["C1.Q1.c"], 
            "C1._2": ["C1.Q1.b", "C1.R1.2"], 
            "C1.gnd": ["C1.Q1.e"], 
            "Input": ["C1.Input", "R1.1", "R2.2"], 
            "Output": ["Q1.e", "C1.Output"], 
            "Vcc": ["R1.2", "Q1.c"], 
            "_4": ["Q1.b", "R2.1"], 
            "gnd": ["C1.gnd"]
        }

        # cleanup canvas
        sch.remove-footprints!

    "indirect connection": ->
        open-collector =
            # open collector output
            iface: "Input, Output, gnd, vcc"
            bom:
                NPN: 'Q1'
                "SMD1206": "R1 R2"
                C1206: "D1"
            netlist:
                Input: 'R1.1'
                2: 'Q1.b R1.2'
                gnd: 'Q1.e'
                Output: 'Q1.c'
                vcc: "D1.a"
                4: "D1.c R2.1"
                5: "R2.2 Q1.c"

        sch = new Schema {name: 'test', data: open-collector,  namespace: 'test'}

        expect sch.compile!
        .to-equal undefined

        # cleanup canvas
        sch.remove-footprints!
