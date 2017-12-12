# aeda

## What is it 

Electronic Design Automation software, like Kicad, but using the web technologies like EasyEDA, with offline installation support. It will be like [Onshape](https://www.onshape.com/) to Solidworks.

Basically a software to create real-world drawings from schematics:

![image](https://user-images.githubusercontent.com/6639874/33883344-862bcbd6-df4c-11e7-84c9-7a077be731a9.png)


## What is wrong with Kicad?  

- No component based approach (Hierarchical sheets just work wrong)
- Bugfixes takes years. 
- So hard to install Kicad, so hard to install libraries that we need another project [for that purpose](https://github.com/aktos-io/kicad-install)
- Versions can be incompatible with the previous versions. You may loose your projects that you made 6 months ago. 

### Schematic Editor 

- No correct component based approach (started with hierarchical sheets, but it does only a basic job)
- Hard to use (IMHO)
- [Changing grid size prevents you to edit your schematic](https://forum.kicad.info/t/shematic-wire-can-not-be-connected/2891)

### PCB Editor

- Only basic support for alignment, no rulers etc.
- No component-based design [(you can not re-use your pcb drawings in another projects)](https://forum.kicad.info/t/can-i-merge-2-separate-kicad-board-designs-into-new-pcb-layout/821)
- Lack of manufacturing mode: You can not create multiple drawings to print out at the same time.
- Hard to use (IMHO)


## What features will AEDA have?

- Web based collaboration
- Versioning support for drawings out of the box: You may produce some PCB's and you may update the schematics later on. PCB's will include an automatically tracked schematic version.

### Schematic editor 
  - Create new components easily 
  - Component based design: You will use your existing components to create sub-circuits
    - Dependency tracking for sub-components
    
### PCB editor 
  - A complete graphics editor (including align tool, rulers, etc.)
  - Component based approach: You will be able to re-use your existing PCB drawings 
  - Multiple association of PCB drawings for the same schematic: You may draw more than one PCB for the same schematic. You will be able to use any of them, or create a new design. 
  - Inherit from Kicad: 
    - [Push and shove routing](https://www.youtube.com/watch?v=kzro0Jc70xI)
    - Net classes 
    
    
# TO BE CONTINUED
  
