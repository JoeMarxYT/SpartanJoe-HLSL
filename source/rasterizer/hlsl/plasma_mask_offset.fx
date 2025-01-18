#ifndef _PLASMA_MASK_OFFSET_FX_ 
#define _PLASMA_MASK_OFFSET_FX_

// #include "additional_parameters.fx" // Don't need this shit anymore because we need to explain SOTR functions here

// Special thanks to  ...H2EK\tags\rasterizer\pixel_shaders_dx9\shaders_shader_passes_transparent_plasma_mask_offset_0.psh

/*
=============================================
Created by SpartanJoe193
last modified on December 30th, 2024 1:48 PM GMT+8
=============================================
*/

#define SRCCOLOR albedo.rgb
#define SRCALPHA albedo.a


PARAM_SAMPLER_2D(plasma_mask_map);
PARAM(float4, plasma_mask_map_xform);
PARAM_SAMPLER_2D(plasma_offset_map);
PARAM(float4, plasma_offset_map_xform);
PARAM_SAMPLER_2D(plasma_noise_map_a);
PARAM(float4, plasma_noise_map_a_xform);
PARAM_SAMPLER_2D(plasma_noise_map_b);
PARAM(float4, plasma_noise_map_b_xform);

PARAM(float, plasma_factor1);
PARAM(float, plasma_factor2);
PARAM(float3, glow);
PARAM(float3, plasma_tint);
PARAM(float, tint_glow_blend);

PARAM(float, plasma_mask_strength);
PARAM(float, plasma_brightness);                                //  Applied before self illum
PARAM(bool, masked);                              				//  D1 is multiplied to R1. If on, R1 equals plasma mask's color (T3), else it's plasma mask's inverted alpha INVERT(T3a)
PARAM(bool, separate_glow_and_tint);							//	If true D1 equals lerp($plasma_tint, $glow, $tint_glow_blend) else it's just $glow

// PARAM(float, plasma_factor3);                                //  Deprecated, replaced by $plasma_mask_strength
// PARAM(float4, color_0);                                      //  Deprecated, replaced by $plasma_tint
// PARAM(float3, color_1);                                    	//  Deprecated, replaced by $glow

// PARAM(float, plasma_illumination);                           //  Deprecated, please use calc_self_illum_from_albedo_ps


 /* float3 calc_self_illumination_transparent_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
	// Concocted specifically to be used alongside plasma_mask offset
	float3 self_illum= albedo * plasma_illumination;
	
	return(self_illum);
}
*/

//#define MUX(a, b) R0a >= 0.5 ? b : a
#define MUX(a, b) lerp(a, b, round(R0a))

