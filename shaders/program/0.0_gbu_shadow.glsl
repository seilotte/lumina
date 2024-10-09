// #include "/shader.h"
// #include "/program/lib/math.glsl"

#ifdef VSH

in vec3 vaPosition;

uniform vec3 chunkOffset;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;



// =========



void main()
{
    // vertex -> local -> view -> ndc
    gl_Position.xyz =
    mat3(modelViewMatrix) * (vaPosition + chunkOffset) + modelViewMatrix[3].xyz;
    gl_Position = vec4(
        projectionMatrix[0].x * gl_Position.x,
        projectionMatrix[1].y * gl_Position.y,
        projectionMatrix[2].z * gl_Position.z + projectionMatrix[3].z,
        projectionMatrix[3].w
    );
}

#endif



/*
 * #########
 */



#ifdef FSH

// NOTE: We only use shadowtexN. There is no need to write shdowcolorN.
void main()
{

}

#endif
