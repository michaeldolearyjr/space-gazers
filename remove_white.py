import os
from PIL import Image

def remove_white(image_path):
    try:
        img = Image.open(image_path)
        img = img.convert("RGBA")
        datas = img.getdata()

        new_data = []
        for item in datas:
            # Check if pixel is white or very close to white
            if item[0] > 240 and item[1] > 240 and item[2] > 240:
                new_data.append((255, 255, 255, 0)) # Transparent
            else:
                new_data.append(item)

        img.putdata(new_data)
        img.save(image_path, "PNG")
        print(f"Processed: {image_path}")
    except Exception as e:
        print(f"Failed processing {image_path}: {e}")

images_dir = r"d:\Projects\space-gazers\assets\images"
for filename in os.listdir(images_dir):
    if filename.endswith(".png"):
        remove_white(os.path.join(images_dir, filename))
