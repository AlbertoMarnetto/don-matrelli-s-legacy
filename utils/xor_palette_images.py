#! env python3

"""Utility to XOR palette indices of two indexed BMP images."""

from PIL import Image
import sys


def xor_palette_images(img1_path, img2_path, output_path, xoff=0, yoff=0):
    """Create a new image by XORing palette indices of two BMP images."""
    img1 = Image.open(img1_path)
    img2 = Image.open(img2_path)

    if img1.mode != 'P' or img2.mode != 'P':
        raise ValueError("Both images must be indexed palette (mode 'P') BMP images")

    w1, h1 = img1.size
    w2, h2 = img2.size
    out_w = max(w1, w2)
    out_h = max(h1, h2)

    pixels1 = img1.load()
    pixels2 = img2.load()

    result_img = Image.new('P', (out_w, out_h))
    result_pixels = result_img.load()

    for y in range(out_h):
        for x in range(out_w):
            idx1 = pixels1[x, y] if x < w1 and y < h1 else 0
            idx2 = pixels2[x - xoff, y - yoff] if (x - xoff) >= 0 and (x - xoff) < w2 and (y - yoff) >= 0 and (y - yoff) < h2 else 0
            result_pixels[x, y] = idx1 ^ idx2

    result_img.putpalette(img1.getpalette())
    result_img.save(output_path)
    print(f"Saved XORed image to {output_path}")


if __name__ == "__main__":
    if len(sys.argv) not in (4, 6):
        print(f"Usage: {sys.argv[0]} <image1.bmp> <image2.bmp> <output.bmp> [xoff yoff]")
        sys.exit(1)

    xoff = int(sys.argv[4]) if len(sys.argv) >= 6 else 0
    yoff = int(sys.argv[5]) if len(sys.argv) >= 6 else 0

    xor_palette_images(sys.argv[1], sys.argv[2], sys.argv[3], xoff, yoff)
