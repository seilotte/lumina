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

#if defined VOXY

    #define colortex7 colortex17
    #define colortex6 colortex16

#endif

in vec2 uv;

uniform sampler2D noisetex;
uniform sampler2D depthtex0;

uniform sampler2D colortex0; // final.rgb
uniform sampler2D colortex8; // coloured_lights_prev.rgb
uniform usampler2D colortex7; // data.r
uniform sampler2D colortex6; // pos_vs_pixelated.rgb

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



/* RENDERTARGETS: 8,3 */
layout(location = 0) out vec3 col8;
layout(location = 1) out vec4 col3;

void main()
{
    // Initialize values.
    col8 = vec3(0.0);
    col3 = vec4(0.0);



//     ivec2 texel = ivec2(gl_FragCoord.xy * 1.0); // resolution;
    ivec2 texel = ivec2(gl_FragCoord.xy / SS_R_RES);

    float dither = texelFetch(noisetex, texel & 63, 0).r;

    #if defined TAA

        dither = fract(dither + float(frameCounter) * 1.618034);

    #endif

    uint c7 = texelFetch(colortex7, texel, 0).r; // data
    if (c7 < 1u) return; // is_sky

    float is_emissive = float((c7 >> 1u) & 7u) / 7.0;
    float is_metal = float(c7 & 1u); // float((c8 >> 0u) & 1u) / 1.0;

//     vec3 pos_ss = vec3(uv, textureLod(depthtex0, uv, 0).r);
    vec3 pos_ss = vec3(uv, texelFetch(depthtex0, texel, 0).r);



//*
#if defined LIGHTS_COLOURED

    // Coloured Lights.
    vec2 uv_prev = get_prev_screen(pos_ss);

//     if (clamp(uv_prev, 0.0, 1.0) == uv_prev)
    {
        float radius = (1.0 - pos_ss.z) * gProj[0].x * 15.0; // 15 = size

        #if !defined TAA

            radius *= fract(dither + float(frameCounter) * 1.618034);

        #endif

        vec3 emissive = texture(colortex0, uv).rgb * is_emissive;

        // 4x star
        vec3 emissive_prev = 0.25 * (
            texture(colortex8, uv_prev + vec2(radius, 0)).rgb + // +x
            texture(colortex8, uv_prev + vec2(0, radius)).rgb + // +y
            texture(colortex8, uv_prev - vec2(radius, 0)).rgb + // -x
            texture(colortex8, uv_prev - vec2(0, radius)).rgb   // -y
        );

        emissive = mix(emissive_prev, emissive * 10.0, 0.1);



        // Write.
        col8 = vec3(emissive);
    }

#endif
//*/



//*
#if defined SS_R && SS_R_MODE == 0

    // Simple Reflections.
    if (is_metal < 1.0) return; // !is_metal



    vec3 normal_vs;
    normal_vs.x = float((c7 >> 26u) & 63u) / 63.0;
    normal_vs.y = float((c7 >> 20u) & 63u) / 63.0;
    normal_vs.z = float((c7 >> 14u) & 63u) / 63.0;
    normal_vs = mat3(gMV) * (normal_vs * 2.0 - 1.0);

    bool is_hand = pos_ss.z < 0.56;

    #if !defined PIXELATE

//         vec3 pos_vs = unproj3(gProjInv, pos_ss * 2.0 - 1.0);
        vec3 pos_vs = unproj3(gProjInv, (pos_ss*2.-1.) * vec3(1.,1.,is_hand?1./MC_HAND_DEPTH:1.));

    #else

//         vec3 pos_vs = textureLod(colortex6, uv, 0.0).gba;
        vec3 pos_vs = texelFetch(colortex6, texel, 0).gba;

    #endif

    vec3 view_vs = -normalize_fast(pos_vs);

    vec3 uv_ref = reflect(-view_vs, normal_vs); // vs
    uv_ref = proj3(gProj, uv_ref) * 0.5 + 0.5; // ss



    vec3 ssr = vec3(0.0);
    float mask = 1.0;

    if (clamp(uv_ref, 0.0, 1.0) != uv_ref) return;

    ssr = texture(colortex0, uv_ref.xy).rgb;

    mask = 1.0 - dot(normal_vs, view_vs); // NoV
    mask *= is_hand ? 1.0 : (abs(uv_ref.x - 0.5) *2.-1.) * (abs(uv_ref.y - 0.5) *2.-1.); // vignette
//     mask *= max(is_metal, 1.0 - is_roughness);



    // Write.
    col3 = vec4(ssr, mask);

#endif
//*/



//*
#if defined SS_R && SS_R_MODE == 1

    // [fclem]? https://github.com/blender/blender
    // [h3r2tic] https://gist.github.com/h3r2tic/9c8356bdaefbe80b1a22ae0aaee192db
    // Screen Space Reflections.
    // Modified.
//     #define SS_R_ITERS 12
    #define THICKNESS 0.2

    if (is_metal < 1.0) return; // !is_metal



    vec3 normal_vs;
    normal_vs.x = float((c7 >> 26u) & 63u) / 63.0;
    normal_vs.y = float((c7 >> 20u) & 63u) / 63.0;
    normal_vs.z = float((c7 >> 14u) & 63u) / 63.0;
    normal_vs = mat3(gMV) * (normal_vs * 2.0 - 1.0);

    bool is_hand = pos_ss.z < 0.56;

    #if !defined PIXELATE

//         vec3 pos_vs = unproj3(gProjInv, pos_ss * 2.0 - 1.0);
        vec3 pos_vs = unproj3(gProjInv, (pos_ss*2.-1.) * vec3(1.,1.,is_hand?1./MC_HAND_DEPTH:1.));

    #else

//         vec3 pos_vs = textureLod(colortex6, uv, 0.0).gba;
        vec3 pos_vs = texelFetch(colortex6, texel, 0).gba;

    #endif

    // NOTE: Normals require a float buffer for reflections.
    // An inaccurate workaround is to offset the reflection vector slightly.
    #define MAGIC_VALUE vec3(0.0, 0.06, 0.0)

    vec3 view_vs = -normalize_fast(pos_vs);
    vec3 ref_vs = normalize_fast(reflect(-view_vs - MAGIC_VALUE, normal_vs));



    vec4 ro;
    vec4 rd;

    ro.xyz = proj3(gProj, pos_vs); // 2ndc
    rd.xyz = proj3(gProj, pos_vs + ref_vs);

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
//         z = textureLod(depthtex0, ro.xy, 0.0).r;
        z = texelFetch(depthtex0, ivec2(ro.xy * u_viewResolution.xy + 0.5), 0).r;
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



    vec3 ssr = texture(colortex0, uv_hit).rgb * mask;

    mask *= 1.0 - dot(normal_vs, view_vs); // NoV
    mask *= is_hand ? 1.0 : (abs(uv_hit.x - 0.5) *2.-1.) * (abs(uv_hit.y - 0.5) *2.-1.); // vignette
//     mask *= max(is_metal, 1.0 - is_roughness);



    // Write.
    col3 = vec4(ssr, mask);

#endif
//*/
}

#endif
