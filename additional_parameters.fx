#ifndef _ADDITIONAL_PARAMETERS_FX_
#define _ADDITIONAL_PARAMETERS_FX_


#define CLAMP_X(v) max(v, 0.0)

#define CLAMP_MULTIPLY(a, b) clamp(a * b, -1.0, 1.0)

#define MUX(v, a, b, c, d) v >= 0.5 ? clamp(c * d, -1.0, 1.0) : clamp(a * b, -1.0, 1.0)

#define SUM(a, b, c, d) CLAMP_MULTIPLY(a, b) + CLAMP_MULTIPLY(c, d)

#define MUX2(a, b, c, d) r0.a >= 0.5 ? clamp(c * d, -1.0, 1.0) : clamp(a * b, -1.0, 1.0)

#define INVERT(v) 1 - clamp(v, -1.0, 1.0)

#define EXPAND(v) 2.0 * max(v, 0.0)- 1.0

#define HALF_BIAS(v) max(v, 0.0) - 0.5

#define HALF_BIAS_NEGATIVE(v) max(v, 0.0) - 0.5

#define TWO_VALUE_SUBTRACT(a, b) a - b




#endif