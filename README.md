## Intro
If you use other hlsl mods make sure to modify both this set and the other for compatibility. Either way drop the fx files in "...\H3EK\source\rasterizer\hlsl"
As porting to newer games: It's likely compatible with Halo 3 ODST and maybe ElDewrito. Reach+, you will have to do extra work.
There's also sample tags you can use you can use (thanks to RynoMods for porting the portable shield)

## How to set up
### Most of the functions are for `halogram` we will set things up in the `render_method_defintion` tag 
1. Open `shaders\halogram.render_method_definition` and add a new block in the category you want to modify
![setup](https://github.com/SpartanJoe193/SpartanJoe-HLSL/blob/main/pics/render_method_definition_setup.png?raw=true)
2. Create a new `render_method_option` tag. Check the parameters of the HLSL file then add them there.
   For example. `transparent_generic.fx` has the float4 (rgba) parameter `plasma_color`, add that in the
   render_method_option then set it to rgba color. Float1 paramters are under `real`
![param fx](https://github.com/SpartanJoe193/SpartanJoe-HLSL/blob/main/pics/fx%20file%20parameter.png?raw=true)
![param setup](https://github.com/SpartanJoe193/SpartanJoe-HLSL/blob/main/pics/parameters%20in%20option.png?raw=true)

### We will now compile the actual shaders
3. extract the files to the `H3EK` folder
