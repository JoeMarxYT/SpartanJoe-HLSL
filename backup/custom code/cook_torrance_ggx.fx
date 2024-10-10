#ifndef _COOK_TORRANCE_GGX_FX_
#define _COOK_TORRANCE_GGX_FX_

#include "cook_torrance.fx"

float get_material_cook_torrance_ggx_pbr_maps_specular_power(float power_or_roughness)
{
	[branch]
	if (roughness == 0)
	{
		return 0;
	}
	else
	{
		return 0.27291 * pow(roughness, -2.1973); // ###ctchou $TODO low roughness still needs slightly higher power - try tweaking
	}
}

float3 get_diffuse_multiplier_cook_torrance_ggx_pbr_maps_ps()
{
	return diffuse_coefficient;
}

float3 get_analytical_specular_multiplier_cook_torrance_pbr_ggx_maps_ps(float specular_mask)
{
	return specular_mask * specular_coefficient * analytical_specular_contribution * specular_tint;
}


void calc_material_analytic_specular_cook_torrance_ggx_pbr_maps_ps(
	in float3 view_dir,										// fragment to camera, in world space
	in float3 normal_dir,									// bumped fragment surface normal, in world space
	in float3 view_reflect_dir,								// view_dir reflected about surface normal, in world space
	in float3 light_dir,									// fragment to light, in world space
	in float3 light_irradiance,								// light intensity at fragment; i.e. light_color
	in float3 diffuse_albedo_color,							// diffuse reflectance (ignored for cook-torrance)
	in float2 texcoord,
	in float vertex_n_dot_l,								// original normal dot lighting direction (used for specular masking on far side of object)
	in float3 surface_normal,
	in float4 misc,
	out float4 spatially_varying_material_parameters,
	out float3 specular_fresnel_color,						// fresnel(specular_albedo_color)
	out float3 specular_albedo_color,						// specular reflectance at normal incidence
	out float3 analytic_specular_radiance)					// return specular radiance from this light				<--- ONLY REQUIRED OUTPUT FOR DYNAMIC LIGHTS
{

	// the following parameters can be supplied in the material texture
	// r: specular coefficient
	// g: roughless
	spatially_varying_material_parameters= sampleBiasGlobal2D(material_texture, transform_texcoord(texcoord, material_texture_xform)).xxyy;
	spatially_varying_material_parameters.y = albedo_blend;
	spatially_varying_material_parameters.z = environment_map_specular_contribution;

	specular_albedo_color= diffuse_albedo_color * spatially_varying_material_parameters.g + fresnel_color * (1-spatially_varying_material_parameters.g);

	float n_dot_l = dot( normal_dir, light_dir );
	float l_dot_n = dot( light_dir, normal_dir);
	float n_dot_v = dot( normal_dir, view_dir );
	float min_dot = min( n_dot_l, n_dot_v );
	float3 half_vector = normalize( view_dir + light_dir );
	float n_dot_h = dot( normal_dir, half_vector );
	float v_dot_h = dot( view_dir, half_vector);
	float v_dot_n = dot( view_dir, normal_dir);
	float pi = 3.14159265358979323846264338327950;
	
	if ( min_dot > 0)
	{
		// D (Normal Distributpbion Function): GGX/Trowbridge-Reitz
			float a2 = pow(spatially_varying_material_parameters.g, 4);
			float D_denom = pi * pow((pow(n_dot_h, 2.0) * (a2 - 1)), 2);

		float D = a2/D_denom;

		// G (Geometry Function): Shlick-Beckmann
			float K = a2/2;
			float G_Denom = n_dot_v * (1 - K) + K;

		float G = n_dot_l/G_Denom;

		// F (Fresnel Function): Schlick Fast Approximation
		float3 f0= min(specular_albedo_color, 0.999f);
		
		float3 F = f0 + (1- f0) * pow((1 - v_dot_h), 5);
		
		float3 DGF = D * G * F;
		float CT_Denom = 4 * (v_dot_n + 0.0001) * (l_dot_n + 0.0001);

		
		//puting it all together
		analytic_specular_radiance= DGF / CT_Denom;
		analytic_specular_radiance= min(analytic_specular_radiance, vertex_n_dot_l + 1.0f) * light_irradiance;
		
	}
	else
	{
		analytic_specular_radiance= 0.00001f;
		specular_fresnel_color= specular_albedo_color;
	}
}

