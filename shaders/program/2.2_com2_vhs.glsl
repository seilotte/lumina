#include "/shader.h"
// #include "/program/lib/math.glsl"

#ifdef VSH

out vec2 uv;

in vec3 vaPosition;



// =========



void main()
{
    // vertex -> screen
    gl_Position = vec4(vaPosition.xy * 2.0f - 1.0f, 0.0f, 1.0f);

    uv = vaPosition.xy;
}

#endif



/*
 * #########
 */



#ifdef FSH

in vec2 uv;

uniform vec2 c_viewResolution;

uniform sampler2D noisetex;
uniform sampler2D depthtex0;
uniform sampler2D colortex0; // c_final.rgb



// =========

// Default values:
// blur_strength = 1.2
// iterations = uvec2(8u, 3u)

#define VHS_BLUR_STRENGTH   1.0
#define VHS_ITER_X          3u
#define VHS_ITER_Y          1u

mat3 rgb_to_yiq = mat3(
    0.299f,  0.5959f,  0.2115f,
    0.587f, -0.2746f, -0.5227f,
    0.114f, -0.3213f,  0.3112f
);

mat3 yiq_to_rgb = mat3(
    1.0f,   1.0f,     1.0f,
    0.956f, -0.272f, -1.106f,
    0.619f, -0.647f,  1.703f
);

vec3 vhs_downscale(vec2 uv, vec2 resolution, sampler2D tex)
{
    #ifdef VHS_DOWNSCALE

        uv = floor(uv * resolution) / resolution; // pixelate

    #endif

    vec2 uv_pixel = VHS_BLUR_STRENGTH / resolution; // slight box blur to avoid aliasing

    vec2 uv_start   = uv - uv_pixel * 0.5f;
    vec2 uv_end     = uv + uv_pixel;



    vec3 col = vec3(0.0f);

    for (uint ix = 0u; ix < VHS_ITER_X; ++ix)
    {
        float u = mix(
            uv_start.x,
            uv_end.x,
            float(ix) / float(VHS_ITER_X)
        );

        for (uint iy = 0u; iy < VHS_ITER_Y; ++iy)
        {
            float v = mix(
                uv_start.y,
                uv_end.y,
                float(iy) / float(VHS_ITER_Y)
            );

            col += texture(tex, vec2(u, v)).rgb;
        }
    }

    return (col / float(VHS_ITER_X * VHS_ITER_Y)) * rgb_to_yiq;
}



// =========



/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 col0; // c_final.rgb

void main()
{
    // Initialize values.
    col0 = vec3(.0f);



    // [mpalko] https://www.shadertoy.com/view/tsfXWj
    #if VHS_TYPE == 0 // NTSC

        vec2 res_luma   = min(c_viewResolution, vec2(333.0f, 480.0f));
        vec2 res_chroma = min(c_viewResolution, vec2(40.0f, 480.0f));

    #else // PAL

        vec2 res_luma   = min(c_viewResolution, vec2(335.0f, 576.0f));
        vec2 res_chroma = min(c_viewResolution, vec2(40.0f, 240.0f));

    #endif

    col0.r  = vhs_downscale(uv, res_luma, colortex0).r;
    col0.gb = vhs_downscale(uv, res_chroma, colortex0).gb;

    // Grain.
    // Ideally we want "overlay" but it is too expensive, so we use "dodge".
    col0.r /= // should be *iq* instead of *y*
    1.0f -
    texture(noisetex, gl_FragCoord.xy * 0.015625f).r *
    (texture(depthtex0, uv).r < 1.0f ? 0.1f : 0.05f);



    // WRITE: c_final.rgb
    col0 *= yiq_to_rgb;
}

#endif
