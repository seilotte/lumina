#include "/programme/_lib/version.glsl"

#include "/programme/_lib/uniforms.glsl"
#include "/programme/_lib/math.glsl"
#include "/shader.h"

#ifdef VSH

in vec3 vaPosition;

out vec2 uv;

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

uniform sampler2D colortex1; // final.rgb
uniform sampler2D colortex9; // reflections.rgb, reflections_mask.a

// =========

float luma(vec3 c)
{
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

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

// =========



/* RENDERTARGETS: 1 */
layout(location = 0) out vec3 col1;

void main()
{
    // Initialize values.
//     col1 = vec3(0.0);



    vec3 c1 = texelFetch(colortex1, ivec2(gl_FragCoord), 0).rgb;



    #if defined SS_R

        // TODO: Do not use textureSize().
        vec4 c9 = texelFetch(colortex9, ivec2(uv * textureSize(colortex9, 0)), 0);
        c1 += (c9.rgb - c1) * c9.a; // mix()

    #endif



    #if 1

        c1 += purkinje_shift(c1) * (1.0 - skyColor.b) * (1.0 - luma(c1)) * 0.03;

    #endif



    // Write.
    col1 = c1;
}

#endif
