# Creating new circuits 

A circuit is a simple JSON object with `iface`, `netlist`, `bom` and optional `schemas`, `no-connect` and `notes` fields. 

Single underscore prefixed components (`_x`) are excluded from BOM, but included into the netlist. (See `.get-bom-list()` and `component-syntax` in `post-process-netlist.ls`)

Double underscore prefixed components (`__x`) are exclude both from BOM and the netlist. (See `.find-unused()`)

A subcircuit is a simple schema JSON or a function that takes `value` as the first argument and `labels` as the second argument when initialized in `bom.ls` and returns a schema JSON. Subcircuits are registered in `schemas` section of the parent circuit. 

Generally it's wise to declare a function that returns the subcircuit function. In this way you can easily provide parameters to get the proper variant of the subcircuit during registration in the `schemas` section.

> `# provides this` comment: See below, "provides this" section.

```ls
foo = (config) -> # provides this 
	(value[, labels]) -> 
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

> It may also make sense to declare the tip circuit as if it were a subcircuit, because every circuit may be considered as a subcircuit in the future.

Footprints are initiated in `bom` section with either `Array` or `Object` format:

```ls 
bom: 
	MyFootprint: "c1 c2"
	MyFootprint2: 
		"some value": "c3 c4"
	MyFootprint3: 
		"some value": 
			c5:
				1: "a"  # Declare a custom label set 
				2: "b"
			c6: null 	# Use default label set 
		"": "c7 c8" 	# No value, multiple instances			
```

### `.netlist`

Format: `{netid: List of connected Pad's}`

### `.iface`

Interface of this circuit. This is used as connection points when the circuit is used as a subcircuit.

Syntax: 

```ls
iface: [
    foo     # Expose the "foo" connection ("foo" key of the netlist)
    c1.x    # Automatically expose component c1's 'x' pin.
    c1.*    # TODO: Automatically expose component c1's every pin. 
    ]

```

### Quick Labels 

You can assign quick labels to the circuits or components by simply replacing the instance name with `{instance: labels}` where `labels` is the object in `{pin_number: "new_label"}` format: 

```
bar =
    # series resistors
    iface: "a b"
    schemas: {foo: foo!}
    bom:
        foo:
            '500ohm':
                "x":            # Here the sub-circuit uses new quick labels.
                    1: "aaa"
                    2: "bbb"
            "3kohm": "y"
    netlist:
        a: "x.bbb"
        b: "y.1"
        1: "x.aaa y.2"
```

Quick labels overrides the `allow-duplicate-labels` property and allows duplicate labels. 

### `.cables`

Cable connections can be defined under this property. Two forms are possible: 

1. Whole connector 
2. Pin by pin 

```ls
    ...
    cables: 
        "j1": "j2"

```

Above definition declares that "Every pin of `j1` is connected to `j2` outside of the circuit". 

```ls
    ...
    cables:
        "j1.1": "j2.2"
        "j1.2": "j2.3"
```

Now only 2 pins are connected via cable.

### `.disable-drc`

Disable Design Rule Checking for the provided functionalities. Supported switches: 

* `unused`: Disable unused pad detection. 
* `duplicate-netid`: Disable checking duplicate netid for the pads in the same net.

Example: 

```ls
mycircuit = 
  ...
  disable-drc: "unused"
```

### Bom component's `value` 

The `value` is a simple string value that is assigned in `bom` section.

For subcircuits, it's passed as the first argument in `schema/bom.ls` if the subcircuit is a function.

For Footprints, it's passed as `data.value` in `schema/footprints.ls`

### `# provides this`

This indicator makes this function (subcircuit) added to the "`.[]exposes`" array so that any other 
dependent can explicitly require this function by `# depends: foo` syntax. 

If omitted, the script of subcircuit is loaded anyway, so it's normally found. It's only useful to detect/resolve a circular dependency. When a circular dependency is detected, the dependent is not loaded.

# Unit tests

Call `run-unit-tests!` in your circuit script. 

# Virtual Traces

It's useful to declare virtual traces to write tests. Example: 

```ls
my-circuit = 
    bom: ...
    netlist: ...
    virtual-traces:
        1: "c4.SWCLK debug.swclk"
        2: "c4.GND debug.gnd"
        3: "c4.NRST debug.nrst"

```

# Debugging 

Some debug output will be printed to the console when `{debug: true}` is passed as an option to the `new Schema` constructor or to the `Schema.data`. If value is `all` (`{debug: "all"}`), `{debug: true}` is passed to all sub-circuits. 

```ls
standard new Schema {
		debug: yes 
        name: 'my-circuit'
        data: bar
        }
```

```ls
standard new Schema {
        name: 'my-circuit'
        data: 
			debug: yes 
			netlist: ...
        }
```

# Example Circuit

See https://github.com/aktos-io/aecad-example
