/*
const int colortex0Format = RGB8;       // c_final.rgb
const int colortex4Format = RGB8;       // c_sky.rgb
const int colortex5Format = RGBA8;      // normals.rg, uv_lightmap.b, stencil.a
const int colortex6Format = RGB5_A1;    // c_emissivet.rgb, m_emissivet.a
const int colortex7Format = RGBA8;      // ssgi.rgb, ssao.a
const int colortex8Format = RGB8;       // c_lights.rgb
const int colortex9Format = RGB8;       // c_taa.rgb

// c = colour; m = mask; emissivet = emissive_translucents;
// ss = screen space; taa = temporal...
*/

const bool colortex0Clear = false;
const bool colortex4Clear = false;
const bool colortex5Clear = false;
const bool colortex6Clear = false;
const bool colortex7Clear = false;
const bool colortex8Clear = false;
const bool colortex9Clear = false;

// const vec4 colortex0ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
// const vec4 colortex4ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
// const vec4 colortex5ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
// const vec4 colortex6ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
// const vec4 colortex7ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
// const vec4 colortex8ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
// const vec4 colortex9ClearColor = vec4(0.0, 0.0, 0.0, 0.0);

// =========

// Stencil; 8-bits [0-255]
#define s_WATER             0.2     // 051/255
#define s_WATER_CAULDRON    0.202   // 051/255; buffer rounds
#define s_METALLIC          0.6     // 153/255
#define s_EMISSIVE          0.8     // 204/255
#define s_NETHER_PORTAL     0.802   // 204/255; buffer rounds
#define s_LIGHTNING_BOLT    1.0     // 255/255
#define s_BEACONBEAM        1.0     // 255/255
#define s_SKY               1.0     // 255/255

// =========

// #define DEBUG // enables composite99



// [Displacement]
#define DIS_FOLLIAGE
    #define DIS_FOLLIAGE_STRENGTH       0.0002  // [0.0001 0.0002 0.0003]
    #define DIS_FOLLIAGE_SPEED          1.0     // [1.0 2.0 3.0 4.0 5.0]
#define DIS_WATER
    #define DIS_WATER_STRENGTH          0.05    // [0.0125 0.025 0.05]
    #define DIS_WATER_SPEED             2.0     // [1.0 2.0 3.0 4.0 5.0]


// [Textures]
#define MAP_ALBEDO
#define MAP_SPECULAR
#define MAP_NORMAL
#define MAP_NORMAL_WATER
    #define MAP_NORMAL_WATER_STRENGTH   0.01    // [0.01 0.03 0.06 0.09]
    #define MAP_NORMAL_WATER_SPEED      0.05    // [0.025 0.05 0.075 0.1]


// [Material] Albedo.
#define ALBEDO
#define VCOL // vertex_colour
#define DH_VCOL_NOISE
    #define DH_VCOL_NOISE_SIZE          0.0625  // [0.015625 0.03125 0.0625 0.125] 1px 2px 4px 8px

// [Material] Specular.
#define SPECULAR

// [Material] Ambient.
#define AMBIENT
    #define AMBIENT_INTENSITY           0.3     // [0.1 0.2 0.3 0.4 0.5]
#define SS_GI // global_illumination
#define SS_AO // ambient_occlusion
    #define SS_GIAOCL_RESOLUTION        0.499   // [0.25 0.499 0.75 1.0]
    #define SS_GIAOCL_ITERATIONS        4       // [2 4 8 16]
    #define SS_GIAOCL_RADIUS            -500.0  // [-100.0 -200.0 -300.0 -400.0 -500.0]
const float ambientOcclusionLevel =     0.0;    // [0.0 1.0]

// [Material] Diffuse.
#define DIFFUSE
    #define DIFFUSE_INTENSITY           1.0     // [1.0 1.1 1.2 1.3 1.4 1.5]
#define MAP_SHADOW
    #define MAP_SHADOW_PIXEL            0.0     // [0.0 4.0 8.0 16.0 32.0 64.0]
    const int shadowMapResolution =     256;    // [256 512 1024 2048 4096]
    const float shadowDistance =        32.0;   // [16.0 32.0 48.0 64.0 80.0 96.0]
    const float shadowDistanceRenderMul = 1.0;
