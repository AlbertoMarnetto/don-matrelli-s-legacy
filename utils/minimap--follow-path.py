#! env python3

from PIL import Image
import sys

def load_image(filename):
    img = Image.open(filename)
    return img.convert('RGB')

def is_track(r, g, b):
    return r == 0 and g == 0 and b == 0

def find_leftmost_track_pixel(img):
    width, height = img.size
    for x in range(width):
        for y in range(height):
            r, g, b = img.getpixel((x, y))
            if is_track(r, g, b):
                return (x, y)
    return None

def dfs_track_pixels(img, start):
    width, height = img.size
    visited = set()
    current = start
    result = []
    
    directions = [(1, 0), (0, 1), (-1, 0), (0, -1), (1, 1), (-1, 1), (-1, -1), (1, -1)]
    
    while current is not None:
        result.append(current)
        visited.add(current)
        x, y = current
        
        next_pixel = None
        for dx, dy in directions:
            nx, ny = x + dx, y + dy
            if 0 <= nx < width and 0 <= ny < height:
                if (nx, ny) not in visited:
                    r, g, b = img.getpixel((nx, ny))
                    if is_track(r, g, b):
                        next_pixel = (nx, ny)
                        break
        
        current = next_pixel
    
    return result

def print_ascii_art(img, path):
    order = {}
    for i, (x, y) in enumerate(path):
        order[(x, y)] = i
    
    max_idx = len(path) - 1
    gradient = '0123456789abcdef'
    
    width, height = img.size
    for y in range(height):
        line = ''
        for x in range(width):
            if (x, y) in order:
                idx = order[(x, y)]
                pos = idx * (len(gradient) - 1) // max_idx
                line += gradient[pos]
            else:
                line += '.'
        print(f"{y:3d}: {line}")

def main():
    import sys
    
    show_art = '--art' in sys.argv
    args = [a for a in sys.argv if a != '--art']
    
    if len(args) < 4:
        print(f"Usage: python3 {sys.argv[0]} <bmp_file> <x> <y> [--art]")
        return
    
    filename = args[1]
    x = int(args[2])
    y = int(args[3])
    start_coords = (x, y)
    
    img = load_image(filename)
    width, height = img.size
    
    if start_coords is None:
        print("No track pixel found")
        return
    
    x, y = start_coords
    if not (0 <= x < width and 0 <= y < height):
        print(f"Error: coordinates ({x},{y}) out of bounds")
        return
    
    r, g, b = img.getpixel((x, y))
    if not is_track(r, g, b):
        print(f"Error: pixel ({x},{y}) is not track (RGB=({r},{g},{b}))")
        return
    
    print(f"Starting pixel: {start_coords}")
    
    path = dfs_track_pixels(img, start_coords)
    
    if show_art:
        print_ascii_art(img, path)
    else:
        print("Visited pixels:")
        for coord in path:
            print(coord)

if __name__ == '__main__':
    main()
