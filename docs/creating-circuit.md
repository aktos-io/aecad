# Creating new circuits 

A circuit is a simple JSON object with `iface`, `netlist`, `bom` and optional `schemas`, `no-connect` and `notes` fields. 

A subcircuit is a function that takes `value` as an argument (while being initiated within the `bom` section) and returns the schema JSON. Subcircuits are registered in `schemas` section. 

Generally it's wise to declare a function that returns the subcircuit function. In this way you can easily provide parameters to get the proper variant of the subcircuit during registration in the `schemas` section.

```ls
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
```

> It may also make sense to declare the tip circuit as if it were a subcircuit, because every circuit can be considered as a subcircuit in the future.

Footprints are initiated in `bom` section with either `{"Footprint": [instances]}` or `{"Footprint": {"value": [instances]}}` format.

### Example Circuit

```ls
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
            C1206:                  # Footprint initialization 
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
            baz:                    # Subcircuit initialization
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
if __main__?
    sch = new Schema {
        name: 'my-circuit'
        data: bar
        bom:
            # helper materials
            RefCross: '_a _b'   # underline prefixes excluded from BOM
        }
        ..clear-guides!
        ..compile!
        ..guide-unconnected!
    
    # Calculate unconnected count
    pcb.ractive.fire 'calcUnconnected'

    # Populate component-selection dropdown
    # Any component can be highlighted by selecting it 
    # from the "component selection dropdown", located above of drawing area:
    pcb.ractive.set \currComponentNames, sch.get-component-names!
    
    # Detect component upgrades
    unless empty upgrades=(sch.get-upgrades!)
        msg = ''
        for upgrades
            msg += ..reason + '\n\n'
            pcb.selection.add do
                aeobj: ..component
        # display a visual message
        pcb.vlog.info msg
```
