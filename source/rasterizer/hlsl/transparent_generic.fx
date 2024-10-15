/*
=============================================
Created by SpartanJoe193
last modified on October 9th, 2024 2:31 PM GMT+8
=============================================
*/


#ifndef _TRANPSARENT_GENERIC_FX_
#define _TRANPSARENT_GENERIC_FX_

#include "additional_parameters.fx"

PARAM_SAMPLER_2D(plasma_mask_map);
PARAM(float4, plasma_mask_map_xform);
PARAM_SAMPLER_2D(plasma_offset_map);
PARAM(float4, plasma_offset_map_xform);
PARAM_SAMPLER_2D(plasma_noise_map_a);
PARAM(float4, plasma_noise_map_a_xform);
PARAM_SAMPLER_2D(plasma_noise_map_b);
PARAM(float4, plasma_noise_map_b_xform);

PARAM(float4, plasma_color);
PARAM(float3, plasma_flash_color);
PARAM(float, plasma_factor1);
PARAM(float, plasma_factor2);
PARAM(float, plasma_brightness);


void calc_albedo_plasma_offset_legacy_ps(
	in float2 texcoord,
	out float4 albedo,
    in float3 normal,
	/*in float4 view_dir,*/
	in float4 misc)
{
	float4 plasma_mask = 		sample2D(plasma_mask_map, transform_texcoord(texcoord, plasma_mask_map_xform));
	float4 plasma_offset = 		sample2D(plasma_offset_map, transform_texcoord(texcoord, plasma_offset_map_xform));
	float4 plasma_noise_b = 	sample2D(plasma_noise_map_b, transform_texcoord(texcoord, plasma_noise_map_b_xform));
	float4 plasma_noise_a = 	sample2D(plasma_noise_map_a, transform_texcoord(texcoord, plasma_noise_map_a_xform));

// This is Halo 1's Implementation, I was unable to create the color fade due to limitations in my HLSL knowledge

	/* Only the following parameters are used */
	
	float3 T3 = plasma_mask.rgb;
	float T3a = plasma_mask.a;
	float T2 = 	plasma_offset.a;
	float T1 = 	plasma_noise_b.r;
	float T0 = 	plasma_noise_a.r;
	
	float4 	R0;
	float4 	R1;
	float4  V1;

	//float view_dot_normal = normalize(dot(view_dir.xyz, normal));
	float3	a, b, c, d, ab, cd, ab_cd;
	float	a_a, b_a, c_a, d_a, ab_a, cd_a, ab_cd_a;


/* Stage 0
C0 = (0, 0, $plasma_factor2)
C0a = $plasma_factor1

R0= 	INVERT(C0a)* UNSIGNED(T2a) + C0a*UNSIGNED(T0r)
R0a= 	INVERT(C0b)*1/2 + C0a*UNSIGNED(T1r)
*/
	R0.rgb= 	INVERT(plasma_factor1)*UNSIGNED(T2) + plasma_factor1*UNSIGNED(T0);
	R0.a= 		INVERT(plasma_factor2)*0.5 + plasma_factor2*UNSIGNED(T1);


/* Stage 1
R0= 	UNSIGNED(T3a)*1/2 + INVERT(T3a)*R0
R0a= 	UNSIGNED(T3a)*1/2 + INVERT(T3a)*R0a
*/
	R0.rgb= 	UNSIGNED(T3a)*0.5 + INVERT(T3a)*R0.rgb;
	R0.a= 		UNSIGNED(T3a)*0.5 + INVERT(T3a)*R0.a;

/* Stage 2
R0= 	R0 + HALF_BIAS_NEGATIVE(R0a)
R0a= 	UNSIGNED(R0a) + HALF_BIAS_NEGATIVE(R0b)
*/
	R0.rgb= 	R0.rgb + HALF_BIAS_NEGATIVE(R0.a);
	R0.a=		UNSIGNED(R0.a) +  HALF_BIAS_NEGATIVE(R0.b);

/* Stage 3
		C0= $plasma_color
		C1= $plasma_flash_color

		R0a= SCALE_BY_4(R0b*R0b mux R0a*R0a)
		V1= UNSIGNED_INVERT(C0a) * C0 + C0 * C1

		If R0a is greater than than 0.5, CD is returned, else AB
*/
R0.a=		R0.a>=0.5 ? UNSIGNED(R0.b*R0.b) : UNSIGNED(R0.a*R0.a);
R0.a*= 		4.0;
V1.rgb= 	INVERT(plasma_color.a)*plasma_color.rgb + plasma_color.a*plasma_flash_color; //C0a's value determines what color the shield is


/* Stage 4
R0a= 	0 mux EXPAND_UNSIGNED(R0a)*EXPAND_UNSIGNED(R0a)
*/
R0.a=		R0.a>=0.5 ? (EXPAND_UNSIGNED(R0.a)*EXPAND_UNSIGNED(R0.a)) : (0*0);

/* Stage 5
R1= 	INVERT(T3a)
R0a= 	OUT_SCALE_BY_2(UNSIGNED(R0a) + UNSIGNED(R0a)*UNSIGNED_INVERT(R0a))
*/
R1.rgb= 	INVERT(T3a);
R0.a=		UNSIGNED(R0.a) + UNSIGNED(R0.a)*UNSIGNED_INVERT(R0.a);
R0.a*=		2.0; // Removing this will cause shading artifacts

/* Stage 6
R0= 	UNSIGNED(R0a)*T3 + V1*R1
R0= 	R0 * $plasma_brightness
*/
R0.rgb=		UNSIGNED(R0.a)*T3 + V1.rgb*R1.rgb;
R0.rgb*= 	plasma_brightness;

albedo = 	R0;

apply_pc_albedo_modifier(albedo, normal);

}

