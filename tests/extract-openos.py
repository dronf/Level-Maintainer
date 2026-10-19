"""Extract the exact OpenOS buffer implementation for nei-openos-io.lua."""
import pathlib
import sys
import zipfile

jar, destination = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
destination.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(jar) as archive:
    for source, target in (("buffer.lua", "buffer.lua"), ("core/full_buffer.lua", "full_buffer.lua")):
        data = archive.read("assets/opencomputers/loot/openos/lib/" + source)
        (destination / target).write_bytes(data)
print("Extracted OpenOS buffer sources from", jar, "to", destination)
