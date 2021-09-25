# Troubleshooting 

## Wrong unconnected count

1. Get `connection-list` and verify the relevant pads are calculated in the same net: 

  ```ls
  conn-list-txt = []
  for id, net of sch.connection-list
      conn-list-txt.push "#{id}: #{net.filter((-> not it.is-via)).map (.uname) .join(',')}"
  console.log conn-list-txt.join '\n\n'
  ```

2. Get the "connection states" to determine which pads are connected by what traces and vias:

  ```ls
  for netid, i of sch._connection_states
    console.log "#{netid}: ", i.reduced.0.join ', '
  ```

