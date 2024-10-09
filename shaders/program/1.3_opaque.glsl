#ifdef VSH

// {
    #ifndef RENDER_TERRAIN

        return;

    #endif



    // vertex -> local -> view
    gl_Position.xyz =
    mat3(modelViewMatrix) * (vaPosition + chunkOffset) + modelViewMatrix[3].xyz;



    stencil         = entityId == 1 ? s_LIGHTNING_BOLT : 0.0f;
    uv              = vaUV0;
    uv_lightmap     = vaUV2 * 0.004167f;
    pos_view        = gl_Position.xyz;
    vcol            = vaColor;
    tbn[2]          = normalMatrix * vaNormal;



    uv_lightmap.x *= uv_lightmap.x; // There is no point in doing it later.



    #ifdef DIS_FOLLIAGE

        if (mc_Entity.x > 99 && mc_Entity.x < 200) // wind 1xx
        {
            float strength = vaUV2.y * DIS_FOLLIAGE_STRENGTH;

            switch (int(mc_Entity.x))
            {
//                 case 100: // full
//                     strength *= 1.0;
//                     break;
                case 101: // more stiffness
                    strength *= 0.5f;
                    break;
                case 102: // potted
                    strength *= max(0.15f - at_midBlock.y * 0.015625f, 0.0f);
                    break;
                case 103: // lower/short folliage
                    strength *= 0.5f - at_midBlock.y * 0.015625f;
                    break;
                case 104: // upper folliage
                    strength *= 1.5f - at_midBlock.y * 0.015625f;
                    break;
            }

            gl_Position.x +=
            sin(gl_Position.x + gl_Position.y + frameTimeCounter * DIS_FOLLIAGE_SPEED) * strength;
            gl_Position.z +=
            sin(gl_Position.z + gl_Position.y + frameTimeCounter * DIS_FOLLIAGE_SPEED) * strength;
        }

    #endif



    #if defined REF_WATER || defined TRANSPARENT_WATER_CAULDRON

        if (mc_Entity.x == 3)
        {
            stencil = vaColor.r < 0.5 ? s_WATER_CAULDRON : s_METALLIC;
        }

    #endif



    #ifdef MAP_NORMAL

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



    #if defined TRANSPARENT_WATER_CAULDRON || defined FOG_WATER

        if (stencil == s_WATER_CAULDRON)
        {
            #ifdef TRANSPARENT_WATER_CAULDRON

                if (dither > 0.75f) {discard; return;}

            #endif

            #ifdef FOG_WATER

                col0.rgb *= c_colWaterAbsorb;

            #endif
        }

    #endif



    #ifdef VCOL

        col0 *= vcol;

    #endif

    col0.a = 1.0f;

    if (stencil == s_LIGHTNING_BOLT) col0 = vec4(1.0f);



    #if defined SS_GI || defined SS_CL

        {
            // Pass the buffer from the previous frame.
            vec4 c6 = texelFetch(colortex6, ivec2(gl_FragCoord), 0);

            // WRITE: c_emissivet.rgb, m_emissivet.a
            col6 = vec4(c6.rgb * c6.a, 0.0f);
        }

    #endif



    #ifdef MAP_NORMAL

        {
            vec3 normal_map;
            normal_map.xy = texture(normals, uv).rg * 2.0f - 1.0f;
            normal_map.z = sqrt_fast(1.0f - dot(normal_map.xy, normal_map.xy));

            normal = tbn * normal_map;
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
