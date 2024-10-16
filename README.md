## Intro
If you use other hlsl mods make sure to modify both this set and the other for compatibility. Either way drop the fx files in "...\H3EK\source\rasterizer\hlsl"
As porting to newer games: It's likely compatible with Halo 3 ODST and maybe ElDewrito. Reach+, you will have to do extra work.
There's also sample tags you can use you can use (thanks to RynoMods for porting the portable shield)

## How to set up
### Most of the functions are for `halogram` we will set things up in the `render_method_defintion` tag 
1. Open `shaders\halogram.render_method_definition` and add a new block in the category you want to modify
![setup](https://github.com/SpartanJoe193/SpartanJoe-HLSL/blob/main/pics/render_method_definition_setup.png?raw=true)

3. Create a new `render_method_option` tag. Check the parameters of the HLSL file then add them there.
   For example. `transparent_generic.fx` has the float4 (rgba) parameter `plasma_color`, add that in the
   render_method_option then set it to rgba color. Float1 paramters are under `real`
![param fx](https://github.com/SpartanJoe193/SpartanJoe-HLSL/blob/main/pics/fx%20file%20parameter.png?raw=true)
![param setup](https://github.com/SpartanJoe193/SpartanJoe-HLSL/blob/main/pics/parameters%20in%20option.png?raw=true)

### We will now create compile the actual shaders
3. Extract the tags and source folder the to the `H3EK` root directory e.g. `F:/Steam/steampps/common/H3EK`. The tags folder already has the necessary shader tags and sample tags that use them

4. Run the following commands:
   ```
      tool shaders win
      tool dump-render-method-toptions
      tool generate-templates win shaders\halogram
   ```

   Check for any errors. If you see `PC and durango constant tables do not match` do not panic. You are compiling shaaders for Windows, Durango is for Xbox. Always check debug text files
   for more details.

6. Open up Sapien. Load any scenario you want like `levels\test\box\box` and place the sample tags.

7. If the sample tags' shaders render, then you've succeeded.

![final render](https://github.com/SpartanJoe193/SpartanJoe-HLSL/blob/main/pics/Screenshot%202024-10-16%20104110.png)
Notes:
- `cook_torrance_ggx.fx` is broken. Any attempt at compiling will result in errors.
- any tag that uses the functions in `transparent_generic.fx` is strongly recommended to have `calc_self_illumination_transparent_ps` setup in the same `render_method_definition` tag as well
- you can to port the hlsl functions to ODST and newer games although as previously stated porting them to Reach+ games require more effort 