void calc_albedo_plasma_mask_offset_ps(
    in float2 texcoord,
	out half4 albedo,
	in float3 normal,
	in float4 misc)
{

		float4 plasma_mask = 		saturate(sample2D(plasma_mask_map, transform_texcoord(texcoord, plasma_mask_map_xform)));
		float T2a = 				saturate(sample2D(plasma_offset_map, transform_texcoord(texcoord, plasma_offset_map_xform)).a);
		float T1a = 				saturate(sample2D(plasma_noise_map_b, transform_texcoord(texcoord, plasma_noise_map_b_xform)).a);
		float T0a = 				saturate(sample2D(plasma_noise_map_a, transform_texcoord(texcoord, plasma_noise_map_a_xform)).a);

	//  Both Halo 1 and Halo 2's imeplentations have been merged into one

			float3 T3 = plasma_mask.rgb;
			float T3a = plasma_mask.a;

    half R0a, R0b;
    half3 R0, R1, D1;



    // ---
    // // Stage 0: Pre-Plasma Stage

    // C0= {0, 0, $plasma_factor2}
    // C0a= $plasma_factor1

    // R0= INVERT(C0a)*T2a + C0a*T0a   // linear interpolation
    // R0a= INVERT(C0b)*1/2 + C0b*T1a  // INVERT(C0b) / 2 is acceptable
    		R0b = (1.0 - saturate(plasma_factor1)) * saturate(T2a) + saturate(plasma_factor1) * saturate(T0a);
			R0a = (1.0 - saturate(plasma_factor2)) / 2.0 + saturate(plasma_factor2) * saturate(T1a);

    // ---
    // // Stage 1: Preparation Stage

    // R0= T3a*1/2 + INVERT(T3a)*R0    // T3a/2
    // R0a= T3a*1/2 + INVERT(T3a)*R0a
			R0b = saturate(T3a) / 2.0 + (1.0 - saturate(T3a)) * saturate(R0b);
		    R0a = saturate(T3a) / 2.0 + (1.0 - saturate(T3a)) * saturate(R0a);

    // ---
    // // Stage 2: Half-Bias Stage

    // R0= R0 + HALF_BIAS_NEGATE(R0a)            // half-bias is x - 0.5
    // R0a= R0a + HALF_BIAS_NEGATE(R0b)
			R0b = saturate(R0b) - saturate(R0a)  + 0.501961;    // Because we are clamping between 0 and 1, we use half bias negate (-v + 0.5) to prevent artifacts
			R0a = saturate(R0a) - saturate(R0b)  + 0.501961;    // Don't know why Halo Studios chose 0.501961 when they fixed the shaders for Halo 2
    // ---
    // // Stage 3: Plasma Scale By 4 and Glow Stage

    // C0= $plasna_tint
    // C0a= $tint_glow_blend
    // C1= $glow

    // #switch $glow_and_tint
    //     #case true
    //         D1= INVERT(C0a)*C0 + C0*C1 // linear interpolation
    //     #case false 
    //         D1= $glow
    // #endswitch

    // R0a= OUT_SCALE_BY_4(R0a*R0a mux R0b*R0b)
        	D1 = D1= (1.0 - tint_glow_blend) * plasma_tint + tint_glow_blend * glow;
			D1 = separate_glow_and_tint ? saturate(glow) : saturate(D1);

			R0a= MUX(saturate(R0a), saturate(R0b)); // If R0a equals 0.5 or higher, 4(R0b^2) is the output, otherwise it's 4(R0a^2)
			R0a= 4.0 * (R0a * R0a);

    // ---
    // // Stage 4: Mask Attenuation and Plasma Sharpening Stage
    // C0a = $plasma_mask_strength

    // T3= = T3*C0a				                // Not scaling by causes visibility issues because gamma correction default is 4
    // R0a= 0 mux EXPAND(R0a)*EXPAND(R0a)       // Expand is 2x-1
    		T3	= saturate(T3*plasma_mask_strength);
			if(separate_glow_and_tint)
			{
				T3 = plasma_tint*T3;
			}
            
			R0a= 	MUX(0.0, 2.0 * saturate(R0a)  - 1.0);
            R0a=    R0a*R0a;  // saturate removes shading artifacts

    // ---
    // // Stage 5: Mask Colorizing and Plasma Dulling stage

    // C0 = $plasma_tint
    // #switch $glow_and_tint
    // 	#case true
    // 		T3= T3*C0
    // 	#case false
    // 		T3= T3;
    // 			#endswitch
    //
    // R0a= R0a + R0a*INVERT(R0a)
    		R0a= (saturate(R0a) + saturate(R0a) * (1.0-saturate(R0a))); 		// R0a

    // ---
    // // Stage 6: Plasma Masking Stage

    // #switch $masked
    //     #case true
    //         R1= D1*T3
    //     #case false
    //         R1= D1*INVERT(T3a)
    // #endswitch
    //
    // R0= R0a*T3 + R1

            R1 = masked ? (4.0 * saturate(plasma_mask.rgb)) : (1.0 - saturate(T3a));      // saving time
            R1 = saturate(D1) * saturate(R1);
			R0=  saturate(R0a) * saturate(T3) + saturate(R1);

    // ---
    // // Stage 7: Post-Processing Stage

    // C0a= $plasma_brightness           // applied before self_illum
    // SRCCOLOR= R0*C0a
    // SRCALPHA= 0

    		SRCCOLOR = R0 * plasma_brightness;
			SRCALPHA = 0;

	//apply_pc_albedo_modifier(albedo, normal);


}

#undef SRCCOLOR
#undef SRCALPHA


#endif