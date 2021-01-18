# Creating Footprint

```
Coordinate System:
=================

    0 ------> +x
    |
    |  [Screen]
    v
    +y
    
    Units: in "mm", unless explicitly declared.
```

## Creating From Scratch 

```ls
add-class class ExampleFootprint extends Footprint
    create: (data) ->
        '''
        data: (Object)
        --------------
        The initialization data. May be supplied when this footprint 
        is inherited.

        @iface: (Object)
        ----------------
        Interface data for this footprint. Normally all pins should 
        be exposed.

        Same property is used within schemas to provide connection 
        information.

        @make-border (Function. Args: {border: Object})
        ----------------------------------------------
        > Note: This function should be called after initializing all Pad objects
        > because it determines the center of the footprint by iterating over Pad objects.
        
        Object defines the footprint border. Automatically centered to the bounding 
        box of the Pad's. 
        
        If `width` and `height` keys exist, it is Rectangular.
        If `dia` key exist, it's Circular.
        `drill`: Drill hole diameter.
        `offset-x`: Offset towards +x direction.
        `offset-y`: Offset towards +y direction.

        @mirror() (Function)
        --------------------
        Create mirror of this footprint. Useful for female header 
        definitions and trough-hole components. 
        '''
        
        Pad(Object): Class.
        -------------------
        Object:
            .pin: Pin number. Integer.
            .label: Pin label. 
            .width and .height: Dimensions if it's a Rectangle.
            .dia: Dimensions if it's a Circle.
            .pos-x: Absolute x position in mm. (Type: Property)
            .pos-y: Absolute y position in mm. (Type: Property)
            .centered: Boolean. Rectangular pads are centered if set to true.
            
        Position defines: 
            * Center of a circular pad.
            * Top-left point of a rectangular pad.
        
        ...
        
```

# One Pad Footprint 

![image](https://user-images.githubusercontent.com/6639874/104859284-35760d80-5935-11eb-801b-53696e498863.png)

```ls
add-class class ExampleFootprint extends Footprint
    create: (data) ->
        pads =
            pad1:  
                desc:
                    pin: 1
                    label: 'a'
                    width: 2.3mm
                    height: 3.4mm
                position:
                    x: 0mm
                    y: 0mm
                    
        border = 
            width: 4mm
            height: 6mm

        for i, pad of pads
            # initialize @iface
            @iface[pad.desc.pin] = pad.desc.label

            # create Pad objects
            new Pad ({parent: this} <<< pad.desc)
                ..pos-x += pad.position.x
                ..pos-y += pad.position.y

        @make-border {border}

new ExampleFootprint!
```

# Two Pads

![image](https://user-images.githubusercontent.com/6639874/104860360-39f1f480-593c-11eb-8989-5bc758fb773e.png)

```ls
add-class class ExampleFootprint extends Footprint
    create: (data) ->
        pads =
            pad1:  # A square pad
                desc:
                    pin: 1
                    label: 'a'
                    width: 2.3mm
                    height: 3.4mm
                position:
                    x: 0mm
                    y: 0mm
            pad2:
                desc:
                    pin: 2
                    label: 'b'
                    width: 2.3mm
                    height: 3.4mm
                position:
                    x: 3mm
                    y: 0
                    
        border = 
            width: 4mm
            height: 6mm

        for i, pad of pads
            # initialize @iface
            @iface[pad.desc.pin] = pad.desc.label

            # create Pad objects
            new Pad ({parent: this} <<< pad.desc)
                ..pos-x += pad.position.x
                ..pos-y += pad.position.y

        @make-border {border}

new ExampleFootprint!
```

# A Complex Footprint 

![image](https://user-images.githubusercontent.com/6639874/104860343-1169fa80-593c-11eb-9440-b351ec266cab.png)

```ls
add-class class ExampleFootprint extends Footprint
    create: (data) ->
        pads =
            pad1:  # A square pad
                desc:
                    pin: 1
                    label: 'a'
                    width: 2mm
                    height: 3mm
                position:
                    x: 0mm
                    y: 0mm
            pad2:
                desc:
                    pin: 2
                    label: 'b'
                    width: 2mm
                    height: 3mm
                position:
                    x: 3mm
                    y: 0
                    
            pad3:
                desc:
                    pin: 3
                    label: 'c'
                    width: 2mm
                    height: 3mm
                    drill: 1.2mm
                position:
                    x: 6mm
                    y: 0
                    
            pad4:
                desc:
                    pin: 4
                    label: 'd'
                    dia: 3mm
                    drill: 1.2mm
                position:
                    x: 4mm
                    y: 6mm
                
        border = 
            width: 9mm
            height: 8mm

        for i, pad of pads
            # initialize @iface
            @iface[pad.desc.pin] = pad.desc.label

            # create Pad objects
            new Pad ({parent: this} <<< pad.desc)
                ..pos-x += pad.position.x
                ..pos-y += pad.position.y

        @make-border {border}

new ExampleFootprint!
```

# Highly Asymmetric Footprint 

Component: [Bourns Trimpot 3006P](https://user-images.githubusercontent.com/6639874/104923123-af95a900-59ac-11eb-8b7f-8e1f7f30f68a.png)

![image](https://user-images.githubusercontent.com/6639874/104923425-17e48a80-59ad-11eb-82b5-a3ad7219c17d.png)


```ls
add-class class Trimpot_Bourns_3006P extends Footprint
    create: (data) ->

        dia = 1.2mm
        drill = 0.6mm
        body-length = 19.2mm
        body-height = 5mm
        #
        #            ,- t(op)
        # [ 1 2 3 ]=
        # l       r  ^- b(ottom)
        #
        d13x = 12.7mm # distance from 1 to 3, x direction
        d23x = 5.08mm
        d3rx = 3.3mm
        
        d23y = 2.54mm
        d3by = 1.4mm
        d13y = 0mm
        
        # calculated values
        dl1x = body-length - (d13x + d3rx)
        dt1y = body-height - (d13y + d3by)

        pads =
            pin1:
                desc: {pin: 1, dia, drill}
                position: 
                    x: dl1x 
                    y: dt1y
            pin2:
                desc: {pin: 2, dia, drill}
                position: 
                    x: dl1x + d13x - d23x 
                    y: dt1y + d13y - d23y
            pin3:
                desc: {pin: 3, dia, drill}
                position: 
                    x: dl1x + d13x 
                    y: dt1y + d13y

        border =
            body:
                width: body-length
                height: body-height
                centered: no

            screw:
                width: 0.8mm
                height: 2.4mm
                centered: no
                offset-x:~ -> border.body.width
                offset-y:~ -> border.body.height/2 - @height/2
                
        for i, pad of pads
            # initialize @iface
            @iface[pad.desc.pin] = pad.desc.label

            # create Pad objects
            new Pad ({parent: this} <<< pad.desc)
                ..pos-x += pad.position.x
                ..pos-y += pad.position.y

        for name, data of border
            @make-border {border: data}

        # We assumed to view from top. However, all 
        # dimensions were defined from bottom. 
        @mirror!

new Trimpot_Bourns_3006P!
```

![image](https://user-images.githubusercontent.com/6639874/104927460-82e49000-59b2-11eb-8f53-896cbe209fcb.png)


