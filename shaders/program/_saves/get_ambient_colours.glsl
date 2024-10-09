// Needs:   int worldTime, float rainStrength
// Returns: vec3 col_zenith, vec3 col_fog, vec3 col_sun, vec3 col_ss

// ===

// Intialize values.
vec3 col_zenith;    // sky_top; ambient
vec3 col_fog;       // sky_bottom
vec3 col_sun;       // ambient
vec3 col_ss;        // sunrise & sunset blend

{
    // Colours.
    vec3 col_sunrise   = vec3(1.0, 0.9, 0.2);
    vec3 col_sunset    = vec3(0.7, 0.2, 0.2);


    vec3 zcol_day       = vec3(0.45, 0.63, 0.90); // Vanilla: 0.47, 0.65, 1.0
    vec3 zcol_night     = vec3(.001, .002, .003);

    vec3 fcol_day       = vec3(0.70, 0.80, 1.00);
    vec3 fcol_night     = vec3(.035, 0.04, 0.07);

    vec3 scol_day       = vec3(0.90, 0.84, 0.79); // 1. .97 .92
    vec3 scol_night     = vec3(0.10, 0.10, 0.30); // .1 .1 .3



    float fac;

    if      (worldTime < 1000)      // 00000-01000 sunrise-day
    {
        fac = worldTime * 0.001;
        col_ss      = mix(col_sunset, col_sunrise, fac * 0.5 + 0.5) * (1.0 - fac);

        col_sun     = mix(col_ss, scol_day, fac);
        col_zenith  = mix(zcol_night, zcol_day, fac * 0.3 + 0.7);
        col_fog     = mix(fcol_night, fcol_day, fac * 0.3 + 0.7);
    }
    else if (worldTime < 11000)     // 01000-11000 day
    {
        col_sun     = scol_day;
        col_zenith  = zcol_day;
        col_fog     = fcol_day;
    }
    else if (worldTime < 12000)     // 11000-12000 day-sunset
    {
        fac = (worldTime - 11000) * 0.001;
        col_ss      = mix(col_sunrise, col_sunset, fac * 0.5) * fac;

        col_sun     = mix(scol_day, col_ss, fac);
        col_zenith  = mix(zcol_day, zcol_night, fac * 0.5);
        col_fog     = mix(fcol_day, fcol_night, fac * 0.5);
    }
    else if (worldTime < 13000)     // 12000-13000 sunset-night
    {
        fac = (worldTime - 12000) * 0.001;
        col_ss      = mix(col_sunrise, col_sunset, fac * 0.5 + 0.5) * (1.0 - fac);

        col_sun     = mix(col_ss, scol_night, fac);
        col_zenith  = mix(zcol_day, zcol_night, fac * 0.5 + 0.5);
        col_fog     = mix(fcol_day, fcol_night, fac * 0.5 + 0.5);
    }
    else if (worldTime < 23000)     // 13000-23000 night
    {
        col_sun     = scol_night;
        col_zenith  = zcol_night;
        col_fog     = fcol_night;
    }
    else                            // 23000-24000 night-sunrise
    {
        fac = (worldTime - 23000) * 0.001;
        col_ss      = mix(col_sunset, col_sunrise, fac * 0.5) * fac;

        col_sun     = mix(scol_night, col_ss, fac);
        col_zenith  = mix(zcol_night, zcol_day, fac * 0.5);
        col_fog     = mix(fcol_night, fcol_day, fac * 0.5);
    }



//     col_zenith  = mix(col_zenith, vec3(0.7, 0.85, 1.0) * luma(col_zenith), rainStrength);
//     col_fog     = mix(col_fog, vec3(0.35, 0.425, 0.5) * luma(col_fog), rainStrength);

    col_zenith  = mix(col_zenith,   vec3(0.4, 0.50, 0.6), rainStrength);
    col_fog     = mix(col_fog,      vec3(0.3, 0.35, 0.4), rainStrength);
}
