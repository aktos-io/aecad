require! './get-aecad': {get-aecad, get-parent-aecad}
require! './get-class': {get-class, add-class}
require! './find-comp': {find-comp}
require! './component-base': {ComponentBase}
require! './table2obj': {table2obj}
require! './schematic': {Schematic}

utils = {
    get-class, add-class
    get-aecad, get-parent-aecad
    find-comp
    ComponentBase
    table2obj
    Schematic
}

# Component classes
require! './container': {Container}
require! './footprint': {Footprint}
require! './pad': {Pad}
require! './trace': {Trace}

component-classes = {
    Container, Footprint, Pad, Trace
}

for n, cls of component-classes
    add-class cls

module.exports = utils <<< component-classes
