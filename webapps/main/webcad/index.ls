Ractive.components['webcad'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug')
    on:
        updateModel: (ctx) ->
            btn = ctx.component
            btn.state \doing
            err, msg <~ ctx.actor.send-request \@occ-worker.updateModel, {script: @get \model}
            if err
                return btn.error err
            console.log "Response: ", msg.data
            btn.state \done...

    data:
        model: """
            print(" ------------------ Creating youghurt pots -------");

            var height = 20;
            var thickness = 1;
            var radius =10.0;

            var s1 = csg.makeCylinder([0,0,0],[0,0,height] , radius);
            var s2 = csg.makeSphere([0,0,0], radius);
            var s3 = csg.makeCylinder([0,0,-radius*0.7],[0,0,height], radius*2);
            var s4 = csg.fuse(s1,s2);
            var s5 = csg.common(s4,s3);


            var smallRadius = radius-thickness;
            var r1 = csg.makeCylinder([0,0,0],[0,0,height] , smallRadius);
            var r2 = csg.makeSphere([0,0,0],smallRadius);
            var r3 = csg.makeCylinder( [0,0,-radius*0.7 + thickness ],[0,0,height], radius*2);
            var r4 = csg.fuse(r1,r2);
            var r5 = csg.common(r4,r3);

            var solid = csg.cut(s5,r5);

            var dist = 21;
            display(solid);
            display(solid.translate([dist,0,0]));
            display(solid.translate([-dist,0,0]));
            display(solid.translate([0,-dist,0]));
            display(solid.translate([0,dist,0]));
            """
