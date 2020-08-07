export init = (pcb) ->
    handlers =
        removeCurrLayer: (ctx) ->
            curr = @get \activeLayer
            action, data <~ pcb.vlog.yesno do
                title: 'Delete Whole Layer'
                icon: ''
                closable: yes
                message: "Are you sure you want to delete all contents of layer #{curr}?"
                buttons:
                    remove:
                        text: 'Remove'
                        color: \red
                        icon: \trash
                    cancel:
                        text: \Cancel
                        color: \gray
                        icon: \remove

            if action in [\hidden, \cancel]
                console.log "Cancelled."
                return

            pcb.history.commit!
            pcb.remove-layer curr 
