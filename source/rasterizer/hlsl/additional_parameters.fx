/*
=============================================
Created by SpartanJoe193
last modified on December 13th, 2024 10:27 AM GMT+8
=============================================
*/

#ifndef _ADDITIONAL_PARAMETERS_FX_
#define _ADDITIONAL_PARAMETERS_FX_

/*
	This file along transparent_generic.fx is made for the purpose of
	not only reverse engineering shader_transparent_generic and
	continue MosesOfEgypt's documentation of that shader but also explain
	the parameters

	Unused parameters and explanations will be indicated via comments
*/

/* AB, CD, and ABCD  pprocessing */

/* Input mapping */


#define MAX_0(v) max(v,0.0)
#define signed_saturate(v) clamp(v, -1.0, 1.0)

// SIGNED
	#define INVERT(v)															\
			(1.0 - v)

	#define	HALF_BIAS(v)														\
			(v - 0.5)																	

	#define	HALF_BIAS_NEGATE(v)													\
			(0.5 - v)																//Unused as of now

	#define EXPAND(v)															\
			(2 * v -1)

	#define EXPAND_NEGATE(v)													\
			(1 - 2 * v)																// Unused as of now

/* Output processing clamped */

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

#define SRCCOLOR	float3(0,0,0)
#define SRCALPHA	0.0


/* Misc*/
// For plasma_mask_offset.fx

#define lerp_inverse(x, y, s) x*s + y*(1-s) 

#endif// _ADDITIONAL_PARAMETERS_FX_