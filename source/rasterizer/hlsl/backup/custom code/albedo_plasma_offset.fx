PARAM_SAMPLER_2D(shield_mask_map);
PARAM(float4, shield_mask_map_xform);
PARAM_SAMPLER_2D(shield_offset_map);
PARAM(float4, shield_offset_map_xform);
PARAM_SAMPLER_2D(plasma_noise_map_a);
PARAM(float4, plasma_noise_map_a_xform);
PARAM_SAMPLER_2D(plasma_noise_map_b);
PARAM(float4, plasma_noise_map_b_xform);

PARAM(float4, plasma_color);
PARAM(float3, plasma_flash_color);
PARAM(float, plasma_factor1);
PARAM(float, plasma_factor2);
PARAM(float, plasma_brightness);
PARAM(float, plasma_intensity);

void calc_albedo_plasma_offset_ps(
	in float2 texcoord,
	out float4 albedo)
{
	float4 shield_mask = sample2D(shield_mask_map, transform_texcoord(texcoord, shield_mask_map_xform));
	float4 shield_offset = sample2D(shield_offset_map, transform_texcoord(texcoord, shield_offset_map_xform));
	float4 plasma_noise_a = sample2D(plasma_noise_map_a, transform_texcoord(texcoord, plasma_noise_map_a_xform));
	float4 plasma_noise_b = sample2D(plasma_noise_map_b, transform_texcoord(texcoord, plasma_noise_map_b_xform));


// Initial input and some explanation as to how it works in Combat Evolved
	/*
	
	c0_input (stage 0's constant_color_0.rgb) is rgb(0, 0, plasma_factor2)
	c0a_input (stage 0's constant_color_0.a) is plasma_factor1

	output abcd is (a * b) + (c * d)
	whilc output abcd sum returns cd when scratch color 0 is greater than 0.5 and returns ab otherwise

	*/

	float3	r0_input = SUM_ABCD(INVERT(plasma_factor1), shield_offset.a, plasma_factor1, plasma_noise_a.a);
	float	r0a_input = SUM_ABCD(INVERT(plasma_factor2), 0.5, plasma_factor2, plasma_noise_b.a);

// Offset time
	float3	r0_plasma = SUM_ABCD(shield_mask.a, 0.5, INVERT(shield_mask.a), r0_input);
	float	r0a_plasma = SUM_ABCD(shield_mask.a, 0.5, INVERT(shield_mask.a), r0a_input);

// Half-bias stage
	float3	r0_hb = TWO_VALUE_SUBTRACT(r0_plasma, HALF_BIAS(r0a_plasma));
	float	r0a_hb = TWO_VALUE_SUBTRACT(r0a_plasma, HALF_BIAS(r0_plasma.b));

// Scale by 4 and color blend stage
	float3 plasma_blend = SUM_ABCD(plasma_color.rgb, INVERT(plasma_color.a), plasma_color.a, plasma_flash_color);
	float r0a_4 = MUX(r0a_hb, r0a_hb, r0a_hb, r0_hb.b, r0_hb.b) * plasma_intensity;

// Sharpening
	float r0a_sharp = MUX(r0a_4, 0, 0, EXPAND(r0a_4), EXPAND(r0a_4));

// Dull and colorize. This is how Halo 2 describes its
	float r0a_dull = SUM_ABCD(r0a_sharp, 1, r0a_sharp, INVERT(r0a_sharp));

// final output
	albedo.rgb = SUM_ABCD(r0a_dull, shield_mask.rgb, plasma_blend, INVERT(shield_mask.a));
	albedo.a = r0a_dull;

}