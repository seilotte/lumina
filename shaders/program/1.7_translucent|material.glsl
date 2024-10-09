#ifdef VSH

// {
    #ifndef RENDER_TERRAIN

        return;

    #endif



    // vertex -> local -> view
    gl_Position.xyz =
    mat3(modelViewMatrix) * (vaPosition + chunkOffset) + modelViewMatrix[3].xyz;



    stencil         = 0.0f;
    uv              = vaUV0;
    uv_lightmap     = vaUV2 * 0.004167f;
    pos_view        = gl_Position.xyz;
    vcol            = vaColor;
    tbn[2]          = normalMatrix * vaNormal;



    uv_lightmap.x *= uv_lightmap.x; // There is no point in doing it later.

    if (
        mc_Entity.x == 2 && isEyeInWater == 1 && // water & in_water
        abs(vaNormal.y) > 0.99
    ) tbn[2].y *= -1.0f; // NoL fix

    else if (
        renderStage == MC_RENDER_STAGE_RAIN_SNOW ||
        renderStage == MC_RENDER_STAGE_PARTICLES
    ) tbn[2].z = 1.0f;



    #if defined SS_GI || defined SS_CL

        if (mc_Entity.x == 4) stencil = s_NETHER_PORTAL;

    #endif



    #if defined DIS_WATER || defined REF_WATER || defined MAP_NORMAL_WATER

        if (mc_Entity.x == 2)
        {
            #ifdef DIS_WATER

                float mask_dis =
                linearstep(length_fast(gl_Position.xyz), far * 0.9f, far * 0.8f);

                gl_Position.y +=
                cos(gl_Position.x + gl_Position.y + frameTimeCounter * DIS_WATER_SPEED) * DIS_WATER_STRENGTH * mask_dis;

            #endif

            #if defined REF_WATER || defined MAP_NORMAL_WATER

                stencil = s_WATER;

            #endif

            #ifdef MAP_NORMAL_WATER

                pos_world =
                mat3(gbufferModelViewInverse) * pos_view + gbufferModelViewInverse[3].xyz + cameraPosition;

            #endif
        }

    #endif



    #if defined MAP_NORMAL || defined MAP_NORMAL_WATER

        tbn[0] = normalize(normalMatrix * at_tangent.xyz);
        tbn[1] = normalize(cross(
            tbn[0],
            tbn[2] * (at_tangent.w < 0.0f ? -1.0f : 1.0f)
        ));

    #endif



    #ifdef LIGHTS_HAND

        if (
            renderStage == MC_RENDER_STAGE_HAND_SOLID &&
            heldBlockLightValue > 0
        ) stencil = s_EMISSIVE;

        uv_lightmap.x = max(
            uv_lightmap.x,
            (float(heldBlockLightValue) - length_fast(gl_Position.xyz)) * 0.06f
        );

    #endif



    // view -> ndc
    gl_Position = vec4(
        projectionMatrix[0].x * gl_Position.x,
        projectionMatrix[1].y * gl_Position.y,
        projectionMatrix[2].z * gl_Position.z + projectionMatrix[3].z,
        -gl_Position.z
    );
// }

#endif



/*
 * #########
 */



#ifdef FSH

