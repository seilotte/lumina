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

uniform sampler2D colortex0; // final.rgb
uniform sampler2D colortex10; // final.rgb (translucency)
uniform sampler2D colortex1; // alpha.r
uniform sampler2D colortex3; // reflections.rgb, reflections_mask.a

// =========

vec3 purkinje_shift(vec3 rgb)
{
    // [Jasmin Patry] https://advances.realtimerendering.com/s2021/jpatry_advances2021/index.html#/167
    // https://www.youtube.com/watch?v=GOee6lcEbWg
    const mat4x3 rgb_to_lmsr = mat4x3
    (
        7.69684945, 18.4248204, 2.06809497,
        2.43113687, 18.6979422, 3.01246326,
        0.28911757, 1.40183293, 13.7922962,
        0.46638595, 15.5643680, 10.0599647
    );

    const mat3 lms_gain_to_rgb = mat3
    ( // good enough
         1.0, -0.1, -0.2,
        -0.8,  0.4, -0.3,
        -0.2,  0.0,  1.7
    );

    vec4 lmsr = rgb * rgb_to_lmsr;

    vec3 lms_gain = inversesqrt(1.0 + lmsr.xyz);

//     return rgb + (lms_gain_to_rgb * lms_gain) * (lmsr.w * 0.05);
    return (lms_gain_to_rgb * lms_gain) * lmsr.w;
}

float luma(vec3 c)
{
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// =========



/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 col0;

void main()
{
    // Initialize values.
//     col0 = vec3(0.0);



    ivec2 texel = ivec2(gl_FragCoord);

    // TODO: Find a better solution for Voxy translucency.
    // In other words, remove all the extra buffers and passes.
    vec3 c0 = texelFetch(colortex0, texel, 0).rgb;
    float c1 = texelFetch(colortex1, texel, 0).r;
    vec3 c10 = texelFetch(colortex10, texel, 0).rgb;

    c0 = c0 * c1 + c10;



    #if defined SS_R

        vec4 c3 = texelFetch(colortex3, ivec2(gl_FragCoord.xy * SS_R_RES), 0);

        c0.rgb = mix(c0.rgb, c3.rgb, c3.a);

    #endif



    #if 1

        c0 += purkinje_shift(c0) * (1.0 - skyColor.b) * (1.0 - luma(c0)) * 0.05;

    #endif



    // Write.
    col0 = c0;
}

#endif
