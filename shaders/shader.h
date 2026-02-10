/*
    colortex0 | RGBA8 | 50% resolution
[rgb][3x8] sky.rgb
[a] Image format does not have rgb8.

    colortex1 (opaque) | RGBA8
[rgb][3x8] albedo.rgb -> final.rgb
[a][1x8] diffuse.a

    colortex2 (translucent) | RGBA8
[rgb][3x8] albedo.rgb
[a][1x8] alpha.a

    colortex3 (opaque) & colortex4 (translucent) | RGBA32F
[r][1x32F] depth.r
[gba][3x32F] pos_vs_pixelated.gba

    colortex5 (opaque) & colortex6 (translucent) | R32UI
[r][666] normals.xyz
[r][5] uv_lightmap.x
[r][5] uv_lightmap.y
[r][3] is_emissive
[r][1] is_metal

    colortex7 (opaque) | RGB8 | 50% resolution
[r][8] ao
[g][8] shadows
[b][8] pixel_age

    colortex9 | RGBA8 | 50% resolution
[rgb][3x8] reflections.rgb
[a][8] reflections_mask

    colortex10 | R11F_G11F_B10F | 50% resolution
[rgb][] coloured_lights.rgb

    colortex11 | RGB8
[rgb][3x8] final_prev.rgb
*/

#if defined G_FINAL

/*
const int colortex0Format = RGBA8;
const int colortex1Format = RGBA8;
const int colortex2Format = RGBA8;
const int colortex3Format = RGBA32F;
const int colortex4Format = RGBA32F;
const int colortex5Format = R32UI;
const int colortex6Format = R32UI;
const int colortex7Format = RGB8;
const int colortex8Format = RGB8;
const int colortex9Format = RGBA16F;
const int colortex10Format = R11F_G11F_B10F;
const int colortex11Format = RGB8;

const bool colortex7Clear = false;
const bool colortex8Clear = false;
const bool colortex9Clear = false;
const bool colortex10Clear = false;
const bool colortex11Clear = false;

// const vec4 colortex0ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex1ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex2ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const vec4 colortex3ClearColor = vec4(1.0, 0.0, 0.0, 0.0);
const vec4 colortex4ClearColor = vec4(1.0, 0.0, 0.0, 0.0);
const vec4 colortex5ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex6ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
*/

#endif

// =========

// NOTE: I am lazy...
#define gMV gbufferModelView
#define gMVInv gbufferModelViewInverse
#define gPrevMV gbufferPreviousModelView
#define gProj gbufferProjection
#define gProjInv gbufferProjectionInverse
#define gPrevProj gbufferPreviousProjection

#define sProj shadowProjection
#define sProjInv shadowProjectionInverse
#define sMV shadowModelView
#define sMVInv shadowModelViewInverse

#define mMV modelViewMatrix
#define mMVInv modelViewMatrixInverse
#define mProj projectionMatrix
#define mProjInv projectionMatrixInverse
#define mNor normalMatrix

// =========

// ID's; 16-bit [-32768, 32767]; <file>.properties
#define i_LIGHTNING_BOLT    1
#define i_WATER             2
#define i_WATER_CAULDRON    3
#define i_WIND              100
#define i_EMISSION          200
#define i_METALLIC          300

// =========

// [Textures]
#define MAP_ALBEDO
#define MAP_SPECULAR

// #define MAP_NORMAL
#define MAP_NORMAL_WATER

#define MAP_SHADOW
    const int shadowMapResolution = 256; // [256 512 1024 2048 4096]
    const float shadowDistance = 32.0; // [16.0 32.0 48.0 64.0 80.0 96.0]
    const float shadowDistanceRenderMul = 1.0;
    const float sunPathRotation = -30.0; // [-90.0 -30.0 -10.0 0.0 10.0 30.0 90.0]

// [Shader]
    // ambient
#define AO_VANILLA 0 // [0 1]
    const float ambientOcclusionLevel = AO_VANILLA;

#define SS_AO
    #define SS_AO_RES 0.5 // [0.25 0.5 1.0]
    #define SS_AO_DIRS 1 // [1 2 3 4]
    #define SS_AO_ITERS 8 // [4 8 12 16]
    #define SS_AO_ACCUM
    #define SS_AO_MODE 1 // [0 1] 0=ssao, 1=gtao

#define SS_GI
    // #define SS_GI_RES SS_AO_RES
    // #define SS_GI_DIRS SS_AO_DIRS
    // #define SS_GI_ITERS SS_AO_ITERS
    // #define SS_GI_ACCUM SS_AO_ACCUM
    // #define SS_GI_MODE SS_AO_MODE
    #define SS_GI_MODE 1 // [0 1] 0=project 1=raymarch

    // shadows
