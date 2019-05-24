# Creating new circuits 

Format: 

```ls
mycircuit = 
    params: Default parameters in string format. Merged with parent parameters.
    iface: Interface labeling
    netlist: Connection list
    schemas: [Object] Available sub-circuits
    bom: Bill of Materials
        key1: values # => List of instances
        key2:
            "params": values # => instances receive "params"
        "My:{{x}}": values # => dynamic parameter passing 
    notes: [Array] Notes for each component
```

```ls
sch = new Schema {
    name: 'DRV8711_Basic'
    data: drv8711_bare
    params: 
        M: \NMos # => Pass root parameters here 
    }
    ..clear-guides!
    ..compile!
    ..guide-unconnected!
```

# Generating BOM list 

```ls
sch.get-bom-list!

# Returns: Array of components grouped by TYPE+VALUE in the following format: 
# [{count, type, value, instances}]
```

### Example BOM display: 

```ls
# Dump the BOM
bom-list = "BOM List:\n"
bom-list += "-------------"
for sch.get-bom-list!
    bom-list += "\n#{..count} x #{..type}, #{..value}"
PNotify.info do
    text: bom-list
# End of BOM
```

# Parametric Schematics 

Schemas can use simple parameters with default values located in `.params` property: 

> See [schema/tests/parametric.ls](master/../../webapps/main/sketcher/tools/lib/schema/tests/parametric.ls) for more examples.

```ls
foo = (args) ->
    (value) ->
        value ?= "1K"
        r = mathjs.eval "#{value} * 2"

        schema =
            # parallel resistors
            iface: "1 2" # Compatible with stock resistors
            netlist:
                1: "r1.1 r2.1"
                2: "r1.2 r2.2"
            bom:
                SMD1206:
                    "#{r}": "r1 r2"

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


sch = new Schema {
    name: 'mytest'
    data: bar
    params:
        Q: \qux
    }
    ..clear-guides!
    ..compile!
    ..guide-unconnected!

bom-list = "BOM List:\n"
bom-list += "-------------"
for sch.get-bom-list!
    bom-list += "\n#{..count} x #{..type}, #{..value}"
PNotify.info do
    text: bom-list
```

Displayed BOM is:

```
BOM List:
-------------
2 x SMD1206, 1000 ohm
2 x SMD1206, 6 kohm
```

# Populating selection dropdown

```ls
pcb.ractive.set \currComponentNames, sch.get-component-names!
```
