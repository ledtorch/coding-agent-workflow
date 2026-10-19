"""Space-align every Markdown table in the given files (/trim P12).

Usage: python3 align-tables.py [--write] FILE...
Without --write, lists each file whose tables are not aligned and exits 1.
Whitespace only: cell text, cell count and delimiter colons are kept, CJK and
emoji count as two columns, and fenced code is skipped.
"""
import re
import sys
import unicodedata

ROW = re.compile(r'^(\s*(?:>\s?)*)\|')
DELIM_CELL = re.compile(r'^\s*:?-{1,}:?\s*$')
FENCE = re.compile(r'^\s*(?:>\s?)*(```|~~~)')


def width(s):
    w = 0
    for ch in s:
        if unicodedata.combining(ch) or ch in '‍︎️':
            continue
        w += 2 if unicodedata.east_asian_width(ch) in ('W', 'F') else 1
    return w


def split_cells(body):
    """Split a row body (after the prefix) on unescaped pipes."""
    cells, cur, i = [], '', 0
    while i < len(body):
        c = body[i]
        if c == '\\' and i + 1 < len(body):
            cur += body[i:i + 2]
            i += 2
            continue
        if c == '|':
            cells.append(cur)
            cur = ''
        else:
            cur += c
        i += 1
    cells.append(cur)
    # Leading pipe gives an empty first piece; a trailing pipe an empty last.
    if cells and cells[0].strip() == '':
        cells = cells[1:]
    if cells and cells[-1].strip() == '' and body.rstrip().endswith('|') and not body.rstrip().endswith('\\|'):
        cells = cells[:-1]
    return [c.strip() for c in cells]


def format_table(lines):
    prefix = ROW.match(lines[0]).group(1)
    rows = [split_cells(l[len(ROW.match(l).group(1)):].rstrip('\n')) for l in lines]
    delim = rows[1]
    n = max(len(r) for r in rows)
    widths = [0] * n
    for k, r in enumerate(rows):
        if k == 1:
            continue
        for j, c in enumerate(r):
            widths[j] = max(widths[j], width(c))
    widths = [max(w, 3) for w in widths]
    out = []
    for k, r in enumerate(rows):
        parts = []
        for j, c in enumerate(r):
            w = widths[j]
            if k == 1:
                left, right = c.startswith(':'), c.endswith(':')
                dashes = w - left - right
                parts.append((':' if left else '') + '-' * dashes + (':' if right else ''))
            else:
                parts.append(c + ' ' * (w - width(c)))
        out.append(prefix + '| ' + ' | '.join(parts) + ' |\n')
    return out


def process(text):
    lines = text.splitlines(keepends=True)
    if lines and not lines[-1].endswith('\n'):
        lines[-1] += '\n'
        trailing = False
    else:
        trailing = True
    out, i, in_fence, tables = [], 0, False, 0
    while i < len(lines):
        l = lines[i]
        if FENCE.match(l):
            in_fence = not in_fence
            out.append(l)
            i += 1
            continue
        if (not in_fence and ROW.match(l) and i + 1 < len(lines) and ROW.match(lines[i + 1])):
            d = split_cells(lines[i + 1][len(ROW.match(lines[i + 1]).group(1)):].rstrip('\n'))
            if d and all(DELIM_CELL.match(c) for c in d):
                j = i
                while j < len(lines) and ROW.match(lines[j]) and not FENCE.match(lines[j]):
                    j += 1
                out.extend(format_table(lines[i:j]))
                tables += 1
                i = j
                continue
        out.append(l)
        i += 1
    result = ''.join(out)
    if not trailing:
        result = result[:-1]
    return result, tables


def main():
    write = '--write' in sys.argv
    unaligned = 0
    for path in [a for a in sys.argv[1:] if a != '--write']:
        src = open(path, encoding='utf-8').read()
        new, _ = process(src)
        if new == src:
            continue
        unaligned += 1
        rows = [n for n, (a, b) in enumerate(zip(src.splitlines(), new.splitlines()), 1) if a != b]
        print(f'{path}: {len(rows)} rows (first at line {rows[0]})')
        if write:
            open(path, 'w', encoding='utf-8').write(new)
    sys.exit(1 if unaligned and not write else 0)


if __name__ == '__main__':
    main()
