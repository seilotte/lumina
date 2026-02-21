'''
Developed for Minecraft 1.21.11.

TODO:
    - Use the same colours for hand(s) light(s).
'''

import os
import json

USE_BLENDER = False

LIGHTS_DATA = \
'''
# block_data;r;g;b;radius;attr_x;is_traced

minecraft:light:level=15;0.392;0.392;0.392;15.;0.9;true
minecraft:beacon;0.450;0.530;0.650;15.;0.9;true
minecraft:conduit;0.450;0.730;1.000;15.;0.9;true
minecraft:copper_lantern;0.570;0.780;0.580;15.;0.9;true
minecraft:exposed_copper_lantern;0.570;0.780;0.580;15.;0.9;true
minecraft:weathered_copper_lantern;0.570;0.780;0.580;15.;0.9;true
minecraft:oxidized_copper_lantern;0.570;0.780;0.580;15.;0.9;true
minecraft:waxed_copper_lantern;0.570;0.780;0.580;15.;0.9;true
minecraft:waxed_exposed_copper_lantern;0.570;0.780;0.580;15.;0.9;true
minecraft:waxed_weathered_copper_lantern;0.570;0.780;0.580;15.;0.9;true
minecraft:waxed_oxidized_copper_lantern;0.570;0.780;0.580;15.;0.9;true
minecraft:end_gateway;0.667;0.667;0.667;15.;0.9;true
minecraft:end_portal;0.667;0.667;0.667;15.;0.9;true
minecraft:fire;0.467;0.416;0.220;15.;0.9;true
minecraft:sea_pickle:pickles=4,waterlogged=true;0.392;0.392;0.392;15.;0.9;true
minecraft:ochre_froglight;0.588;0.863;0.525;15.;0.9;true
minecraft:verdant_froglight;0.569;0.765;0.510;15.;0.9;true
minecraft:pearlescent_froglight;0.698;0.541;0.741;15.;0.9;true
minecraft:glowstone;0.467;0.416;0.220;15.;0.9;true
minecraft:jack_o_lantern;0.467;0.416;0.220;15.;0.9;true
minecraft:lantern;0.467;0.416;0.220;15.;0.9;true
minecraft:lava;0.467;0.416;0.220;15.;0.9;true
minecraft:lava_cauldron;0.467;0.416;0.220;15.;0.9;true
minecraft:campfire:lit=true;0.467;0.416;0.220;15.;0.9;true
minecraft:redstone_lamp:lit=true;0.467;0.416;0.220;15.;0.9;true
minecraft:respawn_anchor:charges=4;0.514;0.031;0.894;15.;0.9;true
minecraft:sea_lantern;0.392;0.392;0.392;15.;0.9;true
minecraft:shroomlight;0.467;0.416;0.220;15.;0.9;true
minecraft:copper_bulb:lit=true;0.467;0.416;0.220;15.;0.9;true
minecraft:waxed_copper_bulb:lit=true;0.467;0.416;0.220;15.;0.9;true

minecraft:light:level=14;0.392;0.392;0.392;14.;0.9;true
minecraft:cave_vines_plant:berries=true;0.467;0.416;0.220;14.;0.9;true
minecraft:cave_vines:berries=true;0.467;0.416;0.220;14.;0.9;true
minecraft:copper_torch;0.570;0.780;0.580;14.;0.9;true
minecraft:copper_wall_torch;0.570;0.780;0.580;14.;0.9;true
minecraft:end_rod;0.667;0.667;0.667;14.;0.9;true
minecraft:torch;0.467;0.416;0.220;14.;0.9;true
minecraft:wall_torch;0.467;0.416;0.220;14.;0.9;true

minecraft:light:level=13;0.392;0.392;0.392;13.;0.9;true
minecraft:furnace:lit=true;0.467;0.416;0.220;13.;0.9;true
minecraft:blast_furnace:lit=true;0.467;0.416;0.220;13.;0.9;true
minecraft:smoker:lit=true;0.467;0.416;0.220;13.;0.9;true

minecraft:light:level=12;0.392;0.392;0.392;12.;0.9;true
minecraft:vault:vault_state=active;0.196;0.196;0.196;6.;0.9;true
minecraft:candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:white_candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:light_gray_candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:gray_candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:black_candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:brown_candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:red_candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:orange_candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:yellow_candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:lime_candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:green_candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:cyan_candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:light_blue_candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:blue_candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:purple_candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:magenta_candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:pink_candle:candles=4,lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:sea_pickle:pickles=3,waterlogged=true;0.392;0.392;0.392;12.;0.9;true
minecraft:exposed_copper_bulb:lit=true;0.467;0.416;0.220;12.;0.9;true
minecraft:waxed_exposed_copper_bulb:lit=true;0.467;0.416;0.220;12.;0.9;true

minecraft:light:level=11;0.392;0.392;0.392;11.;0.9;true
minecraft:nether_portal;0.514;0.031;0.894;11.;0.9;true
minecraft:respawn_anchor:charges=3;0.514;0.031;0.894;11.;0.9;true

minecraft:light:level=10;0.392;0.392;0.392;10.;0.9;true
minecraft:crying_obsidian;0.514;0.031;0.894;10.;0.9;true
minecraft:soul_campfire:lit=true;0.200;0.800;1.000;10.;0.9;true
minecraft:soul_fire;0.200;0.800;1.000;10.;0.9;true
minecraft:soul_lantern;0.200;0.800;1.000;10.;0.9;true
minecraft:soul_torch;0.200;0.800;1.000;10.;0.9;true
minecraft:soul_wall_torch;0.200;0.800;1.000;10.;0.9;true

minecraft:light:level=9;0.392;0.392;0.392;9.;0.9;true
minecraft:candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:white_candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:light_gray_candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:gray_candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:black_candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:brown_candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:red_candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:orange_candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:yellow_candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:lime_candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:green_candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:cyan_candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:light_blue_candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:blue_candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:purple_candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:magenta_candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:pink_candle:candles=3,lit=true;0.467;0.416;0.220;9.;0.9;true
minecraft:deepslate_redstone_ore:lit=true;1.000;0.200;0.200;9.;0.9;true
minecraft:redstone_ore:lit=true;1.000;0.200;0.200;9.;0.9;true
minecraft:sea_pickle:pickles=2,waterlogged=true;0.392;0.392;0.392;9.;0.9;true

minecraft:light:level=8;0.392;0.392;0.392;8.;0.9;true
minecraft:trial_spawner:trial_spawner_state=active;0.196;0.196;0.196;8.;0.9;true
minecraft:weathered_copper_bulb:lit=true;0.467;0.416;0.220;8.;0.9;true
minecraft:waxed_weathered_copper_bulb:lit=true;0.467;0.416;0.220;8.;0.9;true

minecraft:light:level=7;0.392;0.392;0.392;7.;0.9;true
minecraft:enchanting_table;0.502;0.275;0.000;7.;0.9;true
minecraft:ender_chest;0.392;0.392;0.392;7.;0.9;true
minecraft:glow_lichen;0.443;0.525;0.494;7.;0.9;true
minecraft:redstone_torch:lit=true;1.000;0.200;0.200;7.;0.9;true
minecraft:redstone_wall_torch:lit=true;1.000;0.200;0.200;7.;0.9;true
minecraft:respawn_anchor:charges=2;0.514;0.031;0.894;7.;0.9;true

minecraft:light:level=6;0.392;0.392;0.392;6.;0.9;true
minecraft:candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:white_candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:light_gray_candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:gray_candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:black_candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:brown_candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:red_candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:orange_candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:yellow_candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:lime_candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:green_candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:cyan_candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:light_blue_candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:blue_candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:purple_candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:magenta_candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:pink_candle:candles=2,lit=true;0.467;0.416;0.220;6.;0.9;true
minecraft:sea_pickle:pickles=1,waterlogged=true;0.392;0.392;0.392;6.;0.9;true
minecraft:sculk_catalyst;0.153;0.522;0.569;6.;0.9;true
minecraft:vault:vault_state=inactive;0.196;0.196;0.196;6.;0.9;true

minecraft:light:level=5;0.392;0.392;0.392;5.;0.9;true
minecraft:amethyst_cluster;0.478;0.357;0.710;5.;0.9;true

minecraft:light:level=4;0.392;0.392;0.392;4.;0.9;true
minecraft:large_amethyst_bud;0.478;0.357;0.710;4.;0.9;true
minecraft:oxidized_copper_bulb:lit=true;0.467;0.416;0.220;4.;0.9;true
minecraft:waxed_oxidized_copper_bulb:lit=true;0.467;0.416;0.220;4.;0.9;true
minecraft:trial_spawner:trial_spawner_state=waiting_for_players;0.196;0.196;0.196;4.;0.9;true
minecraft:trial_spawner:trial_spawner_state=waiting_for_reward_ejection;0.196;0.196;0.196;4.;0.9;true

minecraft:light:level=3;0.392;0.392;0.392;3.;0.9;true
minecraft:candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:white_candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:light_gray_candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:gray_candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:black_candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:brown_candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:red_candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:orange_candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:yellow_candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:lime_candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:green_candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:cyan_candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:light_blue_candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:blue_candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:purple_candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:magenta_candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:pink_candle:candles=1,lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:white_candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:light_gray_candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:gray_candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:black_candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:brown_candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:red_candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:orange_candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:yellow_candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:lime_candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:green_candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:cyan_candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:light_blue_candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:blue_candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:purple_candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:magenta_candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:pink_candle_cake:lit=true;0.467;0.416;0.220;3.;0.9;true
minecraft:magma_block;0.467;0.416;0.220;3.;0.9;true
minecraft:respawn_anchor:charges=1;0.514;0.031;0.894;3.;0.9;true

minecraft:light:level=2;0.392;0.392;0.392;2.;0.9;true
minecraft:medium_amethyst_bud;0.478;0.357;0.710;2.;0.9;true
minecraft:firefly_bush;0.910;0.765;0.596;2.;0.9;true

minecraft:light:level=1;0.392;0.392;0.392;1.;0.9;true
minecraft:brewing_stand;0.467;0.416;0.220;1.;0.9;true
minecraft:brown_mushroom;0.590;0.430;0.300;1.;0.9;true
minecraft:calibrated_sculk_sensor;0.153;0.522;0.569;1.;0.9;true
minecraft:dragon_egg;0.196;0.196;0.196;1.;0.9;true
minecraft:end_portal_frame;0.667;0.667;0.667;1.;0.9;true
minecraft:sculk_sensor;0.153;0.522;0.569;1.;0.9;true
minecraft:small_amethyst_bud;0.478;0.357;0.710;1.;0.9;true



minecraft:torchflower;0.850;0.350;0.100;14.;0.9;false
minecraft:torchflower_crop;0.850;0.350;0.100;14.;0.9;false
minecraft:pitcher_plant;0.100;0.200;0.300;10.;0.9;false
minecraft:pitcher_crop;0.100;0.200;0.300;10.;0.9;false
minecraft:open_eyeblossom;1.000;0.500;0.250;14.;0.9;false

minecraft:repeater:powered=true;1.000;0.200;0.200;7.;0.9;false
minecraft:comparator:powered=true;1.000;0.200;0.200;7.;0.9;false
minecraft:comparator:mode=subtract;1.000;0.200;0.200;7.;0.9;false
minecraft:redstone_wire;1.000;0.200;0.200;7.;0.9;false

minecraft:sculk_shrieker;0.890;0.925;0.894;1.;0.9;false

minecraft:amethyst_block;0.478;0.357;0.710;15.;0.9;false
minecraft:emerald_block;0.090;0.867;0.384;15.;0.9;false
minecraft:lapis_block;0.114;0.290;0.584;15.;0.9;false
minecraft:redstone_block;1.000;0.200;0.200;15.;0.9;false

'''

