#include "/programme/_lib/version.glsl"

#include "/programme/_lib/uniforms.glsl"
#include "/programme/_lib/math.glsl"
#include "/shader.h"

#ifdef VSH

in vec3 vaPosition;

out vec2 uv_ndc;

// =========



void main()
{
    uv_ndc = vaPosition.xy * 2.0 - 1.0;



    gl_Position = vec4(uv_ndc, 0.0, 1.0);
//     gl_Position.xy = gl_Position.xy * 0.25 - gl_Position.w * 0.75; // x*res + x*(res-1)
}

#endif



/*
 * #########
 */



#ifdef FSH

in vec2 uv_ndc;

uniform sampler2D noisetex;

// =========

vec3 normalize_fast(vec3 v)
{
    return v * inversesqrt(dot(v, v));
//     return v * rsqrt_fast(dot(v, v));
}

// =========



/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 col0;

void main()
{
    // Initialize values.
//     col0 = vec4(0.0);


    vec3 albedo = vec3(0.0);
    vec3 pos_ws = mat3(gMVInv) * normalize_fast(unproj3(gProjInv, vec3(uv_ndc, 0.0)));

    {
        // sky gradient
        albedo = mix(fogColor, skyColor, pos_ws.y);



        #if defined OVERWORLD

            // sunrise & sunset
            vec3 sun_dir = mat3(gMVInv) * (sunPosition * 0.01);
            vec3 sun_dir90z = vec3(sun_dir.y, -sun_dir.x, -sun_dir.z); // rotate around the z-axis by 90°

            float light_mask = u_lightColor.a // is_sunrise_sunset
            * (dot(pos_ws, sun_dir) * 0.25 + 0.5) // stronger on the sun side
            * (1.0 - abs(dot(pos_ws + vec3(0.0, 0.25, 0.0), sun_dir90z))); // horizon mask

            albedo = mix(albedo, u_lightColor.rgb, light_mask);

        #endif



        // dither; x * 1.0/bit_range - 0.5/bit_range
//         albedo += noise_r2(gl_FragCoord.xy) * 0.004 - 0.002;

        float dither = texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 63, 0).r;
        dither = fract(dither + float(frameCounter) * 1.618034);

        albedo += dither * 0.006 - 0.003;
    }



    // NOTE: Due to clouds, stars must be applied after fog.
    // Moved to: `d1_shading.glsl`



    // Write.
    col0 = vec4(albedo, 1.0);
}

#endif
