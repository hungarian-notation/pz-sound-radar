local colorutil = require('hfsound/colors')


return {
    parse           = colorutil.parse_rgba,

    SimpleColor     = require('hfsound/scope/_color/simple'),
    CyclicColor     = require('hfsound/scope/_color/cyclic'),
    ConfiguredColor = require('hfsound/scope/_color/configured'),
}
