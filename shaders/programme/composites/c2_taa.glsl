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

uniform sampler2D depthtex0;

uniform sampler2D colortex0; // final.rgb
uniform sampler2D colortex2; // final_prev.rgb

#if defined TAA_MOTION_BLUR

    const bool colortex0MipmapEnabled = true;

#endif

// =========

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
//     mat3 rgb_to_ycocg = mat3(
//         0.25, 0.5, 0.25,
//         0.5, 0.0, -0.5,
//         -0.25, 0.5, -0.25
//     );

    // https://en.wikipedia.org/wiki/YCoCg
    return vec3(
        c.x * 0.25 + c.y * 0.5 + c.z * 0.25,
        c.x * 0.5 - c.z * 0.5,
        -c.x * 0.25 + c.y * 0.5 - c.z * 0.25
    );
}

vec3 ycocg_to_rgb(vec3 c)
{
//     mat3 ycocg_to_rgb = mat3(
//         1., 1., -1.,
//         1., 0., 1.,
//         1., -1., -1.
//     );

    // https://en.wikipedia.org/wiki/YCoCg
    return vec3(
        c.x + c.y - c.z,
        c.x + c.z,
        c.x - c.y - c.z
    );
}

// =========



/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec3 col0;
layout(location = 1) out vec3 col2;

void main()
{
    // Initialize values.
    col0 = texture(colortex0, uv).rgb;
//     col2 = vec3(0.0);



//*
    // [] https://github.com/playdeadgames/temporal
    // [] https://developer.download.nvidia.com/gameworks/events/GDC2016/msalvi_temporal_supersampling.pdf
    // Temporal Anti-Aliasing.

    // TODO: Jitter vertices.
    float depth = texelFetch(depthtex0, ivec2(gl_FragCoord), 0).r;
//     if (depth == 1.0 || depth < 0.56) return;

    vec2 uv_prev = get_prev_screen(vec3(uv, depth));
//     if (clamp(uv_prev, -0.25, 1.25) != uv_prev) return;



    // aabb_clamping()
//     vec3 c0 = texture(colortex0, uv).rgb;
    vec3 c0 = rgb_to_ycocg(col0);

    vec3 col_min;
    vec3 col_max;
//     vec3 col_avg;

    vec2 offsets01 = vec2(-u_viewResolution.z, u_viewResolution.w);
    vec2 offsets11 = vec2( u_viewResolution.z, u_viewResolution.w);

    vec3 c00 = rgb_to_ycocg(texture(colortex0, uv - offsets11).rgb);
    vec3 c10 = rgb_to_ycocg(texture(colortex0, uv - offsets01).rgb);
    vec3 c01 = rgb_to_ycocg(texture(colortex0, uv + offsets01).rgb);
    vec3 c11 = rgb_to_ycocg(texture(colortex0, uv + offsets11).rgb);

    col_min = min(c00, min(c10, min(c01, c11)));
    col_max = max(c00, max(c10, max(c01, c11)));
//     col_avg = (c00 + c10 + c01 + c11) * 0.25;



    // shirnk chroma min-max
//     vec2 chroma_extent = vec2(col_max.r - col_min.r) * 0.125;
//     vec2 chroma_center = c0.gb;
//
//     col_min.yz = chroma_center - chroma_extent;
//     col_max.yz = chroma_center + chroma_extent;
// //     col_avg.yz = chroma_center;



    // variance_clipping()
//     #define VC_GAMMA 1.0 // default = 1, higher = +ghosting, lower = +jittering
//
//     vec3 m1 = c00 + c10 + c01 + c11;
//     vec3 m2 = c00 * c00 + c10 * c10 + c01 * c01 + c11 * c11;
//
//     vec3 mu = m1 * 0.25; // m1/N
//     vec3 sigma = sqrt(m2 * 0.25 - mu * mu);
//
//     col_min = max(col_min, mu - VC_GAMMA * sigma); // minc
//     col_max = min(col_max, mu + VC_GAMMA * sigma); // maxc



    vec3 c0_prev = texture(colortex2, uv_prev).rgb;
    c0_prev = rgb_to_ycocg(c0_prev);

    // clip_aabb()
    vec3 p_clip = 0.5 * (col_max + col_min);
    vec3 e_clip = 0.5 * (col_max - col_min) + 1e-4;

    vec3 v_clip = c0_prev - p_clip; // vec4(p_clip, col_avg.w)
    vec3 v_unit = v_clip / e_clip;
    vec3 a_unit = abs(v_unit);
    float ma_unit = max(a_unit.x, max(a_unit.y, a_unit.z));

    c0_prev = ma_unit > 1.0 ? p_clip + v_clip / ma_unit : c0_prev; // vec4(p_clip, avg.w)



    // luminance_weights()
//     float lum0 = dot(c0, vec3(0.2126, 0.7152, 0.0722)); // vec3(0.299, 0.587, 0.114)
//     float lum1 = dot(c0_prev, vec3(0.2126, 0.7152, 0.0722));
    float lum0 = c0.r;
    float lum1 = c0_prev.r;

    float lum_fac;
    lum_fac = abs(lum0 - lum1) / max(lum0, max(lum1, 0.2));
    lum_fac = 1.0 - lum_fac;
    lum_fac = lum_fac * lum_fac;
    lum_fac = 0.88 + 0.09 * lum_fac; // mix(0.88, 0.97, lum_fac)



    // finalize
    c0 = mix(c0, c0_prev, lum_fac);
    c0 = ycocg_to_rgb(c0);



    #if defined TAA_MOTION_BLUR

        // motion_blur()
        #define MB_STRENGTH 1.5 // [0, 4]

        vec2 vel = (uv - uv_prev) * u_viewResolution.xy;
        vec2 vig = (uv_prev - 0.5) * (uv_prev - 0.5);

        float mip;
        mip = clamp(dot(vel, vel) - 25.0, 0.0, 100.0) * 0.01; // velocity factor
        mip = max(mip, min(1.0, dot(vig, vig))); // vignette

        c0 = mix(c0, textureLod(colortex0, uv, mip * MB_STRENGTH).rgb, mip);

    #endif



    // Write.
    col0 = c0;
    col2 = c0;
//*/
}

#endif
