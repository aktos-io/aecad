

power-test = (args) ->
    vin = args?.vin or '24V'
    (value) ->
        # Power Layer
        # Input: 9-30V, Output: 5V and 3.3V
        iface: 'vff, vfs, 5v, 3v3, gnd'
        bom:
            'LM2576':
                "5V": 'C1'
            "LM1117": "C2"
        netlist: {}
        no-connect: """
            C1.vin,C1.out,C1.gnd,C1.fb,C1.onoff,vff,vfs,5v,3v3,gnd
            C2.gnd,C2.vout,C2.vin
            """

if __main__?
    report-bom = yes

    sch = new Schema {
        name: 'step-driver1'
        data: power!
        bom: { }
        }
        ..clear-guides!
        ..compile!
        ..guide-unconnected!

    if report-bom
        # Dump the BOM
        bom-list = "BOM List:\n"
        bom-list += "-------------"
        for sch.get-bom-list!
            bom-list += "\n#{..count} x #{..type}, #{..value}"
        PNotify.info do
            text: bom-list
        console.log bom-list
        # End of BOM

    # Calculate unconnected count
    pcb.ractive.fire 'calcUnconnected'

    # Populate component-selection dropdown
    pcb.ractive.set \currComponentNames, sch.get-component-names!

    # Detect component upgrades
    unless empty upgrades=(sch.get-upgrades!)
        msg = ''
        for upgrades
            msg += ..reason + '\n\n'
            pcb.selection.add do
                aeobj: ..component
        # display a visual message
        pcb.vlog.info msg

