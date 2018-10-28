# AeCAD Data

All component data should reside in its `Group.data`.

data:
    tmp: *bool* Temporary item, will be remove on import
    aecad:
        tid: "Trace ID" (if this is a trace)
        type: *String* one of "via, drill, $footprint_name"
        group: *Array* of

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

# Selection

1. Clicking will select only child objects under a layer.
2. If object is a group, "open the object" must be clicked
3. Trace routes are exceptions, their segments or curves will be selected on
    click. `Ctrl + |click|` will disable this rule (thus select the group.)
4. Selecting a `Layer` is possible:
    1. `Ctrl + a` (TODO)
    2. Via tree view (TODO

## Modifiers

1. `Shift + |drag|` = Pan

# Move

Move mode does what selection does + moves the selected item(s) by:

1. By drag and drop
2. Pick and place (shortcut: a/a)

Traces are handled specially: Left and right curves' slope is preserved

## Keys

1. `Del`: Deletes selected items
2. `Esc`:
    1. In Move: Cancel movement (restore the item position)
    2. On Idle: Activate Selection Tool.
3. `ı`: Rotate CW
