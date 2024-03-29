[![image](https://user-images.githubusercontent.com/6639874/57297951-9dd97880-70d9-11e9-9d63-be42fa1f6c30.png)](https://aktos.io/aecad)

# aeCAD

## What is it?

Electronic Design Automation software, like [KiCAD](http://kicad.org/), but using the web technologies (runs in the browser or desktop via [ElectronJS](https://electronjs.org/)) like [EasyEDA](https://easyeda.com/), with offline installation support. It will be like [Onshape](https://www.onshape.com/) to [Solidworks](http://www.solidworks.com/).

Basically a software to create schematics and real-world drawings for physical production (and/or machining).

# Key Features 

| Feature &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Description
| -------------- | --- | 
| **Parametric footprints** | Create inheritable, parametric footprints. Only new topologies has to be created, rest of footprints are only differs by their parameter values, such as pin count and pin labels. No need for incomprehensible libraries.
| **Component based design** | Create re-usable circuits to build huge and complex circuits.
| **Scripting support** | Create schemas and PCB layouts via Livescript and/or Javascript. 
| **Correct Tools for Placement** | Appropriate tools to use your EDA in tandem with a mechanical CAD output for a correct approach of handling mechanical constraints (PCB geometry, bolt placements, socket placements, heatsink placements, etc.)
| **Browser based** | Installation headache is over. Open your browser, start using. No need for active internet connection after first load.
| **Healthy** | Shortcuts and tools are designed with [Carpal Tunnel Syndrome](https://en.wikipedia.org/wiki/Carpal_tunnel_syndrome) in mind. 

# Status

Pre-beta: We, as [Aktos Electronics](https://aktos.io), are using aeCAD in production. However [some cruical features](https://github.com/aktos-io/aecad/issues?q=is%3Aopen+is%3Aissue+milestone%3ABeta) are still missing.

## Why Another Software?

- See [What is wrong with Kicad](./problems-with-others.md#what-is-wrong-with-kicad)
- See [What is wrong with EasyEDA](./problems-with-others.md#what-is-wrong-with-easyeda)

# What features will aeCAD have?

- Web based collaboration
  - Realtime online collaboration for helping, task sharing, etc.
- Versioning support for drawings out of the box: You may produce some PCB's and you may update the schematics later on. PCB's will include an automatically tracked schematic version.
- Support for Test Driven Development: Every subproject might require its own test procedure. Test procedures will be defined within schematics and concatenated as a checklist on demand.
- Inherit from Kicad
  - Selecting a component in schematic/PCB will show where it is located on PCB/schematic.
    - Smooth camera change between components
    - Distincly visible cursor for schematics (and pcb)
- Drawing records: Any drawing will be able to recorded programmatically
  - "How to" support out of the box: Send a portion of a real *drawing record* to a colleauge/user that will serve as a mini tutorial.
    - Makes it possible to search in tutorial "videos"
  - Infinite undo/redo operations
  - Create tutorials from real works
  - Edit to strip down a *drawing record video* by a text editor (or online) to make HowTo's shorter.
  - Visual representation of two versions of a drawing, like `git diff` but more visual form like in [Meld](https://user-images.githubusercontent.com/6639874/34307383-f1242316-e758-11e7-8f10-ec4fb162899b.png), step by step (like a motion capture video)
  - Replay since last commit: A quick and smooth replay from last commit helps developer what he is changed so far, thus will allow a proper commit message

- Hotkeys:
  - Keyboard focused hotkeys: Hotkeys should be bound to physical keys on the keyboard, not letters, because main purpose of hotkeys is make usage faster and if keyboard layout is different from US (or like), "hotkeys" might not be "hot" enough.
  - It will be possible to bind macros to hotkeys (press a `KEY` to do that, do this and do some other thing).
- Virtual layers: Grouping some drawings at the same physical layer, like the [layers in Gimp](https://user-images.githubusercontent.com/6639874/34307018-2d156fc6-e757-11e7-8ceb-582ee74d99af.png).
- A complete graphics editor (including align tool, rulers, etc.)

### Schematic editor
- Create new components easily
- Component based design:
  - You will be able to use your existing components (sub-circuits) in your PCB design (as if they are modules)
    - Copy-n-paste will create another instance of a sub-circuit. References will be stored as changes in each instance.
    - Any instance will be made unique (like in SketchUP)
    - Any instance's class can be changed to another class (sub-circuit).
      - Current references may or may not be changed. This will be left to the user.
    - Any selection can be turned into a sub-circuit in-place.
  - Dependency tracking for sub-circuits
- Schematic time design rules (see Advanced desing rules)
- Human readable Netlist syntax: Any schematic can be read in text mode and can be edited by hand, with a text editor.
- Topological versioning: Schematic file itself might be changed somehow (added/removed/moved a wire, for example) but topology might stay intact. This topological version is important, schematic file version (the SHA1 of the file, for example) is not. So schematic editor should provide this topological version for printing onto the PCB.
- Printable schematics:
  - Cross references (like in EPlan)
  - A separate, well structured annotation table which will let you to edit the printed version of the schematic by hand and pass both the annotation table and the schematics to the software from printed version, lazily.
- Wire/label representation of a connection (like in Siemens Logo Comfort), but highlight the connection as wire on hover.

### Footprints

- Components that will be used in a single footprint should be assigned independently from schematic. For example, a schematic may include 4 different opamps and these opamps might be chosen 4 different IC's or 1 IC with 4 opamps. This difference is independent from schematic, thus must be adjusted independently from schematic time. (This is mandatory if we want to use multiple components in an IC package while each of these components are coming from different instances of a sub-circuit. This is a kind of component optimization.)
- Class based footprint association:
  - Declare your technology (eg. "I'll use SMD_1206 packages for resistors, etc.), overwrite any of the components when needed.
  - Change your technology definition later if needed (eg. "I'll use 805 packages instead of 1206 packages" and it will handle the rest)



### PCB editor
- Component based approach:
  - You will be able to re-use your existing PCB drawings for a schematic component (as if they are [castellated circuits](https://user-images.githubusercontent.com/6639874/34306391-e57154d0-e753-11e7-8079-a435ea0059cb.png)).
  - Multiple association of PCB drawings for the same schematic: You may draw more than one PCB for the same schematic. You will be able to use any of them, or create a new design. For example, you may define PCB layouts for the same schematic for single sided PCB placement, for double sided PCB placement, for 4 layer setup, etc... over time and use any of them later on.

- Inherit from Kicad:
  - [Push and shove routing](https://www.youtube.com/watch?v=kzro0Jc70xI)
  - Net classes
    - Allow to freely select any netclass on each tracing.
  - [Highlight net](https://github.com/ceremcem/aeda/issues/2)
    - Highlight net when a wire or component is clicked in schematic
- Components as PCB layers: A zero ohm resistor or a piece of wire might be used just like a jumper.
- Modular PCB design:
  - A design may include another project as a module. Pin connections should point the outer project's specified pins.
  - A design may be made up of more than one PCB (modules). Provide a free cabling layer for that purpose.

### Design Rules

- Schematic time design rules
  - Component based DRC (design rule checking): A component will be able to make you warn if you connect a pin to any wrong ping (for example, a warning will be thrown if you connect `VDD` to `GND`.
  - PCB Design rule definitions: You are not always allowed to place your components onto the PCB freely in real-world applications. For example the manufacturer of an MCU requires you to place parasitic capacitors as close as possible to the MCU pins. Moreover, they require some specific capacitors to be placed close to some specific pins. This should (and will) be possible at the definition (schematic/sub-circuit) step.
- PCB time design rules
  - Dynamic collision dedection: A realtime process that checks if PCB can currently fit in the physical case.
  - Inherit from Kicad
    - Clearance definition

# Intended Workflow

When we need a custom hardware, following actions must be taken in this specific order:

1. Design/choose or optimize the device case/housing.
2. Get or create the connectors' 3D models, place them within the housing in your preferred mechanical CAD software.
3. PCB edge cuts, connector placements (pin holes) on the PCB and mechanical keep out areas should be determined in 3D design phase.
4. Export the PCB layout in DXF format and import it in aeCAD. 
5. Place the rest of the circuit components, draw the PCB.
6. If any optimization is required (in case of component collision, insufficient PCB space, etc...), go to step 1.
7. Produce a prototype PCB
8. Finalize the design and create fabrication files (Gerber files etc.)

# Install

### Use Online 

You can use aeCAD online at https://aktos.io/aecad

### Use Offline

You can download the files and open in your browser. 

1. Download the latest release: https://github.com/aktos-io/aecad-webapp/archive/master.zip
2. Unzip 
3. Open the `index.html` in your browser. 

### Build aeCAD

See [./docs/development.md](./docs/development.md)

# Usage

This part is under development. I can barely find time to complete the documentation. You can start with `Help` button, on the top right corner. Then simply click to green "Compile" button (`[>]`), poke around with the example design (which can be downloaded by its link button). 

# TODO

* Get the good design bits from [Horizon](https://github.com/carrotIndustries/horizon/wiki/Feature-overview).
* Get the good design bits from [pcb-rnd](http://repo.hu/projects/pcb-rnd/index.html)

# Similar Projects

* [MeowCAD](https://meowcad.com)