JSON_COMMENT = \
'''/*
    TODO:
        - Use the same colours for hand(s) light(s).

    radius:
        - light.attenuation.y = 1 / radius
        - affects rt
    intensity:
        - light.color *= (intensity / 100)
    falloff:
        - light.falloff = falloff
        - idk, docs say [0, 1]
*/'''



def main_fn():

    # Parse data.
    OVERRIDES = {}
    counter = 0

    for line in LIGHTS_DATA.splitlines():
        line = line.strip()

        if not line \
        or not line.startswith('minecraft:'):
            continue

        data = line.split(';')

        if len(data) != 7: # block;r;g;b;radius;attr_x;is_traced
            continue


        # key = f'{radius:02}_{block_parts[1]}'
        key = f'light_{counter}'
        counter += 1

        block = data[0]
        block_parts = data[0].split(':')

        if len(block_parts) > 2:
            '''
            From: minecraft:candle:candles=4,lit=true
            To:   minecraft:candle[candles=4, lit=true]
            '''
            namespace, block, *props = block_parts
            props_str = ':'.join(props).replace(',',', ')

            block = f'{namespace}:{block}[{props_str}]'

        r = round(float(data[1]), 2)
        g = round(float(data[2]), 2)
        b = round(float(data[3]), 2)

        radius = int(float(data[4]) + 0.5)

        # attr_x = float(data[5])

        is_traced = data[6].lower() == "true"



        OVERRIDES[key] = {
            "radius": radius,
            "color": f'rgb({r}, {g}, {b})',
            "blocks": [ block ]
        }

        if is_traced is False:
            OVERRIDES[key]["is_traced"] = is_traced



    # Get directory.
    current_dir = __file__

    if USE_BLENDER:
        import bpy
        current_dir = bpy.context.space_data.text.filepath

    current_dir = os.path.dirname(current_dir)
    parent_dir = os.path.abspath(os.path.join(current_dir, os.pardir))

    # TODO: Use a writable location (no admin).
    os.makedirs(parent_dir, exist_ok = True) # always exists



    # Create file.
    json_final = \
    {
        "lights": {
            "minecraft": {
                "radius": 15,
                "intensity": 100,
                "falloff": 1,
                "color": "#ffffff",
                "is_traced": True,
                "overrides": OVERRIDES
            }
        }
    }

    filepath = os.path.join(parent_dir, 'ph_lights.json')

    with open(filepath, 'w') as f:
        f.write(JSON_COMMENT)
        f.write('\n\n')

        json.dump(json_final, f, indent=4)
        f.write('\n')



    print(f'Created: {filepath}')

    return None

# =========

if __name__ == '__main__':
    main_fn()
