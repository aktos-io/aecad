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
        sch = new Schema {name: 'test', data: circuit1,  namespace: 'test'}
        expect (-> sch.compile!)
        .to-throw "Components missing in BOM: Q1"

        # cleanup canvas
        sch.remove-footprints!

    "component not found": ->
        sch = new Schema {name: 'test', data: circuit2,  namespace: 'test'}
        expect (-> sch.compile!)
        .to-throw "Can not find type: FOO"

        # cleanup canvas
        sch.remove-footprints!

    'duplicate instance': ->
        circuit2 =
            bom:
                FOO: 'Q1'
                "SMD1206": "R1 Q1"

        sch = new Schema {name: 'test', data: circuit2,  namespace: 'test'}
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

        sch = new Schema {name: 'test', data: parasitic,  namespace: 'test'}
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
                namespace: 'test'
                data: bar
                }
                ..compile!

        expect compile-schema
        .to-throw '''Sub-circuit "foo" should be simple function, not a factory function. Did you forget to initialize it?'''

        sch.remove-footprints!

    "unconnected pins of Sub-circuit": -> 
        AM26C31x_circuit = (config) -> # provides this
            # config:
            #   variant: AM26C31x variant
            (value) ->
                iface: "c1.1a,c1.1y,c1.1z,c1.g,c1.2z,
                    c1.2y,c1.2a,c1.3a,c1.3y,c1.3z,c1.n_g,
                    c1.4z,c1.4y,c1.4a,c1.vcc,c1.gnd"

                netlist:
                    "vcc": "c1.vcc c2.a"
                    "gnd": "c1.gnd c2.c"
                bom:
                    AM26C31x:
                        "#{config.variant}": "c1"
                    C1206:
                        "100nF": "c2"

        example =
            iface: "+3v3 gnd A1 B1"
            schemas:
                AM26C31D_std: AM26C31x_circuit({variant: "D"})
            bom:
                AM26C31D_std: "x1"
            netlist:
                "+3v3": "x1.vcc"
                "gnd": "x1.gnd"
                "A1": "x1.1y"
                "B1": "x1.1z"


        sch = null
        compile-schema = -> 
            sch := new Schema {
                name: 'mytest'
                namespace: 'test'
                data: example
                }
                ..compile!

        expect compile-schema
        .to-throw '''Unused pads: test.x1.1a, test.x1.g, test.x1.2z, test.x1.2y, test.x1.2a, test.x1.3a, test.x1.3y, test.x1.3z, test.x1.n_g, test.x1.4z, test.x1.4y, test.x1.4a'''
        sch.remove-footprints!
