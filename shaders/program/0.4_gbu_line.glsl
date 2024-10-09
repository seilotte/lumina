// #include "/shader.h"
// #include "/program/lib/math.glsl"

#ifdef VSH

#define LINE_WIDTH 2.0
#define VIEW_SHRINK 0.99609375 // view_shrink = 1.0 - (1.0 / 256.0)

in vec2 vaUV0;
in vec3 vaPosition;
in vec3 vaNormal;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

uniform vec2 c_viewResolution;



// =========



void main()
{
    // From vanilla minecraft 1.21.1. /shaders/core/rendertype_lines.vsh
    // Modified.
    vec3 line_pos_start;
    float line_pos_start_w;

    // vertex -> local -> view -> view_shrink -> ndc
    line_pos_start = (mat3(modelViewMatrix) * vaPosition + modelViewMatrix[3].xyz) * VIEW_SHRINK;
    line_pos_start_w = -line_pos_start.z;
    line_pos_start = vec3(
        projectionMatrix[0].x * line_pos_start.x,
        projectionMatrix[1].y * line_pos_start.y,
        projectionMatrix[2].z * line_pos_start.z + projectionMatrix[3].z
    ) / line_pos_start_w;

    vec3 line_pos_end;

    // vertex -> local -> view -> view_shrink -> ndc
    line_pos_end = (mat3(modelViewMatrix) * (vaPosition + vaNormal) + modelViewMatrix[3].xyz) * VIEW_SHRINK;
    line_pos_end = vec3(
        projectionMatrix[0].x * line_pos_end.x,
        projectionMatrix[1].y * line_pos_end.y,
        projectionMatrix[2].z * line_pos_end.z + projectionMatrix[3].z
    ) / -line_pos_end.z;



    vec2 line_screen_dir = normalize((line_pos_end.xy - line_pos_start.xy) * c_viewResolution);
    vec2 line_offset = vec2(-line_screen_dir.y, line_screen_dir.x) * LINE_WIDTH / c_viewResolution;

    if (line_offset.x < 0.0f) line_offset = -line_offset;
    if (gl_VertexID % 2 != 0) line_offset = -line_offset;

    gl_Position = vec4((line_pos_start + vec3(line_offset, 0.0f)) * line_pos_start_w, line_pos_start_w);
}

#endif



/*
 * #########
 */



#ifdef FSH

/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 col0; // c_final.rgb

void main()
{
    // Initialize values.
//     col0 = vec4(.0f);



    // WRITE: c_final.rgb
    col0 = vec3(0.05f);
}

#endif
