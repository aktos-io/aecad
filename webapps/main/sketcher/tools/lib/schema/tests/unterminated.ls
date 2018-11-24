require! '../schema': {Schema}

open-collector =
    # open collector output
    iface: "Input, Output, gnd"
    bom:
        NPN: 'Q1'
        "SMD1206": "R1"
    netlist:
        1: 'R1.1 Input'
        2: 'Q1.b'
        gnd: 'Q1.e'
        3: 'Q1.c Output'

export do
    1: ->
        sch = new Schema {name: 'test', data: open-collector, prefix: 'test.'}

        expect (-> sch.compile!)
        .to-throw "Unterminated pads: test.R1.2"

        # cleanup canvas
        sch.remove-footprints!
