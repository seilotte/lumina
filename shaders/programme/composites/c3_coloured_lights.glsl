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

uniform sampler2D noisetex;

uniform sampler2D colortex1; // final.rgb
uniform sampler2D colortex4; // depth.r, pos_vs_pixelated.gba (translucent)
uniform usampler2D colortex6; // data.r (translucent)

uniform sampler2D colortex10; // coloured_lights.rgb (previous)

// =========

vec2 get_prev_screen(vec3 p)
{
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
    p = p + cameraPosition - previousCameraPosition;

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

// =========



/* RENDERTARGETS: 10 */
layout(location = 0) out vec3 col10;

void main()
{
    // Initialize values.
    col10 = vec3(0.0);



//     const vec2 resolution = u_viewResolution.xy * vec2(0.5, 1.0);
    #define resolution u_viewResolution.xy
    const ivec2 texel = ivec2(uv * resolution);



    float dither = texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 63, 0).r;
    dither = fract(dither + float(frameCounter) * 1.618034);

    uint c6 = texelFetch(colortex6, texel, 0).r; // data
    if (c6 < 1u) return; // is_sky

    float is_emissive = float((c6 >> 1u) & 7u) / 7.0;

    vec3 pos_ss = vec3(uv, texelFetch(colortex4, texel, 0).r);



//*

    // Coloured Lights.
    vec2 uv_prev = get_prev_screen(pos_ss);

//     if (clamp(uv_prev, 0.0, 1.0) == uv_prev) return;

    float radius = (1.0 - pos_ss.z) * gProj[0].x * 15.0; // 15 = size
    radius *= dither;

    vec3 emissive = textureLod(colortex1, uv, 0.0).rgb * is_emissive;

    // 4x diamond
//     vec3 emissive_prev = 0.25 * (
//         texture(colortex10, uv_prev + vec2(radius, 0)).rgb + // +x
//         texture(colortex10, uv_prev - vec2(radius, 0)).rgb + // -x
//         texture(colortex10, uv_prev + vec2(0, radius)).rgb + // +y
//         texture(colortex10, uv_prev - vec2(0, radius)).rgb   // -y
//     );

    // 4x square
    vec3 emissive_prev = 0.25 * (
        texture(colortex10, uv_prev + vec2(-radius, -radius)).rgb +
        texture(colortex10, uv_prev + vec2( radius, -radius)).rgb +
        texture(colortex10, uv_prev + vec2(-radius,  radius)).rgb +
        texture(colortex10, uv_prev + vec2( radius,  radius)).rgb
    );

    emissive = mix(emissive_prev, emissive * 10.0, 0.1);



    // Write.
    col10 = emissive;

//*/
}

#endif
