# Creating new circuits 

Format: 

```
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