#include "/programme/_lib/version.glsl"

#include "/programme/_lib/uniforms.glsl"
#include "/programme/_lib/math.glsl"
#include "/shader.h"

in vec2 uv;

// uniform sampler2D noisetex;

uniform sampler2D colortex3; // depth.r, pos_vs_pixelated.gba (opaque)
uniform usampler2D colortex5; // data.r (opaque)

// =========

#include "/photonics/photonics.glsl"

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
    out_handheld = vec4(0.0);



    ivec2 texel = ivec2(gl_FragCoord);

    vec4 c3 = texelFetch(colortex3, texel, 0);
    if (c3.r > 0.99999) return;

    uint c5 = texelFetch(colortex5, texel, 0).r;



    float dither_col = noise_r2(gl_FragCoord.xy) * 0.004 - 0.002;
//     vec3 dither_shadow = vec3(0.0); // kogan spiral or tetrahedron; 111, -1-11, -11-1, 1-1-1



    #if defined PIXELATE

        vec3 pos_ws = c3.gba;

    #else

        vec3 pos_ws = vec3(uv, c3.r);
        pos_ws = unproj3(gProjInv, pos_ws * 2.0 - 1.0);

    #endif

    vec3 normal_sc = vec3(uvec3(c5) >> uvec3(26u, 20u, 14u) & 63u);
    normal_sc = normal_sc / 63.0 * 2.0 - 1.0;

    pos_ws = mul3(gMVInv, pos_ws) + cameraPosition;
    pos_ws = pos_ws - normal_sc * 0.01 - world_offset; // photonics.glsl



    RayJob ray = RayJob(vec3(0), vec3(0), vec3(0), vec3(0), vec3(0), false);
    ray.origin = pos_ws + normal_sc * 0.02;

    RAY_ITERATION_COUNT = 20; // from ph_raytracing.glsl



    {
        // lights direct
        vec3 lights = vec3(0.0);

        int light_offset = load_light_offset(pos_ws); // ph_core.glsl
        int light_count = light_registry_array[light_offset];

//         ray.origin = pos_ws + normal_sc * 0.02;

        for (int i = 0; i < light_count; ++i)
        {
            int idx = light_registry_array[i + light_offset + 1];
            Light light = load_light(idx); // ph_core.glsl

            // TODO: Make penumbra light dependant.
//             light.position += dither_shadow;

            vec3 to_light = light.position - ray.origin;
            float dist_sqr = dot(to_light, to_light);

            ray.direction = to_light * inversesqrt(dist_sqr);

            float lightmap_x = sqrt_fast(dist_sqr) * light.attenuation.y; // 1/radius
            if (lightmap_x > 1.0) continue;

            lightmap_x = 1.0 - lightmap_x;
            lightmap_x *= 2.0 / (light.attenuation.y * 15.0);
            lightmap_x *= lightmap_x; // square it as in every gbuffer

            float cos_theta = dot(normal_sc, ray.direction) * 0.6 + 0.4;
            if (cos_theta < 0.001) continue;

            ray_target = ivec3(light.position); // from ph_raytracing.glsl
            trace_ray(ray, true); // from ph_raytracing.glsl

            if (ivec3(light.position) != ivec3(ray.result_position)) light.color = vec3(0.0);

            lights += light.color * result_tint_color * (lightmap_x * cos_theta);
        }

        lights = lights / (lights + 1.0); // prevent clipping

        ray_target = ivec3(-9999); // from ph_raytracing.glsl



        // Write.
        out_direct.rgb = lights;
        out_direct.rgb += dither_col;
    }



#if defined MAP_SHADOW

    {
//         ray.origin = pos_ws + normal_sc * 0.02;
        ray.direction = mat3(gMVInv) * u_shadowLightDirection;

        trace_ray(ray, false);



        // Write.
        out_direct.a = float(!ray.result_hit);
        out_direct.a += dither_col;
    }

#endif



#if defined LIGHTS_HAND

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
        if (dist_sqr < 225.0)
        {
            trace_ray(ray, false);

            to_light = pos_ws - ray.result_position;
            dist_sqr = dot(to_light, to_light);

            shadow = clamp((dist_sqr - 0.25) * -4.0, 0.0, 1.0);
            shadow *= dot(normal_sc, -ray.direction) * 0.6 + 0.4; // cos_theta
        }



        // Write.
        out_handheld.r = shadow;
        out_handheld.r += dither_col;
    }

#endif



/*
#if 1

    // Temporal Accumulation.
    vec2 uv_prev;
    {
        vec3 ws = pos_ws + normal_sc * 0.01 + world_offset;
        vec4 vs = previous_modelview_projection * vec4(ws, 1.0);

        uv_prev = (vs.xy / vs.ww) * 0.5 + 0.5;
    }

    vec4 prev_col = textureLod(prev_radiosity_direct, uv_prev, 0.0);
    vec3 prev_pos = textureLod(prev_radiosity_position, uv_prev, 0.0).rgb;
    vec3 prev_nor = textureLod(prev_radiosity_normal, uv_prev, 0.0).rgb;

    vec3 d = prev_pos - pos_ws - world_offset;

    float weight = 0.9;
    weight *= float(uv_prev == clamp(uv_prev, 0.0, 1.0));
    weight *= float(dot(d, d) < 0.1);
    weight *= float(dot(normal_sc, prev_nor) > 0.9);



    // Write.
    out_direct = mix(out_direct, prev_col, weight);
    out_direct.rgb += dither_col;
//     out_direct.rgb = vec3(weight); // debug

    out_position = vec4(pos_ws + world_offset, 0.0);
    out_normal = vec4(normal_sc, 0.0);

#endif
//*/
}
