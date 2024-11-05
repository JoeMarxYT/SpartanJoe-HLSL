#ifndef _MULTIPURPOSE_TEXTURE_FX
#define _MULTIPURPOSE_TEXTURE_FX

/*
=============================================
Created by SpartanJoe193
last modified on November 2nd, 2024 11:34 AM GMT+8
=============================================
*/


PARAM(bool, xbox_order);
PARAM(bool, invert_detail_mask);
PARAM(uint, detail_channel_index); // 0 = none; 1 = specular; 2 = emmissive; 3 = cc0; 4 = cc1;

PARAM_SAMPLER_2D(multipurpose_map);
PARAM(float4, multipurpose_map_xform);

#define mask_specular 				xbox_order ? multipurpose.r : multipurpose.b
#define mask_emmisive 				multipurpose.g
#define mask_cc0					xbox_order ? multipurpose.b : multipurpose.a
#define mask_cc1					xbox_order ? multipurpose.a : multipurpose.a

#define INVERT_OR_NOT(v)			invert_detail_mask ? (1-v) : v				\

#define DECLARE_DETAIL_MASK(v, detail_channel_index, invert_detail_mask)		\
			if(detail_channel_index = 0)										\
					{	v = 1	}; 												\
																				\
			if(detail_channel_index = 1)										\
					{	v = INVERT_OR_NOT(mask_specular)	};					\
																				\
			if(detail_channel_index = 2)										\
					{	v = INVERT_OR_NOT(mask_emmisive)	};					\
																				\
			if(detail_channel_index = 3)										\
					{	v = INVERT_OR_NOT(mask_cc0)	};							\
																				\
			if(detail_channel_index = 4)										\
					{	v = INVERT_OR_NOT(mask_cc1)	};							\



void calc_albedo_two_cc_from_multipurpose_ps(
    in float2 texcoord,
	out float4 albedo,
	in float3 normal,
	in float4 misc)

{	
        float  epsilon      = 0.000001f;

        float4 base         = sampleBiasGlobal2D(base_map,			transform_texcoord(texcoord, base_map_xform));
	    float4 detail       = sampleBiasGlobal2D(detail_map,		transform_texcoord(texcoord, detail_map_xform));
        float4 multipurpose = sampleBiasGlobal2D(multipurpose_map, 	transform_texcoord(texcoord, multipurpose_map_xform));
        float2 cc			= float2(mask_cc0, mask_cc1);
		float  detail_mask;
		
			if(detail_channel_index = 0)
					{	
						detail_mask = 1;
					}

			if(detail_channel_index = 1)
					{	
						detail_mask = INVERT_OR_NOT(mask_specular);
					}
			if(detail_channel_index = 2)
					{	
						detail_mask = INVERT_OR_NOT(mask_emmisive);
					}
			if(detail_channel_index = 3)
					{	
						detail_mask = INVERT_OR_NOT(mask_cc0);
					}
			if(detail_channel_index = 4)
					{
						detail_mask = INVERT_OR_NOT(mask_cc1);
					};




        // Gearbox order: Red is CC0, Alpha is CC1
        // Xbox order: Blue is CC0, Alpha is CC1
    
        float3 change_color=        ((1.0f-cc.x) + cc.x*primary_change_color.xyz)*
						            ((1.0f-cc.y) + cc.y*secondary_change_color.xyz);
        
        if(detail_after_color_change)
	        {
	            albedo.xyz= DETAIL_MULTIPLIER *  epsilon+change_color.xyz*detail.xyz;
	            }
	    else{
		            albedo.xyz= DETAIL_MULTIPLIER * epsilon+detail.xyz*change_color.xyz;
	        }



}

float3 calc_self_illumination_from_multipurpose_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
    float mask = sample2D(multipurpose_map, transform_texcoord(texcoord, multipurpose_map_xform)).g;
	float3 result= (albedo*self_illum_color)*mask;
	result *= self_illum_intensity;
    
	return result;
}

void calc_specular_mask_from_multipurpose_ps(
	in float2 texcoord,
	in float in_specular_mask,
	out float specular_mask)
{
    float4 multipurpose = sample2D(multipurpose_map, transform_texcoord(texcoord, multipurpose_map_xform));
    specular_mask = mask_specular;
}

#endif