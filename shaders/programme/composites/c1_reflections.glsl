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

// =========

float min_of(vec3 v)
{
    return min(min(v.x, v.y), v.z);
}

vec3 normalize_fast(vec3 v)
{
//     return v * inversesqrt(dot(v, v));
    return v * rsqrt_fast(dot(v, v));
}

// =========



/* RENDERTARGETS: 9 */
layout(location = 0) out vec4 col9;

void main()
{
    // Initialize values.
    col9 = vec4(0.0);



//     const vec2 resolution = u_viewResolution.xy * vec2(0.5, 1.0);
    #define resolution u_viewResolution.xy
    const ivec2 texel = ivec2(uv * resolution);



    float dither = 1.0;

    #if defined SS_R_NOISE

        dither = texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 63, 0).r;

    #if defined TAA

        dither = fract(dither + float(frameCounter) * 1.618034);

    #endif
    #endif

    uint c6 = texelFetch(colortex6, texel, 0).r; // data
    if (c6 < 1u) return; // is_sky
    if ((c6 & 1u) < 1u) return; // !is_metal

    vec3 normal_vs;
    normal_vs.x = float((c6 >> 26u) & 63u) / 63.0;
    normal_vs.y = float((c6 >> 20u) & 63u) / 63.0;
    normal_vs.z = float((c6 >> 14u) & 63u) / 63.0;
    normal_vs = mat3(gMV) * (normal_vs * 2.0 - 1.0);




    vec3 pos_ss = vec3(uv, texelFetch(colortex4, texel, 0).r);

    bool is_hand = pos_ss.z < 0.56;

    #if !defined PIXELATE

        // TODO: Tag is_hand, and use MC_HAND_DEPTH.
        vec3 pos_vs = unproj3(gProjInv, (pos_ss * 2.0 - 1.0));

    #else

        vec3 pos_vs = texelFetch(colortex4, texel, 0).gba;

    #endif

    vec3 view_vs = -normalize_fast(pos_vs);



//*
#if defined SS_R && SS_R_MODE == 0

    // Simple Reflections.
    vec3 uv_ref = reflect(-view_vs, normal_vs); // vs
    uv_ref = proj3(gProj, uv_ref) * 0.5 + 0.5; // ss



    vec3 ssr = vec3(0.0);
    float mask = 1.0;

    if (clamp(uv_ref, 0.0, 1.0) != uv_ref) return;

    ssr = textureLod(colortex1, uv_ref.xy, 0.0).rgb;

    mask = 1.0 - dot(normal_vs, view_vs); // NoV
    mask *= is_hand ? 1.0 : (abs(uv_ref.x - 0.5) *2.-1.) * (abs(uv_ref.y - 0.5) *2.-1.); // vignette
//     mask *= max(is_metal, 1.0 - is_roughness);



    #if defined FOG_BORDER

        {
            // TODO: Wrong, find a better solution.
            float pos_len = sqrt_fast(dot(pos_vs, pos_vs));

            float fog_start = isEyeInWater > 0 ? fogStart : 16.0;
            float fog_end = isEyeInWater > 0 ? min(fogEnd, vxFar) : vxFar;

            float fog = linearstep(fog_start, fog_end, pos_len);
            fog = fog * fog;

            mask *= 1.0 - fog;
        }

    #endif



    // Write.
    col9 = vec4(ssr, mask);

#endif
//*/



//*
#if defined SS_R && SS_R_MODE == 1

    // [fclem]? https://github.com/blender/blender
    // [h3r2tic] https://gist.github.com/h3r2tic/9c8356bdaefbe80b1a22ae0aaee192db
    // Screen Space Reflections.
    // Modified.
//     #define SS_R_ITERS 8
    #define THICKNESS 0.2

    // NOTE: Normals require a float buffer for reflections.
    // An inaccurate workaround is to offset the reflection vector slightly.
    #define MAGIC_VALUE vec3(0.0, 0.06, 0.0)

    vec3 ref_vs = normalize_fast(reflect(-view_vs - MAGIC_VALUE, normal_vs));



    vec4 ro;
    vec4 rd;

    ro.xyz = proj3(gProj, pos_vs); // 2ndc
    rd.xyz = proj3(gProj, pos_vs + ref_vs * abs(pos_vs.z));

    ro.w = pos_vs.z - THICKNESS;
    rd.w = pos_vs.z + ref_vs.z - THICKNESS;

    ro.w = (gProj[2].z * ro.w + gProj[3].z) / (gProj[2].w * ro.w); // 2ndc
    rd.w = (gProj[2].z * rd.w + gProj[3].z) / (gProj[2].w * rd.w);

    ro.zw -= 4.8e-7;
    rd.zw -= 4.8e-7;

    rd -= ro;

    rd *= min_of((sign(rd.xyz) - ro.xyz) / rd.xyz); // clip to the view frustum, infinite
    rd *= (1.01 / SS_R_ITERS);

    ro += rd * dither; // dither -1,1?

    ro = ro * 0.5 + 0.5;
    rd = rd * 0.5;



    float z = 0.0, z_delta = 0.0;

    vec2 uv_hit = vec2(-1.0);
    float mask = 0.0;

    for (int i = 0; i < SS_R_ITERS; ++i)
    {
        ro += rd;
        if (clamp(ro.xy, 0.0, 1.0) != ro.xy) continue;

        // TODO: Mip optimization (depth hierarchical z-buffer).
        z = texelFetch(colortex4, ivec2(ro.xy * resolution), 0).r;
//         if (z == 1.0) continue;

        z_delta = z - ro.z;

        if (
            z_delta < 0.0 // hit
            && (z_delta > ro.z - ro.w || abs(z_delta) < abs(rd.z * 2.0)) // thickness
        )
        {
            uv_hit = ro.xy;
            mask = 1.0;
            break;
        }
    }



    vec3 ssr = textureLod(colortex1, uv_hit, 0.0).rgb * mask;

    mask *= 1.0 - dot(normal_vs, view_vs); // NoV
    mask *= is_hand ? 1.0 : (abs(uv_hit.x - 0.5) *2.-1.) * (abs(uv_hit.y - 0.5) *2.-1.); // vignette
//     mask *= max(is_metal, 1.0 - is_roughness);



    #if defined FOG_BORDER

        {
            // TODO: Wrong, find a better solution.
            float pos_len = sqrt_fast(dot(pos_vs, pos_vs));

            float fog_start = isEyeInWater > 0 ? fogStart : 16.0;
            float fog_end = isEyeInWater > 0 ? min(fogEnd, vxFar) : vxFar;

            float fog = linearstep(fog_start, fog_end, pos_len);
            fog = fog * fog;

            mask *= 1.0 - fog;
        }

    #endif



    // Write.
    col9 = vec4(ssr, mask);

#endif
//*/
}

#endif
