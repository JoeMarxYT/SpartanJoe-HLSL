/*
=============================================
Created by SpartanJoe193
last modified on October 9th, 2024 2:31 PM GMT+8
=============================================
*/

#ifndef _ADDITIONAL_PARAMETERS_FX_
#define _ADDITIONAL_PARAMETERS_FX_

/*
	This file along transparent_generic.fx is made for the purpose of
	not only reverse engineering shader_transparent_generic and
	continue MosesOfEgypt's documentation of that shader but also explain
	the parameters
UNSIGNED_INVERT
	Unused parameters will be indicated via comments
*/

/* AB, CD, and ABCD  pprocessing */

	#define AB(f, a, b)


/* Input mapping */

// UNSIGNED, concocted specifically to fight artifacting
	#define UNSIGNED(v)															\
			max(v, 0.0)

	#define UNSIGNED_INVERT(v)													\
			(1.0 - clamp(v, 0.0, 1.0))

	#define EXPAND_UNSIGNED(v)													\
			(2.0 * max(v, 0.0) - 1.0)

	#define EXPAND_UNSIGNED_NEGATIVE(v)											\
			(-2.0 * max(v, 0.0) + 1.0)												//Unused as of now

	#define DOUBLE_UNSIGNED(v)													\
			(2.0 * max(0.0, v))														//Unused as of now

	#define	DOUBLE_UNSIGNED_NEGATIVE(v)											\
			(-2.0 * max(0.0, v))														//Unused as of now

	#define	HALF_BIAS_UNSIGNED(v)												\
			(max(v, 0.0) - 0.5;)														//Unused as of now

	#define	HALF_BIAS_UNSIGNED_NEGATIVE(v)										\
			(-max(v, 0.0) + 0.5)														//Unused as of now


// SIGNED
	#define INVERT(v)															\
			(1.0 - v)

	#define	HALF_BIAS(v)														\
			(v-0.5)																	//Unused as of now

	#define	HALF_BIAS_NEGATIVE(v)												\
			(-v+0.5)

	#define EXPAND(v)															\
			(2.0*v-1.0)																//Unused as of now

	#define EXPAND_NEGATIVE(v)													\
			(-2.0*v+1)																// Unused as of now

/* Output processing clamped */
#define CLAMP_MULTIPLY(a, b)													\
			clamp(a*b, -1.0, 1.0)													/*
																	   					Unused as of now, originally used in Halo 1 to process outputs
																	   					AB and CD before combining them as either a MUX or a sum.
																	   					See "HCEEK\shaders\fx\transparent_generic_shader.psh"
																					*/

#define MUX(a_a, b_a, c_a, d_a) 												\
			ab = CLAMP_MULTIPLY(a, b);											\
			cd = CLAMP_MULTIPLY(c, d);											\
			ab_cd = R0.a>= 0.5 ? cd: ab;										\
			ab_cd = clamp(ab_cd, -1.0, 1.0)											/*
																       					Unused. Checks if R0's alpha is greater than or equal to 0.5.
																	   					If true, Returns CD, else AB
																					*/

#define MUX_A(a_a, b_a, c_a, d_a) 												\
			ab_a = CLAMP_MULTIPLY(a_a, b_a);									\
			cd_a = CLAMP_MULTIPLY(c_a, d_a);									\
			ab_cd_a = R0a>= 0.5 ? cd_a: ab_a;									\
			ab_cd_a = clamp(ab_cd_a, -1.0, 1.0)										// Unused

#define SUM_CLAMPED(a, b, c, d)													\
			ab = CLAMP_MULTIPLY(a, b);											\
			cd = CLAMP_MULTIPLY(c, d);											\
			ab_cd = ab + cd;													\
			ab_cd = clamp(ab_cd, -1.0, 1.0);										// Unused

#define SUM_CLAMPED_A(a_a, b_a, c_a, d_a)										\
			ab_a = CLAMP_MULTIPLY(a_a, b_a);									\
			cd_a = CLAMP_MULTIPLY(c_a, d_a);									\
			ab_cd_a = ab_a + cd_a;												\
			ab_cd_a = clamp(ab_cd_a, -1.0, 1.0);									// Unused

/* Output modifying */
// All these parameters are except in comments of the various functions in "transparent_generic.fx"
// This section serves as documentation

#define OUTPUT_HALF(v)															\
			v / 2.0

#define OUTPUT_SCALE_BY_2(v)													\
			v * 2.0

#define OUTPUT_SCALE_BY_4(v)													\
			v * 4.0

#define OUTPUT_HALF_BIAS(v)														\
			v - 0.5

#define OUTPUT_EXPAND(v)														\
			(v - 0.5) * 2.0


/* Experimental */

// Vertex shaders from Halo 2

struct transparent_world_vertex{
	float4 oPos : SV_POSITION;
    float4 oD0 : COLOR0;
    float4 oD1 : COLOR1;
	float4 oD2 : COLOR2;
	float4 oD3 : COLOR3;
    float4 oT0 : TEXCOORD0;
    float4 oT1 : TEXCOORD1;
    float4 oT2 : TEXCOORD2;
    float4 oT3 : TEXCOORD3;
    float4 oT4 : TEXCOORD4;
    float4 oT5 : TEXCOORD5;
    float4 oT6 : TEXCOORD6;
    float4 oT7 : TEXCOORD7;

};


/* Misc */

#define saturate_h1(x) clamp(x, -1.0, 1.0)


#endif