PARAM(float3, plasma_tint);
PARAM(float3, glow);

void calc_albedo_plasma_offset_new_ps(
	in float2 texcoord,
	out float4 albedo,
    in float3 normal,
	/*in float4 view_dir,*/
	in float4 misc)
{
	float4 plasma_mask = 		sample2D(plasma_mask_map, transform_texcoord(texcoord, plasma_mask_map_xform));
	float4 plasma_offset = 		sample2D(plasma_offset_map, transform_texcoord(texcoord, plasma_offset_map_xform));
	float4 plasma_noise_b = 	sample2D(plasma_noise_map_b, transform_texcoord(texcoord, plasma_noise_map_b_xform));
	float4 plasma_noise_a = 	sample2D(plasma_noise_map_a, transform_texcoord(texcoord, plasma_noise_map_a_xform));

	/* Only the following parameters are used */
	
	float3 T3 = plasma_mask.rgb;
	float T3a = plasma_mask.a;
	float T2 = plasma_offset.a;
	float T1 = plasma_noise_b.a;
	float T0 = plasma_noise_a.a;

	float3 C0;
	float3 C1;

	float4 	R0;
	float4 	R1;
	float4  V1;
	float 	R0a;
	//float view_dot_normal = normalize(dot(view_dir.xyz, normal));

	float3	a, b, c, d, ab, cd, ab_cd;
	float	a_a, b_a, c_a, d_a, ab_a, cd_a, ab_cd_a;

// This is Halo 2's Implementation, the difference being the plasma mask's RGB can now be tinted

/* Stage 0
C0 = (0, 0, $plasma_factor2)
C0a = $plasma_factor1

R0= 	INVERT(C0a)* UNSIGNED(T2a) + C0a*UNSIGNED(T0r)
R0a= 	INVERT(C0b)*1/2 + C0a*UNSIGNED(T1r)
*/
	R0.rgb= 	INVERT(plasma_factor1)*UNSIGNED(T2) + plasma_factor1*UNSIGNED(T0);
	R0.a= 		INVERT(plasma_factor2)*0.5 + plasma_factor2*UNSIGNED(T1);


/* Stage 1
R0= 	UNSIGNED(T3a)*1/2 + INVERT(T3a)*R0
R0a= 	UNSIGNED(T3a)*1/2 + INVERT(T3a)*R0a
*/
	R0.rgb= 	UNSIGNED(T3a)*0.5 + INVERT(T3a)*R0.rgb;
	R0.a= 		UNSIGNED(T3a)*0.5 + INVERT(T3a)*R0.a;

/* Stage 2
R0= 	R0 + HALF_BIAS_NEGATIVE(R0a)
R0a= 	UNSIGNED(R0a) + HALF_BIAS_NEGATIVE(R0b)
*/
	R0.rgb= 	R0.rgb + HALF_BIAS_NEGATIVE(R0.a);
	R0.a=		UNSIGNED(R0.a) +  HALF_BIAS_NEGATIVE(R0.b);

/* Stage 3
		R0a= SCALE_BY_4(R0b*R0b mux R0a*R0a)

		If R0a is greater than than 0.5, CD is returned, else AB
*/
R0.a=		R0.a>=0.5 ? UNSIGNED(R0.b*R0.b) : UNSIGNED(R0.a*R0.a);
R0.a*= 		4.0;


/* Stage 4
R0a= 	0 mux EXPAND_UNSIGNED(R0a)*EXPAND_UNSIGNED(R0a)
*/
R0.a=		R0.a>=0.5 ? (EXPAND_UNSIGNED(R0.a)*EXPAND_UNSIGNED(R0.a)) : (0*0);

/* Stage 5
C0= 	$plasma_tint
C1= 	$glow

T3= 	T3*C0
R1= 	INVERT(T3a)
R0= 	INVERT(T3a)*C1
R0a= 	OUT_SCALE_BY_2(UNSIGNED(R0a) + UNSIGNED(R0a)*UNSIGNED_INVERT(R0a))
*/
T3= 		T3*plasma_tint;
R0.rgb=		INVERT(T3a)*glow;
R0.a=		UNSIGNED(R0.a) + UNSIGNED(R0.a)*UNSIGNED_INVERT(R0.a);
R0.a*=		2.0; // Removing this will cause shading artifacts

/* Stage 6
R0= 	UNSIGNED(R0a)*T3 + R0
R0= 	R0 * $plasma_brightness
*/
R0.rgb=		UNSIGNED(R0.a)*T3 + R0.rgb;
R0.rgb*= 	plasma_brightness;

albedo = 	R0;

apply_pc_albedo_modifier(albedo, normal);
}

