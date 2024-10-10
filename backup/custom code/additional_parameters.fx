#define MUX(v, a, b, c, d) v >= 0.5 ? (c * d) : (a * b)

#define SUM_ABCD(a, b, c, d) (a * b) + (c * d)

#define INVERT(v) 1 - v

#define EXPAND(v) 2.0 * max(v, 0.0)- 1.0

#define HALF_BIAS(v) -v + 0.5

#define TWO_VALUE_SUBTRACT(a, b) a - b