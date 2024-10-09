#include "/shader.h"
#include "/program/lib/math.glsl"

#ifdef VSH

in vec3 vaPosition;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

// ===

#if defined CLOUDS_GRADIENT || defined FOG

out float fac_fog;

#endif

/**/
#ifdef FOG

out vec3 pos_view;

#endif



// =========



void main()
{
    #ifndef RENDER_CLOUDS_VANILLA

        return;

    #endif



    // vertex -> local -> view
    gl_Position.xyz =
    mat3(modelViewMatrix) * vaPosition + modelViewMatrix[3].xyz;



    #if defined CLOUDS_GRADIENT

        #if CLOUDS == 2

            fac_fog = (vaPosition.y + 1.0f) * 0.125f; // fancy

        #else

            fac_fog = 0.25f; // fast

        #endif

    #elif defined FOG

        fac_fog = 1.0f;

    #endif



    #ifdef FOG

        pos_view = gl_Position.xyz;

    #endif



    // view -> ndc
    gl_Position = vec4(
        projectionMatrix[0].x * gl_Position.x,
        projectionMatrix[1].y * gl_Position.y,
        projectionMatrix[2].z * gl_Position.z + projectionMatrix[3].z,
        -gl_Position.z
    );
}

#endif



/*
 * #########
 */



#ifdef FSH

uniform vec3 c_colClouds;

// ===

#if defined CLOUDS_GRADIENT || defined FOG

in float fac_fog;

uniform sampler2D colortex4; // c_sky.rgb

#endif

/**/
#ifdef FOG

in vec3 pos_view;

uniform float c_farPlane;

#endif



// =========



/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 col0; // c_final.rgb

void main()
{
    #ifndef RENDER_CLOUDS_VANILLA

        discard; return;

    #endif



    // Initialize values.
//     col0 = vec4(.0f);



    #ifdef FOG

        float fac_fog = fac_fog * linearstep(
            length_fast(pos_view.xz),
            c_farPlane,
            c_farPlane * FOG_STRENGTH
        );

    #endif



    #if defined CLOUDS_GRADIENT || defined FOG

        col0 = mix(
            texelFetch(colortex4, ivec2(gl_FragCoord), 0).rgb,
            c_colClouds,
            fac_fog
        );

    #endif



    // WRITE: c_final.rgb
//     col0 = c_colClouds;
}

#endif
