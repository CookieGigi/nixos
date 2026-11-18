import struct
import sys


DT_NULL = 0
DT_RELA = 7
DT_RELASZ = 8
DT_RELAENT = 9
DT_RELACOUNT = 0x6FFFFFF9
PT_LOAD = 1
PT_DYNAMIC = 2
R_X86_64_RELATIVE = 8
R_X86_64_PLT32 = 4


def rela_info(elf, path):
    header = elf.read(64)
    if header[:4] != b"\x7fELF" or header[4:6] != b"\x02\x01":
        raise ValueError(f"{path} is not a little-endian ELF64 binary")
    if struct.unpack_from("<H", header, 18)[0] != 62:
        raise ValueError(f"{path} is not an x86_64 binary")

    phoff = struct.unpack_from("<Q", header, 32)[0]
    phentsize, phnum = struct.unpack_from("<HH", header, 54)
    load_segments = []
    dynamic_segment = None

    for index in range(phnum):
        elf.seek(phoff + index * phentsize)
        program_header = elf.read(phentsize)
        p_type, _, p_offset, p_vaddr = struct.unpack_from("<IIQQ", program_header)
        p_filesz = struct.unpack_from("<Q", program_header, 32)[0]
        if p_type == PT_LOAD:
            load_segments.append((p_vaddr, p_vaddr + p_filesz, p_offset))
        elif p_type == PT_DYNAMIC:
            dynamic_segment = (p_offset, p_filesz)

    if dynamic_segment is None:
        raise ValueError(f"{path} has no PT_DYNAMIC segment")

    dynamic_offset, dynamic_size = dynamic_segment
    dynamic_values = {}
    relacount_offset = None
    for offset in range(dynamic_offset, dynamic_offset + dynamic_size, 16):
        elf.seek(offset)
        tag, value = struct.unpack("<qQ", elf.read(16))
        if tag == DT_NULL:
            break
        dynamic_values[tag] = value
        if tag == DT_RELACOUNT:
            relacount_offset = offset + 8

    rela_addr = dynamic_values[DT_RELA]
    rela_size = dynamic_values[DT_RELASZ]
    rela_entry_size = dynamic_values[DT_RELAENT]
    rela_offset = next(
        (
            segment_offset + rela_addr - segment_start
            for segment_start, segment_end, segment_offset in load_segments
            if segment_start <= rela_addr < segment_end
        ),
        None,
    )
    if rela_offset is None or rela_entry_size < 24:
        raise ValueError(f"{path} has an invalid .rela.dyn mapping")

    return rela_offset, rela_entry_size, rela_size, relacount_offset, dynamic_values


def first_relocation(elf, rela_offset):
    elf.seek(rela_offset)
    return struct.unpack("<QQq", elf.read(24))


def capture(path, state_path):
    with open(path, "rb") as elf:
        rela_offset, _, _, relacount_offset, dynamic_values = rela_info(elf, path)
        if relacount_offset is None:
            raise ValueError(f"{path} has no DT_RELACOUNT")
        relocation = first_relocation(elf, rela_offset)
        if relocation[1] & 0xFFFFFFFF != R_X86_64_RELATIVE:
            raise ValueError(f"{path} does not start with a relative relocation")

    with open(state_path, "wb") as state:
        state.write(struct.pack("<QQqQ", *relocation, dynamic_values[DT_RELACOUNT]))


def repair(path, state_path):
    with open(state_path, "rb") as state:
        original_info = struct.unpack("<QQqQ", state.read(32))
        original_relocation = original_info[:3]
        original_relacount = original_info[3]

    with open(path, "r+b") as elf:
        rela_offset, _, _, relacount_offset, _ = rela_info(elf, path)
        current_relocation = first_relocation(elf, rela_offset)
        if current_relocation == original_relocation:
            return

        current_offset, current_info, current_addend = current_relocation
        if (
            current_offset != 0x24
            or current_info & 0xFFFFFFFF != R_X86_64_PLT32
            or current_info >> 32 != 0
            or current_addend != original_relocation[2]
            or relacount_offset is None
        ):
            raise ValueError(f"{path} has an unexpected first dynamic relocation")

        elf.seek(rela_offset)
        elf.write(struct.pack("<QQq", *original_relocation))
        elf.seek(relacount_offset)
        elf.write(struct.pack("<Q", original_relacount))
        print("Restored the original first relative relocation and DT_RELACOUNT")


if __name__ == "__main__":
    if len(sys.argv) not in (4,):
        raise SystemExit(f"Usage: {sys.argv[0]} capture|repair ELF_FILE STATE_FILE")
    mode, elf_path, state_path = sys.argv[1:]
    if mode == "capture":
        capture(elf_path, state_path)
    elif mode == "repair":
        repair(elf_path, state_path)
    else:
        raise SystemExit(f"Unknown mode: {mode}")
