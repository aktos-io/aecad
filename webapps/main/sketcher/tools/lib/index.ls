require! './get-aecad': {get-aecad, get-parent-aecad}
require! './get-class': {get-class, add-class}
require! './find-comp': {find-comp}
require! './component-base': {ComponentBase}

utils = {
    get-class, add-class
    get-aecad, get-parent-aecad
    find-comp
    ComponentBase
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