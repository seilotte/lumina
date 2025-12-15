#include "/programme/_lib/version.glsl"
// #extension GL_ARB_texture_gather : enable

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

uniform sampler2D colortex3; // depth.r, pos_vs_pixelated.gba (opaque)
uniform usampler2D colortex5; // data.r (opaque)

uniform sampler2D colortex7; // ao.r, shadows.g, pixel_age.b (previous)

// =========

vec3 normalize_fast(vec3 v)
{
//     return v * rsqrt_fast(dot(v, v));
    return v * inversesqrt(dot(v, v));
}

uint update_sectors(vec2 horizons)
{
    uint start = uint(horizons.x * 32.0);
    // round: half a sector
    // ceil: touches the sector
    // floor: entire sector
    uint angle = uint(round((horizons.y - horizons.x) * 32.0));
    uint bitfield = angle > 0u ? (0xFFFFFFFFu >> (32u - angle)) : 0u;

    return bitfield << start;
}

float min_of(vec3 v)
{
    return min(min(v.x, v.y), v.z);
}

vec3 get_prev_screen(vec3 p)
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
    return p * 0.5 + 0.5;
}

// =========



/* RENDERTARGETS: 7 */
layout(location = 0) out vec3 col7;

void main()
{
    // Initialize values.
    col7 = vec3(1.0, 1.0, 0.0);
//     col8 = vec3(0.0);



    // gl_FragCoord = floor(uv * resolution) + 0.5
//     ivec2 texel = ivec2(gl_FragCoord.xy * 2.0); // resolution

//     const vec2 resolution = u_viewResolution.xy * vec2(0.5, 1.0);
    #define resolution u_viewResolution.xy
    const ivec2 texel = ivec2(uv * resolution);



    float dither = texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 63, 0).r;

    #if defined SS_AO_ACCUM || defined TAA

        dither = fract(dither + float(frameCounter) * 1.618034);

    #endif

    uint c5 = texelFetch(colortex5, texel, 0).r; // data

    vec3 normal_vs;
    normal_vs.x = float((c5 >> 26u) & 63u) / 63.0;
    normal_vs.y = float((c5 >> 20u) & 63u) / 63.0;
    normal_vs.z = float((c5 >> 14u) & 63u) / 63.0;
    normal_vs = mat3(gMV) * (normal_vs * 2.0 - 1.0);



    vec3 pos_ss = vec3(uv, texelFetch(colortex3, texel, 0).r);
    if (pos_ss.z == 1.0 || pos_ss.z < 0.56) return; // is_sky & is_hand

    #if !defined PIXELATE

        vec3 pos_vs = unproj3(gProjInv, pos_ss * 2.0 - 1.0);

    #else

        vec3 pos_vs = texelFetch(colortex3, texel, 0).gba;

    #endif

    // TODO: Fix with get_prev_screen().
//     pos_ss = pos_ss * 2.0 - 1.0; // ndc
//     pos_ss.z /= pos_ss.z < 0.56 ? MC_HAND_DEPTH : 1.0;
//
//     vec3 pos_vs = unproj3(gprojInv, pos_ss);



//*
#if SS_AO_MODE == 0
#if defined SS_AO || defined SS_GI

    // [null511] https://github.com/Null-MC
    // Screen Space Ambient Occlusion & Global Illumination.
    // Modified.
//     #define SS_AO_ITERS 8
    #define RADIUS_MAX 4.0 // 4
    #define OFFSET_Z vec3(1.0, 1.0, 0.99999952) // fp24: -4.8e-7, in ndc

    float rcp_iters = 1.0 / SS_AO_ITERS;
    float radius = min(RADIUS_MAX, -pos_vs.z * 0.25);
    float angle = 6.283185 * dither;



    float ao = 0.0; // ambient occlusion
