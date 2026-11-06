#!/usr/bin/env python3
"""Builds pizzahutmy/Resources/Assets.xcassets from assets-source/.

Asset naming rule (mirrored in Swift by CatalogImage.assetName(for:)):
  "img/products/super-supreme-q2.jpg" -> "products-super-supreme-q2"
Run from the ios/ folder: python3 scripts/build_assets.py
"""
import json
import os
import shutil

IOS = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(IOS, 'assets-source')
RES = os.path.join(IOS, 'pizzahutmy', 'Resources')
XC = os.path.join(RES, 'Assets.xcassets')


def asset_name(rel_path):
    stem = os.path.splitext(rel_path)[0]
    if stem.startswith('img/'):
        stem = stem[4:]
    return stem.replace('/', '-')


def write_json(path, data):
    with open(path, 'w') as f:
        json.dump(data, f, indent=2)


def color_set(name, hex_light):
    r, g, b = (int(hex_light[i:i + 2], 16) / 255 for i in (1, 3, 5))
    d = os.path.join(XC, name + '.colorset')
    os.makedirs(d, exist_ok=True)
    write_json(os.path.join(d, 'Contents.json'), {
        'colors': [{'idiom': 'universal', 'color': {'color-space': 'srgb', 'components': {
            'red': '%.3f' % r, 'green': '%.3f' % g, 'blue': '%.3f' % b, 'alpha': '1.000'}}}],
        'info': {'author': 'xcode', 'version': 1}})


def main():
    if os.path.exists(XC):
        shutil.rmtree(XC)
    os.makedirs(XC)
    write_json(os.path.join(XC, 'Contents.json'), {'info': {'author': 'xcode', 'version': 1}})

    count = 0
    img_root = os.path.join(SRC, 'img')
    for folder, _, files in os.walk(img_root):
        for fname in sorted(files):
            if fname.startswith('.'):
                continue
            rel = os.path.relpath(os.path.join(folder, fname), SRC)
            name = asset_name(rel)
            d = os.path.join(XC, name + '.imageset')
            os.makedirs(d)
            shutil.copy(os.path.join(folder, fname), os.path.join(d, fname))
            write_json(os.path.join(d, 'Contents.json'), {
                'images': [{'idiom': 'universal', 'filename': fname, 'scale': '2x'}],
                'info': {'author': 'xcode', 'version': 1}})
            count += 1

    icon = os.path.join(XC, 'AppIcon.appiconset')
    os.makedirs(icon)
    shutil.copy(os.path.join(img_root, 'brand', 'app-icon-1024.png'), os.path.join(icon, 'app-icon-1024.png'))
    write_json(os.path.join(icon, 'Contents.json'), {
        'images': [{'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024', 'filename': 'app-icon-1024.png'}],
        'info': {'author': 'xcode', 'version': 1}})

    color_set('AccentColor', '#CE2828')
    color_set('BrandRed', '#CE2828')

    shutil.copy(os.path.join(SRC, 'data', 'catalog.json'), os.path.join(RES, 'catalog.json'))
    print('imagesets: %d' % count)


if __name__ == '__main__':
    main()
