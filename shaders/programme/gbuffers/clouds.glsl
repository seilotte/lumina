#include "/programme/_lib/version.glsl"

#include "/programme/_lib/uniforms.glsl"
#include "/programme/_lib/math.glsl"
#include "/shader.h"

#ifdef VSH_COMPAT

out float gradient;
// out vec3 vcol;

// =========



void main()
{
    #if !defined RENDER_CLOUDS

        gl_Position = vec4(-10.0);
        return;

    #endif



    // NOTE: Iris is more stable with the compatibility version.
    // Without it, iris_cloudsMain() & _iris_internal_translate(),
    // were not being patched.
    gradient = ((gl_Vertex.y + cameraPosition.y - cloudHeight) + 1.0) * 0.125;
//     vcol = gl_Color.rgb;



    #if defined FOG_CLOUDS

//         #define CLOUDS_RENDER_DISTANCE 2048.0 // 1 chunk = 16

        float fog = sqrt_fast(dot(gl_Vertex.xyz, gl_Vertex.xyz)); // length()
        fog = linearstep(CLOUDS_RENDER_DISTANCE, 16.0, fog);

        gradient = min(gradient, fog);

    #endif



    gl_Position = proj4(gl_ProjectionMatrix, mul3(gl_ModelViewMatrix, gl_Vertex.xyz));
}

#endif



/*
 * #########
 */



#ifdef FSH_COMPAT

in float gradient;
// in vec3 vcol;

uniform sampler2D colortex9; // sky.rgb

// =========



/* RENDERTARGETS: 0,1,10 */
layout(location = 0) out vec4 col0;
layout(location = 1) out vec4 col1;
layout(location = 2) out vec4 col10;

void main()
{
    vec3 col = mix(vec3(0.2, 0.21, 0.23), vec3(0.9, 0.9, 0.95), skyColor.bbb);
    vec3 col_fog = texelFetch(colortex9, ivec2(gl_FragCoord), 0).rgb;

    col = mix(col_fog, col, gradient);



    // Write.
    col0 = vec4(col, 1.0);
    col1 = vec4(1.0);
    col10 = vec4(0.0);
}

#endif