void calc_material_cook_torrance_ggx_pbr_maps_ps(
	in float3 view_dir,						// normalized
	in float3 fragment_to_camera_world,
	in float3 view_normal,					// normalized
	in float3 view_reflect_dir_world,		// normalized
	in float4 sh_lighting_coefficients[10],	//NEW LIGHTMAP: changing to linear
	in float3 view_light_dir,				// normalized
	in float3 light_color,
	in float3 albedo_color,
	in float  specular_mask,
	in float2 texcoord,
	in float4 prt_ravi_diff,
	in float3x3 tangent_frame,				// = {tangent, binormal, normal};
	in float4 misc,
	out float4 envmap_specular_reflectance_and_roughness,
	out float3 envmap_area_specular_only,
	out float4 specular_color,
	inout float3 diffuse_radiance
)
{
	float3 spec_tint = sampleBiasGlobal2D(spec_tint_map, texcoord).xyz;

#ifdef pc
	if (p_shader_pc_specular_enabled!=0.f)
#endif // pc
	{
	
	
		float3 fresnel_analytical;			// fresnel_specular_albedo
		float3 effective_reflectance;		// specular_albedo (no fresnel)
		float4 per_pixel_parameters;
		float3 specular_analytical;			// specular radiance
		float4 spatially_varying_material_parameters;
		
		calc_material_analytic_specular_cook_torrance_ggx_pbr_maps_ps(
			view_dir,
			view_normal,
			view_reflect_dir_world,
			view_light_dir,
			light_color,
			albedo_color,
			texcoord,
			prt_ravi_diff.w,
			tangent_frame[2],
			misc,
			spatially_varying_material_parameters,
			fresnel_analytical,
			effective_reflectance,
			specular_analytical);

		// apply anti-shadow
		if (analytical_anti_shadow_control > 0.0f)
		{
			float4 temp[4]= {sh_lighting_coefficients[0], sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
			float ambientness= calculate_ambientness(
				temp,
				light_color,
				view_light_dir);
			float ambient_multiplier= pow((1-ambientness), analytical_anti_shadow_control * 100.0f);
			specular_analytical *= ambient_multiplier;
		}
		
		float3 simple_light_diffuse_light; //= 0.0f;
		float3 simple_light_specular_light; //= 0.0f;
		
		if (!no_dynamic_lights)
		{
			float3 fragment_position_world= Camera_Position_PS - fragment_to_camera_world;
			calc_simple_lights_analytical(
				fragment_position_world,
				view_normal,
				view_reflect_dir_world,											// view direction = fragment to camera,   reflected around fragment normal
				GET_MATERIAL_SPECULAR_POWER(material_type)(spatially_varying_material_parameters.a),
				simple_light_diffuse_light,
				simple_light_specular_light);
		}
		else
		{
			simple_light_diffuse_light= 0.0f;
			simple_light_specular_light= 0.0f;
		}

		float3 sh_glossy= 0.0f;
		// calculate area specular
		float r_dot_l= max(dot(view_light_dir, view_reflect_dir_world), 0.0f) * 0.65f + 0.35f;

		//calculate the area sh
		float3 specular_part=0.0f;
		float3 schlick_part=0.0f;
		
		if (order3_area_specular)
		{
			float4 sh_0= sh_lighting_coefficients[0];
			float4 sh_312[3]= {sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
			float4 sh_457[3]= {sh_lighting_coefficients[4], sh_lighting_coefficients[5], sh_lighting_coefficients[6]};
			float4 sh_8866[3]= {sh_lighting_coefficients[7], sh_lighting_coefficients[8], sh_lighting_coefficients[9]};
			sh_glossy_ct_3(
				view_dir,
				view_normal,
				sh_0,
				sh_312,
				sh_457,
				sh_8866,	//NEW_LIGHTMAP: changing to linear
				spatially_varying_material_parameters.a,
				r_dot_l,
				1,
				specular_part,
				schlick_part);	
		}
		else
		{
	
			float4 sh_0= sh_lighting_coefficients[0];
			float4 sh_312[3]= {sh_lighting_coefficients[1], sh_lighting_coefficients[2], sh_lighting_coefficients[3]};
			
			sh_glossy_ct_2(
				view_dir,
				view_normal,
				sh_0,
				sh_312,
				spatially_varying_material_parameters.a,
				r_dot_l,
				1,
				specular_part,
				schlick_part);	
		}
						
		sh_glossy= specular_part * effective_reflectance + (1 - effective_reflectance) * schlick_part;
		envmap_specular_reflectance_and_roughness.w= spatially_varying_material_parameters.a;
		envmap_area_specular_only= sh_glossy * prt_ravi_diff.z * spec_tint;
				
		//scaling and masking
		
		specular_color.xyz= specular_mask * spatially_varying_material_parameters.r * spec_tint * (
			(simple_light_specular_light * effective_reflectance + specular_analytical) * analytical_specular_contribution +
			max(sh_glossy, 0.0f) * area_specular_contribution);
			
		specular_color.w= 0.0f;
		
		envmap_specular_reflectance_and_roughness.xyz=	spatially_varying_material_parameters.b * specular_mask * spatially_varying_material_parameters.r;		// ###ctchou $TODO this ain't right
				
		float diffuse_adjusted= diffuse_coefficient;
		if (use_material_texture)
		{
			diffuse_adjusted= 1.0f - spatially_varying_material_parameters.r;
		}
			
		diffuse_radiance= diffuse_radiance * prt_ravi_diff.x;
		diffuse_radiance= (simple_light_diffuse_light + diffuse_radiance) * diffuse_adjusted;
		specular_color*= prt_ravi_diff.z;		
		
		//diffuse_color= 0.0f;
		//specular_color= spatially_varying_material_parameters.r;
	}
#ifdef pc
	else
	{
		envmap_specular_reflectance_and_roughness= float4(0.f, 0.f, 0.f, 0.f);
		envmap_area_specular_only= float3(0.f, 0.f, 0.f);
		specular_color= 0.0f;
		diffuse_radiance= ravi_order_3(view_normal, sh_lighting_coefficients) * prt_ravi_diff.x;
	}
#endif // pc
}

#endif