# --------------------------------------------------
# all lib* scripts will be included automatically.
#
# This script will also be treated as a library file.
# --------------------------------------------------
parasitic = (value) ->
    iface: 'a, c'
    netlist:
        a: "C1.a C2.a"
        c: "C1.c C2.c"
    bom:
        C1206:
            "10nF": "C1"
            "1uF": "C2"

power-parasitic = (value) ->
    iface: 'a, c'
    netlist:
        a: "C1.a C2.a C3.a"
        c: "C1.c C2.c C3.c"
    bom:
        C1206:
            "100nF": "C1, C2"
            "4.7uF": "C3"

power = (args) ->
    vin = args?.vin or '24V'
    (value) ->
        # Power Layer
        # Input: 9-30V, Output: 5V and 3.3V
        iface: 'vff, vfs, 5v, 3v3, gnd'
        bom:
            'LM2576':
                "5V": 'C1'
            'LM1117': 'C2'
            TestBoundary1206: "R1, R2"
            'C1206':
                "100uF,>#{math.evaluate "#{vin}*1.5"}": 'C13'
                "10uF": "C11"
            "CAP_thd":
                "1000uF,16V": "C10"
            'Inductor_thd':
                "100..360uH,2A": 'L1'
            'DO214AC':
                '1N5822': 'D14, D13, D15'
            parasitic: "C3"
        netlist:
            # Trace_id: "list, of, connected, pads"
            1: "C1.vin, vfs, C13.a"
            gnd: """
                C13.c C1.gnd C1.onoff
                D15.a C10.c C2.gnd D14.a C11.c
                C3.c
                """
            2: 'C1.out, L1.1, D15.c'
            "5v": """
                L1.2 C1.fb C10.a
                R1.1
                C2.vin
                C3.a
                """
            "3v3": 'C11.a R2.1 C2.vout'
            vff: 'D13.a'
            vfs: 'D13.c, D14.c'
        schemas: {parasitic}
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

oc-output = (args) ->
    r-value = args?R?value or "300ohm"
    q-value = args?Q?value or "2N2222"
    (value) ->
        # Open Collector Output
        iface: "out, in, gnd"
        netlist:
            1: "Q1.b R1.1"
            in: "R1.2"
            gnd: "Q1.e"
            out: "Q1.c"
        bom:
            NPN:
                "#{q-value}": "Q1"
            SMD1206:
                "#{r-value}": "R1"


signal-led = (args) ->
    color = args?color or "red"
    (value) ->
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
                "#{color}": "D1"  # Led
            SMD1206:
                "330 ohm": "R1" # Current limiting resistor

buzzer = (value) ->
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


oc-sensor = (args) ->
    conn = args?.socket or "Conn_3pin_2_54_thd"
    (value) ->
        iface: "vcc gnd out"
        netlist:
            vcc: "conn.1"
            out: "conn.2"
            gnd: "conn.3"
        bom:
            "#{conn}": "conn"


debounce_switch = (value) ->
    # connect the mechanical switch
    # between a and b pins
    iface: "vcc gnd out a b"
    netlist:
        vcc: "R1.1"
        a: "R1.2 R2.1"
        out: "R2.2 C1.a"
        gnd: "b C1.c"
    bom:
        SMD1206:
            "10K": "R1"
            "330": "R2"
        C1206:
            "100nF": "C1"