#endif

void calc_albedo_plasma_offset_masked_ps(
	in float2 texcoord,
	out float4 albedo,
    in float3 normal,
	/*in float4 view_dir,*/
	in float4 misc)
{
	float4 plasma_mask = 		sample2D(plasma_mask_map, transform_texcoord(texcoord, plasma_mask_map_xform));
	float4 plasma_offset = 		sample2D(plasma_offset_map, transform_texcoord(texcoord, plasma_offset_map_xform));
	float4 plasma_noise_b = 	sample2D(plasma_noise_map_b, transform_texcoord(texcoord, plasma_noise_map_b_xform));
	float4 plasma_noise_a = 	sample2D(plasma_noise_map_a, transform_texcoord(texcoord, plasma_noise_map_a_xform));

// This is Halo another version of 1's Implementation the difference is the last stage is that
//	the plasma flash color is multiplied to the mask's rgb components

	/* Only the following parameters are used */
	
	float3 T3 = plasma_mask.rgb;
	float T3a = plasma_mask.a;
	float T2 = 	plasma_offset.a;
	float T1 = 	plasma_noise_b.r;
	float T0 = 	plasma_noise_a.r;
	
	float4 	R0;
	float4 	R1;
	float4  V1;

	//float view_dot_normal = normalize(dot(view_dir.xyz, normal));
	float3	a, b, c, d, ab, cd, ab_cd;
	float	a_a, b_a, c_a, d_a, ab_a, cd_a, ab_cd_a;


/* Stage 0
C0 = (0, 0, $plasma_factor2)
C0a = $plasma_factor1

R0= 	INVERT(C0a)* UNSIGNED(T2a) + C0a*UNSIGNED(T0r)
R0a= 	INVERT(C0b)*1/2 + C0a*UNSIGNED(T1r)
*/
	R0.rgb= 	INVERT(plasma_factor1)*UNSIGNED(T2) + plasma_factor1*UNSIGNED(T0);
	R0.a= 		INVERT(plasma_factor2)*0.5 + plasma_factor2*UNSIGNED(T1);


/* Stage 1
R0= 	UNSIGNED(T3a)*1/2 + INVERT(T3a)*R0
R0a= 	UNSIGNED(T3a)*1/2 + INVERT(T3a)*R0a
*/
	R0.rgb= 	UNSIGNED(T3a)*0.5 + INVERT(T3a)*R0.rgb;
	R0.a= 		UNSIGNED(T3a)*0.5 + INVERT(T3a)*R0.a;

/* Stage 2
R0= 	R0 + HALF_BIAS_NEGATIVE(R0a)
R0a= 	UNSIGNED(R0a) + HALF_BIAS_NEGATIVE(R0b)
*/
	R0.rgb= 	UNSIGNED(R0.rgb) + HALF_BIAS_NEGATIVE(R0.a);
	R0.a=		UNSIGNED(R0.a) +  HALF_BIAS_NEGATIVE(R0.b);

/* Stage 3
		C0= $plasma_color
		C1= $plasma_flash_color

		R0a= SCALE_BY_4(R0b*R0b mux R0a*R0a)
		V1= UNSIGNED_INVERT(C0a) * C0 + C0 * C1

		If R0a is greater than than 0.5, CD is returned, else AB
*/
R0.a=		R0.a>=0.5 ? UNSIGNED(R0.b*R0.b) : UNSIGNED(R0.a*R0.a);
R0.a*= 		4.0;
V1.rgb= 	INVERT(plasma_color.a)*plasma_color.rgb + plasma_color.a*plasma_flash_color; //C0a's value determines what color the shield is


/* Stage 4
R0a= 	0 mux EXPAND_UNSIGNED(R0a)*EXPAND_UNSIGNED(R0a)
*/
R0.a=		R0.a>=0.5 ? (EXPAND_UNSIGNED(R0.a)*EXPAND_UNSIGNED(R0.a)) : (0*0);

/* Stage 5
R1= 	INVERT(T3a)
R0a= 	OUT_SCALE_BY_2(UNSIGNED(R0a) + UNSIGNED(R0a)*UNSIGNED_INVERT(R0a))
*/
R0.a=		UNSIGNED(R0.a) + UNSIGNED(R0.a)*UNSIGNED_INVERT(R0.a);
R0.a*=		2.0; // Removing this will cause shading artifacts

/* Stage 6
R0= 	UNSIGNED(R0a)*T3 + V1*R1
R0= 	R0 * $plasma_brightness
*/
R0.rgb=		UNSIGNED(R0.a)*T3 + V1.rgb*T3;
R0.rgb*= 	plasma_brightness;

albedo = 	R0;

apply_pc_albedo_modifier(albedo, normal);
}

