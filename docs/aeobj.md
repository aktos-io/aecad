# What is aeobj

An `aeobj` is a JS object whose
- "on-disk-data" is a plain Paper.js JSON with `data.aecad.type` is one of the known types[1].
- itself is the "rehydrated" (resumed) or newly created instance of `data.aecad.type` class.

See `get-aecad.ls/get-aecad` for the details.

Properties of an aeCAD object (aeobj) will be displayed in the "Properties" window.

[1]: Known types are the classes that are registered via `get-class/add-class` method.

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
