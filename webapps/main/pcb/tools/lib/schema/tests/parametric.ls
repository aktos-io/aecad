require! '../schema': {Schema}
require! mathjs


export do
    "simple parametric sub-circuit": ->
        foo = (config)-> 
            (value) -> 
                R = mathjs.evaluate "#{value} * 2"

                # parallel resistors                
                iface: "1 2" # Make it compatible with simple resistor iface.
                netlist:
                    1: "r1.1 r2.1"
                    2: "r1.2 r2.2"
                bom:
                    SMD1206:
                        "#{R}": "r1 r2"

        bar =
            # series resistors
            iface: "a b"
            schemas: {foo: foo!}
            bom:
                foo:
                    '500ohm': "x"
                    "3kohm": "y"
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
        baz = (config) -> 
            (value) -> 
                R = mathjs.evaluate "#{value} * 4"

                # series resistors
                iface: "1 2"
                netlist:
                    1: "r1.a"
                    2: "r2.c"
                    "x": "r1.c r2.a"
                bom:
                    C1206:
                        "#R": "r1 r2"

        foo = (config) -> 
            (value) -> 

                iface: "1 2" 
                netlist:
                    1: "r1.1 r2.1"
                    2: "r1.2 r2.2"
                    3: "r3.1 r3.2"
                schemas: {baz: baz!}
                bom:
                    baz:
                        "2kohm": "r1 r2"
                        "1kohm": "r3"

        bar =
            # series resistors
            iface: "a b"
            schemas: {foo: foo!}
            bom:
                foo:
                    '500ohm': "x"
                    "3kohm": "y"
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
        .to-equal bom-list = [
            {
                "count": 8, 
                "instances": ["test.x.r1.r1", "test.x.r1.r2", "test.x.r2.r1", "test.x.r2.r2", "test.y.r1.r1", "test.y.r1.r2", "test.y.r2.r1", "test.y.r2.r2"], 
                "type": "C1206", 
                "value": "8 kohm"
            }, 
            {
                "count": 4, 
                "instances": ["test.x.r3.r1", "test.x.r3.r2", "test.y.r3.r1", "test.y.r3.r2"], 
                "type": "C1206", 
                "value": "4 kohm"
            }
        ]

        # cleanup canvas
        sch.remove-footprints!

    "factory parametric sub-circuit": ->
        foo = (config) -> 
            type = config?type or "C1206"
            (value) ->         
                R = mathjs.evaluate "#{value} * 2"
                # parallel resistors
                iface: "1 2" # Compatible with stock resistors
                netlist:
                    1: "r1.1 r2.1"
                    2: "r1.2 r2.2"
                bom:
                    "#{type}":
                        "#{R}": "r1 r2"

        bar =
            # series resistors
            iface: "a b"
            schemas: 
                foo_1206: foo({type: "SMD1206"})
            bom:
                foo_1206:
                    '500ohm': "x"
                    "3kohm": "y _z"
            netlist:
                a: "x.2 _z.1"
                b: "y.1 _z.2"
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
