#include "/shader.h"
// #include "/program/lib/math.glsl"

#ifdef VSH

out float stars;
out vec3 position;

in vec3 vaPosition;
in vec4 vaColor;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

uniform int renderStage;



// =========



void main()
{
    if (renderStage == MC_RENDER_STAGE_SUNSET) return; // discard sunrise/sunset geometry



    // vertex -> local -> view -> ndc
    gl_Position.xyz =
    mat3(modelViewMatrix) * vaPosition + modelViewMatrix[3].xyz;
    gl_Position = vec4(
        projectionMatrix[0].x * gl_Position.x,
        projectionMatrix[1].y * gl_Position.y,
        projectionMatrix[2].z * gl_Position.z + projectionMatrix[3].z,
        -gl_Position.z
    );



    if (renderStage == MC_RENDER_STAGE_STARS)
    {
        position = vec3(0.0f);
        stars = vaColor.b * 0.6f;
    }
    else
    {
        position = vaPosition;
        stars = 0.0f;
    }
}

#endif



/*
 * #########
 */



#ifdef FSH

in float stars;
in vec3 position;

uniform int isEyeInWater;
uniform float c_facRain;
uniform float c_isSunrise;
uniform float c_isSunset;
uniform vec3 c_sunDirection;
uniform vec3 c_sunDirScene90z;
uniform vec3 c_colFog;
uniform vec3 c_colSun;
uniform vec3 c_colZenith;
uniform vec3 c_colWater;
uniform vec3 c_colWaterAbsorb;


// =========



/* RENDERTARGETS: 0,5 */
layout(location = 0) out vec4 col0; // c_final.rgb
layout(location = 1) out vec4 col5; // normals.rg, uv_lightmap.b, stencil.a
layout(location = 2) out vec3 col4; // c_sky.rgb

#if defined CLOUDS_GRADIENT || defined FOG

/* RENDERTARGETS: 0,5,4 */

#endif

void main()
{
    // Initialize values.
//     col0 = vec4(.0f);
//     col4 = vec3(.0f);



    vec3 position = normalize(position);
    vec3 col_fog = c_colFog;

    if (c_isSunrise > 0.0f || c_isSunset > 0.0f)
    {
        float fac =
        max(0.0f, -c_sunDirection.z) * // looking at sun
        (1.0f - abs(dot(position, c_sunDirScene90z) + 0.25f)); // half sphere

        col_fog = mix(col_fog, c_colSun, fac * max(c_isSunrise, c_isSunset));
    }

    vec3 col_sky;
    col_sky = mix(col_fog, c_colZenith, max(0.0f, position.y));
    col_sky = max(vec3(stars), col_sky) * c_facRain;



    #ifndef FOG_WATER

        // 0.6 -> account for water albedo and alpha values
        col_sky = isEyeInWater == 1 ? c_colWater * 0.6f : col_sky;

    #else

        col_sky = isEyeInWater == 1 ? c_colWater * c_colWaterAbsorb * 0.6f : col_sky;

    #endif



    // WRITE: c_final.rgb
    col0 = vec4(col_sky, 1.0f);

    // WRITE: normals.rg, uv_lightmap.b, stencil.a
    col5 = vec4(0.0f, 0.0f, 0.0f, s_SKY);

    #if defined CLOUDS_GRADIENT || defined FOG

        // WRITE: c_sky.rgb
        col4 = col_sky;

    #endif
}

#endif
