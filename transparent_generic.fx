
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
	float4 plasma_mask = 		sample2D(plasma_mask_map, transform_texcoord(texcoord, plasma_mask_map_xform));
	float4 plasma_offset = 		sample2D(plasma_offset_map, transform_texcoord(texcoord, plasma_offset_map_xform));
	float4 plasma_noise_b = 	sample2D(plasma_noise_map_b, transform_texcoord(texcoord, plasma_noise_map_b_xform));
	float4 plasma_noise_a = 	sample2D(plasma_noise_map_a, transform_texcoord(texcoord, plasma_noise_map_a_xform));

	/* Only the following parameters are used */
	
	float3 T3 = plasma_mask.rgb;

	float T3a = plasma_mask.a;
	float T2 = plasma_offset.a;
	float T1 = plasma_noise_b.r;
	float T0 = plasma_noise_a.r;

	float3 	R0;
	float3 	R1;
	float3  V1;
	float 	R0a;



/* Stage 0
C0 = (0, 0, $plasmma_factor2)
C0a = $plasma_factor1

R0 = INVERT(C0a) * T2a + C0a * T0r
R0a = INVERT(C0a) * 1/2 + C0a * T1r
*/

R0= (1-plasma_factor1)*max(T2, 0.0) + plasma_factor1*T0;
R0a= (1-plasma_factor2)*0.5 + plasma_factor2*T1;

/* Stage 1
R0 = T3a * 1/2 + INVERT(T3a) * R0
R0a = T3a * 1/2 + INVERT(T3a) * R0a
*/

R0= T3a*0.5 + (1-T3a)*R0;

R0a= T3a*0.5 + (1-T3a)*R0a;

/* Stage 2
R0 = R0 + HALF_BIAS_NEGATIVE(R0a)
R0a = R0a + HALF_BIAS_NEGATIVE(R0b)
*/

R0a= R0a + (-R0.b + 0.5);
R0= R0 + (-R0a + 0.5);

/* Stage 3
C0 = $plasma_color
C0a is used for blending
C1 is plasma flash color

R0a = SCALE_BY_4(R0a ^ 2 mux R0B ^ 2)
V1 = INVERT(C0a) * C0 + C0 * C1

If R0a is greater than than 0.5, CD is returned, else AB
*/

R0a=R0a>0.5 ? pow(R0.b, 2) : pow(R0a, 2);
R0a = 4 * R0a;

V1= (1-plasma_color.a)*plasma_color.rgb + plasma_color.a*plasma_flash_color;

//V1=clamp(V1, -1.0, 1.0);

/* Stage 4
R0a = 0 * 0 mux EXPAND(R0a) * EXPAND(R0a)
*/

R0a= R0a>0.5 ? pow(EXPAND(R0a), 2) : 0;


/* Stage 5
R1 = INVERT(T3a)
R0a= R0a + R0a * INVERT(R0a)
*/

R1= (1-T3a);
R0a= R0a + R0a*(1-R0a);

/* Stage 6
R0 = R0 * T3 + D1 * R1
*/

R0 = R0a*T3 + V1*R1;

albedo.rgb = R0;
albedo.a = 0;

}
