#include "/programme/_lib/version.glsl"

#include "/programme/_lib/uniforms.glsl"
#include "/programme/_lib/math.glsl"
#include "/shader.h"

#ifdef VSH

out vec2 uv;

in vec3 vaPosition;



// =========



void main()
{
    uv = vaPosition.xy;



    gl_Position = vec4(vaPosition.xy * 2.0 - 1.0, 0.0, 1.0);
}

#endif



/*
 * #########
 */



#ifdef FSH

in vec2 uv;

uniform sampler2D noisetex;
uniform sampler2D depthtex0;

uniform sampler2D colortex1; // final.rgb
uniform sampler2D colortex11; // final_prev.rgb

// =========

float luma(vec3 c)
{
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec2 get_prev_screen(vec3 p)
{
    bool is_hand = p.z < 0.56;

    // screen -> ndc
    p = p * 2.0 - 1.0;

    // ndc -> view
    // x  0  0  0
    // 0  x  0  0
    // 0  0  x  x
    // 0  0 -1  1
    p = vec3(
        gProjInv[0].x * p.x,
        gProjInv[1].y * p.y,
        gProjInv[3].z
    ) / (gProjInv[2].w * p.z + gProjInv[3].w);

    // view -> feet
    // x  x  x  t
    // x  x  x  t
    // x  x  x  t
    // 0  0  0  1
    p = mat3(gMVInv) * p + gMVInv[3].xyz;

    // feet -> world -> prev_feet
    p += is_hand ? vec3(0.0) : cameraPosition - previousCameraPosition;

    // prev_feet -> prev_view
    // x  x  x  t
    // x  x  x  t
    // x  x  x  t
    // 0  0  0  1
    p = mat3(gPrevMV) * p + gPrevMV[3].xyz;

    // prev_view -> prev_ndc
    // x  0  0  0
    // 0  x  0  0
    // 0  0  x  x
    // 0  0 -1  0
    p = vec3(
        gPrevProj[0].x * p.x,
        gPrevProj[1].y * p.y,
        gPrevProj[2].z * p.z + gPrevProj[3].z
    ) / (gPrevProj[2].w * p.z);

    // prev_ndc -> prev_screen
    return p.xy * 0.5 + 0.5;
}

vec3 rgb_to_ycocg(vec3 c)
{
    // https://en.wikipedia.org/wiki/YIQ
    return vec3(
        dot(c, vec3(0.299, 0.5959, 0.2115)),
        dot(c, vec3(0.587, -0.2746, -0.5227)),
        dot(c, vec3(0.114, -0.3213, 0.3112))
    );

    // https://en.wikipedia.org/wiki/YCoCg
    return vec3(
        c.x * 0.25 + c.y * 0.5 + c.z * 0.25,
        c.x * 0.5 - c.z * 0.5,
        -c.x * 0.25 + c.y * 0.5 - c.z * 0.25
    );
}

vec3 ycocg_to_rgb(vec3 c)
{
    // https://en.wikipedia.org/wiki/YIQ
    return vec3(
        c.x + c.y + c.z,
        dot(c, vec3(0.956, -0.272, -1.106)),
        dot(c, vec3(0.619, -0.647, 1.703))
    );

    // https://en.wikipedia.org/wiki/YCoCg
    return vec3(
        c.x + c.y - c.z,
        c.x + c.z,
        c.x - c.y - c.z
    );
}

// =========



/* RENDERTARGETS: 1,11 */
layout(location = 0) out vec3 col1;
layout(location = 1) out vec3 col11;

void main()
{
    // Initialize values.
//     col1 = vec3(0.0);
//     col11 = vec3(0.0);



//*
    // [] https://github.com/playdeadgames/temporal
    // [] https://developer.download.nvidia.com/gameworks/events/GDC2016/msalvi_temporal_supersampling.pdf
    // Temporal Anti-Aliasing.

    // NOTE: I am not jittering vertices.
    // It added flickering.
    #define TAA_FAC 0.9
    #define TAA_ACCUM 0.3 // 1 = off
    #define TAA_SHARPEN 1.5

    float depth = texelFetch(depthtex0, ivec2(gl_FragCoord), 0).r;
//     if (depth == 1.0 || depth < 0.56) return;

    vec2 uv_prev = get_prev_screen(vec3(uv, depth));
//     if (clamp(uv_prev, -0.25, 1.25) != uv_prev) return;



    vec3 c1 = textureLod(colortex1, uv, 0.0).rgb;
    c1 = rgb_to_ycocg(c1);

    vec3 c1_prev = textureLod(colortex11, uv_prev, 0.0).rgb;
    c1_prev = rgb_to_ycocg(c1_prev);



    // square
    vec3 c00 = rgb_to_ycocg(textureLodOffset(colortex1, uv, 0.0, ivec2(-1, -1)).rgb);
    vec3 c10 = rgb_to_ycocg(textureLodOffset(colortex1, uv, 0.0, ivec2( 1, -1)).rgb);
    vec3 c01 = rgb_to_ycocg(textureLodOffset(colortex1, uv, 0.0, ivec2(-1,  1)).rgb);
    vec3 c11 = rgb_to_ycocg(textureLodOffset(colortex1, uv, 0.0, ivec2( 1,  1)).rgb);



    // [Luna5ama] https://github.com/Luna5ama/Alpha-Piscium
    // ellipsoid_clipping(); License: GPL-3.0
    vec3 c_mean = (c00 + c10 + c01 + c11) * 0.25;
    vec3 c_mean2 = (c00 * c00 + c10 * c10 + c01 * c01 + c11 * c11) * 0.25;

    vec3 std = sqrt(abs(c_mean2 - c_mean * c_mean)); // standard_deviation = sqrt(variance)

    vec3 delta = c1_prev - c_mean;
    delta /= max(1.0, length(delta / std));

//     c1_prev = c_mean + delta;



    // accumulate()
    #if 1

        c1_prev = c_mean + delta;

    #else

        // TODO: Use motion vectors to reduce ghosting?
        vec2 velocity = (uv - uv_prev) * u_viewResolution.xy; // camPos - prevCamPos
        float fac_vel = clamp(dot(velocity, velocity) * 1000.0, TAA_ACCUM, 1.0);

        c1_prev = mix(c1_prev, c_mean + delta, fac_vel);

    #endif



    // sharpen()
    c1.r += (c1.r - c_mean.r) * TAA_SHARPEN;



    c1 = mix(c1, c1_prev, TAA_FAC);
    c1 = ycocg_to_rgb(c1);
//*/



    // Write.
    col1 = c1;
    col11 = c1;
}

#endif
