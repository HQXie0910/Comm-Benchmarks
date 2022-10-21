# !usr/bin/env python
# -*- coding:utf-8 _*-

import argparse
from PIL import Image
from tqdm import tqdm
import os

parser = argparse.ArgumentParser()
parser.add_argument('--input-path', default='...', type=str, help='The PATH to load input images')
parser.add_argument('--output-path', default='....', type=str, help='The PATH to store the output images')


args = parser.parse_args()
images = os.listdir(args.input_path)
if not os.path.exists(args.output_path):
    os.makedirs(args.output_path)
for image in tqdm(images):
    image_path = os.path.join(args.input_path, image)
    img = Image.open(image_path)
    img = img.convert('RGB')
    image_name = '_'.join(os.path.splitext(image)[0].split('_')[1:])
    output_image = os.path.join(args.output_path, image_name + '.webp')
    img.save(output_image, 'webp')

print('finished source compression')
