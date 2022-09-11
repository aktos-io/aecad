# What is `aeobj`

An `aeobj` is a JS object where:
- "On-disk-data" is a valid Paper.js JSON where the component/rehydration data is stored in `.data.aecad`.
- It is the "rehydrated" (resumed) (or a newly created) instance of `data.aecad.type` class. Rehydration is performed by `new THAT_CLASS data.aecad`. `THAT_CLASS` is a class which is registered via `get-class/add-class` method.
- The plain PaperJS object on the canvas can be get via `aeobj.g`.

See `get-aecad.ls/get-aecad` for the details.

aeCAD specific properties is displayed in the "Properties" window.

# aeCAD Data

All component data should reside in its `Group.data`.


    data:
        tmp: *bool* Temporary item, will be remove on import
        aecad:
            tid: "Trace ID" (if this is a trace)
            layer: *String*: one of "F.Cu, B.Cu"
            type: *String* one of "via, drill, $footprint"
            name: *String* Instance name
            pin: *Int* Pin number of the $footprint, starts from 1; `0` means `N.C`
            group: *Array* of group names.
            label: Label of handle (eg. pin)

### when aecad.type is "via"

...TODO


### Temporary Objects

```
data:
    tmp: true
```

#### Handles

...for segment handles:
```
data:
    tmp: true
    role: \handle
    tid: "the selected trace's id"
    curve: hit.location.curve
```
...for point type handles:
```
data:
    tmp: true
    role: \handle
    tid: "the selected trace's id"
    geo: \c, # means this is circle
    segment: hit.segment
```

# Behavior

See `help.pug` (the help button) for behavior explanation.

# Examples

```json
            "data": {
              "aecad": {
                "type": "SMD1206",
                "name": "s1",
                "value": "120ohm",
                "rev": 2,
                "_labels": {"1": "1", "2": "2"},
                "_iface": {"1": 1, "2": 2},
                "side": "B.Cu",
                "userDefined": ""
              }
            },
