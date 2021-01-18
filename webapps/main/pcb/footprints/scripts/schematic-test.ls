# --------------------------------------------------
# all lib* scripts will be included automatically.
# --------------------------------------------------

parasitic =
    iface: 'a, c'
    netlist:
        a: "C1.a C2.a"
        c: "C1.c C2.c"
    bom:
        C1206:
            "100nF": "C1"
            "1uF": "C2"

power =
    # Power Layer
    # Input: 9-30V, Output: 5V and 3.3V
    iface: 'vfs, vff, 5v, 3v3, gnd'
    netlist:
        # Trace_id: "list, of, connected, pads"
        1: "C1.vin, vfs, C13.a"
        gnd: """
            C13.c C1.gnd C1.onoff
            D15.a C10.c C2.gnd D14.a C11.c
            C3.c
            """
        2: 'C1.out, L1.1, D15.c'
        _5v: """
            L1.2 C1.fb C10.a
            R1.1
            C2.vin
            C3.a
            """
        _3v3: 'C11.a R2.1 C2.vout'
        '5v': 'R1.2'
        '3v3': 'R2.2'
        vff: 'D13.a'
        vfs: 'D13.c, D14.c'
    schemas: {parasitic}
    bom:
        'LM2576': 'C1'
        'LM1117': 'C2'
        'SMD1206':
            "0 ohm": "R1, R2"
        'C1206':
            "100uF": 'C13'
            "10uF": "C11"
        "CAP_thd":
            "1000uF": "C10"
        'Inductor_thd':
            "100..360uH,2A": 'L1'
        'DO214AC':
            '1N5822': 'D14, D13, D15'
        parasitic: "C3"
    notes:
        'L1': """
            This part is an EMC source, keep it
            close to LM2576
            """
        'R1, R2': """
            These parts are used in testing step
            """
        'D15': "Should be VERY CLOSE to LM2576"
        "C3": "Should be close to _5v output"

    tests:
        "full load":
            do: "Connect a load that draws high current"
            expect:
                * "No noise"
                * "No overheat"
                * "No high jitter"

        "Reverse voltage":
            do: "Apply reverse polarity"
            expect:
                * "Stay safe for 1 minute"
                * "No heat"

oc-output =
    # Open Collector Output
    iface: "out, in, gnd"
    netlist:
        1: "Q1.b R1.1"
        in: "R1.2"
        gnd: "Q1.e"
        out: "Q1.c"
    bom:
        NPN:
            "2N2222": "Q1"
        SMD1206:
            "300 ohm": "R1"

signal-led =
    params:
        c: 'green'
    iface: "gnd, in, vcc"
    netlist:
        vcc: "D1.a"
        1: "D1.c R1.1"
        2: "R1.2 DR.out"
        in: "DR.in"
        gnd: "DR.gnd"
    schemas: {oc-output}
    bom:
        oc-output: 'DR'
        C1206:
            "{{c}}": "D1"  # Led
        SMD1206:
            "330 ohm": "R1" # Current limiting resistor

buzzer =
    iface: "gnd, in, vcc"
    schemas: {oc-output}
    bom:
        oc-output: 'D'
        SMD1206:
            "1K": "R1"
        Buzzer: 'b'
    netlist:
        gnd: 'D.gnd'
        in: 'D.in'
        1: 'D.out b.c R1.2'
        vcc: 'b.a R1.1'

sgw =
    iface: "Pow+, Pow-"
    netlist:
        gnd: """ P.gnd cn.1 Pow- led1.gnd
            led2.gnd beep.gnd
            ,rpi.gnd5,rpi.gnd6,rpi.gnd2,rpi.gnd7,rpi.gnd8,rpi.gnd3
            """
        vff: 'P.vff, cn.2, Pow+'
        '5v': 'P.5v rpi.5v led1.vcc led2.vcc'
        2: 'led2.in rpi.7'
        3: 'led1.in rpi.0'
        4: 'rpi.11 beep.in'
        6: 'beep.vcc 5v'
    schemas: {power, signal-led, buzzer}
    bom:
        power: 'P'
        signal-led:
            'c:red': 'led1'
            'c:green': 'led2'
        buzzer: 'beep'
        'RpiHeader' : 'rpi'
        'Conn_2pin_thd' : 'cn'

        # Virtual components start with an underscore
        Bolt : '_1, _2, _3, _4'
        RefCross: '_a _b _c _d'
    no-connect: """rpi.1 rpi.2 rpi.16 rpi.3v3
        rpi.3 rpi.4 rpi.17 rpi.27 rpi.22 rpi.10
        rpi.9 rpi.5 rpi.6 rpi.13 rpi.19 rpi.26
        rpi.14 rpi.15 rpi.18 rpi.23 rpi.24 rpi.25
        rpi.8 rpi.12 rpi.20 rpi.21
        P.vfs P.3v3
        rpi.gnd4,rpi.gnd1
        """

sch = new Schema {name: 'sgw', data: sgw}
    ..clear-guides!
    ..compile!
    ..guide-unconnected!

pcb.ractive.fire 'calcUnconnected'

conn-list-txt = []
for id, net of sch.connection-list
    conn-list-txt.push "#{id}: #{net.map (.uname) .join(',')}"
#pcb.vlog.info conn-list-txt.join '\n\n'

bom-list = "BOM List:\n"
bom-list += "-------------"
for sch.get-bom-list!
    bom-list += "\n#{..count} x #{..type}, #{..value}"
PNotify.info do
    text: bom-list

unless empty upgrades=(sch.get-upgrades!)
    msg = ''
    for upgrades
        msg += ..reason + '\n\n'
        pcb.selection.add do
            aeobj: ..component
    # display a visual message
    pcb.vlog.info msg

PNotify.notice hide: yes, text: """
    TODO:
    * Lights should be turned on upon sgw energized.
    """