#define SS_SHADOWS
    // #define SS_SHADOWS_RES SS_AO_RES
    #define SS_SHADOWS_ITERS 12 // [4 8 12 16]
    // #define SS_SHADOWS_ACCUM SS_AO_ACCUM

#define CLOUDS_SHADOWS

    // lights
#define LIGHTS_HAND
    #define LIGHTS_HAND_COLOURED
#define LIGHTS_COLOURED
    #define LIGHTS_COLOURED_RES 0.5 // [0.25 0.5 1.0]

    // reflections
#define SS_R
    #define SS_R_RES 1.0 // [0.25 0.5 1.0]
    #define SS_R_ITERS 12 // [4 8 12 16]
    #define SS_R_MODE 1 // [0 1] 0=project, 1=raymarch
    // #define SS_R_NOISE

    // environment
#define FOG_BORDER
#define FOG_HEIGHT
#define FOG_WATER
#define FOG_CLOUDS
    #define CLOUDS_RENDER_DISTANCE 2048.0 // [32.0 64.0 128.0 256.0 512.0 1024.0 2048.0]



// [Miscellaneous]
#define DIS_FOLLIAGE
#define DIS_WATER

#define PIXELATE

// #define TAA



// [Debug]
// #define DEBUG
    #define DEBUG_MODE -1 // [-1 0 10 11 30 31 50 51 52 53 54 55 70 71 72 80 90 91 100 110]

// #define WHITE_WORLD

#define RENDER_OPAQUE
#define RENDER_TRANSLUCENT
#define RENDER_OPAQUE_VX
#define RENDER_TRANSLUCENT_VX

#define RENDER_CLOUDS fancy // [off fast fancy]
#define RENDER_BEACON_BEAMS

// =========

// TODO: Remove this. Custom uniform?
#if defined VOXY && \
(defined RENDER_OPAQUE_VX || defined RENDER_TRANSLUCENT_VX)

    #define vxFar float(vxRenderDistance)

#else

    #if defined VOXY
        #undef VOXY
    #endif

    #if defined vxFar
        #undef vxFar
    #endif

    #define vxFar far // always

#endif

// =========

// Decoys for parser.
#ifdef DEBUG
#endif



#ifdef MAP_ALBEDO
#endif
#ifdef MAP_SPECULAR
#endif
#ifdef MAP_NORMAL
#endif
#ifdef MAP_NORMAL_WATER
#endif
#ifdef MAP_SHADOW
#endif

#ifdef AO_VANILLA
#endif
#ifdef SS_AO
#endif
    #ifdef SS_AO_RES
    #endif
    #ifdef SS_AO_DIRS
    #endif
    #ifdef SS_AO_ITERS
    #endif
    #ifdef SS_AO_ACCUM
    #endif
    #ifdef SS_AO_MODE
    #endif
#ifdef SS_GI
#endif
    #ifdef SS_GI_MODE
    #endif

#ifdef CLOUDS_SHADOWS
#endif
#ifdef SS_SHADOWS
#endif
    #ifdef SS_SHADOWS_ITERS
    #endif

#ifdef LIGHTS_COLOURED
#endif
    #ifdef LIGHTS_COLOURED_RES
    #endif
#ifdef LIGHTS_HAND
#endif
    #ifdef LIGHTS_HAND_COLOURED
    #endif

#ifdef SS_R
#endif
    #ifdef SS_R_RES
    #endif
    #ifdef SS_R_ITERS
    #endif
    #ifdef SS_R_MODE
    #endif
    #ifdef SS_R_NOISE
    #endif

#ifdef FOG_BORDER
#endif
#ifdef FOG_HEIGHT
#endif
#ifdef FOG_WATER
#endif
#ifdef FOG_CLOUDS
#endif
    #ifdef CLOUDS_RENDER_DISTANCE
    #endif

#ifdef DIS_FOLLIAGE
#endif
#ifdef DIS_WATER
#endif
#ifdef PIXELATE
#endif
#ifdef TAA
#endif

#ifdef DEBUG
#endif
    #ifdef DEBUG_MODE
    #endif

#ifdef WHITE_WORLD
#endif
#ifdef RENDER_OPAQUE
#endif
#ifdef RENDER_TRANSLUCENT
#endif
#ifdef RENDER_OPAQUE_VX
#endif
#ifdef RENDER_TRANSLUCENT_VX
#endif
#ifdef RENDER_CLOUDS
#endif
#ifdef RENDER_BEACON_BEAMS
#endif

