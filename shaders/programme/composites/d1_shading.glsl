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
uniform sampler2D depthtex0;

uniform sampler2D colortex0; // albedo.rgb, diffuse.a
uniform sampler2D colortex9; // sky.rgb
uniform sampler2D colortex8; // coloured_lights.rgb
uniform usampler2D colortex7; // data.r
uniform sampler2D colortex5; // ao.r, shadows.g, pixel_age.b
// uniform sampler2D colortex4; // gi.rgb

const bool colortex0MipmapEnabled = true;

// =========

#include "/programme/_lib/lights_colours.glsl"

// =========

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



/* RENDERTARGETS: 0,9 */
layout(location = 0) out vec3 col0;
layout(location = 1) out vec3 col9;

void main()
{
    ivec2 texel = ivec2(gl_FragCoord);

    vec4 c0 = texelFetch(colortex0, texel, 0);
    uint c7 = texelFetch(colortex7, texel, 0).r;

    // TODO: Avoid writing to the sky colortexN.
    // Determine how to use the fog colour when clearing the texture.
    col0 = isEyeInWater > 1 ? fogColor : c0.rgb;
    col9 = isEyeInWater > 1 ? fogColor : texelFetch(colortex9, texel, 0).rgb;

    if (c7 < 1u) return; // is_sky

    vec3 c8 = vec3(1.0, 0.8, 0.6);
    vec2 c5 = vec2(1.0);
    vec3 c4 = vec3(0.0);



    vec3 pos_ss = vec3(uv, texelFetch(depthtex0, texel, 0).r); // ss
    vec3 pos_vs = unproj3(gProjInv, pos_ss * 2.0 - vec3(1.0, 1.0, 1.00000048));
    vec3 pos_ft = mul3(gMVInv, pos_vs);

    vec2 uv_lightmap;
    uv_lightmap.x = float((c7 >> 9u) & 31u) / 31.0;
    uv_lightmap.y = float((c7 >> 4u) & 31u) / 31.0;
    float is_emissive = float((c7 >> 1u) & 7u) / 7.0;



    #if defined LIGHTS_COLOURED

        // NOTE: We cannot debug this here. Use the "final" programme.
        vec2 uv_prev = get_prev_screen(pos_ft);

        c8 = texture(colortex8, uv_prev).rgb + vec3(1e-5, 8e-6, 6e-6);
        c8 = c8 * inversesqrt(dot(c8, c8)); // normalize()

    #endif

    #if defined SS_AO || defined SS_SHADOWS || defined SS_GI

        // TODO: Upscale?
//         c5 = texelFetch(colortex5, ivec2(uv * textureSize(colortex5, 0)), 0).rg;
        c5 = texelFetch(colortex5, ivec2(uv * u_viewResolution.xy * SS_AO_RES), 0).rg;

    #endif

    #if defined SS_GI

//         c4 = texelFetch(colortex4, ivec2(uv * textureSize(colortex4, 0)), 0).rgb;

        {
//             float gi_mip = max(0.167, (pos_vs.z + vxFar) / vxFar) * 6.0;
            float gi_mip = max(0.167, (pos_vs.z + 192.0) * 0.005208) * 6.0; // 12 chunks

            // [rj200] https://github.com/rj200/Glamarye_Fast_Effects_for_ReShade
            // Sample the texture a little bit in the normal direction.
            vec2 slope = vec2(dFdx(pos_ss.z), dFdy(pos_ss.z));
            slope *= rsqrt_fast(dot(slope, slope)) * 0.02;

            vec4 gi_albedo = textureLod(colortex0, uv + slope, gi_mip);

            // albedo * diffuse * (1 - ao)
            c4 = gi_albedo.rgb * (1.0 - c5.r);
            c4 *= u_lightColor.rgb * gi_albedo.a;
            c4 = /*pow(c4, vec3(1.2)) * 9.0*/ c4 * 9.0;
            c4 = c4 / (c4 + 1.0);
        }

    #endif



    #if defined CLOUDS_SHADOWS

        // [null511] https://github.com/Null-MC
        // [fayer3]
        // Cloud Shadows.
        // Modified.
        vec2 uv_clouds = pos_ft.xz;
//         vec2 uv_clouds = mul3(gMV, pos_vs + u_shadowLightDirection * cloudHeight).xz;

        // 3072.0 is one full cloud cycle
        uv_clouds = mod(pos_ft.xz, vec2(3072.0)) + cameraPosition.xz;
//         uv = mod(uv, vec2(3072.0)) + vec2(cameraPositionInt.xz) + cameraPositionFract.xz; // better

        uv_clouds += vec2(mod(cloudTime, 3072.0), 4.0); // 4.0 = magic_value_offset
        uv_clouds /= 3072.0;

        // TODO: Cloud texture interpolation, linear.
        c5.g *= 1.0 - texture(cloudtex, uv_clouds).r * uv_lightmap.y * 0.6;

    #endif



    vec3 light_hand = vec3(0.0);
    vec3 light_hand2 = vec3(0.0);

    #if defined LIGHTS_HAND

        vec3 pos_hand = (pos_ft + cameraPosition) - eyePosition;
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

    #if AO_VANILLA < 1 && defined SS_AO && defined SS_GI

        c5.r = c5.r * 1.3 - 0.3;

    #endif



    vec3 shading;

    // ambient
    shading = fogColor * mix(10.0, 1.0, skyColor.b) * AMBIENT_STRENGTH;

    // light
    float light = c0.a * c5.g * uv_lightmap.y;

    shading += u_lightColor.rgb * (light * DIFFUSE_STRENGTH);
    shading += c4.rgb; // gi

    // lights
    shading += (c8.rgb * uv_lightmap.x + light_hand + light_hand2)
    * (LIGHTS_STRENGTH - light * skyColor.b);

    // finalize
    #if !defined WHITE_WORLD

        shading = mix(shading * c5.r, vec3(EMISSIVE_STRENGTH), is_emissive); // ao
        shading *= c0.rgb; // albedo

    #else

        shading = mix(shading * c5.r, vec3(EMISSIVE_STRENGTH) * c0.rgb, is_emissive);

    #endif



/*
    if (uv.x < 0.5)
    {
        // Correct version.
//         vec3 ambient = c5.r * u_skyColor * u_fogColor * AMBIENT_STRENGTH;
        vec3 ambient = c5.r * fogColor * mix(10.0, 1.0, skyColor.b) * AMBIENT_STRENGTH;

        vec3 light = u_lightColor.rgb;
        light *= c0.a * c5.g * uv_lightmap.y * DIFFUSE_STRENGTH; // diffuse * shadows

        light = c0.rgb * light + c0.rgb * c4.rgb; // diffuse + gi

        vec3 lights = c8.rgb; // col
        lights *= uv_lightmap.x * (LIGHTS_STRENGTH - skyColor.b);

        shading = mix(ambient + light + lights, c0.rgb, is_emissive);
    }
//*/



//*
    #if defined FOG_BORDER || defined FOG_HEIGHT

        float fog = 0.0;
        float pos_len = sqrt_fast(dot(pos_ft, pos_ft)); // length()



        #if defined FOG_BORDER

            // NOTE: Make sure in Voxy, "Enable vanilla fog" is enabled.
            float fog_start = isEyeInWater > 0 ? fogStart : 16.0;
            float fog_end = isEyeInWater > 0 ? min(fogEnd, vxFar) : vxFar;

            fog = linearstep(fog_start, fog_end, pos_len); // 1 chunk = 16
            fog = fog * fog;

        #endif



        #if defined FOG_HEIGHT

            vec3 pos_ws = pos_ft + cameraPosition;

            float height = abs(pos_ws.y - 63.0); // sea level = 63
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
        shading = mix(shading, col9, fog); // sky

    #endif
//*/



    #if defined DEBUG && DEBUG_MODE == 40

        shading = c4.rgb;

    #endif



    // Write.
    col0 = shading;
}

#endif
