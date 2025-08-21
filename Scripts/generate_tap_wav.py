#!/usr/bin/env python3
import wave
import math
import struct

sample_rate = 44100
duration = 0.12  # short click
frequency = 1200.0
amplitude = 0.5

n_samples = int(sample_rate * duration)
with wave.open('Resources/sounds/tap.wav', 'wb') as wf:
    wf.setnchannels(1)
    wf.setsampwidth(2)
    wf.setframerate(sample_rate)
    for i in range(n_samples):
        t = float(i) / sample_rate
        # quick decay envelope
        env = math.exp(-30 * t)
        val = int(amplitude * env * math.sin(2 * math.pi * frequency * t) * 32767)
        data = struct.pack('<h', val)
        wf.writeframesraw(data)

print('tap.wav generated')
