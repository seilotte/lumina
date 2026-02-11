'''
Developed for Minecraft 1.21.11.

TODO:
    Convert decimal to RGB.
    https://www.minecraft.net/en-us/article/minecraft-snapshot-25w42a
'''

import os
import json

USE_BLENDER = False

BIOMES_DATA = (
#   (biome,
#       fog_color, sky_color, water_color, water_fog_color)
    ('badlands',
        '16760159', '#FFFFFF', '5144449', '#FFFFFF'),
    ('bamboo_jungle',
        '14471367', '#FFFFFF', '1352389', '#FFFFFF'),
    ('basalt_deltas',
        '#FFFFFF', '#FFFFFF', '4159204', '#FFFFFF'),
    ('beach',
        '13882332', '#FFFFFF', '1408171', '#FFFFFF'),
    ('birch_forest',
        '13292785', '#FFFFFF', '423886', '#FFFFFF'),
    ('cherry_grove',
        '13030905', '#FFFFFF', '6141935', '#FFFFFF'),
    ('cold_ocean',
        '13030905', '#FFFFFF', '2130121', '#FFFFFF'),
    ('crimson_forest',
        '13030905', '#FFFFFF', '9460055', '#FFFFFF'),
    ('dark_forest',
        '13554919', '#FFFFFF', '3894481', '#FFFFFF'),
    ('deep_cold_ocean',
        '13030905', '#FFFFFF', '2130121', '#FFFFFF'),
    ('deep_dark',
        '13882332', '#FFFFFF', '4501493', '#FFFFFF'),
    ('deep_frozen_ocean',
        '12244761', '#FFFFFF', '2453685', '#FFFFFF'),
    ('deep_lukewarm_ocean',
        '#FFFFFF', '#FFFFFF', '890587', '#FFFFFF'),
    ('deep_ocean',
        '13030905', '#FFFFFF', '1542100', '#FFFFFF'),
    ('desert',
        '16760159', '#FFFFFF', '3319192', '#FFFFFF'),
    ('dripstone_caves',
        '13882332', '#FFFFFF', '4501493', '#FFFFFF'),
    ('end_barrens',
        '#FFFFFF', '#FFFFFF', '6443678', '#FFFFFF'),
    ('end_highlands',
        '#FFFFFF', '#FFFFFF', '6443678', '#FFFFFF'),
    ('end_midlands',
        '#FFFFFF', '#FFFFFF', '6443678', '#FFFFFF'),
    ('eroded_badlands',
        '16760159', '#FFFFFF', '4816793', '#FFFFFF'),
    ('flower_forest',
        '13554919', '#FFFFFF', '2139084', '#FFFFFF'),
    ('forest',
        '13554919', '#FFFFFF', '2004978', '#FFFFFF'),
    ('frozen_ocean',
        '12244761', '#FFFFFF', '2453685', '#FFFFFF'),
    ('frozen_peaks',
        '11654962', '#FFFFFF', '4501493', '#FFFFFF'),
    ('frozen_river',
        '12244761', '#FFFFFF', '1594256', '#FFFFFF'),
    ('grove',
        '12048162', '#FFFFFF', '4501493', '#FFFFFF'),
    ('ice_spikes',
        '12244761', '#FFFFFF', '1332635', '#FFFFFF'),
    ('jagged_peaks',
        '11654962', '#FFFFFF', '4501493', '#FFFFFF'),
    ('jungle',
        '14471367', '#FFFFFF', '1352389', '#FFFFFF'),
    ('lukewarm_ocean',
        '13030905', '#FFFFFF', '890587', '#FFFFFF'),
    ('lush_caves',
        '13554919', '#FFFFFF', '4501493', '#FFFFFF'),
    ('mangrove_swamp',
        '13882332', '#FFFFFF', '3832426', '#FFFFFF'),
    ('meadow',
        '13030905', '#FFFFFF', '4501493', '#FFFFFF'),
    ('mushroom_fields',
        '14209487', '#FFFFFF', '9079191', '#FFFFFF'),
    ('nether_wastes',
        '#FFFFFF', '#FFFFFF', '9460055', '#FFFFFF'),
    ('ocean',
        '13030905', '#FFFFFF', '1542100', '#FFFFFF'),
    ('old_growth_birch_forest',
        '13292785', '#FFFFFF', '685252', '#FFFFFF'),
    ('old_growth_pine_taiga',
        '12637960', '#FFFFFF', '2977143', '#FFFFFF'),
    ('old_growth_spruce_taiga',
        '12572427', '#FFFFFF', '2977143', '#FFFFFF'),
    ('pale_garden',
        '#FFFFFF', '#FFFFFF', '7768221', '#FFFFFF'),
    ('plains',
        '13882332', '#FFFFFF', '4501493', '#FFFFFF'),
    ('river',
        '13030905', '#FFFFFF', '34047', '#FFFFFF'),
    ('savanna',
        '15845785', '#FFFFFF', '2919324', '#FFFFFF'),
    ('savanna_plateau',
        '15845785', '#FFFFFF', '2461864', '#FFFFFF'),
    ('small_end_islands',
        '#FFFFFF', '#FFFFFF', '6443678', '#FFFFFF'),
    ('snowy_beach',
        '12375828', '#FFFFFF', '1336229', '#FFFFFF'),
    ('snowy_plains',
        '12244761', '#FFFFFF', '1332635', '#FFFFFF'),
    ('snowy_slopes',
        '11917093', '#FFFFFF', '4501493', '#FFFFFF'),
    ('snowy_taiga',
        '11786028', '#FFFFFF', '2121347', '#FFFFFF'),
    ('soul_sand_valley',
        '#FFFFFF', '#FFFFFF', '9460055', '#FFFFFF'),
    ('sparse_jungle',
        '14471367', '#FFFFFF', '887523', '#FFFFFF'),
    ('stony_peaks',
        '14667712', '#FFFFFF', '4501493', '#FFFFFF'),
    ('stony_shore',
        '12506894', '#FFFFFF', '878523', '#FFFFFF'),
    ('sunflower_plains',
        '13882332', '#FFFFFF', '4501493', '#FFFFFF'),
    ('swamp',
        '13882332', '#FFFFFF', '5006681', '#FFFFFF'),
    ('taiga',
        '12572427', '#FFFFFF', '2650242', '#FFFFFF'),
    ('the_end',
        '#FFFFFF', '#FFFFFF', '6443678', '#FFFFFF'),
    ('the_void',
        '13030905', '#FFFFFF', '#FFFFFF', '#FFFFFF'),
    ('warm_ocean',
        '13030905', '#FFFFFF', '176357', '#FFFFFF'),
    ('warped_forest',
        '#FFFFFF', '#FFFFFF', '9460055', '#FFFFFF'),
    ('windswept_forest',
        '12506894', '#FFFFFF', '943019', '#FFFFFF'),
    ('windswept_gravelly_hills',
        '12506894', '#FFFFFF', '943019', '#FFFFFF'),
    ('windswept_hills',
        '12506894', '#FFFFFF', '31735', '#FFFFFF'),
    ('windswept_savanna',
        '15845785', '#FFFFFF', '2461864', '#FFFFFF'),
    ('wooded_badlands',
        '16760159', '#FFFFFF', '5603486', '#FFFFFF')
)