//     vec3 gi = vec3(0.0); // global illumination or emissives

    for (float i = 1.0; i <= SS_AO_ITERS; ++i)
    {
        vec2 rd_ss = vec2(cos(angle), sin(angle)) * (radius * i * rcp_iters); // rd = ray direction
        angle += 1.618034;

        vec2 sam_ss = proj3(gProj, pos_vs + vec3(rd_ss, 0.0)).xy * 0.5 + 0.5; // sam = sample
        if (clamp(sam_ss, 0.0, 1.0) != sam_ss) continue;

        // TODO: Mip optimization (depth hierarchical z-buffer).
        float sam_depth = texelFetch(colortex3, ivec2(sam_ss * resolution), 0).r;
        if (sam_depth == 1.0) continue;

        // NOTE: When *PIXELATE* is active,
        // we do not sample colortexN (snapped view position), because it is probably slower.
        vec3 sam_vs = unproj3(gProjInv, vec3(sam_ss, sam_depth) * 2.0 - OFFSET_Z);



        vec3 delta = sam_vs - pos_vs; // front horizon

        if (delta.z < radius)
        {
            float cos_theta = max(0.001, dot(normal_vs, delta * rsqrt_fast(dot(delta, delta))));

            ao += cos_theta;

//             vec4 c0 = textureLod(colortex0, sam_ss, 0.0);
//             gi += c0.rgb * c0.a * u_lightColor.rgb * cos_theta; // diffuse = c0.rgb * c0.a * col_light
        }
    }

    ao = (ao * rcp_iters) * 3.0; // intensity
    ao = 1.0 - ao / (ao + 1.0);

//     gi = (gi * rcp_iters) * 9.0; // intensity
//     gi = gi / (gi + 1.0);



    // Write.
    col7.r = ao;
//     col8 = gi;

#endif
#endif
//*/



//*
#if SS_AO_MODE == 1
#if defined SS_AO || defined SS_GI

    // [] https://www.activision.com/cdn/research/Practical_Real_Time_Strategies_for_Accurate_Indirect_Occlusion_NEW%20VERSION_COLOR.pdf
    // [] https://cdrinmatane.github.io/posts/ssaovb-code/
    // Ground Truth Ambient Occlusion with Visibility Bitmasks & Global Illumination.
    // Modified.
//     #define SS_AO_DIRS 1
//     #define SS_AO_ITERS 8 // halfed
    #define RADIUS_MAX 4.0 // 4
    #define OFFSET_Z vec3(1.0, 1.0, 0.99999952) // fp24: -4.8e-7, in ndc

    vec3 view_vs = -normalize(pos_vs);

    float rcp_dirs = 1.0 / SS_AO_DIRS;
    float rcp_iters = 2.0 / SS_AO_ITERS;

    float radius = min(RADIUS_MAX, -pos_vs.z * 0.25);

    #if !defined SS_AO_ACCUM

        float dither2 = noise_r2(gl_FragCoord.xy);

    #else

        float dither2 = noise_r2(gl_FragCoord.xy + float(frameCounter) * 1.3); // 1.3 chosen empirically

    #endif



    float ao = 0.0; // ambient occlusion
