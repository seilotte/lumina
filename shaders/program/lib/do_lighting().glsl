// Needs: shader.h, vec3 col0, float NoL, float shadows,
//        float nightVision, float c_isDay, float c_facRain,
//        vec2 uv_lightmap, vec3 c_colZenith, vec3 c_colSun,
//        sampler2D colortex8, sampler2D colortex7 (deferred)

// ===

// {
    #ifndef ALBEDO
        col0.rgb = vec3(1.0f);
    #endif



    // ambient + (diffuse + specular) * lights
    vec3 ambient;

    #ifdef AMBIENT
        ambient = c_colZenith * AMBIENT_INTENSITY;
    #else
        ambient = vec3(0.0f);
    #endif



    #if defined DEFERRED && (defined SS_GI || defined SS_AO)

        vec4 col7 = texelFetch(
            colortex7, ivec2(gl_FragCoord.xy * SS_GIAOCL_RESOLUTION), 0
        );

    #endif

    #if defined DEFERRED && defined SS_GI

        ambient += col7.rgb * mix(0.5f, 1.0f, c_isDay);

    #endif



    #if defined DIFFUSE
        ambient += c_colSun * (uv_lightmap.y * shadows * NoL * DIFFUSE_INTENSITY);
    #elif defined MAP_SHADOW || defined SS_SHADOW
        ambient += c_colSun * (uv_lightmap.y * shadows);
    #else
        ambient += c_colSun * uv_lightmap.y;
    #endif



    ambient *= c_facRain;
    ambient = mix(ambient, vec3(1.0f), nightVision * 0.3f);



    #if defined DEFERRED && defined SS_AO

        ambient *= col7.a;

    #endif



    vec3 col_lights;

    #ifndef SS_CL

        col_lights = vec3(1.0f, 0.8f, 0.6f);
        col_lights *= uv_lightmap.x * (LIGHTS_INTENSITY - c_isDay);

    #else

        col_lights = texelFetch(
            colortex8, ivec2(gl_FragCoord.xy * SS_GIAOCL_RESOLUTION), 0
        ).rgb;
        col_lights = normalize(col_lights + vec3(1e-2, 8e-3, 6e-3));
        col_lights *= uv_lightmap.x * (LIGHTS_INTENSITY - c_isDay);

    #endif

    ambient += col_lights;



    // WRITE: c_final.rgb
    col0.rgb *= ambient;
// }
