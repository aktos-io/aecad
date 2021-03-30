# Creating new circuits 

A circuit is a simple JSON object with `iface`, `netlist`, `bom` and optional `schemas`, `no-connect` and `notes` fields. 

A subcircuit is a simple schema JSON or a function that takes `value` as an argument (while being initiated within the `bom` section) which returns a schema JSON. Subcircuits are registered in `schemas` section. 

Generally it's wise to declare a function that returns the subcircuit function. In this way you can easily provide parameters to get the proper variant of the subcircuit during registration in the `schemas` section.

```ls
foo = (config) -> # provides this 
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

### `.netlist`

Format: `{"connection name": ARRAY_OF_PADS}`

### `.iface`

Interface of this circuit. This is used as connection points when the circuit is used as a subcircuit.

Syntax: 

```ls
iface: [
    foo     # Expose the "foo" connection ("foo" key of the netlist)
    c1.x    # Automatically expose component c1's 'x' pin.
    c1.*    # Automatically expose component c1's every pin. 
    ]

```

### `.disable-drc`

Disable Design Rule Checking for the provided functionalities. Supported switches: 

* `unused`: Disable unused pad detection. 

Example: 

```ls
mycircuit = 
  ...
  disable-drc: "unused"
```

### `value` 

The `value` is a simple string value that is assigned in `bom` section.

For subcircuits, it's passed as the first argument in `schema/bom.ls` if the subcircuit is a function.

For Footprints, it's passed as `data.value` in `schema/footprints.ls`

### `# provides this`

This indicator makes this function (subcircuit) added to the "`.[]exposes`" array so that any other 
dependent can explicitly require this function by `# depends: foo` syntax. 

If omitted, the script of subcircuit is loaded anyway, so it's normally found. It's only useful to detect/resolve a circular dependency. When a circular dependency is detected, the dependent is not loaded.

# Excluding from BOM and connection list

Single underscore prefixed components (`_x`) are excluded from BOM, but included into the netlist. (See `.get-bom-list()`)
Double underscore prefixed components (`__x`) are exclude both from BOM and the netlist. (See `.find-unused()`)

# Unit tests

Call `run-unit-tests!` in your circuit script. 

# Example Circuit

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
if __main__
    # Runs unit tests until they are succeeded. 
    #run-unit-tests! 

    # `standard` is a function that takes a schema object and post-processes it 
    # (compiles, creates guides, etc.) accordingly. Returns the same schema object.
    standard new Schema {
        name: 'my-circuit'
        data: bar
        bom:
            # helper materials
            RefCross: '_a _b'   # underline prefixes excluded from BOM
        }
```