/*
NOTE: We are patching the original shader, therefore:

- Version is 460 core.

- The following are defined in "voxy.json":
    - Uniforms.
    - Samplers.
    - Render targets.
    - Blend functions.
    - ...

- There is a parameters struct.
    - struct VoxyFragmentParameters {
        uint face;
        uint modelId;
        uint customId;// same as iris's mcEntity.x
        vec2 uv;
        vec2 lightMap;
        vec2 tile;
        vec4 tinting;
        vec4 sampledColour;
    };
- ...
*/

// #include "/programme/_lib/version.glsl"

// #include "/programme/_lib/uniforms.glsl"
#include "/programme/_lib/math.glsl"
#include "/shader.h"

// uniform sampler2D ...

// =========



/* RENDERTARGETS: ... */
layout(location = 0) out vec4 col1;
layout(location = 1) out vec4 col2;
layout(location = 2) out vec4 col3;
layout(location = 3) out vec4 col4;
layout(location = 4) out uint col5;
layout(location = 5) out uint col6;

void voxy_emitFragment(VoxyFragmentParameters parameters)
{
    #if !defined RENDER_OPAQUE_VX

        discard; return;

    #endif



    #if defined PIXELATE || 1

        // NOTE: Derivatives are currently unsupported.
        // Therefore, PIXELATE has no effect.
        vec3 pos_ss = vec3(gl_FragCoord.xy * u_viewResolution.zw, gl_FragCoord.z); // vx_ss
        vec3 pos_vs = unproj3(vxProjInv, pos_ss * 2.0 - 1.0); // vs

        pos_ss.z = (gProj[2].z * pos_vs.z + gProj[3].z) / (gProj[2].w * pos_vs.z); // ndc
        pos_ss.z = fma(pos_ss.z, 0.5, 0.5); // ss



    #if !defined PIXELATE

        // Write.
        col3.r = pos_ss.z;
        col3.gba = vec3(0.0);
        col4 = col3;

    #else

        // Write.
        col3.r = pos_ss.z;
        col3.gba = pos_vs;
        col4 = col3;

    #endif
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

    vec3 normal_sc = vec3(
        parameters.face >> 1u == 2u,
        parameters.face >> 1u == 0u,
        parameters.face >> 1u == 1u
    ) * (float(parameters.face & 1u) * 2.0 - 1.0);

    // NOTE: Verify on each Voxy update.
    if (
        (interData.x & 1u) == 1u && // cutout/discard
        parameters.customId > 99 && parameters.customId < 110
    )
    {
        normal_sc = vec3(0.0, 1.0, 0.0);
    }

    vec2 uv_lightmap = parameters.lightMap * parameters.lightMap; // square it here



    uint data =
    uint(fma(normal_sc.x, 0.5, 0.5) * 63.0 + 0.501) << 26u | // 6
    uint(fma(normal_sc.y, 0.5, 0.5) * 63.0 + 0.501) << 20u | // 6
    uint(fma(normal_sc.z, 0.5, 0.5) * 63.0 + 0.501) << 14u | // 6

    uint(uv_lightmap.x * 31.0 + dither) << 9u | // 5
    uint(uv_lightmap.y * 31.0 + dither) << 4u INELEGANT // 5

    #if defined MAP_SPECULAR

    uint(is_emissive * 7.0 + dither) << 1u | // 3
    uint(is_metal); // 1; uint(is_metal * 1.0 + dither) << 0u;

    #endif



    // radiance
    float light = fma(dot(normal_sc, mat3(gMVInv) * u_shadowLightDirection), 0.6, 0.4);



    // Write.
//     col1 = vec4(1, 0, 0, 1); // debug
    col1 = vec4(albedo.rgb, light);
    col2 = vec4(0., 0., 0., 1.); // curse entitites
    col5 = data;
    col6 = data;
}
