require! 'dcs/lib/test-utils': {make-tests}
require! './schema': {Schema}

power =
    iface: 'vfs, vff, 5v, 3v3, gnd'
    netlist:
        # Trace_id: "list, of, connected, pads"
        # Power layer
        1: "C1.vin, vfs, C13.a"
        gnd: """
            C13.c C1.gnd C1.onoff
            D15.a C10.c C2.gnd D14.a C11.c
            """
        2: 'C1.out, L1.1, D15.c'
        _5v: """
            L1.2 C1.fb C10.a
            R1.1
            C2.vin
            """
        _3v3: 'C11.a R2.1 C2.vout'
        '5v': 'R1.2'
        '3v3': 'R2.2'
        vff: 'D13.a'
        vfs: 'D13.c, D14.c'
    notes:
        'L1': """
            This part is an EMC source, keep it
            close to LM2576
            """
        'R1, R2': """
            These parts are used in testing step
            """
        'D15': "Should be VERY CLOSE to LM2576"
    bom:
        'LM2576': 'C1'
        'LM1117': 'C2'
        'SMD1206':
            "0 ohm": "R1, R2"
        'C1206':
            "100uF": 'C13'
            "1000uF": "C10"
            "10uF": "C11"
        'Inductor':
            "100..360uH": 'L1'
        'DO214AC':
            '1N5822': 'D14, D13, D15'

led-driver =
    iface: "out, in, Vcc, gnd"
    doc:
        """
        Current sink led driver
        --------------------
        Q1: Driver transistor
        R1: Base resistor
        R2: Current limit resistor

        out: Current sink output
        """
    netlist:
        1: "Q1.b R1.1"
        in: "R1.2"
        gnd: "Q1.e"
        out: "Q1.c"
        Vcc: null
    bom:
        NPN:
            "2N2222": "Q1"
        SMD1206:
            "300 ohm": "R1"

signal-led =
    iface: "gnd, in, vcc"
    netlist:
        vcc: "D1.a DR.Vcc"
        2: "D1.c DR.out"
        in: "DR.in"
        gnd: "DR.gnd"
    params:
        regex: /[a-z]+/
        map: 'color'
    schemas: {led-driver}
    bom:
        led-driver: 'DR'
        C1206:
            "$color": "D1"  # Led
sgw =
    netlist:
        1: 'rpi.gnd gnd'
        gnd: "P.gnd cn.1 Pow- led1.gnd led2.gnd"
        vff: 'P.vff, cn.2, Pow+'
        '3v3': 'P.3v3 rpi.3v3'
        '5v': 'P.5v rpi.5v led1.vcc led2.vcc'
        2: 'led2.in rpi.3'

    schemas: {power, signal-led}
    iface: "Pow+, Pow-"
    bom:
        power: 'P'
        signal-led:
            'red': 'led1'
            'green': 'led2'
        'RpiHeader' : 'rpi'
        'Conn_2pin_thd' : 'cn'

        # Virtual components
        'Conn_1pin_thd' : '_1, _2, _3, _4'

tests = ->
    make-tests "schema", tests =
        1: ->
            sch = new Schema {name: 'sgw', data: sgw}
                ..compile!

            flatten-netlist =
                '1': <[ rpi.gnd gnd ]>
                '2': <[ led2.in rpi.3 ]>
                'gnd': <[ P.gnd cn.1 Pow- led1.gnd led2.gnd ]>
                'vff': <[ P.vff cn.2 Pow+ ]>
                '3v3': <[ P.3v3 rpi.3v3 ]>
                '5v': <[ P.5v rpi.5v led1.vcc led2.vcc ]>
                'Pow+': <[  ]>
                'Pow-': <[  ]>
                'P.1': <[ P.C1.vin P.vfs P.C13.a ]>
                'P.2': <[ P.C1.out P.L1.1 P.D15.c ]>
                'P.gnd': <[ P.C13.c P.C1.gnd P.C1.onoff P.D15.a P.C10.c P.C2.gnd P.D14.a P.C11.c ]>
                'P._5v': <[ P.L1.2 P.C1.fb P.C10.a P.R1.1 P.C2.vin ]>
                'P._3v3': <[ P.C11.a P.R2.1 P.C2.vout ]>
                'P.5v': <[ P.R1.2 ]>
                'P.3v3': <[ P.R2.2 ]>
                'P.vff': <[ P.D13.a ]>
                'P.vfs': <[ P.D13.c P.D14.c ]>
                'led1.2': <[ led1.D1.c led1.DR.out ]>
                'led1.vcc': <[ led1.D1.a led1.DR.Vcc ]>
                'led1.in': <[ led1.DR.in ]>
                'led1.gnd': <[ led1.DR.gnd ]>
                'led1.DR.1': <[ led1.DR.Q1.b led1.DR.R1.1 ]>
                'led1.DR.in': <[ led1.DR.R1.2 ]>
                'led1.DR.gnd': <[ led1.DR.Q1.e ]>
                'led1.DR.out': <[ led1.DR.Q1.c ]>
                'led1.DR.Vcc': <[  ]>
                'led2.2': <[ led2.D1.c led2.DR.out ]>
                'led2.vcc': <[ led2.D1.a led2.DR.Vcc ]>
                'led2.in': <[ led2.DR.in ]>
                'led2.gnd': <[ led2.DR.gnd ]>
                'led2.DR.1': <[ led2.DR.Q1.b led2.DR.R1.1 ]>
                'led2.DR.in': <[ led2.DR.R1.2 ]>
                'led2.DR.gnd': <[ led2.DR.Q1.e ]>
                'led2.DR.out': <[ led2.DR.Q1.c ]>
                'led2.DR.Vcc': <[  ]>

            expect sch.flatten-netlist
            .to-equal flatten-netlist


export schema-tests = (handler) ->
    try
        tests!
        handler!
    catch
        handler e
