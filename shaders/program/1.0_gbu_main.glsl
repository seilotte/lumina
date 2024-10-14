#include "/shader.h"
#include "/program/lib/math.glsl"

#ifdef VSH

out float stencil;
out vec2 uv;
out vec2 uv_lightmap;
out vec3 pos_view;
out vec4 vcol;
out mat3 tbn;

in vec2 mc_Entity;
in vec2 vaUV0;
in ivec2 vaUV2;
in vec3 vaNormal;
in vec3 vaPosition;
in vec4 vaColor;

uniform vec3 chunkOffset;
uniform mat3 normalMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

uniform int renderStage;
uniform int entityId;
uniform int isEyeInWater;

// ===

#ifdef DIS_FOLLIAGE

// in vec2 mc_Entity;
in vec4 at_midBlock;

uniform float frameTimeCounter;

#endif


#ifdef DIS_WATER

// in vec2 mc_Entity;

// uniform float frameTimeCounter;
uniform float far;

#endif

/**/
#if defined MAP_NORMAL || defined MAP_NORMAL_WATER

in vec4 at_tangent;

#endif


#ifdef MAP_NORMAL_WATER

out vec3 pos_world;

uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;

#endif

/**/
#ifdef LIGHTS_HAND

uniform int heldBlockLightValue;

#endif



// =========



void main()
{
    if (renderStage < 17) // It might change in future iris updates.
    {
        #include "/program/1.3_opaque.glsl"
    }
    else
    {
        #include "/program/1.7_translucent|material.glsl"
    }
}

#endif



/*
 * #########
 */



#ifdef FSH

in float stencil;
in vec2 uv;
in vec2 uv_lightmap;
in vec3 pos_view;
in vec4 vcol;
in mat3 tbn;

uniform int renderStage;
uniform float far;
uniform vec4 entityColor;

// lighting
uniform float nightVision;
uniform float c_facRain;
uniform float c_isDay;
uniform vec3 c_shadowLightDirection;
uniform vec3 c_colZenith;
uniform vec3 c_colSun;

// ===

#if defined SS_GI || defined SS_CL

uniform sampler2D colortex6; // c_emissivet.rgb, m_emissivet.a

#endif

/**/
#ifdef MAP_ALBEDO

uniform sampler2D gtexture; // atlas

#endif


#ifdef MAP_NORMAL

uniform sampler2D normals;

#endif


#ifdef MAP_NORMAL_WATER

in vec3 pos_world;

uniform float frameTimeCounter;

uniform sampler2D noisetex;

#endif


#ifdef MAP_SPECULAR

uniform sampler2D specular;

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

#define FOG_WATER_DEPTHTEX depthtex1

uniform int isEyeInWater;
uniform vec3 c_colWaterAbsorb;
uniform vec3 c_colWaterScatter;
uniform mat4 gbufferProjection;

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



/* RENDERTARGETS: 0,5 */
layout(location = 0) out vec4 col0; // c_final.rgb
layout(location = 1) out vec4 col5; // normals.rg, uv_lightmap.b, stencil.a
layout(location = 2) out vec4 col6; // c_emissivet.rgb, m_emissivet.a

#if defined SS_GI || defined SS_CL

/* RENDERTARGETS: 0,5,6 */

#endif

void main()
{
    // Initialize values.
    col0 = vec4(.0f);
    col5 = vec4(.0f);

    #if defined SS_GI || defined SS_CL

        col6 = vec4(.0f);

    #endif



    if (renderStage < 17) // It might change in future iris updates.
    {
        #include "/program/1.3_opaque.glsl"
    }
    else
    {
        #include "/program/1.7_translucent|material.glsl"
    }
}

#endif