stm32f103_bare = (value) ->
    iface: """vdd, gnd
        PC13
        PC14
        PC15
        PD0
        PD1
        PA0
        PA1
        PA2
        PA3
        PA4
        PA5
        PA6
        PA7
        PB0
        PB1
        PB2
        PB10
        PB11
        PB12
        PB13
        PB14
        PB15
        PA8
        PA9
        PA10
        PA11
        PA12
        SWDIO
        SWCLK
        PA15
        PB3
        PB4
        PB5
        PB6
        PB7
        PB8
        PB9
        """
    netlist:
        gnd: """m.VSSA m.VSS_1 m.VSS_2 m.VSS_3
            c1.c c2.c c3.c c4.c c5.c
            R1.2
            c6.c
            """
        vdd: """m.VBAT m.VDDA m.VDD_1 m.VDD_2
            m.VDD_3
            c1.a c2.a c3.a c4.a c5.a
            """
        1: "m.Boot0 R1.1"
        2: "m.NRST c6.a"
        PC13: \m.PC13
        PC14: \m.PC14
        PC15: \m.PC15
        PD0: \m.PD0
        PD1: \m.PD1
        PA0: \m.PA0
        PA1: \m.PA1
        PA2: \m.PA2
        PA3: \m.PA3
        PA4: \m.PA4
        PA5: \m.PA5
        PA6: \m.PA6
        PA7: \m.PA7
        PB0: \m.PB0
        PB1: \m.PB1
        PB2: \m.PB2
        PB10: \m.PB10
        PB11: \m.PB11
        PB12: \m.PB12
        PB13: \m.PB13
        PB14: \m.PB14
        PB15: \m.PB15
        PA8: \m.PA8
        PA9: \m.PA9
        PA10: \m.PA10
        PA11: \m.PA11
        PA12: \m.PA12
        SWDIO: \m.SWDIO
        SWCLK: \m.SWCLK
        PA15: \m.PA15
        PB3: \m.PB3
        PB4: \m.PB4
        PB5: \m.PB5
        PB6: \m.PB6
        PB7: \m.PB7
        PB8: \m.PB8
        PB9: \m.PB9
    schemas: {parasitic}
    bom:
        STM32F103C8: 'm'
        parasitic: "c1, c2, c3, c4"
        C1206:
            "4.7uF": "c5"
            "100nF": "c6"
        SMD1206:
            "10K": "R1"
    notes:
        "c5": "Must be connected to VDD_3
            according to the datasheet"
        "m":
            "Boot": "If SWD pins became unusable, only
                way to load the binary is using USART1 port"
            "NRST": "Pull down to reset the MCU"

stm32f030f4_bare = (value) ->
    description: """ Filter capacitors are attached
        regarding to Power Supply Scheme in the
        datasheet.
        """
    iface: """vdd, gnd,
        PF0
        PF1
        NRST
        PA0
        PA1
        PA2
        PA3
        PA4
        PA5
        PA6
        PA7
        PB1
        PA9
        PA10
        SWDIO
        SWCLK
        """
    netlist:
        gnd: """m.VSS c1.c c2.c R1.2 c3.c"""
        vdd: """m.VDDA m.VDD c1.a c2.a"""
        1: "m.Boot0 R1.1"

        PF0: \m.PF0
        PF1: \m.PF1
        NRST: "m.NRST c3.a"

        PA0: \m.PA0
        PA1: \m.PA1
        PA2: \m.PA2
        PA3: \m.PA3
        PA4: \m.PA4
        PA5: \m.PA5
        PA6: \m.PA6
        PA7: \m.PA7
        PA9: \m.PA9
        PA10: \m.PA10
        SWDIO: \m.PA13   # SWDIO
        SWCLK: \m.PA14   # SWCLK
        PB1: \m.PB1

    schemas: {power-parasitic, parasitic}
    bom:
        STM32F030_20: 'm'
        power-parasitic: "c1"
        parasitic: "c2"
        SMD1206:
            "10K": "R1"
        C1206:
            "100nF": "c3"

    notes:
        "Caution": """
            Filter capacitors must be placed as close
            as possible to, or below, the appropriate
            pins on the underside of the PCB to ensure
            the good functionality of the device.
            (Datasheet, 6.1.6 Power supply scheme)
            """


half-bridge = (args) ->
    mosfet = args?M or \NMos
    (value) ->
        iface: "vcc, gnd, out, hs, ls"
        bom:
          "#{mosfet}": "hs ls"
          C1206:
            "10uF": "c1"
        netlist:
          hs: "hs.g"
          ls: "ls.g"
          vcc: "hs.d c1.a"
          out: "hs.s ls.d"
          gnd: "ls.s c1.c"

full-bridge = (args) ->
    (value) ->
        sense-r = args?R or "Sense1206"
        mosfet = args?M or \NMos
        schema =
            iface: "vcc, gnd, out1, out2,
              hs1, ls1, hs2, ls2,
              sense+ sense-"
            bom:
                half-bridge: "br1 br2"
                sense-r:
                  "#{value or '50mohm'}": "r1"
            schemas: {
                half-bridge: half-bridge {M: mosfet}
                sense-r
                }
            netlist:
              vcc: "br1.vcc br2.vcc"
              1: "br1.gnd br2.gnd r1.1"
              gnd: "r1.2"
              out1: "br1.out"
              out2: "br2.out"
              hs1: "br1.hs"
              ls1: "br1.ls"
              hs2: "br2.hs"
              ls2: "br2.ls"
              "sense+": "r1.sense1"
              "sense-": "r1.sense2"

