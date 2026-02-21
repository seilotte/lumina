#include "/programme/_lib/version.glsl"

#include "/programme/_lib/uniforms.glsl"
#include "/programme/_lib/math.glsl"
#include "/shader.h"

#ifdef VSH

in vec2 mc_Entity;
in vec2 vaUV0;
in ivec2 vaUV2;
in vec3 vaPosition;
in vec3 vaNormal;
in vec4 vaColor;
in vec4 at_tangent;

flat out int id;
out vec2 uv_atlas;
out vec2 uv_lightmap;
out vec3 pos_sc;
out vec4 vcol;
out mat3 tbn_vs;

// =========



void main()
{
    #if !defined RENDER_TRANSLUCENT

        gl_Position = vec4(-10.0); // discard
        return;

    #endif



    vec3 position = vaPosition;

    #if defined G_WATER

        position += chunkOffset;

    #endif



    id = int(mc_Entity.x);
    uv_atlas = vaUV0;
    uv_lightmap = vec2(vaUV2 * vaUV2) * 0.000017; // square it here
    pos_sc = vec3(0.0);
    vcol = vaColor;
    tbn_vs[2] = normalize(normalMatrix * vaNormal);



    #if defined MAP_SHADOW || defined PIXELATE || defined MAP_NORMAL_WATER
    #if defined G_HAND_WATER

        pos_sc = mul3(gMVInv, mul3(mMV, position));

    #else

        pos_sc = position;

    #endif
    #endif



    #if defined G_PARTICLES_TRANSLUCENT

        tbn_vs[2] = normalMatrix[1];

    #endif



    #if defined MAP_NORMAL || defined MAP_NORMAL_WATER

        tbn_vs[0] = normalize(normalMatrix * at_tangent.xyz);
        tbn_vs[1] = cross(tbn_vs[0], tbn_vs[2]) * sign(at_tangent.w);

    #endif




    #if defined DIS_WATER
    #if defined G_WATER

        #define DW_STRENGTH 0.05
        #define DW_SPEED 2.0

        if (id == i_WATER)
        {
            float mask = linearstep(
                vxFar,
                vxFar * 0.8,
                sqrt_fast(dot(pos_sc, pos_sc))
            );

            position.y +=
            cos(position.x + position.y + frameTimeCounter * DW_SPEED) * DW_STRENGTH * mask;
        }

    #endif
    #endif


    gl_Position = proj4(mProj, mul3(mMV, position));
//     gl_Position.x = gl_Position.x * 0.5 - gl_Position.w * 0.5; // downscale
}

#endif



/*
 * #########
 */



#ifdef FSH

flat in int id;
in vec2 uv_atlas;
in vec2 uv_lightmap;
in vec3 pos_sc;
in vec4 vcol;
in mat3 tbn_vs;

uniform sampler2D gtexture; // atlas
uniform sampler2D specular;
uniform sampler2D normals;

uniform sampler2D noisetex;
uniform sampler2D cloudtex; // clouds.png
uniform sampler2D shadowtex1;
uniform sampler2D depthtex1;

uniform sampler2D colortex10; // coloured_lights.rgb (previous)

uniform sampler2D radiosity_direct; // photonics

// NOTE: colortex0 is bound, use the image.
layout(binding = 0, rgba8) readonly uniform image2D colorimg0; // sky.rgb

// =========

#include "/programme/_lib/lights_colours.glsl"

// =========

// [cyanember] shaderLABS discord
// Modified.
vec2 texel_offset(vec2 uv, vec2 s)
{ // uv = uv_atlas, s = texture_size
    return inverse(mat2x2(dFdx(uv),dFdy(uv))) * (((floor(uv * s) + 0.5) / s) - uv);
}

// a = attribute, t = texel_offset
float texel_snap(float a, vec2 t) { return a + (dFdx(a) * t.x + dFdy(a) * t.y); }
vec2 texel_snap(vec2 a, vec2 t) { return a + (dFdx(a) * t.x + dFdy(a) * t.y); }
vec3 texel_snap(vec3 a, vec2 t) { return a + (dFdx(a) * t.x + dFdy(a) * t.y); }
vec4 texel_snap(vec4 a, vec2 t) { return a + (dFdx(a) * t.x + dFdy(a) * t.y); }

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



/* RENDERTARGETS: 2,4,6 */
layout(location = 0) out vec4 col2;
layout(location = 1) out vec4 col4;
layout(location = 2) out uint col6;

