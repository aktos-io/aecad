# AeCAD (DRAFT)

## What is it?

Electronic Design Automation software, like Kicad, but using the web technologies (runs in the browser or desktop via [ElectronJS](https://electronjs.org/)) like EasyEDA, with offline installation support. It will be like [Onshape](https://www.onshape.com/) to Solidworks.

Basically a software to create real-world drawings from schematics:

![image](https://user-images.githubusercontent.com/6639874/33883344-862bcbd6-df4c-11e7-84c9-7a077be731a9.png)

## Why Another Software?

- See [What is wrong with Kicad](./problems-with-others.md#what-is-wrong-with-kicad)
- See [What is wrong with EasyEDA](./problems-with-others.md#what-is-wrong-with-easyeda)

## What features will AECAD have?

- Web based collaboration
- Versioning support for drawings out of the box: You may produce some PCB's and you may update the schematics later on. PCB's will include an automatically tracked schematic version.
- Support for Test Driven Development: Every subproject might require its own test procedure. Test procedures will be defined within schematics and concatenated as a checklist on demand. 
- Inherit from Kicad 
  - Selecting a component in schematic/PCB will show where it is located on PCB/schematic.
- "How do I" section: It will be possible to "record" full/portion of a drawing which will be used for tutorial purposes. That will make it possible to create tutorials from real-world applications. 
- Hotkeys: 
  - Keyboard focused hotkeys: Hotkeys should be bound to physical keys on the keyboard, not letters, because main purpose of hotkeys is make usage faster and if keyboard layout is different from US (or like), "hotkeys" might not be "hot" enough. 
  - It will be possible to bind macros to hotkeys (press a `KEY` to do that, do this and do some other thing).

### Schematic editor 
- Create new components easily 
- Component based design: You will use your existing components to create sub-circuits
  - Dependency tracking for sub-components
- Design rules
  - Component based DRC (design rule checking): A component will be able to make you warn if you connect a pin to any wrong ping (for example, a warning will be thrown if you connect `VDD` to `GND`.
  - PCB Design rule definitions: You are not always allowed to place your components onto the PCB freely in real-world applications. For example the manufacturer of an MCU requires you to place parasitic capacitors as close as possible to the MCU pins. Moreover, they require some specific capacitors to be placed close to some specific pins. This should (and will) be possible at the definition (schematic/sub-circuit) step.

- Human readable Netlist syntax: Any schematic can be read in text mode and can be edited by hand, with a text editor.
- Topological versioning: Schematic file might be changed (added/removed/moved something) but topology might stay intact. This topological version is important, schematic file version is not. So schematic editor will provide this version for printing onto the PCB. 
- Virtual layers: Grouping some drawings at the same physical layer
- Printable schematics:
  - Cross references (like in EPlan)
  - Separate footprint annotation table which is open for editing by hand. 
    
### PCB editor 
- A complete graphics editor (including align tool, rulers, etc.)
- Component based approach: You will be able to re-use your existing PCB drawings 
- Multiple association of PCB drawings for the same schematic: You may draw more than one PCB for the same schematic. You will be able to use any of them, or create a new design. 
- Inherit from Kicad: 
  - [Push and shove routing](https://www.youtube.com/watch?v=kzro0Jc70xI)
  - Net classes 
  - [Highlight net](https://github.com/ceremcem/aeda/issues/2)
- Extra pcb layers with components: A zero ohm resistor might be used just like a jumper. 
- Class based footprint association: Declare your technology, overwrite any of the components when needed.
- Virtual layers: Grouping some drawings at the same physical layer
- Modular PCB design: 
  - A design may include another project as a module. Pin connections should point the outer project's specified pins. 
  - A design may be made up of more than one PCB (modules). Allow cabling layer for that purpose.
- Collision dedection: A realtime checking process that checks if PCB can fit in the physical case. 

# Technology 

Core of AeCAD will be built on [ScadaJS](https://github.com/aktos-io/scada.js). Specific libraries will be built/chosen accordingly.

# TODO

* Get the good design specs from [Horizon](https://github.com/carrotIndustries/horizon/wiki/Feature-overview).

# TO BE CONTINUED
  