def main_fn():
    # Get directory.
    biomes_dir = __file__

    if USE_BLENDER:
        import bpy
        biomes_dir = bpy.context.space_data.text.filepath

    biomes_dir = os.path.dirname(biomes_dir)



    # Debug; Check for missing biomes.
    if False:
        set0 = set(os.path.splitext(f)[0] for f in os.listdir(biomes_dir))
        set1 = set(i[0] for i in BIOMES_DATA)

        print('Missing in BIOMES_DATA:', set0 - set1)
        print('Missing in BIOMES_FOLDER:', set1 - set0)



    # Replace data.
    for biome, fog, sky, water, waterf in BIOMES_DATA:

        filepath = os.path.join(biomes_dir, f'{biome}.json')

        if not os.path.exists(filepath):
            print(f'JSON file not found: {biome}')
            continue

        with open(filepath, 'r') as f:
            file_json = json.load(f)

        file_json.setdefault('attributes', {})
        file_json.setdefault('effects', {})

        if not "#" in fog:
            file_json['attributes']['minecraft:visual/fog_color'] = int(fog)

        if not "#" in sky:
            file_json['attributes']['minecraft:visual/sky_color'] = int(sky)

        if not "#" in water:
            # decimal -> rgb * water_alpha -> decimal
            r = int( 0.6 * (int(water) // 65536) )
            g = int( 0.6 * (int(water) % 65536 // 256) )
            b = int( 0.6 * (int(water) % 256) )

            waterf = r * 65536 + g * 256 + b

            file_json['effects']['water_color'] = int(water)
            file_json['attributes']['minecraft:visual/water_fog_color'] = waterf

#        if not "#" in waterf:
#            file_json['effects']['water_fog_color'] = int(waterf)

        with open(filepath, 'w') as f:
            json.dump(file_json, f, indent=4)



    print(f'Patched: {biomes_dir}')

    return None

# =========

if __name__ == '__main__':
    main_fn()