void main()
{
    #if !defined PIXELATE

        // Write.
        col4.r = gl_FragCoord.z;

    #else

        vec2 texel_offset = texel_offset(uv_atlas, textureSize(gtexture, 0));

        vec2 uv_lightmap = texel_snap(uv_lightmap, texel_offset);
        vec3 pos_sc = texel_snap(pos_sc, texel_offset);
        vec4 vcol = texel_snap(vcol, texel_offset);



        // Write.
        col4.r = gl_FragCoord.z;
        col4.gba = mul3(gMV, pos_sc);

    #endif



    if (gl_HelperInvocation) return;



    vec4 albedo = vcol;

    #if defined MAP_ALBEDO

        albedo *= texture(gtexture, uv_atlas);

    #endif



    #if !defined G_ENTITIES_TRANSLUCENT

        if (albedo.a < 0.1) {discard; return;}

    #else

        if (albedo.a < 0.1 || vcol.a < 0.5) {discard; return;} // nametags & breeze

    #endif



    #if defined G_ENTITIES_TRANSLUCENT

        albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);

    #endif



    #if defined G_WEATHER

        albedo.a *= 0.333;

    #endif



    // data
    #if !defined MAP_NORMAL

        vec3 normal_vs = tbn_vs[2];

    #else

        vec3 normal_map = texture(normals, uv_atlas).rgb;
        normal_map.xy = normal_map.xy * 2.0 - 1.0;
        normal_map.z *= sqrt_fast(1.0 - dot(normal_map.xy, normal_map.xy));

        vec3 normal_vs = tbn_vs * normal_map;

    #endif



    #if defined MAP_NORMAL_WATER

        // TODO: Use 3D noise instead. Grestner Waves.
        #define MAP_NW_SPEED 0.05
        #define MAP_NW_STRENGTH 0.01

        if (id == i_WATER)
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

            mat3 tbn; // vs
            tbn[2] = normal_vs;
            tbn[0] = cross(tbn[2], normalMatrix[2]); // should normalize
            tbn[1] = cross(tbn[2], tbn[0]); // should normalize

            normal_vs = tbn * normal_map;
        }

    #endif



    #if !defined MAP_SPECULAR

        #define INELEGANT ;

    #else

        #define INELEGANT |

        vec4 specular_map = textureLod(specular, uv_atlas, 0.0);

        float is_emissive = fract(specular_map.a);
        float is_metal = float(specular_map.g > 0.9 || specular_map.r > 0.95); // is metal & low roughness

    #endif



    #if defined G_ENTITIES_TRANSLUCENT

        // TODO: Verify there are not false positives.
        bool is_nametag = dot(albedo + vcol, vec4(1.0)) > 7.999;
        is_emissive = is_nametag ? 1.0 : is_emissive;

    #endif



    float dither = noise_r2(gl_FragCoord.xy) * 0.99; // 0.99, fix fireflies when packing

    vec3 normal_sc = (mat3(gMVInv) * normal_vs) * 0.5 + 0.5;



    uint data =
    uint(normal_sc.x * 63.0 + 0.501) << 26u | // 6
    uint(normal_sc.y * 63.0 + 0.501) << 20u | // 6
    uint(normal_sc.z * 63.0 + 0.501) << 14u INELEGANT // 6

    #if defined MAP_SPECULAR

    uint(is_emissive * 7.0 + dither) << 1u | // 3
    uint(is_metal); // 1; uint(is_metal * 1.0 + dither) << 0u;

    #endif

    #if defined G_WATER

        data |= uint(id == i_WATER); // always

    #endif



    // radiance
    float light = dot(normal_vs, u_shadowLightDirection) * 0.6 + 0.4;
