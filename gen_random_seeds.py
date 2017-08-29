#!/usr/bin/env python

import numpy as np

# prng16:
#     lsr rand+1
#     ror rand
#     bcc skip
#     lda rand+1
#     ; $60 = 1..32767, see table above
#     eor #$60
#     sta rand+1
# skip:
#     rts

# rand:
#     ; seed mustn't be zero!
#     .byte $01,$00

# lfsr_order = [
#     (0x03, 0x03, ),
#     (0x07, 0x06, ),
#     (0x0f, 0x0c, ),
#     (0x1f, 0x14, ),
#     (0x3f, 0x30, ),
#     (0x7f, 0x60, ),
#     (0xff, 0xb8, ),
#     ]

# def get_prng(framenum):
#     if framenum < 0 or framenum > 6:
#         return []
#     seed = 0x843f
#     period, term = lfsr_order[framenum]
#     order = []
#     seed = (seed & period) | 0x01
#     for i in range(period):
#         rand = seed >> 1
#         if seed & 0x01:
#             rand ^= term
#         #order.append((rand & period) - 1 - period // 2 + 96)
#         #print("%d seed=%x rand=%x &period=%x" % (i, seed, rand, rand & period))
#         order.append((rand & period))
#         seed = rand
#     return order


# adc/xor routine from:
# https://stackoverflow.com/questions/17411712/finding-seeds-for-a-5-byte-prng


adcxor_order = [
    (3, 0x07, 0x3, 0x7),
    (4, 0x0f, 0x7, 0xd),
    (5, 0x1f, 0x9, 0x1f),
    (6, 0x3f, 0x7, 0x17),
    (7, 0x7f, 0x15, 0x5b),
    (8, 0xff, 0x3b, 0x3f),
]

def get_prng(framenum):
    if framenum < 0 or framenum > 5:
        return []
    BITS, period, num1, num2 = adcxor_order[framenum]
    order = []
    r = 0
    for i in range(period):
        r=(((r>>(BITS-1)) & 1)+r+r+num1)^num2
        r&=(1<<(BITS-1)) | ((1<<(BITS-1))-1)
        order.append(r)
    return order

adcxor_8bit = [
   (0x03, 0x045),
   (0x03, 0x073),
   (0x03, 0x085),
   (0x03, 0x0b3),
   (0x0d, 0x04d),
   (0x0d, 0x08d),
   (0x23, 0x033),
   (0x23, 0x0f3),
   (0x3b, 0x03f),
   (0x3b, 0x0ff),
   (0x45, 0x07f),
   (0x45, 0x0bf),
   (0x5d, 0x073),
   (0x5d, 0x0b3),
   (0x73, 0x00d),
   (0x73, 0x0cd),
   (0x7d, 0x005),
   (0x7d, 0x033),
   (0x7d, 0x0c5),
   (0x7d, 0x0f3),
   ]

def get_prng8(framenum):
    num1, num2 = adcxor_8bit[framenum]
    order = []
    r = 0
    BITS = 8
    for i in range(255):
        r=(((r>>(BITS-1)) & 1)+r+r+num1)^num2
        r&=(1<<(BITS-1)) | ((1<<(BITS-1))-1)
        order.append(r)
    return order


if __name__ == '__main__':
    gen_16_bit = False
    summary = False

    if gen_16_bit:
        random_bits = 16
    else:
        random_bits = 8

    valid_seeds = []
    for BITS in range(2, random_bits + 1):
        mc = 0

        num1 = 1
        while True:
            num2 = 1
            while True:
                r = 0
                c = 0
                values = []
                while True:
                    r=(((r>>(BITS-1)) & 1)+r+r+num1)^num2
                    r&=(1<<(BITS-1)) | ((1<<(BITS-1))-1)
                    c += 1
                    values.append(r)
                    if r == 0:
                        break
                if c == (1 << BITS):
                    #print("BITS: %d Num1(adc): %04x, Num2(eor): %04x count=%d values=%s" % (BITS, num1, num2, len(values), ",".join("%x" % x for x in values)))
                    valid_seeds.append((BITS, num1, num2))
                    print("BITS: %d Num1(adc): %04x, Num2(eor): %04x" % (BITS, num1, num2))
                # if c >= mc:
                #     mc = c
                #     print("BITS: %x Count-1: %04x, Num1(adc): %04x, Num2(eor): %04x\n" % (BITS, c, num1, num2))
                num2 += 2
                num2 &= (1<<(BITS-1)) | ((1<<(BITS-1))-1)
                if num2 == 1:
                    break
            num1 += 2
            num1 &= ((1<<(BITS-1))-1)  # * Do not check complements
            if num1 == 1:
                break

    if summary:
        for bits, num1, num2 in valid_seeds:
            print("BITS: %d Num1(adc): %04x, Num2(eor): %04x" % (bits, num1, num2))
