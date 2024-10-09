// Needs: shader.h, math.glsl...
/*
int         isEyeInWater
float       pos_length
float       far or int dhRenderDistance
float       z // depthtex1 or gl_FragCoord.z
float       stencil // for water mesh
float       uv_lightmap_opaque_x
vec3        c_colWaterAbsorb
vec3        c_colWaterScatter
mat4        gProj // gbufferProjection or dhProjection
sampler2D   FOG_WATER_DEPTHTEX // depthtex1 or dhDepthTex1
sampler2D   colortex4 // c_sky.rgb
sampler2D   colortex5 -> float uv_lightmap_opaque_x
*/

// ===

// {
    #if defined FOG_WATER || defined FOG

    // NOTE: Translucent geometry fog is managed in *translucent gbuffers*.
    float fac_fog = 1.0f;
    vec3 col_sky = texelFetch(colortex4, ivec2(gl_FragCoord), 0).rgb;


    #ifdef FOG_WATER

        #ifdef FOG_WATER_DEPTHTEX

        if (stencil == s_WATER) // water mesh
        {
            float z0 = z;
            float z1 = texelFetch(FOG_WATER_DEPTHTEX, ivec2(gl_FragCoord), 0).r;

            // Linearize.
            // Why `z0 = gl_FragCoord.z / gl_FragCoord.w` does not work with dh?
            z0 = gProj[3].z / (z0 * 2.0f - 1.0f + gProj[2].z); // opaque
            z1 = gProj[3].z / (z1 * 2.0f - 1.0f + gProj[2].z); // translucent

            // NOTE: "Glitches" a bit with transparency, I do not mind.
            float uv_lightmap_opaque_x = unpackUnorm2x4(
                texelFetch(colortex5, ivec2(gl_FragCoord), 0).b
            ).x;

            float fac_fog = max(
                uv_lightmap_opaque_x * 0.5f,
                exp2((z0 - z1) * FOG_WATER_STRENGTH)
            );

            col0 = vec4(
                col0.rgb * mix(c_colWaterAbsorb, c_colWaterScatter, fac_fog),
                1.0f - fac_fog
            );
        }

        #endif

        if (isEyeInWater == 1) // in_water
        {
            float z0 = z * 2.0f - 1.0f;

            // Linearize.
            z0 = gProj[3].z / (z0 + gProj[2].z);

            fac_fog = max(
                uv_lightmap.x * 0.5f,
                exp2(-z0 * FOG_WATER_STRENGTH * 0.5f)
            );

            col_sky *= (1.0f - fac_fog + fac_fog * c_colWaterScatter);
        }

    #endif



    #ifdef FOG
    #if !defined DISTANT_HORIZONS || !defined RENDER_DISTANT_HORIZONS

        // TODO: Height fog.
        fac_fog *= linearstep(
            pos_length,
            far,
            far * FOG_STRENGTH
        );

    #else

        fac_fog *= linearstep(
            pos_length,
            dhRenderDistance,
            dhRenderDistance * FOG_STRENGTH
        );

    #endif
    #endif


    // WRITE: c_final.rgb
    col0.rgb = mix(col_sky, col0.rgb, fac_fog);

    #endif
// }
