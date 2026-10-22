"""Check protected framework functions and record the tested source hashes."""
import hashlib
import pathlib
import re
import subprocess

root = pathlib.Path(__file__).resolve().parents[3]


def function(text, name):
    match = re.search(r"\b" + re.escape(name) + r"\([^;{}]*\)\s*\{", text)
    assert match, name
    start = match.start()
    depth = 1
    pos = match.end()
    while depth:
        depth += (text[pos] == "{") - (text[pos] == "}")
        pos += 1
    return text[start:pos]


print("Branch:", subprocess.check_output(
    ["git", "branch", "--show-current"], cwd=root, text=True).strip())
print("Base commit:", subprocess.check_output(
    ["git", "rev-parse", "HEAD"], cwd=root, text=True).strip())
for relative, names in [
    ("lab2/code/kern/mm/best_fit_pmm.c", ["basic_check", "best_fit_check"]),
    ("lab2/code/kern/mm/pmm.c", ["page_init"]),
]:
    current = (root / relative).read_text(encoding="utf-8")
    baseline = subprocess.check_output(
        ["git", "show", "HEAD:" + relative], cwd=root).decode("utf-8").replace("\r\n", "\n")
    for name in names:
        body = function(current, name)
        assert body == function(baseline, name), name + " changed"
        print(name + ": unchanged; SHA256 " + hashlib.sha256(body.encode()).hexdigest())

for directory in ["kern", "libs", "tools"]:
    for path in sorted((root / "lab2/code" / directory).rglob("*")):
        if path.is_file():
            print(hashlib.sha256(path.read_bytes()).hexdigest(),
                  path.relative_to(root).as_posix())
print("PASS: fixed tests and teammate page_init are unchanged")
