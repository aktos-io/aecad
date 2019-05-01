require! '../schema': {Schema}


export do
    "simple parametric sub-circuit": ->
        foo =
            # parallel resistors
            params:
                R: "4Kohm"
            iface: "1 2" # Compatible with stock resistors
            netlist:
                1: "r1.1 r2.1"
                2: "r1.2 r2.2"
            bom:
                SMD1206:
                    "{{R * 2}}": "r1 r2"

        bar =
            # series resistors
            iface: "a b"
            schemas: {foo}
            bom:
                foo:
                    'R:500ohm': "x"
                    "R:3kohm": "y"
            netlist:
                a: "x.2"
                b: "y.1"
                1: "x.1 y.2"


        sch = new Schema {
            name: 'mytest'
            prefix: 'test.'
            data: bar
            }
            ..compile!

        expect sch.get-bom-list!
        .to-equal bom-list =
            * {count: 2, type: "SMD1206", value: "1000 ohm", "instances":["test.x.r1","test.x.r2"]}
            * {count: 2, type: "SMD1206", value: "6 kohm", "instances":["test.y.r1","test.y.r2"]}

        # cleanup canvas
        sch.remove-footprints!

    "break parameter propagation": -> 
        baz =
            # series resistors
            params:
                R: "123ohm"
            iface: "1 2"
            netlist:
                1: "r1.a"
                2: "r2.c"
                "x": "r1.c r2.a"
            bom:
                C1206:
                    "{{R * 4}}": "r1 r2"

        foo =
            # parallel resistors
            params:
                R: "4kohm"
            iface: "1 2" # Compatible with stock resistors
            netlist:
                1: "r1.1 r2.1"
                2: "r1.2 r2.2"
                3: "r3.1 r3.2"
            schemas: {baz}
            bom:
                baz:
                    "2kohm": "r1 r2"
                    "1kohm": "r3"

        bar =
            # series resistors
            iface: "a b"
            schemas: {foo}
            bom:
                foo:
                    'R:500ohm': "x"
                    "R:3kohm": "y"
            netlist:
                a: "x.2"
                b: "y.1"
                1: "x.1 y.2"


        sch = new Schema {
            name: 'mytest'
            prefix: 'test.'
            data: bar
            params:
                Q: \qux
            }
            ..compile!

        expect sch.get-bom-list!
        .to-equal bom-list = [
            {
                "count":12,
                "type":"C1206",
                "value":"492 ohm",
                "instances":[
                    "test.x.r1.r1","test.x.r1.r2","test.x.r2.r1","test.x.r2.r2","test.x.r3.r1",
                    "test.x.r3.r2","test.y.r1.r1","test.y.r1.r2","test.y.r2.r1","test.y.r2.r2",
                    "test.y.r3.r1","test.y.r3.r2"
                    ]
            }
        ]

        # cleanup canvas
        sch.remove-footprints!
