// [Olivier|Yannick|Clément] https://github.com/cdrinmatane/SSRT3
// Screen Space Ambient Occlusion & Screen Space Indirect Lighting with Visibility Bitmasks.

#include "/shader.h"
#include "/program/utils/math.glsl"

#ifdef VSH

out vec2 uv;

in vec3 vaPosition;



void main()
{
    // vertex -> screen?
    gl_Position = vec4(vaPosition.xy * 2.0 - 1.0, 0.0, 1.0);

    uv = vaPosition.xy;
}

#endif



/*
 * #########
 */



#ifdef FSH

in vec2 uv;

uniform sampler2D depthtex1;
uniform sampler2D colortex0;
uniform sampler2D colortex1; // emission

uniform int frameCounter;
uniform float far;
uniform float near;
uniform float frameTimeCounter;
uniform vec2 viewResolution; // custom
uniform vec2 viewPixelSize; // custom

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;


// precision highp float;
// precision highp int;

vec3 nvec3(vec4 p)
{
    return p.xyz / p.w;
}


// From Activision GTAO paper: https://www.activision.com/cdn/research/s2016_pbs_activision_occlusion.pptx
float SpatialOffsets(ivec2 position)
{
    return 0.25 * float((position.y - position.x) & 3);
}

// From http://byteblacksmith.com/improvements-to-the-canonical-one-liner-glsl-rand-for-opengl-es-2-0/
float rand(vec2 co)
{
    float a = 12.9898;
    float b = 78.233;
    float c = 43758.5453;
    float dt= dot(co.xy ,vec2(a,b));
    float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

vec3 rgb_to_hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float acos_fast(float x)
{
    float r = -0.156583 * abs(x) + 1.570796326794896619;
    r *= sqrt(1.0 - abs(x));
    return x >= 0. ? r : 3.141592653589793238 - r;
}

vec2 acos_fast(vec2 x)
{
    return vec2(
        acos_fast(x.x),
        acos_fast(x.y)
    );
}


const float PI = 3.141592653589793238;
const float HALF_PI = 1.570796326794896619;

const int MAX_RAY = 32;

// Internal parameters
float fov = 2.f * atan(1.f / gbufferProjection[1][1]); // already in radians
float projScale = viewPixelSize.y * (tan(fov * 0.5f) * 2.f) * 0.5f;
float _HalfProjScale = projScale;

// const float temporalRotations[6] = float[](60.f, 300.f, 180.f, 240.f, 120.f, 0.f);
// float temporalRotation = temporalRotations[frameCounter % 6];
// float _TemporalDirections = temporalRotation / 360.f;
float _TemporalDirections = 0.f;

// const float spatialOffsets[4] = float[](0.f, 0.5f, 0.25f, 0.75f);
// float temporalOffset = spatialOffsets[(frameCounter / 6) % 4];
// float _TemporalOffsets = temporalOffset;
float _TemporalOffsets = 0.f;


// Sampling properties
int _RotationCount          = 1; // 1 4
uint _StepCount             = 12u; // 1u 32u
float _Radius               = 5.f; // 1.f 25.f
float _ExpFactor            = 1.f; // 1.f 3.f
bool _JitterSamples         = true;
bool _ScreenSpaceSampling   = true;
bool _MipOptimization       = true;

// GI properties
float _GIIntensity          = 10.f; // 0.f 100.f
float _MultiBounceGI        = 0.f; // 0.f 1.f
float _BackfaceLighting     = 0.f; // 0.f 1.f

// Occlusion properties
float _AOIntensity          = 1.f; // 0.f 4.f
float _Thickness            = 1.f; // 0.01f 10.f
bool _LinearThickness       = false;
// float _DirectLightingAO;



vec3 HorizonSampling(
    bool directionIsRight,
    float radius,
    vec3 posVS,
    vec2 slideDir_TexelSize,
    float initialRayStep,
    vec2 uv,
    vec3 viewDir,
    vec3 normalVS,
    float n,
    inout uint globalOccludedBitfield,
    vec3 planeNormal
)
{

    float stepRadius = _ScreenSpaceSampling ?
    (radius * (viewResolution.x * 0.5f)) / float(_StepCount) :
    max((radius * _HalfProjScale) / posVS.z, float(_StepCount));
//     max((-radius * gbufferProjection[0][0]) / posVS.z, float(_StepCount));

    stepRadius /= float(_StepCount + 1u);

    float radiusVS = max(1.f, float(_StepCount - 1u)) * stepRadius;

    float samplingDirection = directionIsRight ? 1.f : -1.f;

    vec3 col = vec3(0.f);
    vec3 lastSamplePosVS = posVS;

    for (uint j = 0u; j < _StepCount; j++)
    {
        float offse =
        pow(abs((stepRadius * (float(j) + initialRayStep)) / radiusVS), _ExpFactor) * radiusVS;

        vec2 uvOffset = slideDir_TexelSize * max(offse, float(1u + j));
        vec2 sampleUV = uv + uvOffset * samplingDirection;

        if(
            sampleUV.x <= 0.f || sampleUV.y <= 0.f ||
            sampleUV.x >= 1.f || sampleUV.y >= 1.f
        ) break;

        float mip = _MipOptimization ? min(float(j + 1u) * 0.5f, 4.f) : 0.f;

        float sampleDepth = textureLod(depthtex1, sampleUV, mip).r;

//         if (
//             sampleDepth == 1.0
//             sampleDepth < 0.65
//             sampleDepth == z
//         ) continue;

        vec3 samplePosVS =
        nvec3(gbufferProjectionInverse * vec4(vec3(sampleUV, sampleDepth) * 2.f - 1.f, 1.f));

        vec3 pixelToSample = normalize(samplePosVS - posVS);

        float linearThicknessMultiplier = _LinearThickness ?
        clamp(samplePosVS.z / far, 0.f, 1.f) * 100.f : // in glsl: saturate(linear_depth) * 100.f?
        1.f;

        vec3 pixelToSampleBackface =
        normalize((samplePosVS - (linearThicknessMultiplier * viewDir * _Thickness )) - posVS);

        vec2 frontBackHorizon = vec2(
            dot(pixelToSample, viewDir),
            dot(pixelToSampleBackface, viewDir)
        );
        frontBackHorizon = acos_fast(
            clamp(frontBackHorizon, vec2(-1.f), vec2(1.f))
        );
        frontBackHorizon = clamp(
            (((samplingDirection * -frontBackHorizon) - n + 1.570796326794896619) / 3.141592653589793238),
            vec2(0.f), vec2(1.f)
        );
        frontBackHorizon = directionIsRight ? frontBackHorizon.yx : frontBackHorizon.xy;

        uint numOccludedZones;
        { // ComputeOccludedBitfield()
            uint startHorizonInt = uint(frontBackHorizon.x * float(MAX_RAY));
            uint angleHorizonInt = uint(
                ceil(clamp(frontBackHorizon.y - frontBackHorizon.x, 0.f, 1.f) * float(MAX_RAY))
            );
            uint angleHorizonBitfield = angleHorizonInt > 0u ?
            (0xFFFFFFFFu >> (uint(32 - MAX_RAY) + (uint(MAX_RAY) - angleHorizonInt))) :
            0u;

            uint currentOccludedBitfield = angleHorizonBitfield << startHorizonInt;
            currentOccludedBitfield = currentOccludedBitfield & (~globalOccludedBitfield);

            globalOccludedBitfield = globalOccludedBitfield | currentOccludedBitfield;
            numOccludedZones = bitCount(currentOccludedBitfield);
        }


        vec3 lightNormalVS = vec3(0.f);

        // If a ray hit the sample, that sample is visible from shading point
        if(numOccludedZones > 0u)
        {
            vec3 lightColor = textureLod(colortex1, sampleUV, mip).rgb;

            // Continue if there is light at that location (intensity > 0)
            if(luminance(lightColor) > 0.001)
            {
                vec3 lightDirectionVS = normalize(pixelToSample);
                float normalDotLightDirection = clamp(
                    dot(normalVS, lightDirectionVS),
                    0.f, 1.f
                );

                // Continue if light is facing surface normal
                if (normalDotLightDirection > 0.001)
                {
                    // Normal Approximation
                    lightNormalVS =
                    -samplingDirection * cross(normalize(samplePosVS - lastSamplePosVS), planeNormal);

                    // Intensity of outgoing light in the direction of the shading point
                    float lightNormalDotLightDirection = dot(lightNormalVS, -lightDirectionVS);

                    lightNormalDotLightDirection =
                    _BackfaceLighting > 0.f && dot(lightNormalVS, viewDir) > 0.f ?

                    (sign(lightNormalDotLightDirection) < 0.f ?
                    abs(lightNormalDotLightDirection) * _BackfaceLighting : abs(lightNormalDotLightDirection)) :

                    clamp(lightNormalDotLightDirection, 0.f, 1.f);

                    col +=
                    (float(numOccludedZones) / float(MAX_RAY)) *
                    lightColor *
                    normalDotLightDirection * lightNormalDotLightDirection;
                }
            }
        }

        lastSamplePosVS = samplePosVS;
    }

    return col;
}



/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 debug;

void main()
{
    debug = vec3(0.f);

    vec4 col0 = texture(colortex0, uv);
    vec4 col1 = texture(colortex1, uv); // emission or col0

    float z = textureLod(depthtex1, uv, 0.f).r;

    if (z <= 1e-4)
    {
//         debug = vec3(0.f);
        return;
    }

    vec3 posS = vec3(uv, z);
    vec3 posVS = nvec3(gbufferProjectionInverse * vec4(posS * 2.0 - 1.0, 1.0));
    vec3 normalVS = normalize(cross(dFdx(posVS), dFdy(posVS)));

    vec3 viewDir = normalize(-posVS);

    float radius = _Radius;
    float noiseOffset = SpatialOffsets(ivec2(gl_FragCoord.xy));
    float noiseDirection = noise_r2(gl_FragCoord.xy);
    float initialRayStep =
    fract(noiseOffset + _TemporalOffsets) +
    (rand(uv) * 2.f - 1.f) * 1.f * float(_JitterSamples);

    float ao;
    vec3 gi = vec3(0.f);

    for (int i = 0; i < _RotationCount; i++)
    {
        float rotationAngle = (i + noiseDirection + _TemporalDirections) * (PI / float(_RotationCount));
        vec3 sliceDir = vec3(vec2(cos(rotationAngle), sin(rotationAngle)), 0.f);
        vec2 slideDir_TexelSize = sliceDir.xy * viewPixelSize;

        vec3 planeNormal = normalize(cross(sliceDir, viewDir));
        vec3 tangent = cross(viewDir, planeNormal);
        vec3 projectedNormal = normalVS - planeNormal * dot(normalVS, planeNormal);
        vec3 projectedNormalNormalized = normalize(projectedNormal);
        vec3 realTangent = cross(projectedNormalNormalized, planeNormal);

        float cos_n = clamp(dot(projectedNormalNormalized, viewDir), -1.f, 1.f);
        float n = -sign(dot(projectedNormal, tangent)) * acos(cos_n);

        uint globalOccludedBitfield = 0u;

        gi += HorizonSampling(
            true,
            radius,
            posVS,
            slideDir_TexelSize,
            initialRayStep,
            uv,
            viewDir,
            normalVS,
            n,
            globalOccludedBitfield,
            planeNormal
        );
        gi += HorizonSampling(
            false,
            radius,
            posVS,
            slideDir_TexelSize,
            initialRayStep,
            uv,
            viewDir,
            normalVS,
            n,
            globalOccludedBitfield,
            planeNormal
        );

        ao += float(bitCount(globalOccludedBitfield)) / float(MAX_RAY);
    }

    ao /= float(_RotationCount);
    ao = clamp(pow(1.0 - clamp(ao, 0.f, 1.f), _AOIntensity), 0.f, 1.f);

    gi /= _RotationCount;
    gi *= _GIIntensity;

    gi = rgb_to_hsv(gi);
    gi.z = clamp(gi.z, 0.f, 7.f); // Expose and clamp the final color
    gi = hsv_to_rgb(gi);

//     debug = col1.rgb;
//     debug = vec3(ao);
    debug = gi;
}

#endif
