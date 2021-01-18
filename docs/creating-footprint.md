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
        Create mirror of this footprint. Useful for creating female 
        headers.
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

