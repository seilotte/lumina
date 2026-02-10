#include "/programme/_lib/version.glsl"

#include "/programme/_lib/uniforms.glsl"
#include "/programme/_lib/math.glsl"
#include "/shader.h"

#ifdef VSH

in vec3 vaPosition;

out vec2 uv;

// =========



void main()
{
    uv = vaPosition.xy;



    gl_Position = vec4(vaPosition.xy * 2.0 - 1.0, 0.0, 1.0);
}

#endif



/*
 * #########
 */



#ifdef FSH

in vec2 uv;

uniform sampler2D noisetex;

uniform sampler2D colortex0; // sky.rgb
uniform sampler2D colortex1; // albedo.rgb (opaque) -> final.rgb
uniform sampler2D colortex2; // albedo.rgb (translucent)
uniform sampler2D colortex3; // depth.r, pos_vs_pixelated.gba (opaque)
uniform sampler2D colortex4; // depth.r, pos_vs_pixelated.gba (translucent)
uniform usampler2D colortex5; // data.r (opaque)
uniform usampler2D colortex6; // data.r (translucent)
uniform sampler2D colortex7; // ao.r, shadows.g, pixel_age.b
uniform sampler2D colortex8; // gi.rgb
uniform sampler2D colortex9; // reflections.rgb, reflections_mask.a
uniform sampler2D colortex10; // coloured_lights.rgb
uniform sampler2D colortex11; // final_prev.rgb

// const bool colortex9MipmapEnabled = true;



#if defined DEBUG

struct s_Data
{
    vec3 normal_sc;
    vec2 uv_lightmap;
    float is_emissive;
    float is_metal;
};

#endif

// =========

#if defined DEBUG

#include "/programme/_lib/text_rendering.glsl"

#define custom_text(SIDE, TEXT0, IDX, IDX_COL, CHANNELS) \
{ \
    begin_text( \
        ivec2(uv * vec2(210.0) * vec2(aspectRatio, 1.0)), \
        ivec2( vec2(210.0 * 0.01 + 210.0 * 0.5 * SIDE, 210.0 * 0.2) * vec2(aspectRatio, 1.0) ) \
    ); \
    \
    if (TEXT0 != _space) print(TEXT0); \
    \
    if (SIDE > 0) \
    { \
        text.fg_col.rgb = vec3(0.8); \
        print((_space,_open_bracket,_t,_r,_a,_n,_s,_l,_u,_c,_e,_n,_t,_close_bracket)); \
    } \
    \
    print_line(); \
    text.fg_col.rgb = vec3(0.8); print(IDX); \
    text.fg_col.rgb = vec3(1,1,0); print((_space,_c,_o,_l,_o,_r,_t,_e,_x)); print(IDX_COL); \
    text.fg_col.rgb = vec3(0.8); print((_dot)); \
    \
    uint[] channels = uint[] CHANNELS; \
    for (int i = 0; i < channels.length(); ++i) \
    { \
        if      (channels[i] == _r) text.fg_col.rgb = vec3(1,0,0); \
        else if (channels[i] == _g) text.fg_col.rgb = vec3(0,1,0); \
        else if (channels[i] == _b) text.fg_col.rgb = vec3(0,0,1); \
        else                        text.fg_col.rgb = vec3( 0.8 ); \
        \
        print_char(channels[i]); \
    } \
    \
    end_text(debug); \
}

#endif

// =========




/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 debug;

