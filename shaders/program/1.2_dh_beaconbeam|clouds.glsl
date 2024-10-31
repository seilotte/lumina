#include "/shader.h"
#include "/program/lib/math.glsl"

#ifdef VSH_DH

out float stencil;
out vec4 vcol;

// uniform int dhMaterialId; // automatically declared
uniform mat4 dhProjection;

// ===

#if defined CLOUDS_GRADIENT || defined FOG

out float fac_fog;

#endif


#ifdef CLOUDS_GRADIENT

uniform vec3 cameraPosition;

#endif

/**/
#ifdef FOG

out vec3 pos_view;

#endif



// =========



void main()
{
    #ifndef RENDER_DISTANT_HORIZONS

        return;

    #endif



    // vertex -> local -> view
    gl_Position.xyz =
    mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;



    stencil     = 0.0f;
    vcol        = gl_Color;



    #ifndef RENDER_BEACON_BEAMS

        // NOTE: This is wrong, for further information look at the
        // defined macros in iris... But it works.
        // common/src/main/java/net/irisshaders/iris/gl/shader/StandardMacros.java
        if (dhMaterialId == -13) return;

    #else

        stencil = float(dhMaterialId == -13); // is_beaconbeam

    #endif



    #if defined CLOUDS_GRADIENT

        // Fancy & fast; They are the same.
        fac_fog =
        linearstep(gl_Vertex.y + cameraPosition.y, 580.0f, 620.0f);

    #elif defined FOG

        fac_fog = 1.0f;

    #endif



    #ifdef FOG

        pos_view = gl_Position.xyz;

    #endif



    // view -> ndc
    gl_Position = vec4(
        dhProjection[0].x * gl_Position.x,
        dhProjection[1].y * gl_Position.y,
        dhProjection[2].z * gl_Position.z + dhProjection[3].z,
        -gl_Position.z
    );
}

#endif



/*
 * #########
 */



#ifdef FSH_DH

in float stencil;
in vec4 vcol;

uniform int renderStage;

// ===

#if defined CLOUDS_GRADIENT || defined FOG

in float fac_fog;

uniform sampler2D colortex4; // c_sky.rgb

#endif

/**/
#ifdef FOG

in vec3 pos_view;

uniform float dhFarPlane;

#endif



// =========



/* RENDERTARGETS: 0,5 */
layout(location = 0) out vec4 col0; // c_final.rgb
layout(location = 1) out vec4 col5; // normals.rg, uv_lightmap.b, stencil.a

void main()
{
    #ifndef RENDER_DISTANT_HORIZONS

        discard; return;

    #endif



    // Initialize values.
//     col0 = vec4(.0f);
//     col5 = vec4(.0f);

    float dither = noise_r2(gl_FragCoord.xy);



    if (
        !gl_FrontFacing ||
        dither > gl_FragCoord.z / gl_FragCoord.w
    ) {discard; return;}



    #ifdef VCOL

        col0 = vcol;

    #else

        col0 = vec4(0.5f, 0.5f, 0.5f, 1.0f);

    #endif



    #ifdef FOG

        float fac_fog = fac_fog * linearstep(
            length_fast(pos_view.xz),
            dhFarPlane,
            dhFarPlane * FOG_STRENGTH
        );

    #endif




    #if defined CLOUDS_GRADIENT || defined FOG

        // TODO: Identify clouds. Keep in mind vcol changes (e.g. when raining).
        if (stencil < 0.001f)
        {
            col0.rgb = mix(
                texelFetch(colortex4, ivec2(gl_FragCoord), 0).rgb,
                col0.rgb,
                fac_fog
            );
        }

    #endif



    // WRITE: c_final.rgb
//     col0 = col0;

    // WRITE: normals.rg, uv_lightmap.b, stencil.a
    col5 = vec4(0.0f, 0.0f, 0.0f, stencil);
}

#endif
