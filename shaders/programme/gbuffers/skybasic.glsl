#include "/programme/_lib/version.glsl"

#include "/programme/_lib/uniforms.glsl"
#include "/programme/_lib/math.glsl"
#include "/shader.h"

#ifdef VSH

in vec3 vaPosition;
in vec4 vaColor;

out vec2 uv_ndc;
out vec3 vcol;

// =========

const vec2 positions[4] = vec2[4]
( // quad anti-clockwise
    vec2(-1, -1),
    vec2( 1, -1),
    vec2( 1,  1),
    vec2(-1,  1)
);

// =========



void main()
{
    if (gl_VertexID > 3 || renderStage != MC_RENDER_STAGE_SKY)
    {
        gl_Position = vec4(-10.0); // discard
        return;
    }



    uv_ndc = positions[gl_VertexID];
    vcol = vaColor.rgb;



    gl_Position = vec4(uv_ndc, 0.0, 1.0);



    // NOTE: Stars, do not "downscale" accurately,
    // half resolution is sufficient.
    gl_Position.xy = gl_Position.xy * 0.5 - gl_Position.w * 0.5; // x*res + x*(res-1)
}

#endif



/*
 * #########
 */



#ifdef FSH

in vec2 uv_ndc;
in vec3 vcol;

// =========

vec3 normalize_fast(vec3 v)
{
    return v * inversesqrt(dot(v, v));
//     return v * rsqrt_fast(dot(v, v));
}

vec3 noise_wh(vec2 p)
{
    // [] https://www.shadertoy.com/view/cl2GRm
    // White noise.
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.333);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

// =========



/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 col0;

void main()
{
    if (renderStage != MC_RENDER_STAGE_SKY) {discard; return;}



    vec3 albedo = vcol;
    vec3 pos_ws = mat3(gMVInv) * normalize_fast(unproj3(gProjInv, vec3(uv_ndc, 0.0)));

    {
        // sky gradient
        albedo = mix(fogColor, skyColor, pos_ws.y);

        // sunrise & sunset
        vec3 sun_dir = mat3(gMVInv) * (sunPosition * 0.01);
        vec3 sun_dir90z = vec3(sun_dir.y, -sun_dir.x, -sun_dir.z); // rotate around the z-axis by 90°

        float light_mask = u_lightColor.a // is_sunrise_sunset
        * (dot(pos_ws, sun_dir) * 0.25 + 0.5) // stronger on the sun side
        * (1.0 - abs(dot(pos_ws + vec3(0.0, 0.25, 0.0), sun_dir90z))); // horizon mask

        albedo = mix(albedo, u_lightColor.rgb, light_mask);

        // dither; x * 1.0/bit_range - 0.5/bit_range
        albedo += noise_r2(gl_FragCoord.xy) * 0.004 - 0.002;
    }

    {
        // [Builderb0y] https://github.com/Builderb0y
        // Stars.
        // Modified.
        #define STARS_SIZE 96.0
        #define STARS_AMOUNT 0.1 // [0, 1]
        #define STARS_INTENSITY 0.3

        vec3 col_stars = vec3(0.0);

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

            col_stars += col;
        }

        albedo += col_stars;
    }



    // Write.
    col0 = vec4(albedo, 1.0);
}

#endif
