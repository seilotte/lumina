// #include "/shader.h"
// #include "/program/lib/math.glsl"

#ifdef VSH

out vec2 uv;

in vec2 vaUV0;
in vec3 vaPosition;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 textureMatrix;



// =========



void main()
{
    // vertex -> local -> view -> ndc
    gl_Position.xyz =
    mat3(modelViewMatrix) * vaPosition + modelViewMatrix[3].xyz;
    gl_Position = vec4(
        projectionMatrix[0].x * gl_Position.x,
        projectionMatrix[1].y * gl_Position.y,
        projectionMatrix[2].z * gl_Position.z + projectionMatrix[3].z,
        -gl_Position.z
    );



    uv = (textureMatrix * vec4(vaUV0, 0.0f, 1.0f)).xy;
}

#endif



/*
 * #########
 */



#ifdef FSH

in vec2 uv;

uniform sampler2D gtexture; // atlas



// =========



/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 col0; // c_final.rgb

void main()
{
    // Initialize values.
//     col0 = vec4(.0f);



    // WRITE: c_final.rgb
    col0 = texture(gtexture, uv).r * vec3(0.75f, 0.5f, 1.0f); // vanilla: 0.5 0.0 1.0
}

#endif
