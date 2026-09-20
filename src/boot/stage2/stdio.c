#include "stdio.h"
#include "x86.h"

#define VGA ((volatile uint16_t*)0xB8000)
#define WIDTH 80
#define HEIGHT 25

uint8_t sx = 0;
uint8_t sy = 0;
uint8_t color = 0x0F;

void putchar(uint8_t x, uint8_t y, char character) {
    VGA[y * WIDTH + x] = ((uint16_t)color << 8) | (uint8_t)character;
}

void set_cursor(uint8_t x, uint8_t y) {
    uint16_t position = (y * WIDTH) + x;

    outb(0x3D4, 0x0F);
    outb(0x3D5, position & 0xFF);

    outb(0x3D4, 0x0E);
    outb(0x3D5, (position >> 8) & 0xFF);
}

void scroll(void) {
    for (uint8_t y = 1; y < HEIGHT; y++) {
        for (uint8_t x = 0; x < WIDTH; x++) {
            VGA[(y - 1) * WIDTH + x] = VGA[y * WIDTH + x];
        }
    }

    for (uint8_t x = 0; x < WIDTH; x++) {
        VGA[(HEIGHT - 1) * WIDTH + x] =
            ((uint16_t)color << 8) | ' ';
    }

    sy = HEIGHT - 1;
}

void putc(char c) {
    switch (c) {
        case '\n':
            sx = 0;
            sy++;
            break;

        case '\r':
            sx = 0;
            break;

        default:
            putchar(sx, sy, c);
            sx++;

            if (sx == WIDTH) {
                sx = 0;
                sy++;
            }

            break;
    }

    if (sy == HEIGHT) {
        scroll();
    }

    set_cursor(sx, sy);
}

void puts(const char *s) {
    while (*s) {
        putc(*s++);
    }
}