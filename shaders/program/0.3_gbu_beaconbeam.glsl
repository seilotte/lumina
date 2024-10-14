#include "/shader.h"
// #include "/program/lib/math.glsl"

#ifdef VSH

out vec2 uv;
out vec4 vcol;

in vec2 vaUV0;
in vec3 vaPosition;
in vec4 vaColor;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;



// =========



void main()
{
    #ifndef RENDER_BEACON_BEAMS

        return;

    #endif



    // vertex -> local -> view -> ndc
    gl_Position.xyz =
    mat3(modelViewMatrix) * vaPosition + modelViewMatrix[3].xyz;
    gl_Position = vec4(
        projectionMatrix[0].x * gl_Position.x,
        projectionMatrix[1].y * gl_Position.y,
        projectionMatrix[2].z * gl_Position.z + projectionMatrix[3].z,
        -gl_Position.z
    );



    uv      = vaUV0;
    vcol    = vaColor; // glass tint & alpha
}

#endif



/*
 * #########
 */



#ifdef FSH

in vec2 uv;
in vec4 vcol;

uniform sampler2D gtexture; // atlas



// =========



/* RENDERTARGETS: 0,5 */
layout(location = 0) out vec4 col0; // col_final.rgb
layout(location = 1) out vec4 col5; // normals.rg, uv_lightmap.b, stencil.a

void main()
{
    #ifndef RENDER_BEACON_BEAMS

        return;

    #endif



    // Initialize values.
//     col0 = vec4(.0f);



    if (vcol.a < 1.0f) {discard; return;};

    // WRITE: c_final.rgb
    col0 = texture(gtexture, uv) * vcol;

    // WRITE: normals.rg, uv_lightmap.b, stencil.a
    col5 = vec4(0.0f, 0.0f, 0.0f, s_BEACONBEAM);
}

#endif
