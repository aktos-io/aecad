# aecad (DRAFT)

## What is it?

Electronic Design Automation software, like Kicad, but using the web technologies like EasyEDA, with offline installation support. It will be like [Onshape](https://www.onshape.com/) to Solidworks.

Basically a software to create real-world drawings from schematics:

![image](https://user-images.githubusercontent.com/6639874/33883344-862bcbd6-df4c-11e7-84c9-7a077be731a9.png)

## Why Another Software?

- See [What is wrong with Kicad](./problems-with-others.md)

## What features will AECAD have?

- Web based collaboration
- Versioning support for drawings out of the box: You may produce some PCB's and you may update the schematics later on. PCB's will include an automatically tracked schematic version.
- Support for Test Driven Development: Every subproject might require its own test procedure. Test procedures will be defined within schematics and concatenated as a checklist on demand. 
- Inherit from Kicad 
  - Selecting a component in schematic/PCB will show where it is located on PCB/schematic.

### Schematic editor 
  - Create new components easily 
  - Component based design: You will use your existing components to create sub-circuits
    - Dependency tracking for sub-components
  - Component based DRC (design rule checking): A component make you warn if you connect a pin to any wrong ping (for example, a warning will be thrown if you connect `VDD` to `GND`. 
  - Human readable Netlist syntax: Any schematic can be read in text mode and can be edited by hand, with a text editor.
  - Topological versioning: Schematic file might be changed (added/removed/moved something) but topology might stay intact. This topological version is important, schematic file version is not. So schematic editor will provide this version for printing onto the PCB. 
  - Virtual layers: Grouping some drawings at the same physical layer
  - Printable schematics:
    - Cross references (like in EPlan)
    - Separate annotation table which is open for editing by hand. 
    
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
  - Allow designing modular pcb design. 
    
    
# TO BE CONTINUED
  
