#ifndef _PLASMA_MASK_OFFSET_FX_ 
#define _PLASMA_MASK_OFFSET_FX_

#include "additional_parameters.fx"

/*
=============================================
Created by SpartanJoe193
last modified on November 14th, 2024 2:51 AM GMT+8
=============================================
*/

// We need to redefine some shit first because Halo 1 handles this differenely
#undef SRCCOLOR
#undef SRCALPHA

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

PARAM(float4, color_0);                                        	//  $plasma_color in config 0 & 1, $plasma_tint in config 2
PARAM(float3, color_1);                                        	//  $plasma_flash_color in config 0 & 2, $glow in config 2
PARAM(float, plasma_factor1);
PARAM(float, plasma_factor2);
PARAM(float, plasma_factor3);
PARAM(float, plasma_brightness);
PARAM(bool, masked);                              				//  See below
PARAM(bool, glow_and_tint);										//	color_0 tints plasma mask while glow color1 Colors R1


PARAM(float, plasma_illumination);


float3 calc_self_illumination_transparent_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
	// Concocted specifically to be used alongside plasma_mask offset
	float3 self_illum= albedo * plasma_illumination;
	
	return(self_illum);
}

#define MUX(a, b) R0a >= 0.5 ? b : a

void calc_albedo_plasma_mask_offset_ps(
    in float2 texcoord,
	out float4 albedo,
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

    float R0a, R0b;
    float3 R0, D1;

    // ---
    // // Stage 0: Pre-Plasma_stage

    // C0= {0, 0, $plasma_factor2}
    // C0a= $plasma_factor1

    // R0= INVERT(C0a)*T2a + C0a*T0a   // linear interpolation
    // R0a= INVERT(C0b)*1/2 + C0b*T1a  // T3/2 is accemptable
    		R0b = saturate(lerp(T2a, T0a, plasma_factor1));
			R0a = saturate(lerp(0.5, T1a, plasma_factor2));

    // ---
    // // Stage 1: Preparation Stage

    // R0= T3a*1/2 + INVERT(T3a)*R0    // T3a/2
    // R0a= T3a*1/2 + INVERT(T3a)*R0a
			R0b = (T3a/2.0) + (INVERT(T3a)*R0b);
		    R0a = (T3a/2.0) + (INVERT(T3a)*R0b);

    // ---
    // // Stage 2: Half-Bias Stage

    // R0= R0 - HALF_BIAS(R0a)
    // R0a= R0a - HALF_BIAS(R0b)
			R0b = (R0b) - HALF_BIAS(R0a);
			R0a = (R0a) - HALF_BIAS(R0b);

    // ---
    // // Stage 3: Plasma Scale By 4 and Glow Stage

    // C0= $color_0.rgb
    // C0a= $color_0.a
    // C1= $color_1

    // #switch $glow_and_tint
    //     #case true
    //         D1= INVERT(C0a)*C0 + C0*C1 // linear interpolation
    //     #case false 
    //         D1= $color_1
    // #endswitch

    // R0a= OUT_SCALE_BY_4(R0a*R0a mux R0b*R0b)
        	D1 = D1= INVERT(color_0.a)*color_0.rgb + color_1*color_0.a;
			D1 = glow_and_tint ? color_1 : D1;

			R0a= MUX((R0a*R0a), (R0b*R0b));
			R0a= (4.0*R0a);
    // ---
    // // Stage 4: Mask Attenuation and Plasma Sharpening Stage
    // C0a = $plasma_factor3

    // T3= OUT_SCALE_BY_4(T3*C0a)				// Addresses visibility issues
    // R0a= 0 mux EXPAND(R0a)*EXPAND(R0a)
    		T3	= (4.0*T3*plasma_factor3);
			if(glow_and_tint)
			{
				T3 = color_0.rgb*T3;
			}
            
			R0a= 	MUX(0.0, (EXPAND(R0a)*EXPAND(R0a))); 							// R0a
            R0a=    saturate(R0a);

    // ---
    // // Stage 5: Mask Colorizing and Plasma Dulling stage

    // C0 = $color_0.rgb
    // #switch $glow_and_tint
    // 	#case true
    // 		T3= T3*C0
    // 	#case false
    // 		T3= T3;
    // 			#endswitch

    // R0a= R0a + R0a*INVERT(R0a)
    		R0a= R0a + R0a*INVERT(R0a); 		// R0a
            R0a= saturate(R0a);

    // ---
    // // Stage 6: Plasma Masking Stage

    // #switch $masked
    //     #case true
    //         R1= INVERT(T3a)
    //     #case false
    //         R1= T3
    // #endswitch

    // R0= R0a*T3 + D1*R1
		
			R0 = (R0a*T3) + (D1*INVERT(T3a));
				if(masked){
                        R0= (R0a*T3) + (D1*(4.0*plasma_mask.rgb));
                        }

    // ---
    // // Stage 7: Post-Processing Stage

    // C0a= $self_illum_intensity           // handled by calc_self_illumination_transparent_ps
    // SRCCOLOR= R0*C0a
    // SRCALPHA= 0

    		SRCCOLOR = saturate(R0);
			SRCALPHA= 0;

	apply_pc_albedo_modifier(albedo, normal);


}

#endif