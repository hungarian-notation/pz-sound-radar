# PROTOTYPING SUBMODULE

This module enables rapid prototyping of  graphics features via a compatibility 
and translation layer that allows parts of the mod to run under 
[Löve2D](https://love2d.org).

I've implemented a incredibly sparse set of mocks that emulate enough of 
Project Zomboid's Lua environment to keep the renderer happy, while translating 
calls to `getTexture` and the single `renderPolygon` method it uses.

In order for `getTexture` to work properly, the `hfsound/common/media` 
directory must be accessible as a child path of this module. This is achieved 
with a symlink. On windows, you can use setup.bat to create this link 
automatically.

Note that the mod must be built before this module will work as some of the 
resources required by the renderer are generated.