# UTF encoding inspector — shows hex bytes, colored binary, and data bits
# for a character or code point in UTF-8, UTF-16, or UTF-32.
# Called via shell functions: utf-8, utf-16, utf-32
# Usage: python3 utf.py <8|16|32> <char|hex|U+hex> [-v]
import sys, re

Y, C, G, D, R = '\033[93m', '\033[96m', '\033[92m', '\033[90m', '\033[0m'

def resolve(s):
    s = re.sub(r'^[Uu]\+', '', s)
    if len(s) > 1 and re.match(r'^[0-9a-fA-F]+$', s):
        return chr(int(s, 16))
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

    print(f'{D}── code point ──{R}')
    print(f'  U+              U+{cp_hex}')
    print(f'  hex             0x{cp_hex}')
    print(f'  bin             {cp_bin_fmt}')

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

    print(f'\n{D}── stored (UTF-{enc}) ──{R}')
    print(f'  hex             {hex_colored}')
    print(f'  bin             {" ".join(bin_parts)}')


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
            rows = [
                (f'{Y}bytes to read{R}', f'{Y}{prefix} ({n} bytes){R}'),
            ]
            if n > 1:
                rows.append((f'{C}continuation{R}', f'{C}10{R}'))
            rows.append((f'{G}code point{R}', colored_data))

            def vlen(s):
                return len(re.sub(r'\033\[[0-9;]*m', '', s))

            lw = max(vlen(l) for l, _ in rows) + 2
            rw = max(vlen(v) for _, v in rows) + 2
            print(f'\n┌{"─"*lw}┬{"─"*rw}┐')
            for label, val in rows:
                lpad = lw - vlen(label) - 2
                rpad = rw - vlen(val) - 2
                print(f'│ {label}{" "*lpad} │ {val}{" "*rpad} │')
            print(f'└{"─"*lw}┴{"─"*rw}┘')

            is_ascii = cp < 128
            if is_ascii:
                print(f'\n{D}1 byte. Leading {Y}0{D} bit is the indicator (single byte marker).{R}')
                print(f'{D}Remaining 7 bits are the code point directly (U+{cp:04X} = 0x{cp:02X}).{R}')
            else:
                print(f'\n{D}{n} bytes. Along with the code point, UTF-8 stores:{R}')
                print(f'{D}  {Y}{prefix}{D} — byte count indicator (how many bytes to read){R}')
                print(f'{D}  {C}10{D}  — continuation marker (on each following byte){R}')
                print(f'{D}This is why stored hex ({Y}0x{hex_str}{D}) differs from code point ({G}U+{cp:04X}{D}).{R}')
                print(f'\n{Y}bytes to read{R}  {D}how many bytes are used to store this character{R}')
                print(f'{C}continuation{R}  {D}without 10, jumping into the middle of a file you can\'t tell{R}')
                print(f'              {D}if a byte is a new character or part of a previous one.{R}')
                print(f'              {D}10 lets the decoder skip forward until it finds a start byte.{R}')
                print(f'{G}code point{R}    {D}the actual code point bits, reassembled after stripping indicators{R}')

                print(f'\n{D}UTF-8 byte patterns:{R}')
                print(f'{D}  First byte\'s leading bits are reserved to tell how many bytes to read.{R}')
                print(f'{D}  If a byte starts with {C}10{D}, it\'s not a starting point —{R}')
                print(f'{D}  it\'s a continuation that belongs to the previous start byte,{R}')
                print(f'{D}  meaning the character is stored in more than 1 byte.{R}')
                print(f'{D}    {Y}0{D}xxxxxxx  →  1 byte to store the character (ASCII){R}')
                print(f'{D}    {Y}110{D}xxxxx  →  2 bytes to store the character{R}')
                print(f'{D}    {Y}1110{D}xxxx  →  3 bytes to store the character{R}')
                print(f'{D}    {Y}11110{D}xxx  →  4 bytes to store the character{R}')
                print(f'{D}    {C}10{D}xxxxxx  →  part of the previous sequence{R}')

args = sys.argv[1:]
enc = int(args.pop(0))
verbose = '-v' in args
args = [a for a in args if a != '-v']
char = resolve(args[0])

if len(char) > 1:
    enc_name = {8: 'utf-8', 16: 'utf-16-be', 32: 'utf-32-be'}[enc]
    full_raw = char.encode(enc_name)
    full_hex = ' '.join(f'{G}{b:02X}{R}' for b in full_raw)
    cps = ' '.join(f'U+{ord(c):04X}' for c in char)
    full_bin = ' '.join(f'{b:08b}' for b in full_raw)
    print(f'string          {char}')
    print(f'code points     {cps}')
    print(f'hex encoded     {full_hex}')
    print(f'bin encoded     {full_bin}')
    print()

for i, c in enumerate(char):
    if len(char) > 1:
        print(f'── [{c}] ──')
    display(enc, c, verbose)
    if i < len(char) - 1:
        print()
