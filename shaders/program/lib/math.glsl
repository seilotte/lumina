/*
#define pi      3.141592653589793238
#define pi_half 1.570796326794896619
#define pi_inv  0.318309886183790671

#define tau     6.283185307179586476
#define tau_inv 0.159154943091895335

#define phi     1.618033988749894848
#define phi_inv 0.618033988749894848
#define phi2    1.324717957244746025

#define e       2.718281828459045235
*/
// =========

float sqrt_fast(float x)
{
    // [Drobot2014a] Low Level Optimizations for GCN.
    return intBitsToFloat(0x1fbd1df5 + (floatBitsToInt(x) >> 1));
}
/*
vec2 sqrt_fast(vec2 x)
{
    return intBitsToFloat(0x1fbd1df5 + (floatBitsToInt(x) >> 1));
}
*/
float acos_fast(float x)
{
    // [Olivier|Yannick|Clément] https://github.com/cdrinmatane/SSRT3
    // GTAO fast acos.
    float r = -0.156583 * abs(x) + 1.570796326794896619;
    r *= sqrt(1.0 - abs(x));
    return x >= 0.0 ? r : 3.141592653589793238 - r;
}

vec2 acos_fast(vec2 x)
{
    return vec2(
        acos_fast(x.x),
        acos_fast(x.y)
    );
}

float length_fast(vec2 x)
{
    return sqrt_fast(dot(x, x));
}

float length_fast(vec3 x)
{
    return sqrt_fast(dot(x, x));
}

// =========

// https://www.shadertoy.com/view/cl2GRm
// Noises.
float noise_r2(vec2 p)
{
    return fract(dot(p, vec2(0.754877669, 0.569840296)));
}
/*
float noise_wh(vec2 p)
{
    // White noise.
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise_in(vec2 p)
{
    // [Jimenez 2014] http://goo.gl/eomGso
    // Interleaved gradient function.
    return fract(52.9829189 * fract(p.x * 0.06711056 + p.y * 0.00583715));
}

float triwave(float x)
{
    // x in 0...1
    return x > 0.5 ? 2.0 - 2.0 * x : 2.0 * x;
}
*/
// =========
/*
vec3 mix_dodge(vec3 x, vec3 y, float a)
{
    vec3 blend = 1.0 - y * a;
    return (vec3(0.0) == blend) ? vec3(1.0) : x / blend;
}
*/
// =========

float luma_average(vec3 x)
{
    return (x.r + x.g + x.b) * .333333333f;
}
/*
float luma(vec3 x)
{
    return dot(x, vec3(0.2126, 0.7152, 0.0722));
}
*/
// =========
/*
int max_int(int x, int y)
{
    return (y > x) ? y : x;
}

bool compare(float x, float y, float epsilon)
{
    return abs(x - y) < epsilon;
}

float gsmooth(float x, float t, float s)
{
    // Assume s is never 0; min(s, 1e-5) or safe_divide()
    return clamp((x - t) / s, 0.0, 1.0);
}
*/
float linearstep(float x, float a, float b)
{
    // smoothstep without smoothing
    return clamp((x - a) / (b - a), 0.0, 1.0);
}

// =========

float packUnorm2x4(vec2 x, float pattern)
{
    // pattern = 0.5
//     x = clamp(x, 0.0f, 1.0f);

    uvec2 xu = uvec2(x * 15.0f + pattern);

    return float(
        (xu.r << 4u) |
        (xu.g << 0u)
    ) / 255.0f;
}

vec2 unpackUnorm2x4(float x)
{
    uint xu = uint(x * 255.0f);

    return vec2(
        (xu >> 4u) & 15u,
        (xu >> 0u) & 15u
    ) / 15.0f;
}

float packUnorm3x332(vec3 x, float pattern)
{
    // pattern = 0.5
//     x = clamp(x, 0.0f, 1.0f);

    uvec3 xu = uvec3(x * vec3(7.0f, 7.0f, 3.0f) + pattern);

    return float(
        (xu.r << 5u) |
        (xu.g << 2u) |
        (xu.b << 0u)
    ) / 255.0f;
}

vec3 unpackUnorm3x332(float x)
{
    uint xu = uint(x * 255.0f);

    return vec3(
        (xu >> 5u) & 7u,
        (xu >> 2u) & 7u,
        (xu >> 0u) & 3u
    ) / vec3(7.0f, 7.0f, 3.0f);
}
/*
float packUnorm4x2(vec4 x, float pattern)
{
    // pattern = 0.5
//     x = clamp(x, 0.0f, 1.0f);

    uvec4 xu = uvec4(x * 3.0f + pattern);

    return float(
        (xu.r << 6u) |
        (xu.g << 4u) |
        (xu.b << 2u) |
        (xu.a << 0u)
    ) / 255.0f;
}

vec4 unpackUnorm4x2(float x)
{
    uint xu = uint(x * 255.0f);

    return vec4(
        (xu >> 6u) & 3u,
        (xu >> 4u) & 3u,
        (xu >> 2u) & 3u,
        (xu >> 0u) & 3u
    ) / 3.0f;
}

float packUnorm4x4(vec4 x, float pattern)
{
    // pattern = 0.5
//     x = clamp(x, 0.0f, 1.0f);

    uvec4 xu = uvec4(x * 15.0f + pattern);

    return float(
        (xu.r << 12u) |
        (xu.g << 8u) |
        (xu.b << 4u) |
        (xu.a << 0u)
    ) / 65535.0f;
}

vec4 unpackUnorm4x4(float x)
{
    uint xu = uint(x * 65535.0f);

    return vec4(
        (xu >> 12u) & 15u,
        (xu >> 8u) & 15u,
        (xu >> 4u) & 15u,
        (xu >> 0u) & 15u
    ) / 15.0f;
}
*/
// =========

vec2 encode_normal(vec3 n)
{
    // https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/
    // Octahedron normal vector encoding.
    n.xy /= abs(n.x) + abs(n.y) + abs(n.z);

    return n.z >= 0.0
    ? n.xy
    : (1.0 - abs(n.yx)) * vec2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0);
}

vec3 decode_normal(vec2 encoded)
{
    vec3 n = vec3(encoded, 1.0 - abs(encoded.x) - abs(encoded.y));

    float t = max(-n.z, 0.0);
    n.xy += vec2(n.x >= 0.0 ? -t : t, n.y >= 0.0 ? -t : t);

    return normalize(n);
}