// {
    #ifndef RENDER_TERRAIN

        discard; return;

    #endif



    // Initialize values.
    float dither = noise_r2(gl_FragCoord.xy) * 0.99f; // .99 -> fix fireflies
    float pos_length = length_fast(pos_view); // fog & dh

    float stencil = stencil;
    vec3 normal = tbn[2];



    #ifdef MAP_ALBEDO

        col0 = texture(gtexture, uv);

    #else

        col0 = vec4(0.5f);

    #endif



    if (col0.a < 0.1f) {discard; return;}

    #if defined DISTANT_HORIZONS && defined RENDER_DISTANT_HORIZONS

        if (
            dither < linearstep(pos_length, far * 0.9f, far)
        ) {discard; return;}

    #endif



    #ifdef VCOL

        col0 *= vcol;

    #endif



    #if defined SS_GI || defined SS_CL

        if (stencil == s_NETHER_PORTAL)
        {
            // WRITE: c_emissivet.rgb, m_emissivet.a
            col6 = vec4(col0.rgb, 1.0f);
        }

    #endif



    #ifdef MAP_NORMAL

        if (
            renderStage != MC_RENDER_STAGE_RAIN_SNOW &&
            renderStage != MC_RENDER_STAGE_PARTICLES
        )
        {
            vec3 normal_map;
            normal_map.xy = texture(normals, uv).rg * 2.0f - 1.0f;
            normal_map.z = sqrt_fast(1.0f - dot(normal_map.xy, normal_map.xy));

            normal = tbn * normal_map;
        }

    #endif

    #ifdef MAP_NORMAL_WATER

        if (stencil == s_WATER)
        {
            vec2 uv0 = pos_world.xz * 0.0625f; // size
            vec2 uv1 = pos_world.xz * 0.125f;
            uv0.x -= frameTimeCounter * MAP_NORMAL_WATER_SPEED;
            uv1.x += frameTimeCounter * MAP_NORMAL_WATER_SPEED;

            // NOTE: This is not the correct way to combine normal maps.
            // Watch: https://www.youtube.com/watch?v=S9sz00l3FqQ
            vec3 normal_map;
            normal_map.xy = texture(noisetex, uv0).ba * 2.0f - 1.0f;
            normal_map.xy += texture(noisetex, uv1).ba * 2.0f - 1.0f;
            normal_map.xy *= MAP_NORMAL_WATER_STRENGTH;

            normal_map.z = sqrt_fast(1.0f - dot(normal_map.xy, normal_map.xy));

            normal = normalize(tbn * normal_map);
        }

    #endif



    #ifdef MAP_SPECULAR

        if (
            renderStage != MC_RENDER_STAGE_RAIN_SNOW &&
            renderStage != MC_RENDER_STAGE_PARTICLES
        )
        {
            vec4 specular_map = texture(specular, uv);

            stencil = specular_map.g > 0.9f ? s_METALLIC : stencil;
            stencil = specular_map.a > 0.0f && specular_map.a < 1.0f ? s_EMISSIVE : stencil;

            #ifdef SPECULAR

            // [gltracy] https://www.shadertoy.com/view/lsXSz7
            // Cook-Torrance specular.
            // Modified for performance, not physical accuracy.
            vec3 H = normalize(c_shadowLightDirection - normalize(pos_view));

            float NoH = max(0.001f, dot(H, normal));
            float VoH = max(0.001f, dot(H, c_shadowLightDirection)); // VoH = LoH

            // roughness = pow(1.0 - f0, 2.0)
            float roughness = (1.0f - specular_map.r) * 0.3f;

            float F = // specular; fresnel
            specular_map.g + (1.0f - VoH) * max(specular_map.g, roughness);
            float D = // roughness; colour burn
            clamp((NoH - 1.0f) / roughness + 1.0f, 0.0f, 1.0f);

            col0.rgb +=
            stencil == s_METALLIC ? vec3(F * D) * col0.rgb : vec3(F * D);

            #endif
        }

    #endif



    float NoL = dot(normal, c_shadowLightDirection) * 0.5f + 0.5f;
    float shadows = 1.0f;

    // Needs: shader.h, vec3 col0, float NoL, float shadows,
    //        float nightVision, float c_isDay, float c_facRain,
    //        vec2 uv_lightmap, vec3 c_colZenith, vec3 c_colSun,
    //        sampler2D colortex8, sampler2D colortex7 (deferred)
    #include "/program/lib/do_lighting().glsl"



    // Needs: ... Open the file.
    #ifdef FOG_WATER

        // TODO: Fix water fog transition with distant horizons.
        float z = gl_FragCoord.z;
        mat4 gProj = gbufferProjection;

    #endif

    #include "/program/lib/do_fog().glsl"



    // WRITE: c_final.rgb
//     col0 = col0;

    // WRITE: normals.rg, uv_lightmap.b, stencil.a
    col5 = vec4(
        encode_normal(normal) * 0.5f + 0.5f,
        packUnorm2x4(uv_lightmap, dither),
        stencil
    );
// }

#endif
