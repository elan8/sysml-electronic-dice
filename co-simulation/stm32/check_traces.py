"""Check pin timing and measured currents independently of the MCU firmware."""
import csv
import hashlib
import json
import sys
from pathlib import Path

PIP_NAMES = ("topLeft", "topRight", "middleLeft", "center", "middleRight", "bottomLeft", "bottomRight")
PIPS = (0, 8, 65, 73, 99, 107, 119)


def check(run: Path, backend: str) -> list[tuple[int, int]]:
    record = next(
        result
        for result in json.loads((run / f"{backend}-verdicts.json").read_bytes())
        if result["case_name"] == "DiceElf::playSixRolls"
    )
    evidence = record["evidence"]
    if record["verdict"] != "pass" or evidence["elf_backend"] != backend or evidence["omitted_connections"] != "[]":
        raise ValueError(f"{backend} did not pass the complete circuit case")
    image_hash = hashlib.sha256((run / "dice.elf").read_bytes()).hexdigest()
    if not any(name.replace("\\", "/").endswith("/dice.elf") and value == image_hash for name, value in evidence.items()):
        raise ValueError(f"{backend} did not record the shared ELF")
    trace = run / backend / "DiceElf__playSixRolls.csv"
    with trace.open(newline="") as stream:
        samples = list(csv.DictReader(stream))
    if len(samples) != 801:
        raise ValueError(f"{backend} expected 801 samples, got {len(samples)}")
    transitions = []
    last = 0
    for tick, sample in enumerate(samples):
        if abs(float(sample["t"]) * 1000 - tick) > 1e-6:
            raise ValueError(f"{backend} sample {tick} is off its 1 ms boundary")
        levels = [float(sample[f"pd{index}"]) for index in range(7)]
        if not all(level in (0.0, 1.0) for level in levels):
            raise ValueError(f"{backend} sample {tick} has a non-digital output")
        mask = sum(int(level) << index for index, level in enumerate(levels))
        if mask != last:
            transitions.append((tick, PIPS.index(mask)))
            last = mask
        for index, name in enumerate(PIP_NAMES):
            current = float(sample[f"{name}.current"])
            active = mask & (1 << index)
            if not (0.002 <= current <= 0.005 if active else 0.0 <= current < 0.00001):
                raise ValueError(f"{backend} {name} current at {tick} ms does not match GPIO")
    if [face for _, face in transitions] != [1, 2, 3, 4, 5, 6, 0]:
        raise ValueError(f"{backend} incorrect face sequence: {transitions}")
    expected = [29, 129, 229, 329, 429, 529, 779]
    if any(abs(tick - planned) > 1 for (tick, _), planned in zip(transitions, expected)):
        raise ValueError(f"{backend} transition is outside the 1 ms sample tolerance: {transitions}")
    if transitions[-1][0] - transitions[-2][0] != 250:
        raise ValueError(f"{backend} incorrect display timeout: {transitions[-2:]}")
    print(f"{backend}: GPIO face transitions (ms, face): {transitions}")
    return transitions


if __name__ == "__main__":
    run = Path(sys.argv[1])
    labwired = check(run, "labwired")
    renode = check(run, "renode")
    if any(abs(a - b) > 1 for (a, _), (b, _) in zip(labwired, renode)):
        raise SystemExit("Firmware GPIO transition times differ by more than one sample")
