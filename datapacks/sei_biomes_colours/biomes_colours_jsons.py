import os
import json

biomes_dir = "path/to/the/biome/folder"
biomes_data = []

with open(os.path.join(biomes_dir, "biomes_colours.txt"), 'r') as f:
    for line in f:
        line = line.strip()

        if line.startswith('biome'):
            continue

        part = line.split()

        if len(part) < 2:
            continue

        biomes_data.append(part)

for biome, fog, sky, water, waterf in biomes_data:

    filepath = os.path.join(biomes_dir, f'{biome}.json')

    if not os.path.exists(filepath):
        print(f'JSON file not found: {biome}')
        continue

    with open(filepath, 'r') as f:
        file_json = json.load(f)

    if not "#" in fog:
        file_json['effects']['fog_color'] = int(fog)

    if not "#" in sky:
        file_json['effects']['sky_color'] = int(sky)

    if not "#" in water:
        file_json['effects']['water_color'] = int(water)

        # decimal -> rgb * water_alpha -> decimal
        x = int(water)

        r = int( 0.6 * (x // 65536) )
        g = int( 0.6 * (x % 65536 // 256) )
        b = int( 0.6 * (x % 256) )

        d = r * 65536 + g * 256 + b

        file_json['effects']['water_fog_color'] = d

#    if not "#" in waterf:
#        file_json['effects']['water_fog_color'] = int(waterf)

    with open(filepath, 'w') as f:
        json.dump(file_json, f, indent=4)

print("Done")
