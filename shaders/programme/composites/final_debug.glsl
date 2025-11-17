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

uniform sampler2D colortex0; // albedo.rgb (opaque) -> final.rgb, diffuse.a (opaque)
uniform sampler2D colortex9; // sky.rgb
uniform sampler2D colortex8; // coloured_lights.rgb
uniform usampler2D colortex7; // data.r
uniform sampler2D colortex6; // pos_ss_PIXELATEd.rg
uniform sampler2D colortex5; // ao.r, shadows.g, pixel_age.b
// uniform sampler2D colortex4; // gi.rgb
uniform sampler2D colortex3; // reflections.rgb, reflections_mask.a

uniform sampler2D colortex1; // alpha.r (translucent)
uniform sampler2D colortex10; // final.rgb (translucent)
uniform usampler2D colortex17; // data.r (translucent)
uniform sampler2D colortex16; // pos_ss_PIXELATEd.rg (translucent)

// const bool colortex9MipmapEnabled = true;



#if defined DEBUG

struct s_Data
{
    vec3 normal_ft;
    vec2 uv_lightmap;
    float is_emissive;
    float is_metal;
};

#endif

// =========

#if defined DEBUG

#include "/programme/_lib/text_rendering.glsl"

# define custom_text(side, C0, C0_RGBA, C1_IDX, C1_IDX_TEX) \
{ \
    begin_text( \
        texel / 3, \
        ivec2((u_viewResolution.x / 3) * 0.01) + \
        ivec2((u_viewResolution.x / 3) * 0.5 * side, 7 * 4) \
    ); \
    \
    print(C0); \
    if (side > 0) \
    { \
        text.fg_col.rgb = vec3(0.8); \
        print((_space,_open_bracket,_t,_r,_a,_n,_s,_l,_u,_c,_e,_n,_t,_close_bracket)); \
    } \
    \
    print_line(); \
    \
    text.fg_col.rgb = vec3(0.8); print(C1_IDX); \
    text.fg_col.rgb = vec3(1.0, 1.0, 0.0); print((_space,_c,_o,_l,_o,_r,_t,_e,_x)); \
    print(C1_IDX_TEX); \
    text.fg_col.rgb = vec3(0.8); print((_dot)); \
    \
    uint[] channels = uint[] C0_RGBA; \
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
    // NOTE: I do not know why it renders
    // incorrectly without this progamme.
    debug = texelFetch(colortex0, texel, 0).rgb;



    #if defined DEBUG

        #define L * ivec2(2, 1)
        #define R * ivec2(2, 1) - ivec2(u_viewResolution.x, 0)


        vec4 c0 = texelFetch(colortex0, texel L, 0);
        vec4 c9 = texelFetch(colortex9, texel, 0);
        vec4 c8 = texelFetch(colortex8, ivec2(uv * textureSize(colortex8, 0)), 0);
        uint c7 = texelFetch(colortex7, texel L, 0).r;
        vec4 c6 = texelFetch(colortex6, texel L, 0);
        vec4 c5 = texelFetch(colortex5, ivec2(uv * textureSize(colortex5, 0)), 0);
//         vec4 c4 = texelFetch(colortex4, ivec2(uv * textureSize(colortex4, 0)), 0);
        vec4 c3 = texelFetch(colortex3, ivec2(uv * textureSize(colortex3, 0)), 0);

        // TEMPORARY.
        vec4 c1 = texelFetch(colortex1, texel R, 0);
        vec4 c10 = texelFetch(colortex10, texel R, 0);
        uint c17 = texelFetch(colortex17, texel R, 0).r;
        vec4 c16 = texelFetch(colortex16, texel R, 0);

        c0 += c10;
        c7 += c17;
        c6 += c16;



        s_Data data;

        data.normal_ft.x = float((c7 >> 26u) & 63u) / 63.0;
        data.normal_ft.y = float((c7 >> 20u) & 63u) / 63.0;
        data.normal_ft.z = float((c7 >> 14u) & 63u) / 63.0;
        data.normal_ft = data.normal_ft * 2.0 - 1.0;

        data.uv_lightmap.x = float((c7 >> 9u) & 31u) / 31.0;
        data.uv_lightmap.y = float((c7 >> 4u) & 31u) / 31.0;

        data.is_emissive = float((c7 >> 1u) & 7u) / 7.0;
        data.is_metal = float(c7 & 1u); // float((c8 >> 0u) & 1u) / 1.0;



        // Write.
        debug = vec3(uv, 0);



        #if DEBUG_MODE < 0

            custom_text(0, (_D,_e,_b,_u,_g,_space,_M,_o,_d,_e), (_n,_n,_n,_n), (_minus,_1), (_N))

        // ===

        #elif DEBUG_MODE == 0
            debug = c0.rgb; // final.rgb

            custom_text(0, (_F,_i,_n,_a,_l), (_r,_g,_b), (_space,_0), (_0))
            custom_text(1, (_F,_i,_n,_a,_l), (_r,_g,_b), (_space,_0), (_1,_0))

        #elif DEBUG_MODE == 1
//             debug = c0.aaa; // diffuse.a (opaque)
            debug = c1.rrr; // alpha.r (translucent)

            custom_text(0, (_D,_i,_f,_f,_u,_s,_e), (_a), (_space,_1), (_0))
            custom_text(1, (_A,_l,_p,_h,_a), (_r), (_space,_1), (_1))

        // ===

        #elif DEBUG_MODE == 90
            debug = c9.rgb; // sky.rgb

            custom_text(0, (_S,_k,_y), (_r,_g,_b), (_9,_0), (_9))

        // ===

        #elif DEBUG_MODE == 80
            debug = c8.rgb; // coloured_lights.rgb

            custom_text(0, (_C,_o,_l,_o,_u,_r,_e,_d,_space,_L,_i,_g,_h,_t,_s), (_r,_g,_b), (_8,_0), (_8))

        // ===

        #elif DEBUG_MODE == 70
            debug = vec3(c7.r); // data.r

            custom_text(0, (_D,_a,_t,_a), (_r), (_7,_0), (_7))
            custom_text(1, (_D,_a,_t,_a), (_r), (_7,_0), (_7))

        #elif DEBUG_MODE == 71
            debug = data.normal_ft;

            custom_text(0, (_N,_o,_r,_m,_a,_l,_underscore,_f,_t), (_r), (_7,_1), (_7))
            custom_text(1, (_N,_o,_r,_m,_a,_l,_underscore,_f,_t), (_r), (_7,_1), (_7))

        #elif DEBUG_MODE == 72
            debug = vec3(data.uv_lightmap.x);

            custom_text(0, (_L,_i,_g,_h,_t,_m,_a,_p,_underscore,_x), (_r), (_7,_2), (_7))
            custom_text(1, (_L,_i,_g,_h,_t,_m,_a,_p,_underscore,_x), (_r), (_7,_2), (_7))

        #elif DEBUG_MODE == 73
            debug = vec3(data.uv_lightmap.y);

            custom_text(0, (_L,_i,_g,_h,_t,_m,_a,_p,_underscore,_y), (_r), (_7,_3), (_7))
            custom_text(1, (_L,_i,_g,_h,_t,_m,_a,_p,_underscore,_y), (_r), (_7,_3), (_7))

        #elif DEBUG_MODE == 74
            debug = vec3(data.is_emissive);

            custom_text(0, (_I,_s,_space,_E,_m,_i,_s,_s,_i,_v,_e), (_r), (_7,_4), (_7))
            custom_text(1, (_I,_s,_space,_E,_m,_i,_s,_s,_i,_v,_e), (_r), (_7,_4), (_7))

        #elif DEBUG_MODE == 75
            debug = vec3(data.is_metal);

            custom_text(0, (_I,_s,_space,_M,_e,_t,_a,_l), (_r), (_7,_5), (_7))
            custom_text(1, (_I,_s,_space,_M,_e,_t,_a,_l), (_r), (_7,_5), (_7))

        // ===

        #elif DEBUG_MODE == 60
            debug = vec3(near / ((1.0 - c6.r) * vxFar)); // depth with voxy

            custom_text(0, (_D,_e,_p,_t,_h), (_r), (_6,_0), (_6))
            custom_text(1, (_D,_e,_p,_t,_h), (_r), (_6,_0), (_6))

        #elif DEBUG_MODE == 61
            debug = c6.gba; // pos_vs_pixelated.gba

            custom_text(0, (_P,_o,_s,_underscore,_v,_s,_space,_P,_i,_x,_e,_l,_i,_z,_e,_d), (_g,_b,_a), (_6,_1), (_6))
            custom_text(1, (_P,_o,_s,_underscore,_v,_s,_space,_P,_i,_x,_e,_l,_i,_z,_e,_d), (_g,_b,_a), (_6,_1), (_6))

        // ===

        #elif DEBUG_MODE == 50
            debug = c5.rrr; // ao.r

            custom_text(0, (_A,_m,_b,_i,_e,_n,_t,_space,_O,_c,_c,_l,_u,_s,_i,_o,_n), (_r), (_5,_0), (_5))

        #elif DEBUG_MODE == 51
            debug = c5.ggg; // shadows.g

            custom_text(0, (_S,_c,_r,_e,_e,_n,_minus,_S,_p,_a,_c,_e,_space,_S,_h,_a,_d,_o,_w,_s), (_g), (_5,_1), (_5))

        #elif DEBUG_MODE == 52
            debug = c5.bbb * 25.0; // 250/PIXEL_AGE; pixel_age.b

            custom_text(0, (_P,_i,_x,_e,_l,_space,_A,_g,_e), (_b), (_5,_2), (_5))

        // ===

        #elif DEBUG_MODE == 40
//             debug = c4.rgb; // gi.rgb
            debug = texelFetch(colortex0, texel, 0).rgb; // d1_shading.glsl

            custom_text(0, (_G,_l,_o,_b,_a,_l,_space,_I,_l,_l,_u,_m,_i,_n,_a,_t,_i,_o,_n), (_r,_g,_b), (_4,_0), (_4))

        // ===

        #elif DEBUG_MODE == 30
            debug = c3.rgb; // reflections.rgb

            custom_text(0, (_R,_e,_f,_l,_e,_c,_t,_i,_o,_n,_s), (_r,_g,_b), (_3,_0), (_3))

        #elif DEBUG_MODE == 31
            debug = c3.aaa; // reflections_mask.a

            custom_text(0, (_R,_e,_f,_l,_e,_c,_t,_i,_o,_n,_s,_space,_M,_a,_s,_k), (_a), (_3,_1), (_3))

        // ===

        #endif

    #endif
}

#endif
