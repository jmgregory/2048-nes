from mimetypes import init
import sys
assert sys.version_info[0] >= 3, "Python 3 required."

from collections import OrderedDict

class Sym:
    def __init__(self, line):
        self.name = ""
        self.value = -1
        kvs = line.split(",")
        for kv in kvs:
            [key, value] = kv.split("=")
            if key == "id":
                self.id = int(value)
            elif key == "name":
                self.name = value.strip('"')
            elif key == "val":
                self.value = int(value, 16)
            elif key == "type":
                self.type = value
    
    def toString(self):
        return f"${self.value:04x}#{self.name}#"


def label_to_nl(label_file, nl_file, range_min, range_max):
    labels = []
    try:
        of = open(label_file, "rt")
        labels = of.readlines()
    except IOError:
        print("skipped: "+label_file)
        return
    syms = []
    sout = ""
    for line in labels:
        words = line.split()
        if (words[0] == "sym"):
            sym = Sym(words[1])
            if (sym.type != "equ" and sym.value >= range_min and sym.value <= range_max):
                syms.append(sym)
    for sym in syms:
        sout += sym.toString() + "\n"
    open(nl_file, "wt").write(sout)
    print("debug symbols: " + nl_file)
    
if __name__ == "__main__":
    label_to_nl("2048.nes.db", "2048.nes.ram.nl", 0x0000, 0x7FF)
    label_to_nl("2048.nes.db", "2048.nes.0.nl", 0x8000, 0xBFFF)
    label_to_nl("2048.nes.db", "2048.nes.1.nl", 0xC000, 0xFFFF)