//     light *= uv_lightmap.y; // NOTE: Should be applied to the ambient term.



    #if defined MAP_SHADOW && 0
    #if !defined NETHER && defined PHOTONICS_ENABLED

        // NOTE: Only deferred geometry, therefore it looks wrong.
        float fade = dot(pos_sc, pos_sc) / (far * far);
        float depth = textureLod(radiosity_direct, gl_FragCoord.xy * u_viewResolution.zw, 0.0).a;

        light *= mix(depth, 1.0, min(1.0, fade));

    #endif
    #endif



    #if defined MAP_SHADOW
    #if !defined NETHER

        // [] https://github.com/mateuskreuch/minecraft-miniature-shader
        // Shadow Map Sampling.
        // Modified.
        float pos_dist = dot(pos_sc, pos_sc);
        float max_dist = shadowDistance * shadowDistance;

        vec3 shadow_uv = proj3_ortho(sProj, mul3(sMV, pos_sc)); // ndc

        shadow_uv.xy = mat2(u_mat2ShadowAlign) * shadow_uv.xy;
        shadow_uv.xy /= abs(shadow_uv.xy) * 0.7 + 0.3; // distortion

        shadow_uv = shadow_uv * 0.5 + 0.5;

        if (
            clamp(shadow_uv.xy, 0.0, 1.0) == shadow_uv.xy &&
            shadow_uv.z < 1.0 && pos_dist < max_dist
        )
        {
            float fade = 1.0 - pos_dist / max_dist;
            float depth = texture(shadowtex1, shadow_uv.xy).r;

            light *= 1.0 - fade * clamp(
                3.0 * (depth - shadow_uv.z) / sProj[2].z,
                0.0, 1.0
            );
        }

    #endif
    #endif



    #if defined CLOUDS_SHADOWS && defined OVERWORLD

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



    // shading
    vec3 c10 = vec3(1.0, 0.8, 0.6); // lights

    #if defined LIGHTS_COLOURED

        // NOTE: We cannot debug this here. Use the "final" programme.
        vec2 uv_prev = get_prev_screen(pos_sc);

        c10 = texture(colortex10, uv_prev).rgb + vec3(1e-5, 8e-6, 6e-6);
        c10 = c10 * inversesqrt(dot(c10, c10)); // normalize()

    #endif



    vec3 light_hand = vec3(0.0);
    vec3 light_hand2 = vec3(0.0);

    #if defined LIGHTS_HAND

        vec3 pos_hand = (pos_sc + cameraPosition) - eyePosition;
        float light_len = sqrt_fast(dot(pos_hand, pos_hand));

        light_hand.r = 4.0 + 0.234 * heldBlockLightValue; // mix(4, 8, v / 15)
        light_hand.r = linearstep(light_hand.r, 0.0, light_len);
        light_hand.r *= min(1.0, float(heldBlockLightValue));

        light_hand2.r = 4.0 + 0.234 * heldBlockLightValue2;
        light_hand2.r = linearstep(light_hand2.r, 0.0, light_len);
        light_hand2.r *= min(1.0, float(heldBlockLightValue2));

        #if !defined LIGHTS_HAND_COLOURED

            light_hand = vec3(1.0, 0.8, 0.6) * light_hand.rrr;
            light_hand2 = vec3(1.0, 0.8, 0.6) * light_hand2.rrr;

        #else

            light_hand = light_colours[heldItemId - i_EMISSION] * light_hand.rrr;
            light_hand2 = light_colours[heldItemId2 - i_EMISSION] * light_hand2.rrr;

        #endif

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
        #define AMBIENT_STRENGTH 1.0

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
    shading += (c10.rgb * uv_lightmap.x + light_hand + light_hand2)
    * (LIGHTS_STRENGTH - light * skyColor.b);

    // finalize
    #if defined WHITE_WORLD

        albedo.rgb = mix(shading, vec3(EMISSIVE_STRENGTH) * albedo.rgb, is_emissive);

    #else

        shading = mix(shading, vec3(EMISSIVE_STRENGTH), is_emissive); // ao
        albedo.rgb *= shading;

    #endif



    #if defined FOG_WATER
    #if defined G_WATER

        if (id == i_WATER)
        {
            float z0 = gl_FragCoord.z;
            float z1 = texelFetch(depthtex1, ivec2(gl_FragCoord), 0).r;

            z0 = near / (1.0 - z0); // fast linearize
            z1 = near / (1.0 - z1);

            float fog = exp2((z0 - z1) * 0.125);

            albedo.rgb *= mix(vec3(0.5), vec3(1.0, 1.5, 1.0), fog);
            albedo.a = max(0.2, 1.0 - fog);
            albedo.a *= isEyeInWater > 0 ? -1.0 : 1.0;
        }

    #endif
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
        albedo.rgb = mix(albedo.rgb, c0, fog); // sky

    #endif



    // Write.
//     col2 = vec4(0, 0, 1, 1); // debug
    col2 = albedo;
    col6 = data;
}

#endif
