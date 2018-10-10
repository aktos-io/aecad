require! 'three': THREE

Ractive.components['webcad'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug')
    onrender: ->
        view = @find '#graphical_view'
        scene = new THREE.Scene()
        camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000 )
        renderer = new THREE.WebGLRenderer();
        renderer.setSize( 600, 600 )
        view.appendChild( renderer.domElement )

        # FIXME: load the response here
        geometry = new THREE.BoxGeometry( 1, 1, 1 );
        material = new THREE.MeshBasicMaterial( { color: 0x00ff00 } );
        cube = new THREE.Mesh( geometry, material );
        console.log "cube is: ", cube
        scene.add( cube );
        camera.position.z = 5;

        animate = ->
            requestAnimationFrame( animate );
            cube.rotation.x += 0.01;
            cube.rotation.y += 0.01;
            renderer.render( scene, camera );

        animate();

        @on do
            updateModel: (ctx) ->
                btn = ctx.component
                btn.state \doing
                err, msg <~ ctx.actor.send-request \@occ-worker.updateModel, {script: @get \model}
                if err
                    return btn.error err
                console.log "FIXME: Response: ", msg.data
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
