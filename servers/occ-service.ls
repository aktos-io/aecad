require! 'node-occ': {occ, shapeFactory, scriptRunner, fastBuilder}
fast_occ = fastBuilder.occ
require! 'dcs': {DcsTcpClient, Actor, sleep}
require! '../config'

user = "occ-worker"
password = "1234"

new DcsTcpClient port: config.dcs-port .login {user, password}

new class OccActor extends Actor
    ->
        super \node-occ
        @on-topic \@occ-worker.updateModel, (msg) ~>
            @log.log "received message:", msg.data.script
            process = new scriptRunner.ScriptRunner do
                csg: fast_occ,
                occ: fast_occ,
                solids: [],
                display: (objs) ->
                    unless objs instanceof occ.Solid
                        objs.forEach (o) -> process.env.solids.push o
                    else
                        process.env.solids.push objs
                shapeFactory: shapeFactory

            process.run "#{msg.data.script}", (err) ~>
                if err
                    console.log "....................error: ", err
                else
                    solids = process.env.solids
                    logs = process.env.logs
                    @send-response msg, {solids, logs}
