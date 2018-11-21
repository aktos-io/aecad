export {
'find-test': '''
  # --------------------------------------------------
  # all lib* scripts will be included automatically.
  # --------------------------------------------------
  c1 = find-comp "c1"
  c1-pins = c1?.get {pin: 1}
  
  c3 = find-comp "c3"
  c3-pins = c3?.get {pin: 33}
  
  
'''
'class-approach-test': '''
  # Example imaginary footprint 
  # ---------------------------
  fp = new Footprint do 
      name: 'foo'
      symmetry-axis: 'x'
  
  pad1 = new Pad fp, do
      pin: 1
      width: 5
      height: 15
  
  c = new Container fp
  
  for index in [1 to 5]
      pad = new Pad c, do 
          pin: index
          width: 1mm
          height: 2mm
  
      pad.position.y -= 16 * index
      
  c.position = pad1.position
  c.position.x += 23
  
  c2 = new Container fp
  
  for index in [1 to 5]
      pad = new Pad c2, do 
          pin: "#{index}c"
          dia: 3mm
          drill: 1mm
  
      pad.position.y -= 16 * index
  
  c2.position = c.position
  c2.position.x += 10
  
      
  #fp.color = 'red'
  #fp.rotate 45
  
  ## Now find the component by its name 
  ## ----------------------------------
  x = find-comp 'foo'
  #<~ sleep 500ms
  #x.rotate -45
  x.mirror!
  #x.print-mode = yes 
  
'''
'canvas-helper': '''
  cross = new class CanvasHelper extends Container 
      -> 
          super!
          new Path.Line do
              from: [-50, 0]
              to: [50, 0]
              stroke-color: \\white
              parent: @g
              
          new Path.Line do
              from: [0, -50]
              to: [0, 50]
              stroke-color: \\white
              parent: @g
              
          @g.opacity = 0.5
          @g.data.canvas-helper = true 
          
      print-mode: (val) -> 
          @g.remove!
  
'''
'pin-array-test': '''
  a = new PinArray do
      name: 'mypins1'
      pad:
          width: 2mm
          height: 1.2mm
      cols:
          count: 6
          interval: 3.34mm
      rows:
          count: 4
          interval: 2.54mm
      dir: '-y' # numbering direction, 'x' or 'y', default 'x'
  
  
'''
'rpi-header-test': '''
  
  # --------------------------------------------------
  # all lib* scripts will be included automatically.
  # --------------------------------------------------
  new RpiHeader do
      name: 'rpi2'
  
  
  /*
  x = find-comp 'rpi2'
  <~ sleep 500ms
  x.rotate -45
  <~ sleep 500ms
  x.rotate -45
  */
'''
'schematic-test': '''
  # --------------------------------------------------
  # all lib* scripts will be included automatically.
  # --------------------------------------------------
          
  
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
  
  sch = new Schema {name: 'sgw', data: sgw}
      ..clear-guides!
      ..compile!
      #..guide-all!
      ..guide-unconnected!
  
  /*    
  out = []
  for k, v of sch.flatten-netlist
      out.push "'#{k}': <[ #{v.join ' '} ]>"
  console.log out.join('\\n')
  */
      
  pcb.ractive.fire 'calcUnconnected'
  
  upgrades = sch.get-upgrades!
  unless empty upgrades
      pcb.vlog.info upgrades.map((.reason)).join('\\n\\n')
  
'''
'lib-PinArray': '''
  add-class class PinArray extends Footprint
      (data) -> 
          super ...
          if data.parent
              throw "how do we have parent?"
          unless @resuming
              #console.log "Creating from scratch PinArray"
              start = data.start or 1
              unless data.cols
                  data.cols = {count: 1}
              unless data.rows
                  data.rows = {count: 1}
              for cindex to data.cols.count - 1
                  for rindex to data.rows.count - 1
                      pin-num = start + switch (data.dir or 'x')
                      | 'x' => 
                          cindex + rindex * data.cols.count
                      | '-x' => 
                          data.cols.count - 1 - cindex + rindex * data.cols.count
                      | 'y' =>
                          rindex + cindex * data.rows.count
                      | '-y' =>
                          data.rows.count - 1 - rindex + cindex * data.rows.count
  
                      pin-label = data.labels?[pin-num]
                      
                      p = new Pad data.pad <<< do
                          pin: pin-num
                          label: if data.labels? => (pin-label or '?') 
                          parent: this
                          
                      p.position.y += (data.rows.interval or 0 |> mm2px) * rindex 
                      p.position.x += (data.cols.interval or 0 |> mm2px) * cindex 
              
              
              if data.mirror
                  # useful for female headers 
                  @mirror!
                  
              @make-border!
                  
'''
'lib-RpiHeader': '''
  #! requires PinArray
  # --------------------------------------------------
  # all lib* scripts will be included automatically.
  #
  # This script will also be treated as a library file.
  # --------------------------------------------------
  table = table2obj {key: 'Physical', value: 'BCM'}, """
  +-----+-----+---------+------+---+---Pi 3---+---+------+---------+-----+-----+
  | BCM | wPi |   Name  | Mode | V | Physical | V | Mode | Name    | wPi | BCM |
  +-----+-----+---------+------+---+----++----+---+------+---------+-----+-----+
  | 3v3 | 3v3 |    3.3v |      |   |  1 || 2  |   |      | 5v      | 5v  | 5v  |
  |   2 |   8 |   SDA.1 | ALT0 | 1 |  3 || 4  |   |      | 5V      | 5v  | 5v  |
  |   3 |   9 |   SCL.1 | ALT0 | 1 |  5 || 6  |   |      | 0v      | gnd | gnd |
  |   4 |   7 | GPIO. 7 |   IN | 1 |  7 || 8  | 1 | ALT5 | TxD     | 15  | 14  |
  | gnd | gnd |      0v |      |   |  9 || 10 | 1 | ALT5 | RxD     | 16  | 15  |
  |  17 |   0 | GPIO. 0 |   IN | 0 | 11 || 12 | 0 | IN   | GPIO. 1 | 1   | 18  |
  |  27 |   2 | GPIO. 2 |   IN | 0 | 13 || 14 |   |      | 0v      | gnd | gnd |
  |  22 |   3 | GPIO. 3 |   IN | 0 | 15 || 16 | 0 | IN   | GPIO. 4 | 4   | 23  |
  | 3v3 | 3v3 |    3.3v |      |   | 17 || 18 | 0 | IN   | GPIO. 5 | 5   | 24  |
  |  10 |  12 |    MOSI | ALT0 | 0 | 19 || 20 |   |      | 0v      | gnd | gnd |
  |   9 |  13 |    MISO | ALT0 | 0 | 21 || 22 | 0 | IN   | GPIO. 6 | 6   | 25  |
  |  11 |  14 |    SCLK | ALT0 | 0 | 23 || 24 | 1 | OUT  | CE0     | 10  | 8   |
  | gnd | gnd |      0v |      |   | 25 || 26 | 1 | OUT  | CE1     | 11  | 7   |
  |   0 |  30 |   SDA.0 |   IN | 1 | 27 || 28 | 1 | IN   | SCL.0   | 31  | 1   |
  |   5 |  21 | GPIO.21 |   IN | 1 | 29 || 30 |   |      | 0v      | gnd | gnd |
  |   6 |  22 | GPIO.22 |   IN | 1 | 31 || 32 | 0 | IN   | GPIO.26 | 26  | 12  |
  |  13 |  23 | GPIO.23 |   IN | 0 | 33 || 34 |   |      | 0v      | gnd | gnd |
  |  19 |  24 | GPIO.24 |   IN | 0 | 35 || 36 | 0 | IN   | GPIO.27 | 27  | 16  |
  |  26 |  25 | GPIO.25 |   IN | 0 | 37 || 38 | 0 | IN   | GPIO.28 | 28  | 20  |
  | gnd | gnd |      0v |      |   | 39 || 40 | 0 | IN   | GPIO.29 | 29  | 21  |
  +-----+-----+---------+------+---+----++----+---+------+---------+-----+-----+
  | BCM | wPi |   Name  | Mode | V | Physical | V | Mode | Name    | wPi | BCM |
  +-----+-----+---------+------+---+---Pi 3---+---+------+---------+-----+-----+
  """
  
  add-class class RpiHeader extends PinArray
      (data={}) -> 
          defaults =
              name: 'rpi_'
              pad:
                  width: 3.1mm
                  height: 1.5mm
              cols:
                  count: 2
                  interval: 5.3mm
              rows:
                  count: 20
                  interval: 2.54mm
              dir: 'x'
              labels: table
              mirror: yes
              
          data = defaults <<< data 
          super data
  
'''
'lib-SMD1206': '''
  #! requires PinArray 
  # From http://www.resistorguide.com/resistor-sizes-and-packages/
  smd1206 =
      a: 1.6mm
      b: 0.9mm
      c: 2mm
  
  {a, b, c} = smd1206
  
  add-class class SMD1206 extends PinArray
      (data={}) -> 
          defaults =
              name: 'r_'
              pad:
                  width: b
                  height: a
              cols:
                  count: 2
                  interval: c + b
              border:
                  width: c
                  height: a
  
          super defaults <<< data 
  
  #new SMD1206
  
  add-class class SMD1206_pol extends SMD1206
      # Polarized version of SMD1206
      (data={}) -> 
          overrides = 
              name: 'c_'
              labels:
                  1: 'c'
                  2: 'a'
              mark: yes
          
          super overrides <<< data 
  
  add-class class LED1206 extends SMD1206_pol
  add-class class C1206 extends SMD1206_pol
  
  add-class class DO214AC extends SMD1206_pol
      (data={}) -> 
          overrides =
              name: 'd_'
              pad:
                  width: 1.27mm
                  height: 2.10mm
              cols:
                  count: 2
                  interval: 2.70mm
  
          super overrides <<< data 
  
'''
'lib-LM2576': '''
  #! requires TO263
  add-class class LM2576 extends TO263
      (data={}) -> 
          defaults = 
              labels: 
                  # Pin_id: Label
                  1: \\vin 
                  6: \\vin
                  2: \\out
                  3: \\gnd
                  4: \\fb 
                  5: \\onoff
          super data <<< defaults
  
  #a = new LM2576
  #a.get {pin: 'vin'}
'''
'lib-TO263': '''
  # TO263 footprint 
  #
  #! requires DoublePinArray
  # ---------------------------
  
  dimensions = 
      # See http://www.ti.com/lit/ds/symlink/lm2576.pdf
      to263:
          H   : 14.17mm
          die : x:8mm     y:10.8mm
          pads: x:2.16mm  y:1.07mm
          pd  : 1.702
  
  add-class class TO263 extends DoublePinArray
      (data={}) -> 
          {H, die, pads, pd} = dimensions.to263
          defaults =
              name: 'c_'
              distance: H - die.x/2
              left: 
                  start: 6
                  pad:
                      width: die.x
                      height: die.y
                  cols:
                      count: 1
              right:
                  dir: '-y'
                  pad:
                      width: pads.x
                      height: pads.y
                  rows:
                      count: 5
                      interval: pd
  
          super defaults <<< data 
  
  #new TO263
  
'''
'lib-Conn': '''
  #! requires PinArray
  add-class class Conn_2pin_thd extends PinArray
      (data={}) -> 
          defaults =
              name: 'conn_'
              pad:
                  dia: 3.1mm
                  drill: 1mm
              cols:
                  count: 2
                  interval: 3.81mm
              rows:
                  count: 1
              dir: 'x'
  
          data = defaults <<< data 
          super data
  
  add-class class Conn_1pin_thd extends PinArray
      (data={}) -> 
          defaults =
              name: 'conn_'
              pad:
                  dia: 3.1mm
                  drill: 1mm
              cols:
                  count: 1
              rows:
                  count: 1
              dir: 'x'
  
          data = defaults <<< data 
          super data
  
  #new Conn_2pin_thd
  #new Conn_1pin_thd
  
'''
'lib-Inductor': '''
  # --------------------------------------------------
  # all lib* scripts will be included automatically.
  #
  # This script will also be treated as a library file.
  # --------------------------------------------------
  
  #! requires PinArray
  add-class class Inductor extends PinArray
      (data={}) -> 
          defaults =
              name: 'L_'
              pad:
                  width: 4mm
                  height: 4.5mm
              cols:
                  count: 2
                  interval: 8mm
              border:
                  width: 10.7mm
                  height: 10.2mm
  
          data = defaults <<< data 
          super data
  
  #new Inductor
'''
'lib-DoublePinArray': '''
  add-class class DoublePinArray extends Footprint
      (data) -> 
          super ...
          unless @resuming
              overwrites = 
                  parent: @
                  labels: data.labels
  
              left = new PinArray data.left <<< overwrites
              right = new PinArray data.right <<< overwrites
              right.position = left.position.add [data.distance |> mm2px, 0]
              @make-border!
'''
'double-pin-array-test': '''
  a = new SOT223 do
      name: 'hello'
  
  console.log a.get {pin: 1}
'''
'lib-SOT223': '''
  # Sot223
  #! requires DoublePinArray
  add-class class SOT223 extends DoublePinArray
      (data={}) -> 
          defaults =
              name: 'c_'
              distance: 6.3mm
              left: 
                  start: 4
                  pad:
                      width: 2.15mm
                      height: 3.8mm
                  cols:
                      count: 1
              right:
                  dir: '-y'
                  pad:
                      width: 2mm
                      height: 1.5mm
                  rows:
                      count: 3
                      interval: 2.3mm
              border:
                  width: 3.5mm
                  height: 6.5mm
                  
          super defaults <<< data 
  
  add-class class SOT23 extends DoublePinArray
      (data={}) -> 
          pad = 
              width: 0.9mm
              height: 0.7mm
              
          defaults =
              name: 'c_'
              distance: 2mm
              left: 
                  start: 3
                  pad: pad 
                  cols:
                      count: 1
              right:
                  dir: '-y'
                  pad: pad
                  rows:
                      count: 2
                      interval: 1.9mm
              border:
                  width: 1.43mm
                  height: 3mm
  
          super defaults <<< data 
  
  #new SOT23
  
  
  add-class class NPN extends SOT23
      @rev_NPN = 1
      (data={}) -> 
          defaults =
              labels:
                  1: 'b'
                  2: 'e'
                  3: 'c'
          super defaults <<< data
  
'''
'lib-LM1117': '''
  #! requires SOT223
  add-class class LM1117 extends SOT223
      (data) -> 
          data.labels = 
              # Pin_id: Label
              1: 'gnd'
              2: 'vout'
              3: 'vin'
              4: 'vout'
          super ...
  
'''
}