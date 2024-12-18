

PARAM_SAMPLER_2D(warp_map);
PARAM(float4, warp_map_xform);
PARAM(float, warp_amount_x);
PARAM(float, warp_amount_y);


void calc_warp_from_texture_ps(
	in float2 texcoord,
	in float3 view_dir,					// direction towards camera
	out float2 parallax_texcoord)
{
	parallax_texcoord= texcoord + sample2D(warp_map, transform_texcoord(texcoord, warp_map_xform)).xy * float2(warp_amount_x, warp_amount_y);
}

PARAM_SAMPLER_2D(warp_map2);
PARAM(float4, warp_map2_xform);

void calc_warp_from_two_texture_ps(
	in float2 texcoord,
	in float3 view_dir,					// direction towards camera
	out float2 parallax_texcoord)
{
	float2 diff = sample2D(warp_map, transform_texcoord(texcoord, warp_map_xform)).xy - sample2D(warp_map2, transform_texcoord(texcoord, warp_map2_xform)).xy;
	parallax_texcoord= texcoord + diff * float2(warp_amount_x, warp_amount_y);
}