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
in vec4 at_midBlock;

out vec2 uv_atlas;
out vec2 uv_lightmap;
out vec3 pos_sc;
out vec4 vcol;
out mat3 tbn_vs;

// =========



void main()
{
    #if !defined RENDER_OPAQUE

        gl_Position = vec4(-10.0); // discard
        return;

    #endif



    vec3 position = vaPosition;

    #if defined G_TERRAIN || defined G_TERRAIN_CUTOUT

        position += chunkOffset;

    #endif



    uv_atlas = vaUV0;
    uv_lightmap = vec2(vaUV2 * vaUV2) * 0.000017; // square it here
    pos_sc = vec3(0.0);
    vcol = vaColor;
    tbn_vs[2] = normalize(normalMatrix * vaNormal);



    #if defined MAP_SHADOW || defined PIXELATE
    #if defined G_HAND

        pos_sc = mul3(gMVInv, mul3(mMV, position));

    #else

        pos_sc = position;

    #endif
    #endif



    #if defined G_PARTICLES

        tbn_vs[2] = normalMatrix[1];

    #elif defined G_TERRAIN_CUTOUT

        if (
            mc_Entity.x > 99 && mc_Entity.x < 110

            ^^ mc_Entity.x == 102 && // is_pot or is_pitcher_crop_lower
            0.1 - at_midBlock.y * 0.015625 < 0.0
        )
        {
            tbn_vs[2] = normalMatrix[1]; // normalMatrix * vec3(0, 1, 0)
        }

    #endif



    #if defined MAP_NORMAL

        tbn_vs[0] = normalize(normalMatrix * at_tangent.xyz);
        tbn_vs[1] = cross(tbn_vs[0], tbn_vs[2]) * sign(at_tangent.w);

    #endif



    #if defined DIS_FOLLIAGE
    #if defined G_TERRAIN || defined G_TERRAIN_CUTOUT

        #define DF_STRENGTH 0.0002
        #define DF_SPEED 1.0

        // NOTE: "G_TERRAIN" does not need all the checks (101, 102 only).
        // TODO: Use a bitfield for faster checks.
        int id = int(mc_Entity.x);

        if (id > 99 && id < 200) // wind 1xx
        {
            float strength = vaUV2.y * DF_STRENGTH;

//             if (id == 100 || id == 110)
//             { // full
//                 strength *= 1.0;
//             }
            if (id == 101 || id == 111)
            { //  more stiffness
                strength *= 0.5;
            }
            else if (id == 102 || id == 112)
            { // potted
                strength *= max(0.0, 0.1 - at_midBlock.y * 0.015625);
            }
            else if (id == 103 || id == 113)
            { // lower/short folliage
                strength *= 0.5 - at_midBlock.y * 0.015625;
            }
            else if (id == 104 || id == 114)
            { // upper folliage
                strength *= 1.5 - at_midBlock.y * 0.015625;
            }

            position.x +=
            sin(position.x + position.y + frameTimeCounter * DF_SPEED) * strength;
            position.z +=
            cos(position.z + position.y + frameTimeCounter * DF_SPEED) * strength;
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

in vec2 uv_atlas;
in vec2 uv_lightmap;
in vec3 pos_sc;
in vec4 vcol;
in mat3 tbn_vs;

uniform sampler2D gtexture; // atlas
uniform sampler2D specular;
uniform sampler2D normals;

uniform sampler2D shadowtex1;

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

// =========

/* RENDERTARGETS: 1,2,3,4,5,6 */
layout(location = 0) out vec4 col1;
layout(location = 1) out vec4 col2;
layout(location = 2) out vec4 col3;
layout(location = 3) out vec4 col4;
layout(location = 4) out uint col5;
layout(location = 5) out uint col6;

void main()
{
    #if !defined PIXELATE

        // Write.
        col3.r = gl_FragCoord.z;
        col4.r = gl_FragCoord.z;

    #else

        vec2 texel_offset = texel_offset(uv_atlas, textureSize(gtexture, 0));

        vec2 uv_lightmap = texel_snap(uv_lightmap, texel_offset);
        vec3 pos_sc = texel_snap(pos_sc, texel_offset);
        vec4 vcol = texel_snap(vcol, texel_offset);



        // Write.
        col3.r = gl_FragCoord.z;
        col3.gba = mul3(gMV, pos_sc);
        col4 = col3;

    #endif



    if (gl_HelperInvocation) return;



    vec4 albedo = vcol;

    #if defined MAP_ALBEDO

        albedo *= texture(gtexture, uv_atlas);

    #endif



    if (albedo.a < 0.1) {discard; return;}



    #if defined G_ENTITIES

        albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);

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



    #if !defined MAP_SPECULAR

        #define INELEGANT ;

    #else

        #define INELEGANT |

        vec4 specular_map = textureLod(specular, uv_atlas, 0.0);

        float is_emissive = fract(specular_map.a);
        float is_metal = step(0.9, specular_map.g);

        #if defined G_HAND && defined LIGHTS_HAND

            is_emissive = 0.0;

        #endif

    #endif



    float dither = noise_r2(gl_FragCoord.xy) * 0.99; // 0.99, fix fireflies when packing

    vec3 normal_sc = (mat3(gMVInv) * normal_vs) * 0.5 + 0.5;



    uint data =
    uint(normal_sc.x * 63.0 + 0.501) << 26u | // 6
    uint(normal_sc.y * 63.0 + 0.501) << 20u | // 6
    uint(normal_sc.z * 63.0 + 0.501) << 14u | // 6

    uint(uv_lightmap.x * 31.0 + dither) << 9u | // 5
    uint(uv_lightmap.y * 31.0 + dither) << 4u INELEGANT // 5

    #if defined MAP_SPECULAR

    uint(is_emissive * 7.0 + dither) << 1u | // 3
    uint(is_metal); // 1; uint(is_metal * 1.0 + dither) << 0u;

    #endif



    // radiance
    float light = dot(normal_vs, u_shadowLightDirection) * 0.6 + 0.4;
//     light *= uv_lightmap.y; // NOTE: Should be applied to the ambient term.



    #if defined MAP_SHADOW
    #if !defined NETHER

        // [mateuskreuch] https://github.com/mateuskreuch/minecraft-miniature-shader
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
//             && light > 0.401
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



    // Write.
//     col1 = vec4(1, 0, 0, 1); // debug
    col1 = vec4(albedo.rgb, light);
    col2 = vec4(0., 0., 0., 1.); // curse entitites
    col5 = data;
    col6 = data;
}

#endif
