/*
#define pi      3.141593
#define pi_half 1.570796
#define pi_inv  0.318310

#define tau     6.283185
#define tau_inv 0.159155

#define phi     1.618034
#define phi_inv 0.618034
#define phi2    1.324718

#define e       2.718282
*/

// ========= fast math

float sqrt_fast(float v)
{
    // [Drobot2014a] https://github.com/michaldrobot/ShaderFastLibs
    // Low Level Optimizations for GCN.
    return intBitsToFloat(0x1fbd1df5 + (floatBitsToInt(v) >> 1));
}

float rsqrt_fast(float v)
{
    // [Drobot2014a] https://github.com/michaldrobot/ShaderFastLibs
    // Low Level Optimizations for GCN.
    return intBitsToFloat(0x5f341a43 - (floatBitsToInt(v) >> 1));
}

float rcp_fast(float v)
{
    // [Drobot2014a] https://github.com/michaldrobot/ShaderFastLibs
    // Low Level Optimizations for GCN.
    return intBitsToFloat(0x7eef370b - floatBitsToInt(v));
}

float acos_fast(float v)
{
    // [Olivier|Yannick|Clément] https://github.com/cdrinmatane/SSRT3
    float r = 1.570796 - 0.156583 * abs(v);
    r *= sqrt(1.0 - abs(v));
    return v >= 0.0 ? r : 3.141593 - r;
}

// ========= utils

float noise_r2(vec2 p)
{
    // https://www.shadertoy.com/view/cl2GRm
    return fract(dot(p, vec2(0.754877669, 0.569840296)));
}

float linearstep(float a, float b, float x)
{
    // smoothstep without smoothing
    return clamp((x - a) / (b - a), 0.0, 1.0);
}

// ========= transforms

// TODO: Verify that the functions work in every scenario.
vec3 mul3(const in mat4 matrix, const in vec3 vector)
{
    return mat3(matrix) * vector + matrix[3].xyz;
}

vec4 proj4(const in mat4 matrix, const in vec3 vector)
{
    return vec4(
        matrix[0].x * vector.x,
        matrix[1].y * vector.y,
        matrix[2].z * vector.z + matrix[3].z,
        matrix[2].w * vector.z
    );
}

vec4 proj4_ortho(const in mat4 matrix, const in vec3 vector)
{
    return vec4(
        matrix[0].x * vector.x,
        matrix[1].y * vector.y,
        matrix[2].z * vector.z + matrix[3].z,
        1.0
    );
}

vec3 proj3(const in mat4 matrix, const in vec3 vector)
{
    return vec3(
        matrix[0].x * vector.x,
        matrix[1].y * vector.y,
        matrix[2].z * vector.z + matrix[3].z
    ) / (matrix[2].w * vector.z);
}

vec3 proj3_ortho(const in mat4 matrix, const in vec3 vector)
{
    return vec3(
        matrix[0].x * vector.x,
        matrix[1].y * vector.y,
        matrix[2].z * vector.z + matrix[3].z
    );
}

vec3 unproj3(const in mat4 matrix, const in vec3 vector)
{
    return vec3(
        matrix[0].x * vector.x,
        matrix[1].y * vector.y,
        matrix[3].z
    ) / (matrix[2].w * vector.z + matrix[3].w);
}
