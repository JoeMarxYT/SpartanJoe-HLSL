#ifndef _TRANSPARENT_GENERIC_DX
#define _TRANSPARENT_GENERIC_DX

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

void calc_albedo_plasma_offset_ps(
	in float2 texcoord,
	out float4 albedo,
    in float3 normal,
	in float4 misc)
{
	float4 plasma_mask = sample2D(plasma_mask_map, transform_texcoord(texcoord, plasma_mask_map_xform));
	float4 plasma_offset = sample2D(plasma_offset_map, transform_texcoord(texcoord, plasma_offset_map_xform));
	float4 plasma_noise_b = sample2D(plasma_noise_map_b, transform_texcoord(texcoord, plasma_noise_map_b_xform));
	float4 plasma_noise_a = sample2D(plasma_noise_map_a, transform_texcoord(texcoord, plasma_noise_map_a_xform));

	/* Only the following parameters are used */
	
	float3 T3 = plasma_mask.rgb;

	float T3a = plasma_offset.a;
	float T2a = plasma_offset.a;
	float T1a = plasma_noise_b.a;
	float T0a = plasma_noise_a.a;

	float3 R0, R1, D1, V1;
	float R0a, R0b;



/* Stage 0
C0 = (0, 0, $plasmma_factor2)
C0a = $plasma_factor1

R0 = INVERT(C0a) * T2a + C0a * T0a
R0a = INVERT(C0a) * 1/2 + C0a * T0a
*/

R0= INVERT(plasma_factor1) * T2a + plasma_factor1 * T0a;
R0a= INVERT(plasma_factor2) * 1/2 + plasma_factor2 * T0a;


/* Stage 1
R0 = T3a * 1/2 + INVERT(T3a) * R0
R0a = T3a * 1/2 + INVERT(T3a) * R0a
*/

R0= T3a * 1/2 + INVERT(T3a) * R0;
R0a= T3a * 1/2 + INVERT(T3a) * R0a;

/* Stage 2
R0 = R0 + HALF_BIAS_NEGATIVE(R0a)
R0a = R0a + HALF_BIAS_NEGATIVE(R0b)
*/

R0a= R0a + HALF_BIAS_NEGATIVE(R0b);
R0= R0 + HALF_BIAS_NEGATIVE(R0a);

/* Stage 3
C0 = $plasma_color
C0a is used for blending
C1 is plasma flash color

R0a = SCALE_BY_4(R0a * R0a mux R0B * R0b)
V1 = INVERT(C0a) * C0 + C0 * C1

If R0a is greater than than 0.5, CD is returned, else Ab
*/

R0a=R0a>0.5 ? R0b * R0b : R0a * R0a;
R0a*= 4;
V1= INVERT(plasma_color.a) * plasma_color.rgb + plasma_color.a * plasma_flash_color;

/* Stage 4
R0a = 0 * 0 mux EXPAND(R0a) * EXPAND(R0a)
*/

R0a= R0a>0.5 ? EXPAND(R0a) * EXPAND(R0a) : 0 * 0;

/* Stage 5
R1 = INVERT(T3a)
R0a= R0a + R0a * INVERT(R0a)
*/

R1=INVERT(T3a);
R0a= R0a + R0a * INVERT(R0a);

/* Stage 6
R0 = R0 * T3 + D1 * R1
*/

R0 = R0 * T3 + D1 * R1;

	albedo.rgb = R0;
	albedo.a = R0a;

};

#endif