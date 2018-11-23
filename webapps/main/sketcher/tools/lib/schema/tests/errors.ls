require! '../schema': {Schema}

circuit1 =
    # open collector output
    iface: "Input, Output, gnd"
    bom:
        #NPN: 'Q1'
        "SMD1206": "R1"
    netlist:
        1: 'R1.1 Input'
        2: 'Q1.b R1.2'
        gnd: 'Q1.e'
        3: 'Q1.c Output'

circuit2 =
    # open collector output
    iface: "Input, Output, gnd"
    bom:
        FOO: 'Q1'
        "SMD1206": "R1"
    netlist:
        1: 'R1.1 Input'
        2: 'Q1.b R1.2'
        gnd: 'Q1.e'
        3: 'Q1.c Output'

export do
    "missing component in bom": ->
        sch = new Schema {name: 'test', data: circuit1, prefix: 'test.'}
        expect (-> sch.compile!)
        .to-throw "Netlist components missing in BOM: Q1"

        # cleanup canvas
        sch.remove-footprints!

    "component not found": ->
        sch = new Schema {name: 'test', data: circuit2, prefix: 'test.'}
        expect (-> sch.compile!)
        .to-throw "Can not find type: FOO"

        # cleanup canvas
        sch.remove-footprints!
