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
        fog = isEyeInWater > 1 // in_lava & in_snow
        ? linearstep(fogEnd, fogStart, fog)
        : linearstep(CLOUDS_RENDER_DISTANCE, 16.0, fog);

        gradient = min(gradient, fog);

    #endif



    gl_Position = proj4(gl_ProjectionMatrix, mul3(gl_ModelViewMatrix, gl_Vertex.xyz));
//     gl_Position.x = gl_Position.x * 0.5 - gl_Position.w * 0.5; // downscale
}

#endif



/*
 * #########
 */



#ifdef FSH_COMPAT

in float gradient;
// in vec3 vcol;

// NOTE: colortex0 is bound, use the image.
layout(binding = 0, rgba8) readonly uniform image2D colorimg0; // sky.rgb

// =========



/* RENDERTARGETS: 1,2,6 */
layout(location = 0) out vec4 col1;
layout(location = 1) out vec4 col2;
layout(location = 2) out uint col6;

void main()
{
    vec3 col = mix(vec3(0.2, 0.21, 0.23), vec3(0.9, 0.9, 0.95), skyColor.bbb);
//     vec3 col_fog = imageLoad(colorimg0, ivec2(gl_FragCoord.x, gl_FragCoord.y * 0.5)).rgb;
    vec3 col_fog = imageLoad(colorimg0, ivec2(gl_FragCoord) / 4).rgb;

    // NOTE: The stars will render in "front"...
    col = mix(col_fog, col, gradient);



    // Write.
    col1 = vec4(col, 1.0);
    col2 = vec4(0., 0., 0., 1.); // curse entitites
    col6 = 0u;
}

#endif
