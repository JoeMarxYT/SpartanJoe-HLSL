## Intro
If you use other hlsl mods make sure to modify both this set and the other for compatibility. Either way drop the fx files in "...\H3EK\source\rasterizer\hlsl".
As for porting to newer games: It's likely compatible with Halo 3 ODST and maybe ElDewrito. Reach+, you will have to do extra work.
There's also sample tags you can use you can use (thanks to RynoMods for porting the portable shield)

## Functions:
- Cook-Torrance GGX (base and PBR maps);
- plasma mask offset (both Halo 1 and Halo 2 implementations);
- multipurpose map support;

## How to set up
### We will set things up in the `render_method_defintion` tag 
#### Steps 1 and 2 are for any custom shader function you made yourself

1. Open a `render_method_definition` tag like `shaders\halogram.render_method_definition` and add a new option block in the category you want to modify. In the new block type the name of your custom pixel shader (e.g. `calc_albedo_plasma_offset_legacy`).
![setup](https://github.com/SpartanJoe193/SpartanJoe-HLSL/blob/main/pics/render_method_definition_setup.png?raw=true)

2. Create a new `render_method_option` tag. Check the parameters of the HLSL file then add them there.
   For example. `transparent_generic.fx` has the float4 (rgba) parameter `plasma_color`, add that in the
   render_method_option then set it to rgba color. Float1 paramters are under `real`

Return to the `render_method_definition` tag you modified then link the `render_method_option` tag in the option tag reference.
![param fx](https://github.com/SpartanJoe193/SpartanJoe-HLSL/blob/main/pics/fx%20file%20parameter.png?raw=true)
![param setup](https://github.com/SpartanJoe193/SpartanJoe-HLSL/blob/main/pics/parameters%20in%20option.png?raw=true)

### We will now create compile the actual shaders
3. Extract the tags and source folder the to the `H3EK` root directory e.g. `F:/Steam/steampps/common/H3EK`. The tags folder already has the necessary shader tags and sample tags that use them

4. Run the following commands:
   ```
      tool shaders win
      tool dump-render-method-toptions
      start tool generate-templates win shaders\halogram
      start tool generate-templates win shaders\shader

   ```
The commands first compile the explicit shaders then dump the render method options and finally the templates in separate windows.

   Check for any errors. If you see `PC and durango constant tables do not match` do not panic. You are compiling shaaders for Windows, Durango is for Xbox. Always check debug text files for more details.

6. Open up Sapien. Load any scenario you want like `levels\test\box\box` and place the sample tags.

7. If the sample tags' shaders render and they look something like this, then you've succeeded.

![final render](https://github.com/SpartanJoe193/SpartanJoe-HLSL/blob/main/pics/Screenshot%202024-10-16%20104110.png)
Notes:
- The Material Models "Cook Torrance GGX" and its PBR map derivative now work albeit the pixel shader `FresnelFast` causes shader artifacts when used
- any tag that uses the functions in `transparent_generic.fx` is strongly recommended to have `calc_self_illumination_transparent_ps` setup in the same `render_method_definition` tag
- you can to port the hlsl functions to ODST and newer games although as previously stated porting them to Reach+ games require more effort
- all plasma mask offset functions are going to be unified in one function