//     vec3 gi = vec3(0.0); // global illumination or emissives

    for (float j = 1.0; j <= SS_AO_DIRS; ++j)
    {
        float phi = (3.141593 * rcp_dirs) * (j + dither);
        vec2 omega = vec2(cos(phi), sin(phi));

        float n;
        {
            // slice
            vec3 axis = cross(vec3(omega, 0.0), view_vs);
            vec3 tangent = cross(view_vs, axis);
            vec3 normal_proj = normal_vs - axis * dot(normal_vs, axis);

            float n_sgn = sign(dot(normal_proj, tangent));
            float n_cos = dot(normalize_fast(normal_proj), view_vs);

            n = n_sgn * acos_fast(n_cos);
        }

        uint occ_bits = 0u;

        for (float i = 0.1; i <= SS_AO_ITERS / 2; ++i)
        {
            float s = rcp_iters * (i + dither2);
            vec2 rd = omega * (s * radius);

            vec2 sam_ss0 = proj3(gProj, pos_vs - vec3(rd, 0.0)).xy * 0.5 + 0.5;
            vec2 sam_ss1 = proj3(gProj, pos_vs + vec3(rd, 0.0)).xy * 0.5 + 0.5;
            if (
                clamp(sam_ss0, 0.0, 1.0) != sam_ss0 &&
                clamp(sam_ss1, 0.0, 1.0) != sam_ss1
            ) continue;

            // TODO: Mip optimization (depth hierarchical z-buffer).
//             float sam_depth0 = texelFetch(colortex3, ivec2(sam_ss0 * resolution), 0).r;
//             float sam_depth1 = texelFetch(colortex3, ivec2(sam_ss1 * resolution), 0).r;

            // NOTE: Iris uses hardware bilinear interpolation for colortexN by default.
            float sam_depth0 = textureLod(colortex3, sam_ss0, 0.0).r;
            float sam_depth1 = textureLod(colortex3, sam_ss1, 0.0).r;
            if (sam_depth0 == 1.0 && sam_depth1 == 1.0) continue;

            vec3 sam_vs0 = unproj3(gProjInv, vec3(sam_ss0, sam_depth0) * 2.0 - OFFSET_Z);
            vec3 sam_vs1 = unproj3(gProjInv, vec3(sam_ss1, sam_depth1) * 2.0 - OFFSET_Z);

            vec3 delta0 = sam_vs0 - pos_vs;
            vec3 delta1 = sam_vs1 - pos_vs;

            vec2 horizons0;
            horizons0.x = dot(view_vs, normalize_fast(delta0));
            horizons0.y = dot(view_vs, normalize_fast(delta0 - view_vs)); // view_vs * thickness
            vec2 horizons1;
            horizons1.x = dot(view_vs, normalize_fast(delta1)); // front
            horizons1.y = dot(view_vs, normalize_fast(delta1 - view_vs)); // back

            horizons0.x = acos_fast(horizons0.x);
            horizons0.y = acos_fast(horizons0.y);
            horizons1.x = acos_fast(horizons1.x);
            horizons1.y = acos_fast(horizons1.y);

            horizons0 = clamp((n + horizons0) * 0.318310 + 0.5, 0.0, 1.0); // [0, pi] -> [0, 1]
            horizons1 = clamp((n - horizons1) * 0.318310 + 0.5, 0.0, 1.0);

            uint occ_bits0 = update_sectors(horizons0.xy);
            uint occ_bits1 = update_sectors(horizons1.yx);

//             {
//                 uint vis_bits0 = occ_bits0 & ~occ_bits;
//                 uint vis_bits1 = occ_bits1 & ~occ_bits;
//
//                 if (vis_bits0 != 0u || vis_bits1 != 0u)
//                 {
//                     float vis0 = float(bitCount(vis_bits0)) * 0.03125;
//                     float vis1 = float(bitCount(vis_bits1)) * 0.03125;
//
//                     vec4 c0 = textureLod(colortex0, sam_ss0, 0.0);
//                     gi += c0.rgb * c0.a * u_lightColor.rgb * vis0; // diffuse * vis0
//
//                     c0 = textureLod(colortex0, sam_ss1, 0.0);
//                     gi += c0.rgb * c0.a * u_lightColor.rgb * vis1;
//                 }
//             }

            occ_bits |= occ_bits0 | occ_bits1;
        }

        ao += float(bitCount(occ_bits)) * 0.03125;
    }

    ao = (ao * rcp_dirs) * 3.0; // intensity
    ao = 1.0 - ao / (ao + 1.0);

//     gi = (gi * rcp_dirs) * 9.0; // intensity
//     gi = gi / (gi + 1.0);



    // Write.
    col7.r = ao;
//     col8 = gi;

#endif
#endif
//*/



//*
# if defined SS_SHADOWS

    // [fclem]? https://github.com/blender/blender
    // [h3r2tic] https://gist.github.com/h3r2tic/9c8356bdaefbe80b1a22ae0aaee192db
    // Screen Space Shadows.
    // Modified.
    #define MAGIC_VALUE 0.996 // TODO: Test with a large render distance.
    #define THICKNESS 0.04

    vec3 ro;
    vec3 rd;

    ro = proj3(gProj, pos_vs * MAGIC_VALUE);
    rd = proj3(gProj, pos_vs * MAGIC_VALUE + u_shadowLightDirection);

    ro.z -= 4.8e-7;
    rd.z -= 4.8e-7;

    rd -= ro;

