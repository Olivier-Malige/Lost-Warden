from array import array
from math import cos, exp, pi, sin
from pathlib import Path
import sys
import wave


def export_ping() -> None:
    rate = 44100
    duration = 0.075
    phase = 0.0
    samples = array("h")
    for index in range(round(duration * rate)):
        time = index / rate
        frequency = 1046.5 + 272.0 * (1.0 - exp(-time / 0.006))
        phase += 2.0 * pi * frequency / rate
        attack = 1.0 - exp(-time / 0.0015)
        release = exp(-time / 0.019)
        tail = min(1.0, max(0.0, (duration - time) / 0.012))
        envelope = attack * release * (0.5 - 0.5 * cos(pi * tail))
        tone = 0.76 * sin(phase) + 0.18 * sin(phase * 2.0) + 0.06 * sin(phase * 3.0)
        samples.append(round(32767 * 0.24 * tone * envelope))
    samples[0] = samples[-1] = 0
    if sys.byteorder != "little":
        samples.byteswap()
    output = Path(__file__).resolve().parents[3] / "assets/audio/sfx/pickups/xp_orb_collect.wav"
    output.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(output), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(rate)
        stream.writeframes(samples.tobytes())
    print(f"Exported {output.name}: {duration:.3f}s, mono PCM16, {rate} Hz")


if __name__ == "__main__":
    export_ping()