parallel-r = (args) ->
    type = args?.type or \SMD1206
    (value) ->
        r = math.evaluate "#{value} * 2"
        schema =
            iface: "1 2"
            bom:
                "#{type}":
                    "#{r}": "r1 r2"
            netlist:
                1: "r1.1 r2.1"
                2: "r1.2 r2.2"

parallel-sense = (args) ->
    type = args?.type or \Sense1206
    (value) ->
        r = math.evaluate "#{value} * 2"
        schema =
            iface: "1 2 sense1 sense2"
            bom:
                "#{type}":
                    "#{r}": "r1 r2"
            netlist:
                1: "r1.1 r2.1"
                2: "r1.2 r2.2"
                sense1: "r1.sense1 r2.sense1"
                sense2: "r1.sense2 r2.sense2"

drv8711-bare = (args) ->
    # Supply voltage
    vcc = args?vcc or \50V

    # Mosfet to be used in H bridges
    mosfet = args?mosfet or \IRFR024

    (value) ->
        iface: """vcc, gnd
          pulse, dir,
          spi_clk, mosi, miso, scs
          sleep_n reset V5
          A+ A- B+ B-"""
        netlist:
            vcc: """c.VM c2.a c3.a c4.a
                a.vcc b.vcc
                """
            gnd: """c.GND1 c.GND2 c.GND3
                c3.c c4.c c5.c c6.c
                c.BIN1 c.BIN2 c7.c
                a.gnd b.gnd
                """
            pulse: 'c.STEP_AIN1'
            dir: 'c.DIR_AIN2'
            spi_clk: 'c.SCLK'
            mosi: 'c.SDATI'
            miso: 'c.SDATO'
            1: 'c.CP1 c1.a'
            2: 'c.CP2 c1.c'
            3: 'c2.c c.VCP'
            V5: 'c.V5 c5.a c.SLEEPn sleep_n'
            5: 'c.VINT c6.a'
            6: 'c.BEMF c7.a'
            # H-bridge connections
            # bridge a
            7: "c.AOUT1 a.out1 A+"
            8: "c.A1HS a.hs1"
            9: "c.A1LS a.ls1"
            10: "c.AISENP a.sense+ c8.a"
            21: "c.AISENN a.sense- c8.c"
            11: "c.A2HS a.hs2"
            12: "c.A2LS a.ls2"
            13: "c.AOUT2 a.out2 A-"
            # bridge b
            14: "c.BOUT1 b.out1 B+"
            15: "c.B1HS b.hs1"
            16: "c.B1LS b.ls1"
            17: "c.BISENP b.sense+ c9.a"
            22: "c.BISENN b.sense- c9.c"
            18: "c.B2HS b.hs2"
            19: "c.B2LS b.ls2"
            20: "c.BOUT2 b.out2 B-"
            #
            scs: "c.SCS"
            reset: "c.RESET"
            faultn: "c.FAULTn"
            stalln: "c.STALLn_BEMFVn"
        schemas: {
            full-bridge: full-bridge({
                R: parallel-sense!
                M: mosfet
                })
        }
        bom:
            DRV8711: 'c'
            C1206:
                "100nF >#{vcc} X7R": 'c1'
                "100nF 10V X7R": "c5"
                '1uF 16V X7R L-ESR': 'c2'
                "1uF 6.3V X7R": "c6"
                '1uF': 'c7'
                '10nF': 'c4'
                '1nF': 'c8 c9'
            CAP_thd:
                '100uF L-ESR': 'c3'
            full-bridge: "a b"

        notes: """
            1. See drv8711 datasheet, 10 Layout
            """

p-contact = (args) ->
    # Note: Not used in a real production.
    # Test well.
    Q = args?.Q or "BC640_SOT23"
    (value) ->
        iface: "v+ v- in"
        bom:
            "#{Q}": "c1"
            SMD1206:
                "1K": "r1"
                "330ohm": "r2"

        netlist:
            "v+": "c1.e r1.1"
            1: "c1.b r2.1 r1.2"
            "v-": "c1.c"
            "in": "r2.2"
if __main__?
    TODO "This is a library, no schema is present."