void main()
{
    // Initialize values.
//     debug = vec3(0.0);



    ivec2 texel = ivec2(gl_FragCoord);

    // Write.
    // NOTE: This programme is required
    // to write back to the *main* buffer.
    debug = textureLod(colortex1, uv, 0.0).rgb;



    #if 0

        // Grain.
        #define GRAIN_FAC vec3(0.03, 0.15, 0.15)

        mat3 rgb_to_yiq = mat3(
            0.299f,  0.5959f,  0.2115f,
            0.587f, -0.2746f, -0.5227f,
            0.114f, -0.3213f,  0.3112f
        );

        mat3 yiq_to_rgb = mat3(
            1.0f,   1.0f,     1.0f,
            0.956f, -0.272f, -1.106f,
            0.619f, -0.647f,  1.703f
        );

        vec3 dither;
        dither.x = texelFetch(noisetex, texel/2 & 63, 0).r;
        dither.y = texelFetch(noisetex, texel/2 + 17 & 63, 0).r;
        dither.z = texelFetch(noisetex, texel/2 + 31 & 63, 0).r;

        dither = fract(dither + frameTimeCounter * 1.618034);

        // overlay()
        vec3 A = rgb_to_yiq * debug;
        vec3 B = (dither * 2.0 - 1.0) * GRAIN_FAC + 0.5;

        A.r = A.r < 0.5 ? 2.0 * A.r * B.r : 1.0 - (2.0 * (1.0 - A.r) * (1.0 - B.r));
        A.g = A.g < 0.5 ? 2.0 * A.g * B.g : 1.0 - (2.0 * (1.0 - A.g) * (1.0 - B.g));
        A.b = A.b < 0.5 ? 2.0 * A.b * B.b : 1.0 - (2.0 * (1.0 - A.b) * (1.0 - B.b));

        debug = yiq_to_rgb * A;

    #endif



    #if defined DEBUG

        #define L * ivec2(2, 1)
        #define R * ivec2(2, 1) - ivec2(u_viewResolution.x, 0)

        vec4 c0 = texelFetch(colortex0, texel / 2, 0);
        vec4 c1 = texelFetch(colortex1, texel L, 0);
             c1 += texelFetch(colortex2, texel R, 0);
        vec4 c3 = texelFetch(colortex3, texel L, 0);
             c3 += texelFetch(colortex4, texel R, 0);
        uint c5 = texelFetch(colortex5, texel L, 0).r;
             c5 += texelFetch(colortex6, texel R, 0).r;
        vec4 c7 = texelFetch(colortex7, ivec2(uv * textureSize(colortex7, 0)), 0);
        vec4 c8 = texelFetch(colortex8, ivec2(uv * textureSize(colortex8, 0)), 0);
        vec4 c9 = texelFetch(colortex9, ivec2(uv * textureSize(colortex9, 0)), 0);
        vec4 c10 = texelFetch(colortex10, ivec2(uv * textureSize(colortex10, 0)), 0);
        vec4 c11 = texelFetch(colortex11, texel, 0);



        s_Data data;

        data.normal_sc.x = float((c5 >> 26u) & 63u) / 63.0;
        data.normal_sc.y = float((c5 >> 20u) & 63u) / 63.0;
        data.normal_sc.z = float((c5 >> 14u) & 63u) / 63.0;
        data.normal_sc = data.normal_sc * 2.0 - 1.0;

        data.uv_lightmap.x = float((c5 >> 9u) & 31u) / 31.0;
        data.uv_lightmap.y = float((c5 >> 4u) & 31u) / 31.0;

        data.is_emissive = float((c5 >> 1u) & 7u) / 7.0;
        data.is_metal = float(c5 & 1u); // float((c5 >> 0u) & 1u) / 1.0;



        // Write.
        debug = vec3(uv, 0);



//*
        #if DEBUG_MODE == 0

            debug = c0.rgb;
            custom_text(0, (_S,_k,_y), (_space,_space,_0), (_0), (_r,_g,_b))

        #elif DEBUG_MODE == 10

            debug = c1.rgb;
//             debug = c2.rgb; // translucent
            custom_text(0, (_F,_i,_n,_a,_l), (_space,_1,_0), (_1), (_r,_g,_b))
            custom_text(1, (_F,_i,_n,_a,_l), (_space,_1,_0), (_2), (_r,_g,_b))

        #elif DEBUG_MODE == 11

            debug = c1.aaa;
//             debug = c2.aaa; // translucent
            custom_text(0, (_D,_i,_f,_f,_u,_s,_e), (_space,_1,_1), (_1), (_a))
            custom_text(1, (_A,_l,_p,_h,_a), (_space,_1,_1), (_2), (_a))

        #elif DEBUG_MODE == 30

            debug = vec3(near / ((1.0 - c3.r) * vxFar)); // depth with voxy
//             debug = vec3(near / ((1.0 - c4.r) * vxFar); // translucent
            custom_text(0, (_D,_e,_p,_t,_h), (_space,_3,_0), (_3), (_r))
            custom_text(1, (_D,_e,_p,_t,_h), (_space,_3,_0), (_4), (_r))

        #elif DEBUG_MODE == 31

            debug = c3.gba;
//             debug = c4.gba; // translucent
            custom_text(0, (_P,_o,_s,_underscore,_v,_s,_space,_P,_i,_x,_e,_l,_a,_t,_e,_d), (_space,_3,_1), (_3), (_g,_b,_a))
            custom_text(1, (_P,_o,_s,_underscore,_v,_s,_space,_P,_i,_x,_e,_l,_a,_t,_e,_d), (_space,_3,_1), (_4), (_g,_b,_a))

        #elif DEBUG_MODE == 50

            debug = c5.rrr;
//             debug = c6.rrr; // translucent
            custom_text(0, (_D,_a,_t,_a), (_space,_5,_0), (_5), (_r))
            custom_text(1, (_D,_a,_t,_a), (_space,_5,_0), (_6), (_r))

        #elif DEBUG_MODE == 51

            debug = data.normal_sc;
            custom_text(0, (_N,_o,_r,_m,_a,_l,_underscore,_s,_c), (_space,_5,_1), (_5), (_r))
            custom_text(1, (_N,_o,_r,_m,_a,_l,_underscore,_s,_c), (_space,_5,_1), (_6), (_r))

        #elif DEBUG_MODE == 52

            debug = vec3(data.uv_lightmap.x);
            custom_text(0, (_L,_i,_g,_h,_t,_m,_a,_p,_underscore,_x), (_space,_5,_2), (_5), (_r))
            custom_text(1, (_L,_i,_g,_h,_t,_m,_a,_p,_underscore,_x), (_space,_5,_2), (_6), (_r))

        #elif DEBUG_MODE == 53

            debug = vec3(data.uv_lightmap.y);
            custom_text(0, (_L,_i,_g,_h,_t,_m,_a,_p,_underscore,_y), (_space,_5,_3), (_5), (_r))
            custom_text(1, (_L,_i,_g,_h,_t,_m,_a,_p,_underscore,_y), (_space,_5,_3), (_6), (_r))

        #elif DEBUG_MODE == 54

            debug = vec3(data.is_emissive);
            custom_text(0, (_I,_s,_space,_E,_m,_i,_s,_s,_i,_v,_e), (_space,_5,_4), (_5), (_r))
            custom_text(1, (_I,_s,_space,_E,_m,_i,_s,_s,_i,_v,_e), (_space,_5,_4), (_6), (_r))

        #elif DEBUG_MODE == 55

            debug = vec3(data.is_metal);
            custom_text(0, (_I,_s,_space,_M,_e,_t,_a,_l), (_space,_5,_5), (_5), (_r))
            custom_text(1, (_I,_s,_space,_M,_e,_t,_a,_l), (_space,_5,_5), (_6), (_r))

        #elif DEBUG_MODE == 70

            debug = c7.rrr;
            custom_text(0, (_A,_m,_b,_i,_e,_n,_t,_space,_O,_c,_c,_l,_u,_s,_i,_o,_n), (_space,_7,_0), (_7), (_r))

        #elif DEBUG_MODE == 71

            debug = c7.ggg;
            custom_text(0, (_S,_c,_r,_e,_e,_n,_minus,_S,_p,_a,_c,_e,_space,_S,_h,_a,_d,_o,_w,_s), (_space,_7,_1), (_7), (_g))

        #elif DEBUG_MODE == 72

            debug = c7.bbb * 25.0; // 250/PIXEL_AGE, d0_ao_gi_shadows.glsl
            custom_text(0, (_P,_i,_x,_e,_l,_space,_A,_g,_e), (_space,_7,_2), (_7), (_b))

        #elif DEBUG_MODE == 80

            #if SS_GI_MODE == 1
                debug = c8.rgb;
            #else
                debug = texelFetch(colortex1, texel, 0).rgb; // d1_shading.glsl
            #endif
            custom_text(0, (_G,_l,_o,_b,_a,_l,_space,_I,_l,_l,_u,_m,_i,_n,_a,_t,_i,_o,_n), (_space,_8,_0), (_8), (_r,_g,_b))

        #elif DEBUG_MODE == 90

            debug = c9.rgb;
            custom_text(0, (_R,_e,_f,_l,_e,_c,_t,_i,_o,_n,_s), (_space,_9,_0), (_9), (_r,_g,_b))

        #elif DEBUG_MODE == 91

            debug = c9.aaa;
            custom_text(0, (_R,_e,_f,_l,_e,_c,_t,_i,_o,_n,_s,_space,_M,_a,_s,_k), (_space,_9,_0), (_9), (_a))

        #elif DEBUG_MODE == 100

            debug = c10.rgb;
            custom_text(0, (_C,_o,_l,_o,_u,_r,_e,_d,_space,_L,_i,_g,_h,_t,_s), (_1,_0,_0), (_1,_0), (_r,_g,_b))

        #elif DEBUG_MODE == 110

            debug = c11.rgb;
            custom_text(0, (_F,_i,_n,_a,_l,_space,_P,_r,_e,_v,_i,_o,_u,_s), (_1,_1,_0), (_1,_1), (_a))

        #else

            custom_text(0, (_D,_e,_b,_u,_g,_space,_M,_o,_d,_e), (_space,_minus,_1), (_N), (_n,_n,_n,_n))

        #endif
//*/

    #endif
}

#endif