void calc_albedo_plasma_offset_inverse_mask_alpha_ps(
	in float2 texcoord,
	out float4 albedo,
    in float3 normal,
	/*in float4 view_dir,*/
	in float4 misc)
{
	float4 plasma_mask = 		sample2D(plasma_mask_map, transform_texcoord(texcoord, plasma_mask_map_xform));
	float4 plasma_offset = 		sample2D(plasma_offset_map, transform_texcoord(texcoord, plasma_offset_map_xform));
	float4 plasma_noise_b = 	sample2D(plasma_noise_map_b, transform_texcoord(texcoord, plasma_noise_map_b_xform));
	float4 plasma_noise_a = 	sample2D(plasma_noise_map_a, transform_texcoord(texcoord, plasma_noise_map_a_xform));

// This is Halo another version of 1's Implementation the difference is the last stage is that
//	the plasma flash color is multiplied to the mask's rgb components

	/* Only the following parameters are used */
	
	float3 T3 = plasma_mask.rgb;
	float T3a = plasma_mask.a;
	float T2 = 	plasma_offset.a;
	float T1 = 	plasma_noise_b.r;
	float T0 = 	plasma_noise_a.r;
	
	float4 	R0;
	float4 	R1;
	float4  V1;

	//float view_dot_normal = normalize(dot(view_dir.xyz, normal));
	float3	a, b, c, d, ab, cd, ab_cd;
	float	a_a, b_a, c_a, d_a, ab_a, cd_a, ab_cd_a;


/* Stage 0
C0 = (0, 0, $plasma_factor2)
C0a = $plasma_factor1

R0= 	INVERT(C0a)* UNSIGNED(T2a) + C0a*UNSIGNED(T0r)
R0a= 	INVERT(C0b)*1/2 + C0a*UNSIGNED(T1r)
*/
	R0.rgb= 	INVERT(plasma_factor1)*UNSIGNED(T2) + plasma_factor1*UNSIGNED(T0);
	R0.a= 		INVERT(plasma_factor2)*0.5 + plasma_factor2*UNSIGNED(T1);


/* Stage 1
R0= 	UNSIGNED(T3a)*1/2 + INVERT(T3a)*R0
R0a= 	UNSIGNED(T3a)*1/2 + INVERT(T3a)*R0a
*/
	R0.rgb= 	UNSIGNED(T3a)*0.5 + INVERT(T3a)*R0.rgb;
	R0.a= 		UNSIGNED(T3a)*0.5 + INVERT(T3a)*R0.a;

/* Stage 2
R0= 	R0 + HALF_BIAS_NEGATIVE(R0a)
R0a= 	UNSIGNED(R0a) + HALF_BIAS_NEGATIVE(R0b)
*/
	R0.rgb= 	R0.rgb + HALF_BIAS_NEGATIVE(R0.a);
	R0.a=		UNSIGNED(R0.a) +  HALF_BIAS_NEGATIVE(R0.b);

/* Stage 3
		C0= $plasma_color
		C1= $plasma_flash_color

		R0a= SCALE_BY_4(R0b*R0b mux R0a*R0a)
		V1= UNSIGNED_INVERT(C0a) * C0 + C0 * C1

		If R0a is greater than than 0.5, CD is returned, else AB
*/
R0.a=		R0.a>=0.5 ? UNSIGNED(R0.b*R0.b) : UNSIGNED(R0.a*R0.a);
R0.a*= 		4.0;
V1.rgb= 	INVERT(plasma_color.a)*plasma_color.rgb + plasma_color.a*plasma_flash_color; //C0a's value determines what color the shield is


/* Stage 4
R0a= 	0 mux EXPAND_UNSIGNED(R0a)*EXPAND_UNSIGNED(R0a)
*/
R0.a=		R0.a>=0.5 ? (EXPAND_UNSIGNED(R0.a)*EXPAND_UNSIGNED(R0.a)) : (0*0);

/* Stage 5
R1= 	INVERT(T3a)
R0a= 	OUT_SCALE_BY_2(UNSIGNED(R0a) + UNSIGNED(R0a)*UNSIGNED_INVERT(R0a))
*/
R1.rgb= 	INVERT(T3a);
R0.a=		UNSIGNED(R0.a) + UNSIGNED(R0.a)*UNSIGNED_INVERT(R0.a);
R0.a*=		2.0; // Removing this will cause shading artifacts

/* Stage 6
R0= 	UNSIGNED(R0a)*T3 + V1*R1
R0= 	R0 * $plasma_brightness
*/
R0.rgb=		UNSIGNED(R0.a)*T3 + V1.rgb*T3;
R0.rgb*= 	plasma_brightness;

albedo = 	R0;

apply_pc_albedo_modifier(albedo, normal);
}
