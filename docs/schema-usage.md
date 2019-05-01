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

```
sch.get-bom-list!

# Returns: Array of components grouped by TYPE+VALUE in the following format: 
# [{count, type, value, instances}]
```