#!/usr/bin/env python

# adc/xor routine from:
# https://stackoverflow.com/questions/17411712/finding-seeds-for-a-5-byte-prng

# Pretty good choices for 8 bit seeds
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

def get_prng8(bits, adc, xor):
    order = []
    r = 0
    for i in range(2**bits):
        r=(((r>>(bits-1)) & 1)+r+r+adc)^xor
        r&=(1<<(bits-1)) | ((1<<(bits-1))-1)
        order.append(r)
    return order


if __name__ == '__main__':
    gen_16_bit = False
    summary = True
    show = True

    if gen_16_bit:
        random_bits = 16
    else:
        random_bits = 8

    valid_seeds = []
    mc = 0
    for BITS in range(2, random_bits + 1):

        adc = 1  # Only odd add values produce useful results
        while True:
            xor = 1  # Only odd add values produce useful results
            while True:
                r = 0
                c = ~0
                values = []
                while True:
                    r=(((r>>(BITS-1)) & 1)+r+r+adc)^xor
                    r&=(1<<(BITS-1)) | ((1<<(BITS-1))-1)
                    c += 1
                    values.append(r)
                    if r == 0:
                        break
                if c >= mc:
                    mc = c
                    valid_seeds.append((BITS, adc, xor))
                    if not summary:
                        print("BITS: %d adc: %04x, xor: %04x" % (BITS, adc, xor))
                xor += 2
                xor &= (1<<(BITS-1)) | ((1<<(BITS-1))-1)
                if xor == 1:
                    break
            adc += 2
            adc &= ((1<<(BITS-1))-1)  # * Do not check complements
            if adc == 1:
                break

    if summary:
        for bits, adc, xor in valid_seeds:
            print("BITS: %d adc(adc): %04x, xor(eor): %04x" % (bits, adc, xor))
            if show:
                values = get_prng8(bits, adc, xor)
                unique_check = set(values)
                if len(values) == len(unique_check):
                    print("%d: %s" % (len(values), str(values)))
                else:
                    print("Failed unique check")
