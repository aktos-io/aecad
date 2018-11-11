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
  
  
  console.log "c1 pos: ", c1-pins.0
  
  guide = (pad1, pad2) -> 
      new Path.Line do
          from: pad1.g-pos
          to: pad2.g-pos
          stroke-color: 'lime'
          selected: yes
          data: {+tmp}
      
  connections = 
      1: "c1.1, c3.31"
      2: "c1.2, c3.13"
      3: "c1.vin c3.31"
      
  # compile schematic 
  conn-processed = []
  for k, conn of connections
      conn-processed.push <| conn
          .split /[,\\s]+/ 
          .map (.split '.')
          .map (x) ->
              comp = find-comp(x.0)
              src: x.join '.'
              c: comp
              pad: comp.get {pin: x.1}
  
  make-guide = (src) -> 
      for conn-processed when find (.src is src), ..
          guide ..0.pad.0, ..1.pad.0
          
  
  make-guide \\c1.vin
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
                      p = new Pad this, do
                          pin: pin-num
                          width: data.pad.width
                          height: data.pad.height
                          
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
'pin-array-test': '''
  new PinArray do
      name: 'c2'
      pad:
          width: 2mm
          height: 1.2mm
      rows:
          count: 2
          interval: 3.34mm
      cols:
          count: 20
          interval: 2.54mm
      dir: 'x'
  
  
  ## Now find the component by its name 
  ## ----------------------------------
  #x = find-comp 'c1'
  #<~ sleep 500ms
  #x.rotate -45
  #x.mirror!
  #x.print-mode = yes 
'''
}