# What is wrong with Kicad?  

- No component based design approach: Broken by design.
  - Hierarchical sheets just work wrong:
    - Can not assign correct references when duplicating a hierarchical sheet[**¹**](https://github.com/aktos-io/kicad-tools/blob/master/kicad-fix-refs).
    - Can not handle circular dependencies 
    - Does not perform a cleanup for deleted/moved HSheets. We need [a separate tool for that purpose](https://github.com/aktos-io/kicad-tools/blob/master/kicad-cleanup-sheets). 
    - Importing other schematics does not append its hierarchical sheets (no dependency tracking)
    - Weird design for storing instance references: HSheet instance references are stored in their own hierarchical sheets, thus you may easily end up duplicate/conflicting component references when you copy a HSheet to another project, duplicate a HSheet in the same project and rename it, etc... 
      - Hard to create new tools for handling the problem.
- Bugfixes take centuries. 
- [Feature requests are not welcome.](https://forum.kicad.info/t/can-i-merge-2-separate-kicad-board-designs-into-new-pcb-layout/821/14?u=ceremcem)
- It's so hard to install both Kicad and the libraries that that we needed [a separate project for that purpose](https://github.com/aktos-io/kicad-install)
- New versions can be incompatible with the previous versions without any compatibility mode. You may loose your projects that you made 6 months ago. 
- Unhelpful error messages:
  - "Multiple item D3 (unit 1)": What is "unit 1"? Where is it? What should I do?

### Schematic Editor 

- No correct component based approach (started with hierarchical sheets, but it does only a basic job)
- [Changing grid size prevents you to edit your schematic](https://forum.kicad.info/t/shematic-wire-can-not-be-connected/2891)
- No copy-n-paste from another schematic editor. Select+copy+paste simply don't work between open windows.

### PCB Editor

- Only basic support for alignment, no rulers etc.
- No component-based design [(you can not re-use your pcb drawings in another projects)](https://forum.kicad.info/t/can-i-merge-2-separate-kicad-board-designs-into-new-pcb-layout/821)
- Lack of manufacturing mode: You can not create multiple drawings to print out at the same time.
- No copy-n-paste from another pcbnew editor.
- Footprint associations is a pain
  - Doubleclick just changes a footprint, without confirmation or undo option. 
  - You can not unassign a footprint association, only option is deleting everything
  - No footprint association table that you can freely edit

# What is wrong with EasyEDA?

- Not open source. 
- No offline ability. 
