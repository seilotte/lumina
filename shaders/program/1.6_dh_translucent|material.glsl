#include "/shader.h"
#include "/program/lib/math.glsl"

#ifdef VSH_DH

out float stencil;
out vec2 uv_lightmap;
out vec3 pos_view;
out vec3 normal;
out vec4 vcol;

// uniform int dhMaterialId; // automatically declared
uniform mat4 dhProjection;

// ===

#ifdef MAP_NORMAL_WATER

out vec3 pos_world;

uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;

#endif



// =========



void main()
{
    #ifndef RENDER_DISTANT_HORIZONS

        return;

    #endif



    // vertex -> local -> view
    gl_Position.xyz =
    mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;

    // align to vanilla
    gl_Position.y -= dhMaterialId == DH_BLOCK_WATER ? 0.1125f : 0.0f;



    stencil     = 0.0f;
    uv_lightmap = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    pos_view    = gl_Position.xyz;
    normal      = mat3(gl_NormalMatrix) * gl_Normal.xyz;
    vcol        = gl_Color;



    #if defined REF_WATER || defined MAP_NORMAL_WATER

        if (dhMaterialId == DH_BLOCK_WATER) stencil = s_WATER;

    #endif



    #ifdef MAP_NORMAL_WATER

        pos_world =
        mat3(gbufferModelViewInverse) * gl_Position.xyz + gbufferModelViewInverse[3].xyz + cameraPosition;

    #endif



    #ifdef REF

        if (dhMaterialId == DH_BLOCK_METAL) stencil = s_METALLIC;

    #endif



    #ifdef MAP_SPECULAR

        if (dhMaterialId == DH_BLOCK_ILLUMINATED) stencil = s_EMISSIVE;

    #endif



    // view -> ndc
    gl_Position = vec4(
        dhProjection[0].x * gl_Position.x,
        dhProjection[1].y * gl_Position.y,
        dhProjection[2].z * gl_Position.z + dhProjection[3].z,
        -gl_Position.z
    );
}

#endif



/*
 * #########
 */



#ifdef FSH_DH

in float stencil;
in vec2 uv_lightmap;
in vec3 pos_view;
in vec3 normal;
in vec4 vcol;

uniform float far;
uniform float dhNearPlane;
uniform float dhFarPlane;
uniform float near;
uniform float c_farPlane;

uniform sampler2D depthtex0;

// lighting
uniform float nightVision;
uniform float c_facRain;
uniform float c_isDay;
uniform vec3 c_shadowLightDirection;
uniform vec3 c_colZenith;
uniform vec3 c_colSun;

// ===

#ifdef MAP_NORMAL_WATER

in vec3 pos_world;

uniform float frameTimeCounter;

uniform sampler2D noisetex;

#endif

/**/
#ifdef SS_CL

uniform sampler2D colortex8; // c_lights.rgb

#endif

/**/
#if defined FOG_WATER || defined FOG

uniform sampler2D colortex4; // c_sky.rgb

#endif


#ifdef FOG_WATER

#define FOG_WATER_DEPTHTEX dhDepthTex1

uniform int isEyeInWater;
uniform vec3 c_colWaterAbsorb;
uniform vec3 c_colWaterScatter;
uniform mat4 dhProjection;

uniform sampler2D FOG_WATER_DEPTHTEX;
// uniform sampler2D colortex4; // c_sky.rgb
uniform sampler2D colortex5; // normals.rg, uv_lightmap.b, stencil.a

#endif


#ifdef FOG

// uniform float far;
uniform mat4 gbufferProjectionInverse;

// uniform sampler2D colortex4; // c_sky.rgb

#if defined DISTANT_HORIZONS && defined RENDER_DISTANT_HORIZONS

uniform int dhRenderDistance;
uniform mat4 dhProjectionInverse;

#endif
#endif



// =========



float linearize_depth(float depth, float near, float far)
{
    // [Kneemund/Niemand] https://shaderlabs.org/wiki/Shader_Tricks
    return (near * far) / (depth * (near - far) + far);
//     return (2.0 * near) / (far + near - depth * (far - near));
}



// =========



/* RENDERTARGETS: 0,5 */
layout(location = 0) out vec4 col0; // c_final.rgb
layout(location = 1) out vec4 col5; // normals.rg, uv_lightmap.b, stencil.a

void main()
{
    #ifndef RENDER_DISTANT_HORIZONS

        discard; return;

    #endif



    // Initialize values.
//     col0 = vec4(.0f);
//     col5 = vec4(.0f);

    float dither = noise_r2(gl_FragCoord.xy) * 0.99f; // .99 -> fix fireflies
    float pos_length = length_fast(pos_view); // fog & dh
    vec3 normal = normal;



    #ifndef RENDER_TERRAIN

        if (
            !gl_FrontFacing ||
            dither > gl_FragCoord.z / gl_FragCoord.w
        ) {discard; return;}

    #else

        // [sixthsurge] https://github.com/sixthsurge/photon
        // Modified.
        float z_mc = texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).r;

        float z_mc_linear = linearize_depth(z_mc, near, c_farPlane);
        float z_dh_linear = linearize_depth(gl_FragCoord.z, dhNearPlane, dhFarPlane);

        if (
            !gl_FrontFacing ||
            dither > linearstep(pos_length, far * 0.8f, far) ||
            (z_mc_linear < z_dh_linear && z_mc < 1.0f)
        ) {discard; return;}

    #endif



    #ifdef VCOL

        col0 = vcol;

    #else

        col0 = vec4(0.5f, 0.5f, 0.5f, 1.0f);

    #endif



    #ifdef MAP_NORMAL_WATER

        if (stencil == s_WATER)
        {
            vec2 uv0 = pos_world.xz * 0.0625f; // size
            vec2 uv1 = pos_world.xz * 0.125f;
            uv0.x -= frameTimeCounter * MAP_NORMAL_WATER_SPEED;
            uv1.x += frameTimeCounter * MAP_NORMAL_WATER_SPEED;

            // NOTE: This is not the correct way to combine normal maps.
            vec3 normal_map;
            normal_map.xy = texture(noisetex, uv0).ba * 2.0f - 1.0f;
            normal_map.xy += texture(noisetex, uv1).ba * 2.0f - 1.0f;
            normal_map.xy *= MAP_NORMAL_WATER_STRENGTH;

            normal_map.z = sqrt_fast(1.0f - dot(normal_map.xy, normal_map.xy));

            mat3 tbn;
            tbn[2] = normal;
            tbn[0] = normalize(dFdx(pos_view));
            tbn[1] = normalize(dFdy(pos_view));

            normal = normalize(tbn * normal_map);
        }

    #endif



    float NoL = dot(normal, c_shadowLightDirection) * 0.5f + 0.5f;
    float shadows = 1.0f;

    // Needs: shader.h, vec3 col0, float NoL, float shadows,
    //        float nightVision, float c_isDay, float c_facRain,
    //        vec2 uv_lightmap, vec3 c_colZenith, vec3 c_colSun,
    //        sampler2D colortex8, sampler2D colortex7 (deferred)
    #include "/program/lib/do_lighting().glsl"



    // Needs: ... Open the file.
    #ifdef FOG_WATER

        float z = gl_FragCoord.z;
        mat4 gProj = dhProjection;

    #endif

    #include "/program/lib/do_fog().glsl"



    // WRITE: c_final.rgb
//     col0 = vcol;

    // WRITE: normals.rg, uv_lightmap.b, stencil.a
    col5 = vec4(
        encode_normal(normal) * 0.5f + 0.5f,
        packUnorm2x4(uv_lightmap, dither),
        stencil
    );
}

#endif
