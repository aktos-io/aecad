# Schema

All sub-circuits are handled as if they are simple components.
`iface` of a `Schema` is the `Pad`s of a `Footprint`. They are required to be
used or declared in `no-connect` list.

# Schema.connection-list

An `Object` where key: `trace-id`, value: array of related Pads. Built by
`Schema.build-connection-list` with the following strategy:

1. Use the existing netid if one is supplied by any of each net's pads.
2. Assign the rest of nets' netid's sequentially


# Schema.netlist

`Array` of "`Array` of Pads which are on the same net".

# Short circuit detection

`Schema.netlist` is reduced by `net-merge` function. ...TODO...