#define SS_SHADOWS
    #define SS_SHADOWS_ITERATIONS        6      // [2 4 6 8 16]
    #define SS_SHADOWS_STRIDE            8.0    // [2.0 4.0 8.0 16.0]
const float sunPathRotation =            -10.0; // [-90.0 -30.0 -10.0 0.0 10.0 30.0 90.0]

// [Material] Lights.
#define LIGHTS_HAND
#define SS_CL // lights_coloured
    #define LIGHTS_INTENSITY            2.0     // [1.0 1.5 2.0]

// [Material] Reflections.
#define REF
    #define REF_INTENSITY               0.6     // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define REF_WATER
    #define REF_WATER_INTENSITY         0.9     // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]


// [Environment]
#define FOG
    #define FOG_STRENGTH                0.125   // [0.03125 0.0625 0.125 0.25 0.5]
#define FOG_WATER
    #define FOG_WATER_STRENGTH          0.5     // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define CLOUDS                          2       // [0 1 2]
    #define CLOUDS_GRADIENT
//    #define RENDER_CLOUDS_VANILLA

// [Post]
#define TAA // temporal_anti-aliasing
    #define TAA_FAC                     0.1     // [0.1 0.2 0.3 0.4 0.5]
// #define VHS // vhs_filter
    #define VHS_TYPE                    0       // [0 1] 0 = NTSC; 1 = PAL
//    #define VHS_DOWNSCALE

// [Miscellaneous]
#define RENDER_TERRAIN
#define RENDER_BEACON_BEAMS
#define RENDER_DISTANT_HORIZONS

#define TRANSPARENT_WATER_CAULDRON

// =========

// Decoys for parser.
#ifdef DEBUG
#endif

#ifdef DIS_FOLLIAGE
#endif
#ifdef DIS_FOLLIAGE_STRENGTH
#endif
#ifdef DIS_FOLLIAGE_SPEED
#endif
#ifdef DIS_WATER
#endif
#ifdef DIS_WATER_STRENGTH
#endif
#ifdef DIS_WATER_SPEED
#endif
#ifdef MAP_ALBEDO
#endif
#ifdef MAP_SPECULAR
#endif
#ifdef MAP_NORMAL
#endif
#ifdef MAP_NORMAL_WATER
#endif
#ifdef MAP_NORMAL_WATER_STRENGTH
#endif
#ifdef ALBEDO
#endif
#ifdef VCOL
#endif
#ifdef DH_VCOL_NOISE
#endif
#ifdef DH_VCOL_NOISE_PIXELATE
#endif
#ifdef SPECULAR
#endif
#ifdef AMBIENT
#endif
#ifdef AMBIENT_INTENSITY
#endif
#ifdef SS_GI
#endif
#ifdef SS_AO
#endif
#ifdef SS_GIAOCL_RESOLUTION
#endif
#ifdef SS_GIAOCL_ITERATIONS
#endif
#ifdef SS_GIAOCL_RADIUS
#endif
#ifdef DIFFUSE
#endif
#ifdef DIFFUSE_INTENSITY
#endif
#ifdef MAP_SHADOW
#endif
#ifdef MAP_SHADOW_PIXEL
#endif
#ifdef SS_SHADOWS
#endif
#ifdef SS_SHADOWS_ITERATIONS
#endif
#ifdef SS_SHADOWS_STRIDE
#endif
#ifdef LIGHTS_HAND
#endif
#ifdef SS_CL
#endif
#ifdef LIGHTS_INTENSITY
#endif
#ifdef REF
#endif
#ifdef REF_INTENSITY
#endif
#ifdef REF_WATER
#endif
#ifdef REF_WATER_INTENSITY
#endif
#ifdef FOG
#endif
#ifdef FOG_STRENGTH
#endif
#ifdef FOG_WATER
#endif
#ifdef FOG_WATER_STRENGTH
#endif
#ifdef CLOUDS
#endif
#ifdef CLOUDS_GRADIENT
#endif
#ifdef TAA
#endif
#ifdef TAA_FAC
#endif
#ifdef VHS
#endif
#ifdef VHS_TYPE
#endif
#ifdef VHS_DOWNSCALE
#endif
#ifdef RENDER_TERRAIN
#endif
#ifdef RENDER_BEACON_BEAMS
#endif
#ifdef RENDER_DISTANT_HORIZONS
#endif
#ifdef TRANSPARENT_WATER_CAULDRON
#endif
