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
uniform sampler2D cloudtex; // clouds.png

uniform sampler2D colortex0; // sky.rgb
uniform sampler2D colortex1; // albedo.rgb (opaque) -> final.rgb
uniform sampler2D colortex3; // depth.r, pos_vs_pixelated.gba (opaque)
uniform usampler2D colortex5; // data.r (opaque)
uniform sampler2D colortex7; // ao.r, shadows.g, pixel_age.b
uniform sampler2D colortex8; // gi.rgb
uniform sampler2D colortex10; // coloured_lights.rgb (previous)

uniform sampler2D radiosity_direct; // photonics
uniform sampler2D radiosity_handheld;

const bool colortex1MipmapEnabled = true;

// =========

#include "/programme/_lib/lights_colours.glsl"

// =========

vec3 noise_wh(vec2 p)
{
    // [] https://www.shadertoy.com/view/cl2GRm
    // White noise.
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.333);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

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



/* RENDERTARGETS: 1 */
layout(location = 0) out vec3 col1;

void main()
{
    // Initialize values.
//     col1 = vec3(0.0);



    ivec2 texel = ivec2(gl_FragCoord);

    vec3 c0 = textureLod(colortex0, uv, 0.0).rgb;
    vec4 c1 = textureLod(colortex1, uv, 0.0);
    float c3 = texelFetch(colortex3, texel, 0).r;



    if (c3 == 1.0) // is_sky
    {
        vec3 c_stars = vec3(0.0);

        #if defined OVERWORLD || defined END

            // [Builderb0y] https://github.com/Builderb0y
            // Stars.
            // Modified.
            #define STARS_SIZE 64.0
            #define STARS_AMOUNT 0.1 // [0, 1]
            #define STARS_INTENSITY 0.3

            #if defined END

                #define STARS_SIZE 96.0
                #define STARS_INTENSITY 0.15

            #endif

            vec3 pos_ws;
            pos_ws = unproj3(gProjInv, vec3(uv * 2.0 - 1.0, 0.0));
            pos_ws = pos_ws * inversesqrt(dot(pos_ws, pos_ws)); // normalize
            pos_ws = mat3(gMVInv) * pos_ws;

            vec3 pos_stars[2] = vec3[2]
            (
                vec3(
                    atan(pos_ws.z, pos_ws.x) * 0.318310, // x/pi+0.5
                    pos_ws.y * 0.5, // x/2+0.5
                    pos_ws.y
                ),
                vec3(
                    atan(pos_ws.z, pos_ws.y) * 0.318310,
                    pos_ws.x * 0.5,
                    pos_ws.x
                )
            );

            for (int i = 0; i < 2; ++i)
            {
                vec3 co = pos_stars[i];
                co.xy *= vec2(STARS_SIZE * 1.31, STARS_SIZE);

                vec3 dither = noise_wh(floor(co.xy));

                co.xy = fract(co.xy) - mix(dither.xy, vec2(0.5), dither.z); // offset

                float n = dither.x * 6.283185; // angle
                co.xy = vec2( // rotate around the z-axis
                    co.x * cos(n) - sin(n) * co.y,
                    co.x * sin(n) + cos(n) * co.y
                );

                co.xy *= co.xy; // square

                float mask;
                mask = 1.0 - clamp(dot(co.xy, co.xy) / (dither.z * 0.001), 0.0, 1.0); // star
                mask *= clamp((0.7 - abs(co.z)) * 3.333, 0.0, 1.0); // borders
                mask *= float(dither.z < STARS_AMOUNT) * STARS_INTENSITY;
                mask *= 1.0 - skyColor.b; // is_night

                vec3 col;
                col = vec3(0.6, 0.8, 1.0); // .25 .5 1.
                col *= (dither.z / STARS_AMOUNT) * 9.0 - 8.0;
                col = exp2(col) * mask;

                c_stars += col;
            }

        #endif



        // Write.
        col1 = c0 + c1.rgb + c_stars;
        return;
    }



    uint c5 = texelFetch(colortex5, texel, 0).r;

    vec2 c7 = vec2(1.0); // ao
    vec3 c8 = vec3(0.0); // gi
    vec3 c10 = vec3(1.0, 0.8, 0.6); // lights



    vec3 pos_vs = unproj3(gProjInv, vec3(uv, c3) * 2.0 - 1.0);
    vec3 pos_sc = mul3(gMVInv, pos_vs);

    vec2 uv_lightmap = vec2((uvec2(c5) >> uvec2(9u, 4u)) & uvec2(31u)) / 31.0;
    float is_emissive = float((c5 >> 1u) & 7u) / 7.0;



    #if (defined SS_AO || (defined SS_GI && SS_GI_MODE == 0)) && defined SS_SHADOWS

        // TODO: Upscale?
        c7 = textureLod(colortex7, uv, 0.0).rg;

    #elif defined SS_SHADOWS

        c7.g = textureLod(colortex7, uv, 0.0).g;

    #endif



    #if defined SS_GI && SS_GI_MODE == 1

        c8 = textureLod(colortex8, uv, 0.0).rgb;

    #elif defined SS_GI && SS_GI_MODE == 0

        {
            // Fast Global Illumination.
//             float gi_mip = max(0.167, (pos_vs.z + vxFar) / vxFar) * 6.0;
            float gi_mip = max(0.167, (pos_vs.z + 192.0) * 0.005208) * 6.0; // 12 chunks

            vec3 normal_vs = vec3((uvec3(c5) >> uvec3(26u, 20u, 14u)) & uvec3(63u));
            normal_vs = mat3(gMV) * (normal_vs / 63.0 * 2.0 - 1.0);

            vec2 uv_slope = proj3(gProj, pos_vs + normal_vs * 0.5).xy * 0.5 + 0.5;

            vec4 gi_albedo = textureLod(colortex1, uv_slope, gi_mip);

            // albedo * diffuse * (1 - ao)
            c8 = gi_albedo.rgb * (1.0 - c7.r);
            c8 *= u_lightColor.rgb * gi_albedo.a;
            c8 = c8 * 9.0; // pow(c8, vec3(1.2)) * 9.0
            c8 = c8 / (c8 + 1.0);
        }

    #endif



    #if defined MAP_SHADOW
    #if !defined NETHER && defined PHOTONICS_ENABLED

        float fade = dot(pos_sc, pos_sc) / (far * far);
        float depth = textureLod(radiosity_direct, uv, 0.0).a;

        c7.g *= mix(depth, 1.0, min(1.0, fade));

    #endif
    #endif



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
        c7.g *= 1.0 - texture(cloudtex, uv_clouds).r;

    #endif



    #if defined LIGHTS_COLOURED

        {
            // NOTE: We cannot debug this here. Use the "final" programme.
            vec2 uv_prev = get_prev_screen(pos_sc);

            c10 = textureLod(colortex10, uv_prev, 0.0).rgb + vec3(1e-5, 8e-6, 6e-6);
            c10 *= inversesqrt(dot(c10, c10)) * uv_lightmap.x; // normalize()

            #if defined PHOTONICS_ENABLED

                // NOTE: Currently copper lights are not supported.
                float fac = linearstep(far * 0.5, far, sqrt_fast(dot(pos_sc, pos_sc)));
                vec3 col = textureLod(radiosity_direct, uv, 0.0).rgb;

                c10 = mix(col, c10, fac);

            #endif
        }

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

        #if defined PHOTONICS_ENABLED

            light_len = textureLod(radiosity_handheld, uv, 0.0).r;

            light_hand.r *= light_len;
            light_hand2.r *= light_len;

        #endif

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

    #if AO_VANILLA < 1 && defined SS_AO && defined SS_GI

        c7.r = c7.r * 1.3 - 0.3;

    #endif

    #if defined NETHER

        // TODO: Justify a "sun", `b0_skybox.glsl`.
        vec3 u_lightColor = vec3(0.8, 0.7, 0.6);
        vec3 skyColor = vec3(1.0);
        uv_lightmap.y = 1.0;

    #endif

    #if defined END

        // TODO: Justify a "sun", `b0_skybox.glsl`.
        vec3 u_lightColor = vec3(0.75, 0.7, 0.8);
        vec3 skyColor = vec3(1.0);
        uv_lightmap.y = 1.0;

    #endif

    vec3 shading;

    // ambient
    shading = fogColor * mix(10.0, 1.0, skyColor.b) * AMBIENT_STRENGTH;

    // light
    float light = c1.a * c7.g * uv_lightmap.y;

    shading += u_lightColor.rgb * (light * DIFFUSE_STRENGTH);
    shading += c8.rgb; // gi

    // lights
    shading += (c10.rgb + light_hand + light_hand2)
    * (LIGHTS_STRENGTH - light * skyColor.b);

    // finalize
    #if defined WHITE_WORLD

        shading = mix(shading * c7.r, vec3(EMISSIVE_STRENGTH) * c1.rgb, is_emissive);

    #else

        shading = mix(shading * c7.r, vec3(EMISSIVE_STRENGTH), is_emissive); // ao
        shading *= c1.rgb; // albedo

    #endif



    #if defined FOG_BORDER || defined FOG_HEIGHT

        float fog = 0.0;
        float pos_len = sqrt_fast(dot(pos_sc, pos_sc)); // length()



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

            float dither = texture(noisetex, uv_dither).r;
//             dither = 0.4 + 0.6 * dither; // mix()

            height *= dither;

            fog = max(fog, height);

        #endif



        // Write.
        shading = mix(shading, c0, fog); // sky

    #endif



    #if defined DEBUG && DEBUG_MODE == 80 && SS_GI_MODE == 0

        shading = c8.rgb;

    #endif



    // Write.
    col1 = shading;
}

#endif
