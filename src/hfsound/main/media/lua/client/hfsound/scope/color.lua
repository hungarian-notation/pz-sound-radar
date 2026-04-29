local colorutil = require('hfsound/colors')


return {
    parse           = colorutil.parse_rgba,

    SimpleColor     = require('hfsound/scope/_color/simple'),
    ConfiguredColor = require('hfsound/scope/_color/configured'),
}
