#!/usr/bin/env bash
# Run the repository's current source in temporary copies, preserving bin/obj.
set -euo pipefail
logs=$(cd -- "$(dirname -- "$0")" && pwd)
repo=$(cd "$logs/../../.." && pwd)
export PATH="/mnt/d/OS/riscv64-unknown-elf-toolchain-10.2.0-2020.12.8-x86_64-linux-ubuntu14/bin:/usr/local/bin:$PATH"
exec > >(tee "$logs/console-summary.log") 2>&1
trap 'printf "\nFAILED at runner line %s; inspect saved logs.\n" "$LINENO"' ERR

printf 'Lab2 T4 | Best-Fit verification | %s\n' "$(date -Iseconds)"
printf 'Repository: %s\n' "$repo"
printf 'Compiler: '; riscv64-unknown-elf-gcc -dumpversion
qemu-system-riscv64 --version | head -n 1
python3 "$logs/check_source.py" > "$logs/source-audit.log"
tail -n 1 "$logs/source-audit.log"

work=$(mktemp -d /tmp/ucore-t4-2511440.XXXXXX)
printf '%s\n' "$work" > "$logs/snapshot-path.txt"
mkdir "$work/normal" "$work/regression"
tar -C "$repo/lab2/code" --exclude=bin --exclude=obj --exclude=.git --exclude=.qemu.out --exclude=.gdb.in -cf - . | tar -C "$work/normal" -xf -
tar -C "$work/normal" -cf - . | tar -C "$work/regression" -xf -
printf 'Build copies: %s\n\n' "$work"

cd "$work/normal"
make -j2 > "$logs/build.log" 2>&1
printf '[1] Clean source build: PASS\n'
if timeout --signal=TERM --kill-after=2 8 qemu-system-riscv64 -machine virt -nographic -bios default -device loader,file=bin/ucore.img,addr=0x80200000 < /dev/null > "$logs/qemu.log" 2>&1; then
    qemu_rc=0
else
    qemu_rc=$?
fi
printf '%s\n' "$qemu_rc" > "$logs/qemu-exit-status.txt"
test "$qemu_rc" -eq 124
grep -Fq 'memory management: best_fit_pmm_manager' "$logs/qemu.log"
grep -Fq 'check_alloc_page() succeeded!' "$logs/qemu.log"
grep -Fq 'slub_check() succeeded!' "$logs/qemu.log"
if grep -Eqi 'kernel panic|assertion failed|panic at' "$logs/qemu.log"; then exit 1; fi
printf '[2] Unmodified kernel boot and self-checks:\n'
grep -E 'memory management:|check_alloc_page\(\) succeeded|slub_check\(\) succeeded|satp .*address:' "$logs/qemu.log"
printf 'QEMU stopped by runner after 8s (exit %s, intentional).\n\n' "$qemu_rc"

cd "$work/regression"
cat "$logs/best_fit_regression.c.txt" >> kern/mm/best_fit_pmm.c
python3 - <<'PY'
from pathlib import Path
p = Path('kern/mm/pmm.c')
s = p.read_text()
needle = '    check_alloc_page();'
assert s.count(needle) == 1
s = s.replace(needle, needle + '\n    extern void best_fit_extra_check(void);\n    best_fit_extra_check();')
p.write_text(s)
PY
make -j2 > "$logs/regression-build.log" 2>&1
if timeout --signal=TERM --kill-after=2 8 qemu-system-riscv64 -machine virt -nographic -bios default -device loader,file=bin/ucore.img,addr=0x80200000 < /dev/null > "$logs/regression-qemu.log" 2>&1; then
    regression_rc=0
else
    regression_rc=$?
fi
printf '%s\n' "$regression_rc" > "$logs/regression-exit-status.txt"
test "$regression_rc" -eq 124
grep -Fq 'T4 regression ALL PASS' "$logs/regression-qemu.log"
grep -Fq 'slub_check() succeeded!' "$logs/regression-qemu.log"
if grep -Eqi 'kernel panic|assertion failed|panic at' "$logs/regression-qemu.log"; then exit 1; fi
printf '[3] Extra checks (injected into temporary copy only):\n'
grep -F 'T4 regression' "$logs/regression-qemu.log"
printf '\n'

cd "$work/normal"
make grade < /dev/null > "$logs/grade.log" 2>&1
grep -Fq 'Total Score: 20/20' "$logs/grade.log"
printf '[4] Repository course grader:\n'
grep -E 'check page init:|check best fit:|Total Score:' "$logs/grade.log"
printf '\nALL CHECKS PASSED. Full raw logs saved under:\n%s\n' "$logs"
printf 'Real source tested normally; extra regression code is isolated.\n'
date -Iseconds > "$logs/completed.txt"
