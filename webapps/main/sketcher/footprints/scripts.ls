export {
'LM 2576': '''
  new LM2576 do
      name: 'c1'
  
'''
R1206: '''
  # From http://www.resistorguide.com/resistor-sizes-and-packages/
  r1206 =
      a: 1.6mm
      b: 0.9mm
      c: 2mm
  
  {a, b, c} = r1206
  
  p1 = pad b, a
  p2 = p1.clone!
      ..position.x += (c + b) |> mm2px
  
'''
'find-test': '''
  # --------------------------------------------------
  # all lib* scripts will be included automatically.
  # --------------------------------------------------
  c1 = find-comp "c1"
  c1-pins = c1?.get {pin: 1}
  
  c3 = find-comp "c3"
  c3-pins = c3?.get {pin: 33}
  
  
'''
lib_to263: '''
  dimensions = 
      to263:
          # See http://www.ti.com/lit/ds/symlink/lm2576.pdf
          H   : 14.17mm
          die : x:8mm     y:10.8mm
          pads: x:2.16mm  y:1.07mm
          pd  : 1.702
  
  
  # TO263 footprint 
  # ---------------------------
  add-class class TO263 extends Footprint
      (data) -> 
          data.symmetry-axis = 'x' # Design criteria
          super ...
          unless @resuming
              # create from scratch 
              console.log "Creating from scratch TO263"
              d = dimensions.to263
    
              pad1 = new Pad this, do
                  pin: 1
                  width: d.die.x
                  height: d.die.y
                  label: data.labels[1]
              
              c = new Container this
              
              for index in [1 to 5]
                  pad = new Pad c, do 
                      pin: index
                      width: d.pads.x
                      height: d.pads.y
                      label: data.labels[index]
              
                  pad.position.y -= (d.pd |> mm2px) * index
                  
              c.position = pad1.position
              c.position.x += (d.H - d.die.x / 2) |> mm2px
  
  
  add-class class PinArray extends Footprint
      (data) -> 
          super ...
          unless @resuming
              console.log "Creating from scratch PinArray"
              
              for cindex from 1 to data.cols.count
                  for rindex from 1 to data.rows.count
                      pin-num = switch (data.dir or 'x')
                      | 'x' => 
                          cindex + (rindex - 1) * data.cols.count
                      | 'y' =>
                          rindex + (cindex - 1) * data.rows.count
      
                      pin-label = data.labels?[pin-num]
      
                      p = new Pad this, do
                          pin: pin-num
                          width: data.pad.width
                          height: data.pad.height
                          label: if data.labels? => (pin-label or '?') 
                          
                      p.position.y += (data.rows.interval |> mm2px) * rindex 
                      p.position.x += (data.cols.interval |> mm2px) * cindex 
  
  add-class class LM2576 extends TO263
      (data) -> 
          data.labels = 
              # Pin_id: Label
              1: \\vin 
              2: \\out
              3: \\gnd
              4: \\fb 
              5: \\onoff
          super ...
  
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
'pin-array-test': ''
'lib-rpi-header': '''
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
                  width: 2mm
                  height: 1.2mm
              cols:
                  count: 2
                  interval: 3.34mm
              rows:
                  count: 20
                  interval: 2.54mm
              dir: 'x'
              labels: table
              
          data = defaults <<< data 
          super ... 
  
'''
'rpi-header-test': '''
  # --------------------------------------------------
  # all lib* scripts will be included automatically.
  # --------------------------------------------------
  new RpiHeader do
      name: 'rpi2'
  
  x = find-comp 'rpi2'
  <~ sleep 500ms
  x.rotate -45
  
'''
'schematic-test': '''
  # --------------------------------------------------
  # all lib* scripts will be included automatically.
  # --------------------------------------------------
  sch = new Schema do 
      name: "sgw"
      netlist: 
          # Trace_id: "list, of, connected, pads"
          1: "c1.1, rpi.3v3"
          2: "c1.onoff, rpi.gnd"
          3: "c1.vin rpi.25"
          4: "c1.fb c1.gnd"
      bom:
          "LM2576"    : 'c1, c3'
          'RpiHeader' : 'rpi'
  
  
  console.log "compiled schematic: ", sch.connections
  sch.guide-for \\c1.vin
  
  new SchemaManager! .curr.guide-for \\c1.onoff
'''
}