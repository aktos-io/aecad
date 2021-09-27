# How the circuits are created

1. Original netlist is manually created by the user in the runtime, by the .netlist (@_netlist) property. 
2. Indirect connections, shorthand interface (.iface) definitions and quick labels are postprocessed and
   injected into the @_netlist. 
3. .cables property is processed inside the @compile method. Appropriate pads are injected into the @_netlist.
4. Within @compile method of the top circuit, all subcircuits are processed and 
   the Array of "Array of connected Pad objects" are calculated (@netlist).
5. Internal connection ID's (`netid`) are read from existing Pads or newly assigned. 
   @netlist "Array" is now converted into @connection-list "Object" where the key is the valid connection ID of that net and 
   the value is the array of Pad objects on that net.

> Troubleshooting: Verify that all `interconnected` pads and appropriate jumper pads are correctly present 
> in @connection-list: 
> 
>    conn-list-txt = []
>    for id, net of sch.connection-list
>        conn-list-txt.push "#{id}: #{net.filter((-> not it.is-via)).map (.uname) .join(',')}"
>    console.log conn-list-txt.join '\n\n'
>


Building the @connection-list is the end of the compilation process. To make aeCAD actually useful, 
unconnected count and connection guides must be calculated. This is where @calc-connection-states() 
method comes into play. 

For each net (`@connection-list[netid]`): 

6. Relevant via's are appended by the `@calc-connection-states()` method. 
7. Traces are processed to determine which pad is connected to what pad. To make that happen,
   `named-connections` array is created. Every element is an array of connected pads ID's and trace ID's. 
8. Relevant external cable pairs are injected into `named-connections`. 

9. Unconnected logical-pins are calculated by `net-merge` function. 

10. @_connection_states object is calculated where the key is the `netid` and value is:


        {
            total: total pads to be connected, 
            unconnected-pads: stray Pad objects that should be connected, calculated by `net-merge` function.
            unconnected: The unconnected pad count 
            reduced: Result of `net-merge` function. 
        }



# Schema

All sub-circuits are handled as if they are simple components.
`iface` of a `Schema` is the `Pad`s of a `Footprint`. They are required to be
used or declared in `no-connect` list.

### SchemaManager

```
sm = new SchemaManager
```

Returns the `SchemaManager` singleton. Use `sm.active` to get active `Schema` instance.

## `Schema.netlist`

`Array` of "`Array` of Pads which are designed to be on the same net".

## `Schema.connection-list`

The final calculation of the `.netlist`. An `Object` where key: `trace-id`, value: array of related Pads. Built by
`Schema.build-connection-list` with the following strategy:

1. Use the existing netid if one is supplied by any of each net's pads.
2. Assign the rest of nets' netid's sequentially

(see [Troubleshooting](./troubleshooting.md) for more)


# Short circuit detection

`sch.netlist` is reduced by `net-merge` function. ...TODO...

# Getting unconnected count

"connection states" are returned by `sch.calc-connection-states!` with the following format:

            {
                {{netid}}:
                    reduced: Array of grouped pads by physical connection states 
                    unconnected-pads: Array of unconnected Pad instances.
                    total: Number of possible connections
                    unconnected: Number of missing traces
            }


# Usage

### Constructor

```ls
sch = new Schema {name: 'my-circuit', data: mycircuitjson}
```

Creates the schema object.

### sch.compile!

Compiles the circuit(s) with its sub-circuits.

### sch.guide-unconnected!

Creates visual guide lines between unconnected pads. Clear with `sch.clear-guides!`.

### sch.get-upgrades!

Returns list of components whose footprints' revisions are incremented.

#### Upgrading Footprints

When a major change is made on a footprint, you should do two things:

1. Increment the revision of the footprint:

            add-class class SMD1206 extends PinArray
                @rev_SMD1206 = 1 # <= this is the revision of the footprint
                (data, overrides) ->
                    ...

2. Upgrade the relevant components:
3.
    1. Select all components that needs upgrade:

            unless empty upgrades=(sch.get-upgrades!)
            msg = ''
            for upgrades
                msg += ..reason + '\n\n'
                pcb.selection.add do
                    aeobj: ..component
            # display a visual message
            pcb.vlog.info msg

    2. Upgrade all selected components automatically: Click the relevant button on canvas control.

# sch.get-connection-states!

Returns unconnected pad count.

### Updating unconnected pad GUI counter

Fire the `calcUnconnected` method within Ractive:

```
pcb.ractive.fire 'calcUnconnected'
```

# Selecting unused components

TODO

# Prefixing current components

Let's assume you wanted your previous drawing to be a sub-circuit of current schema. 

After you defined your previous schema as a single component, you need to fix the 
prefixes: 

```
for pcb.get-components {exclude: <[ Trace Edge RefCross ]>}
    console.log "component: ", ..
    aeobj = get-aecad ..item
    aeobj.name = "d.#{aeobj.name}"
```

# Generating BOM list 

```ls
sch.get-bom-list!

# Returns: Array of components grouped by TYPE+VALUE in the following format: 
# [{count, type, value, instances}]
```

