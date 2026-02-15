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

// NOTE: colortex0 is bound, use the image.
layout(binding = 0, rgba8) readonly uniform image2D colorimg0; // sky.rgb

// =========

vec2 get_prev_screen(vec3 p)
{
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



/* RENDERTARGETS: ... */
layout(location = 0) out vec4 col2;
layout(location = 1) out vec4 col4;
layout(location = 2) out uint col6;

void voxy_emitFragment(VoxyFragmentParameters parameters)
{
    #if !defined RENDER_TRANSLUCENT_VX

        discard; return;

    #endif



    vec3 pos_vs = vec3(gl_FragCoord.xy * u_viewResolution.zw, gl_FragCoord.z); // vx_ss
    pos_vs = unproj3(vxProjInv, pos_vs * 2.0 - 1.0); // vs

    vec3 pos_sc = mul3(gMVInv, pos_vs);



    #if defined PIXELATE || 1

        // NOTE: Derivatives are currently unsupported.
        // Therefore, PIXELATE has no effect.
        float pos_ss_z = (gProj[2].z * pos_vs.z + gProj[3].z) / (gProj[2].w * pos_vs.z); // ndc
        pos_ss_z = fma(pos_ss_z, 0.5, 0.5); // ss



    #if !defined PIXELATE

        // Write.
        col4.r = pos_ss_z;
        col4.gba = vec3(0.0);

    #else

        // Write.
        col4.r = pos_ss_z;
        col4.gba = pos_vs;

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
    vec3 normal_sc = vec3(
        parameters.face >> 1u == 2u,
        parameters.face >> 1u == 0u,
        parameters.face >> 1u == 1u
    ) * (float(parameters.face & 1u) * 2.0 - 1.0);



    #if defined MAP_NORMAL_WATER

        // TODO: Use 3D noise instead. Grestner Waves.
        #define MAP_NW_SPEED 0.05
        #define MAP_NW_STRENGTH 0.01

        if (parameters.customId == i_WATER)
        {
            vec3 pos_ws = pos_sc + cameraPosition;

            vec2 uv0 = pos_ws.xz * 0.0625; // 16px = 0.25
            vec2 uv1 = pos_ws.xz * 0.0625;

            uv0 += vec2(MAP_NW_SPEED, -MAP_NW_SPEED) * frameTimeCounter;
            uv1 -= vec2(MAP_NW_SPEED, -MAP_NW_SPEED) * frameTimeCounter;

            float level;
            level = max(abs(pos_sc.x), max(abs(pos_sc.y), abs(pos_sc.z)));
            level = rcp_fast(floor(sqrt_fast(level) * 0.25) + 1.0);

            uv0 *= level;
            uv1 *= level;

            // NOTE: This is not the correct way to combine normal maps.
            // Watch: https://www.youtube.com/watch?v=S9sz00l3FqQ
            vec3 normal_map;

            normal_map.xy = texture(noisetex, uv0).gb * 2.0 - 1.0;
            normal_map.xy += texture(noisetex, uv1).gb * 2.0 - 1.0;
            normal_map.xy *= MAP_NW_STRENGTH;

//             normal_map.z = sqrt_fast(1.0 - dot(normal_map.xy, normal_map.xy));
            normal_map.z = 1.0;

            mat3 tbn; // ft
            tbn[2] = normal_sc;
            tbn[0] = cross(tbn[2], vec3(0.0, 0.0, 1.0)); // should normalize
            tbn[1] = cross(tbn[2], tbn[0]); // should normalize

            normal_sc = tbn * normal_map;
        }

    #endif



    #if !defined MAP_SPECULAR

        #define INELEGANT ;

    #else

        #define INELEGANT |

        // TODO: Temporary until the unbaked uv_atlas is supported.
        float is_emissive = float(parameters.customId == i_EMISSION);
        float is_metal = float(parameters.customId == i_METALLIC);

    #endif



    float dither = noise_r2(gl_FragCoord.xy) * 0.99; // 0.99, fix fireflies when packing

//     vec3 normal_sc = vec3(
//         parameters.face >> 1u == 2u,
//         parameters.face >> 1u == 0u,
//         parameters.face >> 1u == 1u
//     ) * (float(parameters.face & 1u) * 2.0 - 1.0);

    vec2 uv_lightmap = parameters.lightMap * parameters.lightMap; // square it here



    uint data =
    uint(fma(normal_sc.x, 0.5, 0.5) * 63.0 + 0.501) << 26u | // 6
    uint(fma(normal_sc.y, 0.5, 0.5) * 63.0 + 0.501) << 20u | // 6
    uint(fma(normal_sc.z, 0.5, 0.5) * 63.0 + 0.501) << 14u INELEGANT // 6

    #if defined MAP_SPECULAR

    uint(is_emissive * 7.0 + dither) << 1u | // 3
    uint(is_metal); // 1; uint(is_metal * 1.0 + dither) << 0u;

    #endif

    #if 1

        data |= uint(parameters.customId == i_WATER); // always

    #endif



    // radiance
    float light = fma(dot(normal_sc, mat3(gMVInv) * u_shadowLightDirection), 0.6, 0.4);
//     light *= uv_lightmap.y; // NOTE: Should be applied to the ambient term.



    #if defined CLOUDS_SHADOWS && OVERWORLD

        // [null511] https://github.com/Null-MC
        // [fayer3]
        // Cloud Shadows.
        // Modified.
        vec2 uv_clouds = pos_sc.xz;
//         vec2 uv_clouds = mul3(gMV, pos_vs + u_shadowLightDirection * cloudHeight).xz;

        // 3072.0 is one full cloud cycle
        uv_clouds = mod(pos_sc.xz, vec2(3072.0)) + cameraPosition.xz;
//         uv = mod(uv, vec2(3072.0)) + vec2(cameraPositionInt.xz) + cameraPositionFract.xz; // better

        uv_clouds += vec2(mod(cloudTime, 3072.0), 4.0); // 4.0 = magic_value_offset
        uv_clouds /= 3072.0;

        // TODO: Cloud texture interpolation, linear.
        light *= 1.0 - texture(cloudtex, uv_clouds).r * uv_lightmap.y * 0.6;

    #endif



    vec3 c10 = vec3(1.0, 0.8, 0.6);

    #if defined LIGHTS_COLOURED

        // NOTE: We cannot debug this here. Use the "final" programme.
        vec2 uv_prev = get_prev_screen(pos_sc);

        c10 = textureLod(colortex10, uv_prev, 0.0).rgb + vec3(1e-5, 8e-6, 6e-6);
        c10 = c10 * inversesqrt(dot(c10, c10)); // normalize()

    #endif



    #define AMBIENT_STRENGTH 0.2
    #define DIFFUSE_STRENGTH 1.1
    #define LIGHTS_STRENGTH 1.2
    #define EMISSIVE_STRENGTH 1.1

    #if defined NETHER

        // TODO: Justify a "sun", `b0_skybox.glsl`.
        #define AMBIENT_STRENGTH 0.5

        vec3 u_lightColor = vec3(0.8, 0.7, 0.6);
        vec3 skyColor = vec3(1.0);
        uv_lightmap.y = max(uv_lightmap.y, 0.2);

    #endif

    #if defined END

        // TODO: Justify a "sun", `b0_skybox.glsl`.
        vec3 u_lightColor = vec3(0.75, 0.7, 0.8);
        vec3 skyColor = vec3(1.0);

    #endif

    vec3 shading;

    // ambient
    shading = fogColor * mix(10.0, 1.0, skyColor.b) * AMBIENT_STRENGTH;

    // light
    light *= uv_lightmap.y;

    shading += u_lightColor.rgb * (light * DIFFUSE_STRENGTH);

    // lights
    shading += (c10.rgb * uv_lightmap.x)
    * (LIGHTS_STRENGTH - light * skyColor.b);

    // finalize
    #if defined WHITE_WORLD

        albedo.rgb = mix(shading, vec3(EMISSIVE_STRENGTH) * albedo.rgb, is_emissive);

    #else

        shading = mix(shading, vec3(EMISSIVE_STRENGTH), is_emissive); // ao
        albedo.rgb *= shading;

    #endif



    #if defined FOG_WATER

        if (parameters.customId == i_WATER)
        {
            float z0 = gl_FragCoord.z;
            float z1 = texelFetch(vxDepthTexOpaque, ivec2(gl_FragCoord), 0).r;

            z0 = 16.0 / (1.0 - z0); // fast linearize
            z1 = 16.0 / (1.0 - z1); // 16.0 = near plane

            float fog = exp2((z0 - z1) * 0.125);

            albedo.rgb *= mix(vec3(0.5), vec3(1.0, 1.5, 1.0), fog);
            albedo.a = max(0.2, 1.0 - fog);
            albedo.a *= isEyeInWater > 0 ? -1.0 : 1.0;
        }

    #endif



    #if defined FOG_BORDER || defined FOG_HEIGHT

        float fog = 0.0;
        float pos_len = sqrt_fast(dot(pos_sc, pos_sc)); // length()
        vec3 c0 = imageLoad(colorimg0, ivec2(gl_FragCoord) / 4).rgb; // sky



        #if defined FOG_BORDER

            // NOTE: Make sure in Voxy, "Enable vanilla fog" is enabled.
            float fog_start = isEyeInWater > 0 ? fogStart : 16.0;
            float fog_end = isEyeInWater > 0 ? min(fogEnd, vxFar) : vxFar;

            fog = linearstep(fog_start, fog_end, pos_len); // 1 chunk = 16

        #endif



        #if defined FOG_HEIGHT

            #define SEA_LEVEL 63.0

            #if defined NETHER

                #define SEA_LEVEL  31.0

            #endif

            vec3 pos_ws = pos_sc + cameraPosition;

            float height = abs(pos_ws.y - SEA_LEVEL);
            height = linearstep(16.0, -16.0, height); // 1 chunk = 16

            // masks
            height *= linearstep(16.0, 64.0, pos_len); // 1 chunk = 16

            // TODO: Blur the cloud texture.
            vec2 uv_dither = (pos_ws.xz + frameTimeCounter * 0.25); // speed
//             uv_dither *= 1.0 / (textureSize(noisetex, 0) * 64.0); // size
            uv_dither *= 0.000158; // hardcoded

            float dither2 = texture(noisetex, uv_dither).r;
//             dither2 = 0.4 + 0.6 * dither2; // mix()

            height *= dither2;

            fog = max(fog, height);

        #endif



        // Write.
        albedo.rgb = mix(albedo.rgb, c0, fog);

    #endif



    // Write.
//     col2 = vec4(1, 0, 0, 1); // debug
    col2 = albedo;
    col6 = data;
}
