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
    uv_ndc = vec2(0.0);
    vcol = vaColor.rgb;



    if (renderStage == MC_RENDER_STAGE_STARS)
    {
        gl_Position = proj4(mProj, mul3(mMV, vaPosition));
    }
    else if (renderStage == MC_RENDER_STAGE_SKY && gl_VertexID < 4)
    {
        uv_ndc = positions[gl_VertexID];
        gl_Position = vec4(positions[gl_VertexID], 0.0, 1.0);
    }
    else
    {
        gl_Position = vec4(-10.0); // discard
        return;
    }
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

// =========



/* RENDERTARGETS: 0,9 */
layout(location = 0) out vec4 col0;
layout(location = 1) out vec4 col9;

void main()
{
    vec3 albedo = vcol;

    if (renderStage == MC_RENDER_STAGE_SKY)
    {
        vec3 pos_ws = mat3(gMVInv) * normalize_fast(unproj3(gProjInv, vec3(uv_ndc, 0.0)));



//         #if !defined FOG_WATER
//
//             // 0.6 -> account for water albedo and the alpha value
//             vec3 fogColor = isEyeInWater == 1 ? u_waterColor * 0.6 : fogColor;
//
//         #else
//
//             // 0.5 should be 0.6 * 0.5 (from water fog mix())
//             vec3 fogColor = isEyeInWater == 1 ? u_waterColor * 0.5 : fogColor;
//
//         #endif



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



    // Write.
    col0 = vec4(albedo, 1.0);
    col9 = vec4(albedo, float(renderStage != MC_RENDER_STAGE_STARS));
}

#endif
