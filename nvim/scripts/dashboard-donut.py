"""A small ANSI donut animation for the Snacks dashboard (standard library only)."""

import math
import sys
import time


SHADES = '.,-~:;=!*#$@'
COLORS = ('\033[38;2;117;117;129m', '\033[38;2;172;161;207m', '\033[38;2;230;185;157m')
POINTS = []
for u in range(80):
    theta = u * math.tau / 80
    for v in range(28):
        phi = v * math.tau / 28
        ct, st = math.cos(theta), math.sin(theta)
        cp, sp = math.cos(phi), math.sin(phi)
        POINTS.append(((1.8 + 0.75 * cp) * ct, (1.8 + 0.75 * cp) * st, 0.75 * sp,
                       cp * ct, cp * st, sp))


def frame(width, height, elapsed):
    a, b = 0.7 + elapsed * 0.8, elapsed * 0.35
    ca, sa, cb, sb = math.cos(a), math.sin(a), math.cos(b), math.sin(b)
    pixels = [[' '] * width for _ in range(height)]
    shades = [[0] * width for _ in range(height)]
    depth = [[0.0] * width for _ in range(height)]
    scale = min(height * 2.15, width * 0.9)

    for x, y, z, nx, ny, nz in POINTS:
        ry, rz = y * ca - z * sa, y * sa + z * ca
        rx, ry = x * cb - ry * sb, x * sb + ry * cb
        inverse = 1.0 / (rz + 6)
        col = int(width / 2 + scale * inverse * rx)
        row = int(height / 2 + scale * inverse * ry * 0.45)
        if not (0 <= col < width and 0 <= row < height) or inverse <= depth[row][col]:
            continue

        ly, lz = ny * ca - nz * sa, ny * sa + nz * ca
        lx, ly = nx * cb - ly * sb, nx * sb + ly * cb
        light = max(0.0, min(1.0, -0.3 * lx - 0.6 * ly - 0.74 * lz))
        pixels[row][col] = SHADES[int(light * (len(SHADES) - 1))]
        shades[row][col] = 2 if light > 0.75 else 1 if light > 0.25 else 0
        depth[row][col] = inverse

    # Sparse stars stay outside the donut and twinkle slowly.
    for index, (fx, fy) in enumerate(((0.12, 0.2), (0.22, 0.75), (0.82, 0.3), (0.9, 0.8))):
        col, row = int(width * fx), int(height * fy)
        if pixels[row][col] == ' ':
            pixels[row][col] = '.+*+'[(int(elapsed * 1.5) + index) % 4]

    lines = []
    for row in range(height):
        parts, previous = [], None
        for col in range(width):
            color = shades[row][col]
            if color != previous:
                parts.append(COLORS[color])
                previous = color
            parts.append(pixels[row][col])
        lines.append(''.join(parts) + '\033[0m')
    return '\r\n'.join(lines)


def main():
    width, height = int(sys.argv[1]), int(sys.argv[2])
    start = time.monotonic()
    sys.stdout.write('\033[?25l\033[?7l\033[2J')
    try:
        while True:
            tick = time.monotonic()
            sys.stdout.write('\033[H' + frame(width, height, tick - start))
            sys.stdout.flush()
            time.sleep(max(0, 1 / 12 - (time.monotonic() - tick)))
    except (BrokenPipeError, KeyboardInterrupt):
        pass


if __name__ == '__main__':
    main()
