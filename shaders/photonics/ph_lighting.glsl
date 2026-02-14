#file "/photonics/ph_lighting.glsl"
#create

#include "/programme/_lib/version.glsl"

#include "/programme/_lib/uniforms.glsl"
#include "/programme/_lib/math.glsl"
#include "/shader.h"

uniform sampler2D colortex3; // depth.r, pos_vs_pixelated.gba (opaque)
uniform usampler2D colortex5; // data.r (opaque)

// =========

#include "/photonics/photonics.glsl"
#include "/photonics/shader_interface.glsl"

// =========



/* ... */
layout(location = 0) out vec4 out_position;
layout(location = 1) out vec4 out_normal;
layout(location = 2) out vec4 out_direct;
layout(location = 3) out vec4 out_direct_soft;
layout(location = 4) out vec4 out_handheld;

void main(void)
{
    // Initialize values.
//     out_position = vec4(0.0);
//     out_normal = vec4(0.0);
    out_direct = vec4(0.0);
//     out_direct_soft = vec4(0.0);
    out_handheld = vec4(1.0, 0.0, 0.0, 0.0);



    ivec2 texel = ivec2(gl_FragCoord);

    vec4 c3 = texelFetch(colortex3, texel, 0);
    if (c3.r > 0.99999) return;

    uint c5 = texelFetch(colortex5, texel, 0).r;
    float dither_col = noise_r2(gl_FragCoord.xy) * 0.004 - 0.002;



    #if defined PIXELATE

        vec3 pos_ws = c3.gba;

    #else

        vec3 pos_ws = vec3(gl_FragCoord.xy * u_viewResolution.zw, c3.r);
        pos_ws = unproj3(gProjInv, pos_ws * 2.0 - 1.0);

    #endif

    vec3 normal_sc = vec3(uvec3(c5) >> uvec3(26u, 20u, 14u) & 63u);
    normal_sc = normal_sc / 63.0 * 2.0 - 1.0;

    pos_ws = mul3(gMVInv, pos_ws) + cameraPosition;
    pos_ws = pos_ws - normal_sc * 0.01 - world_offset; // photonics.glsl



    RayJob ray = RayJob(vec3(0), vec3(0), vec3(0), vec3(0), vec3(0), false);
    RAY_ITERATION_COUNT = 20; // from ph_raytracing.glsl
    {
        vec4 lights = vec4(0., 0., 0., 0.001); // .w = total_lights

        // lights direct
        int light_offset = load_light_offset(pos_ws); // ph_core.glsl
        int light_count = light_registry_array[light_offset];

        for (; lights.w < light_count; ++lights.w)
        {
            int idx = light_registry_array[int(lights.w) + light_offset + 1];
            Light light = load_light(idx); // ph_core.glsl



            ray.origin = pos_ws + normal_sc * 0.02;

            vec3 to_light = light.position - ray.origin;
            float dist_sqr = dot(to_light, to_light);

            ray.direction = to_light * inversesqrt(dist_sqr);

            float lightmap_x = sqrt_fast(dist_sqr) / light.attenuation.x;
            if (lightmap_x > 1.0) continue;

            lightmap_x = 1.0 - lightmap_x;
            lightmap_x *= lightmap_x; // square it as in every gbuffer
            lightmap_x *= max(6.0, light.attenuation.x) * (1.0 / 15.0); // max = 15.0

            light.color *= lightmap_x;

            if (floor(light.position) == floor(pos_ws))
            {
                lights.rgb += light.color;
                continue;
            }

            if (dot(ray.direction, normal_sc) < 0.01) continue;

            light.color *= dot(normal_sc, ray.direction) * 0.5 + 0.5; // cos_theta

            ray_target = ivec3(light.position); // from ph_raytracing.glsl
            trace_ray(ray); // from ph_raytracing.glsl

            if (!ray.result_hit)
            {
                lights.rgb += light.color;
                continue;
            }

            if (floor(light.position) != floor(ray.result_position)) continue;

            lights.rgb += light.color;
        }



        // Write.
        out_direct = lights;
        out_direct.rgb += dither_col;
    }



#if defined MAP_SHADOW

//     RAY_ITERATION_COUNT = 100;
    {
        ray.origin = pos_ws + normal_sc * 0.02;
        ray.direction = mat3(gMVInv) * u_shadowLightDirection;

        trace_ray(ray);



        // Write.
        out_direct.a = float(!ray.result_hit);
        out_direct.a += dither_col;
    }

#endif



#if defined LIGHTS_HAND

//     RAY_ITERATION_COUNT = 100;
    if (max(heldBlockLightValue, heldBlockLightValue2) > 0)
    {
        float shadow = 1.0;

        vec4 dir_vert = direction_transformation_matrix_in * vec4(left_handed ? 1.0 : -1.0, -1.0, 0.0, 1.0);
        dir_vert.xyz *= 1.0 / dir_vert.w;



        ray.origin = dir_vert.xyz + eyePosition - world_offset;

        vec3 to_light = pos_ws - ray.origin;
        float dist_sqr = dot(to_light, to_light);

        ray.direction = to_light * inversesqrt(dist_sqr);

        // NOTE: Same distance as in `d1_shading.glsl`.
        if (dist_sqr < 64.0)
        {
            trace_ray(ray);

            to_light = pos_ws - ray.result_position;
            dist_sqr = dot(to_light, to_light);

            shadow = clamp((dist_sqr - 0.25) * -4.0, 0.0, 1.0);
            shadow *= dot(normal_sc, -ray.direction) * 0.5 + 0.5; // cos_theta
        }



        // Write.
        out_handheld.r = shadow;
        out_handheld.r += dither_col;
    }

#endif
}