//     rd *= min(1.0, min_of((sign(rd.xyz) - ro.xyz) / rd.xyz)); // clip to view frustum
//     rd *= (1.0 / SS_SHADOWS_ITERS);

    ro = ro * 0.5 + 0.5;
    rd = rd * 0.5;

    rd *= dither * 0.5; // 0.5 = step_size



    float z0, z1, z_min, z_max;
//     vec2 bi_uv;
//     vec4 bi_weights;
//     vec4 depths;

    float shadows = 1.0;

    // raymarch
    for (int i = 0; i < SS_SHADOWS_ITERS; ++i)
    {
        ro += rd * vec3(i);
        if (clamp(ro.xy, 0.0, 1.0) != ro.xy) continue;

//         { // bilinear depth
//             bi_uv = fract(ro.xy * resolution - vec2(0.5));
//             bi_weights = vec4( // 00 10 01 11
//                 (1.0 - bi_uv.x) * (1.0 - bi_uv.y),
//                 (1.0 - bi_uv.y) * bi_uv.x,
//                 (1.0 - bi_uv.x) * bi_uv.y,
//                 bi_uv.x * bi_uv.y
//             );
//
//             depths = textureGather(colortex3, ro.xy, 0); // 01 11 10 00
//         }
//
//         // TODO: Mip optimization (depth hierarchical z-buffer).
//         z0 = texelFetch(colortex3, ivec2(ro.xy * resolution), 0).r;
//         z1 = dot(depths.wzxy, bi_weights);

        // NOTE: Iris uses hardware bilinear interpolation for colortexN by default.
        z0 = texelFetch(colortex3, ivec2(ro.xy * resolution), 0).r;
        z1 = textureLod(colortex3, ro.xy, 0.0).r;
        if (z0 == 1.0 && z1 == 1.0) continue;

        z_min = min(z0, z1);
        z_max = max(z0, z1);

        if (
//             ro.z > z_max * 1.000002 && // no bias due to MAGIC_VALUE
            ro.z > z_max && // hit
            ro.z < (z_min + THICKNESS) / (1.0 + THICKNESS) // thickness
        )
        {
            shadows = -0.5; // negative value for accumulation contrast
            break;
        }
    }



    // Write.
    col7.g = shadows;

#endif
//*/



//*
#if defined SS_AO_ACCUM || defined SS_GI_ACCUM || defined SS_SHADOWS_ACCUM

    // [sixthsurge] https://github.com/sixthsurge/photon
    // Temporal Accumulation.
    // Modified.
    #define PIXEL_AGE 10.0

    vec3 uv_prev = get_prev_screen(pos_ss);
    if (clamp(uv_prev.xy, 0., 1.) != uv_prev.xy) return;

    vec3 c7 = textureLod(colortex7, uv_prev.xy, 0.0).rgb; // ao_prev.r, shadows_prev.g, pixel_age_prev.b



    // TODO: Use view-space depths?
    float depth = near / (1.0 - pos_ss.z); // fast linearize
    float depth_prev = near / (1.0 - uv_prev.z);

    // depth rejection
    float weight_depth = abs(depth - depth_prev) / max(depth, depth_prev);
    weight_depth = 1.0 - max(0.0, weight_depth);
    weight_depth *= weight_depth;



    float pixel_age = min(c7.b * 250.0, PIXEL_AGE) * weight_depth; // 250 within buffer 8-bits
    float pixel_fac = pixel_age / (pixel_age + 1.0);



    // Write.
    #if defined SS_AO_ACCUM || defined SS_SHADOWS_ACCUM || 1

        col7.rg += (c7.rg - col7.rg) * pixel_fac; // col7 = mix(col7, col7_prev, pixel_fac)

    #endif

    #if defined SS_GI_ACCUM && 0

        vec3 c8 = textureLod(colortex8, uv_prev.xy, 0.0).rgb; // gi_prev.rgb
        col8 += (c8 - col8) * pixel_fac;

    #endif

    col7.b = (pixel_age + 1.0) * 0.004; // 1/250 within buffer 8-bits

#endif
//*/
}

#endif
