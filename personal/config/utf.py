# UTF encoding inspector — shows hex bytes, colored binary, and data bits
# for a character or code point in UTF-8, UTF-16, or UTF-32.
# Called via shell functions: utf-8, utf-16, utf-32
# Usage: python3 utf.py <8|16|32> <char|hex|U+hex> [-v]
import sys, re

Y, C, G, D, R = '\033[93m', '\033[96m', '\033[92m', '\033[90m', '\033[0m'

def resolve(s):
    return s

def plen(b):
    if b >> 7 == 0:  return 1
    if b >> 6 == 2:  return 2
    if b >> 5 == 6:  return 3
    if b >> 4 == 14: return 4
    if b >> 3 == 30: return 5
    return 0

def display(enc, char, verbose=False):
    enc_name = {8: 'utf-8', 16: 'utf-16-be', 32: 'utf-32-be'}[enc]
    raw = char.encode(enc_name)

    cp = ord(char)
    hex_str = ' '.join(f'{b:02X}' for b in raw)

    cp_hex = f'{cp:04X}'
    cp_bin_raw = bin(cp)[2:]
    cp_pad = (4 - len(cp_bin_raw) % 4) % 4
    cp_bin_padded = '0' * cp_pad + cp_bin_raw
    cp_bin_fmt = ' '.join(cp_bin_padded[i:i+4] for i in range(0, len(cp_bin_padded), 4))

    hex_colored = ' '.join(f'{G}{b:02X}{R}' for b in raw)
    bin_parts, data_bits = [], ''
    for b in raw:
        pl = plen(b) if enc == 8 else 0
        bits = f'{b:08b}'
        colored = ''
        for i, bit in enumerate(bits):
            if pl > 0 and i < pl:
                colored += f'{C if pl == 2 else Y}{bit}{R}'
            else:
                colored += f'{G}{bit}{R}'
                if pl > 0:
                    data_bits += bit
            if i == 3:
                colored += ' '
        bin_parts.append(colored)

    is_ascii = enc == 8 and cp < 128
    is_multibyte = enc == 8 and cp >= 128

    n_bytes = len(raw)

    if not verbose:
        all_bits = ''.join(f'{b:08b}' for b in raw)
        bin_nibbles = ' '.join(all_bits[i:i+4] for i in range(0, len(all_bits), 4))
        print(f'hex -> {hex_str}')
        print(f'bin -> {bin_nibbles}')
        return

    utf_label = f'UTF-{enc}'
    print(f'  code point')
    print(f'    hex           U+{cp_hex}')
    print(f'    bin           {cp_bin_fmt}')
    print()
    print(f'  {utf_label}')
    print(f'    hex           {hex_colored}')
    print(f'    bin           {" ".join(bin_parts)}')


    if enc == 8 and data_bits:
        fb = raw[0]
        fp = plen(fb)
        info = {1: (1, '0'),   3: (2, '110'),
                4: (3, '1110'), 5: (4, '11110')}
        n, prefix = info[fp]

        pad = (4 - len(data_bits) % 4) % 4
        padded = '0' * pad + data_bits
        nibbles = ' '.join(padded[i:i+4] for i in range(0, len(padded), 4))
        colored_data = ''
        pos = 0
        for ch in nibbles:
            if ch == ' ':
                colored_data += ' '
            elif pos < pad:
                colored_data += f'{D}{ch}{R}'
                pos += 1
            else:
                colored_data += f'{G}{ch}{R}'
                pos += 1

        if verbose:
            if is_ascii:
                print(f'\n{D}Along with the code point, UTF-8 stores:{R}')
                print(f'{D}  {Y}{prefix}{D} — bytes to read indicator (1 byte, single byte marker){R}')
                print(f'{D}No {C}follow marker{D} since it\'s 1 byte, and {Y}bytes to read{D} is {Y}0{D}{R}')
                print(f'{D}(meaning 1 byte) which doesn\'t affect the value —{R}')
                print(f'{D}that\'s why stored hex ({Y}{hex_str}{D}) matches code point ({G}U+{cp:04X}{D}).{R}')
            else:
                print(f'\n{D}Along with the code point, UTF-8 stores:{R}')
                print(f'{D}  {Y}{prefix}{D} — bytes to read indicator (how many bytes to read){R}')
                print(f'{D}  {C}10{D}  — follow marker (on each following byte){R}')
                print(f'{D}Stored hex ({Y}{hex_str}{D}) = {Y}bytes to read{D} + {C}follow marker{D} + {G}code point{D},{R}')
                print(f'{D}that\'s why it differs from code point ({G}U+{cp:04X}{D}).{R}')

            def vlen(s):
                return len(re.sub(r'\033\[[0-9;]*m', '', s))
            def print_table(header, rows):
                all_r = [header] + rows
                widths = [max(vlen(r[i]) for r in all_r) + 2 for i in range(len(header))]
                print('┌' + '┬'.join('─'*w for w in widths) + '┐')
                print('│' + '│'.join(f' {header[i]}{" "*(widths[i]-vlen(header[i])-2)} ' for i in range(len(header))) + '│')
                print('├' + '┼'.join('─'*w for w in widths) + '┤')
                for row in rows:
                    print('│' + '│'.join(f' {row[i]}{" "*(widths[i]-vlen(row[i])-2)} ' for i in range(len(row))) + '│')
                print('└' + '┴'.join('─'*w for w in widths) + '┘')

            print()
            print_table(
                (f'{D}term{R}', f'{D}meaning{R}'),
                [
                    (f'{Y}bytes to read{R}', f'{D}how many bytes are used to store this character{R}'),
                    (f'{C}follow marker{R}', f'{D}10 on each following byte, lets decoder find start bytes{R}'),
                    (f'{G}code point{R}',    f'{D}the actual character bits, after stripping indicators{R}'),
                ],
            )

            print(f'\n{D}UTF-8 table — how many bytes used to store the character:{R}')
            print_table(
                (f'{D}first byte\'s reserved bits{R}', f'{D}bytes{R}'),
                [
                    (f'{Y}0{D}xxx xxxx{R}',     f'{D}1 byte (ASCII){R}'),
                    (f'{Y}110{D}x xxxx{R}',     f'{D}2 bytes{R}'),
                    (f'{Y}1110{D} xxxx{R}',     f'{D}3 bytes{R}'),
                    (f'{Y}1111{D} {Y}0{D}xxx{R}',     f'{D}4 bytes{R}'),
                ],
            )
            print(f'\n{D}each byte after the first (for multi-byte characters):{R}')
            print_table(
                (f'{D}reserved bits{R}', f'{D}meaning{R}'),
                [
                    (f'{C}10{D}xx xxxx{R}', f'{D}not a start byte, xx xxxx belongs to the previous one.{R}'),
                    (f'', f'{D}lets decoder skip to the next start byte if it{R}'),
                    (f'', f'{D}lands mid-sequence.{R}'),
                ],
            )

args = sys.argv[1:]
enc = int(args.pop(0))
verbose = '-v' in args
args = [a for a in args if a != '-v']
if not args:
    print('usage: utf-8 <char> [-v]')
    sys.exit(1)
char = resolve(args[0])

if len(char) > 1:
    print(f'expected a single character, got "{char}"')
    sys.exit(1)

display(enc, char, verbose)
