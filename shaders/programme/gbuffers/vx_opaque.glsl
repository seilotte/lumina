// #include "/programme/_lib/version.glsl" // 460 core voxy's default

// #include "/programme/_lib/uniforms.glsl" // voxy.json
#include "/programme/_lib/math.glsl"
#include "/shader.h"

// struct VoxyFragmentParameters { // we are patching
//     uint face;
//     uint modelId;
//     uint customId;// same as iris's mcEntity.x
//     vec2 uv;
//     vec2 lightMap;
//     vec2 tile;
//     vec4 tinting;
//     vec4 sampledColour;
// };

// =========



/* RENDERTARGETS: 0,7,6,1,10,17,16 */ // voxy.json
layout(location = 0) out vec4 col0;
layout(location = 1) out uint col7;
layout(location = 2) out vec4 col6;

layout(location = 3) out vec4 col1;
layout(location = 4) out vec4 col10;
layout(location = 5) out uint col17;
layout(location = 6) out vec4 col16;

void voxy_emitFragment(VoxyFragmentParameters parameters)
{
    #if !defined RENDER_OPAQUE_VX

        discard; return;

    #endif



    #if defined PIXELATE || defined VOXY

        // NOTE: Derivatives are currently unsupported.
        // Therefore, PIXELATE has no effect.
        vec3 pos_ss = vec3(gl_FragCoord.xy * u_viewResolution.zw, gl_FragCoord.z); // vx_ss
        vec3 pos_vs = unproj3(vxProjInv, pos_ss * 2.0 - 1.0); // vs

        pos_ss.z = (gProj[2].z * pos_vs.z + gProj[3].z) / (gProj[2].w * pos_vs.z); // ndc
        pos_ss.z = fma(pos_ss.z, 0.5, 0.5); // ss



        // Write.
        col6.r = pos_ss.z;
        col6.gba = pos_vs;

        col16 = col6;

    #endif



    // NOTE: The original shader already does it.
//     if (gl_HelperInvocation) return;



    vec4 albedo = parameters.tinting;

    #if defined MAP_ALBEDO

        albedo *= parameters.sampledColour;

    #endif



    if (albedo.a < 0.1) {discard; return;}



    // data
    #if !defined MAP_SPECULAR

        #define INELEGANT ;

    #else

        #define INELEGANT |

        // TODO: Temporary until the unbaked uv_atlas is supported.
        float is_emissive = float(parameters.customId == i_EMISSION);
        float is_metal = float(parameters.customId == i_METALLIC);

    #endif



    float dither = noise_r2(gl_FragCoord.xy) * 0.99; // 0.99, fix fireflies when packing

    vec3 normal_ft = vec3(
        parameters.face >> 1u == 2u,
        parameters.face >> 1u == 0u,
        parameters.face >> 1u == 1u
    ) * (float(parameters.face & 1u) * 2.0 - 1.0);

    if (
        useCutout() && // (interData.x & 1u) == 1u; we are patching
        parameters.customId > 99 && parameters.customId < 110
    )
    {
        normal_ft = vec3(0.0, 1.0, 0.0);
    }

    vec2 uv_lightmap = parameters.lightMap * parameters.lightMap; // square it here



    uint data =
    uint(fma(normal_ft.x, 0.5, 0.5) * 63.0 + 0.5) << 26u | // 6
    uint(fma(normal_ft.y, 0.5, 0.5) * 63.0 + 0.5) << 20u | // 6
    uint(fma(normal_ft.z, 0.5, 0.5) * 63.0 + 0.5) << 14u | // 6

    uint(uv_lightmap.x * 31.0 + dither) << 9u | // 5
    uint(uv_lightmap.y * 31.0 + dither) << 4u INELEGANT // 5

    #if defined MAP_SPECULAR

    uint(is_emissive * 7.0 + dither) << 1u | // 3
    uint(is_metal); // 1; uint(is_metal * 1.0 + dither) << 0u;

    #endif



    // radiance
    float light = fma(dot(normal_ft, mat3(gMVInv) * u_shadowLightDirection), 0.6, 0.4);



    // Write.
//     col0 = vec4(1, 0, 0, 1); // debug
    col0 = vec4(albedo.rgb, light);
    col7 = data;

    col1 = vec4(1.0);
    col10 = vec4(0.0);
    col17 = data;
}
