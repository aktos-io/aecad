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
        .to-throw "Components missing in BOM: Q1"

        # cleanup canvas
        sch.remove-footprints!

    "component not found": ->
        sch = new Schema {name: 'test', data: circuit2, prefix: 'test.'}
        expect (-> sch.compile!)
        .to-throw "Can not find type: FOO"

        # cleanup canvas
        sch.remove-footprints!

    'duplicate instance': ->
        circuit2 =
            # open collector output
            iface: "Input, Output, gnd"
            bom:
                FOO: 'Q1'
                "SMD1206": "R1 Q1"

        sch = new Schema {name: 'test', data: circuit2, prefix: 'test.'}
        expect (-> sch.compile!)
        .to-throw "Duplicate instance: Q1"

    "incomplete label declaration": ->
        # TODO: extend a component with some missing labels
        false

    "unconnected iface": ->
        parasitic =
            iface: 'a, c'
            netlist:
                1: "C1.a C2.a"
                c: "C1.c C2.c"
            bom:
                C1206:
                    "100nF": "C1"
                    "1uF": "C2"

        sch = new Schema {name: 'test', data: parasitic, prefix: 'test.'}
        expect (-> sch.compile!)
        .to-throw "Unconnected iface: test.a"

    "improper schematic declaration": -> 
        foo = (args) -> 
            (value) ->         
                iface: "1 2" # Compatible with stock resistors
                netlist:
                    1: "r1.1 r2.1"
                    2: "r1.2 r2.2"
                bom:
                    "SMD1206":
                        "#{r}": "r1 r2"

        bar =
            # series resistors
            iface: "a b"
            schemas: 
                foo: foo
            bom:
                foo:
                    '500ohm': "x"
                    "3kohm": "y"
            netlist:
                a: "x.2"
                b: "y.1"
                1: "x.1 y.2"


        sch = null
        compile-schema = -> 
            sch := new Schema {
                name: 'mytest'
                prefix: 'test.'
                data: bar
                }
                ..compile!

        expect compile-schema
        .to-throw '''Sub-circuit "foo" should be simple function, not a factory function. Did you forget to initialize it?'''

        sch.remove-footprints!
