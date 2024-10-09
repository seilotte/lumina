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

#ifdef DH_VCOL_NOISE

out vec3 pos_scene;

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



    stencil     = 0.0f;
    uv_lightmap = vec2(gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    pos_view    = gl_Position.xyz;
    normal      = mat3(gl_NormalMatrix) * gl_Normal.xyz;
    vcol        = gl_Color;



    #ifdef REF

        if (dhMaterialId == DH_BLOCK_METAL) stencil = s_METALLIC;

    #endif



    #ifdef MAP_SPECULAR

        if (dhMaterialId == DH_BLOCK_ILLUMINATED) stencil = s_EMISSIVE;

    #endif



    #ifdef DH_VCOL_NOISE

        pos_scene =
        mat3(gbufferModelViewInverse) * gl_Position.xyz + gbufferModelViewInverse[3].xyz;

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

uniform int renderStage;
uniform float far;

// ===

#ifdef DH_VCOL_NOISE

in vec3 pos_scene;

uniform int dhRenderDistance;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;

uniform sampler2D noisetex;

#endif



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



    #ifndef RENDER_TERRAIN

        if (
            !gl_FrontFacing ||
            dither > gl_FragCoord.z / gl_FragCoord.w
        ) {discard; return;}

    #else

        if (
            !gl_FrontFacing ||
            dither > linearstep(pos_length, far * 0.8f, far)
        ) {discard; return;}

    #endif



    #ifdef VCOL

        col0 = vcol;

    #else

        col0 = vec4(0.5f, 0.5f, 0.5f, 1.0f);

    #endif



    #ifdef DH_VCOL_NOISE

        // [sixthsurge] https://github.com/sixthsurge/photon
        // Modified.
        mat3 tbn;
        // view -> scene
        tbn[2] = mat3(gbufferModelViewInverse) * normal + gbufferModelViewInverse[3].xyz;
        tbn[0] = normalize(cross(tbn[2], vec3(0.0f, 1.0f, 1.0f)));
        tbn[1] = normalize(cross(tbn[2], tbn[0]));

        // world -> "normal" space
        vec3 pos_world = tbn * (pos_scene + cameraPosition);

        float hash = texture(noisetex, pos_world.xy * DH_VCOL_NOISE_SIZE).r;
        hash *= 1.0f - pos_length / float(dhRenderDistance); // distance_fade

        col0.rgb *= hash * 0.1f + 0.9f;

    #endif



    // WRITE: c_final.rgb
//     col0 = col0;

    // WRITE: normals.rg, uv_lightmap.b, stencil.a
    col5 = vec4(
        encode_normal(normal) * 0.5f + 0.5f,
        packUnorm2x4(uv_lightmap, dither),
        stencil
    );
}

#endif
