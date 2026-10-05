#!/usr/bin/env python3
import os
import math
import wave
import struct

output_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "Nook", "Resources", "Audio")
os.makedirs(output_dir, exist_ok=True)

SAMPLE_RATE = 44100

def write_wav(filename, samples):
    filepath = os.path.join(output_dir, filename)
    with wave.open(filepath, 'w') as wav:
        wav.setnchannels(1)        # Mono
        wav.setsampwidth(2)        # 16-bit
        wav.setframerate(SAMPLE_RATE)
        
        # Normalize and convert to 16-bit PCM
        max_val = max(abs(s) for s in samples) if samples else 1.0
        if max_val > 0.0:
            scale = 0.70 / max_val # Conservative soft peak (-3 dB)
        else:
            scale = 1.0
            
        data = bytearray()
        for s in samples:
            val = int(max(-32767, min(32767, s * scale * 32767)))
            data.extend(struct.pack('<h', val))
        wav.writeframes(data)
    print(f"Generated: {filepath} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.2f}s)")

# 1. Soft Meow: Gentle, sweet, classic kitten "m-e-o-w" (~0.42s)
def gen_soft_meow():
    duration = 0.42
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        p = i / n_samples
        
        # Pitch curve: starts at 720 Hz, rises to 860 Hz, glides to 620 Hz
        if p < 0.25:
            f0 = 720 + (860 - 720) * (p / 0.25)
        else:
            f0 = 860 - (860 - 620) * ((p - 0.25) / 0.75)
            
        # Subtle feline vibrato
        vib = math.sin(2 * math.pi * 5.5 * t) * 12.0
        inst_f = f0 + vib
        
        phase = 2 * math.pi * inst_f * t
        
        # Harmonics (1st fundamental, 2nd, 3rd, 4th with vocal tract emphasis)
        signal = (
            1.00 * math.sin(phase) +
            0.55 * math.sin(2 * phase) +
            0.28 * math.sin(3 * phase) +
            0.12 * math.sin(4 * phase)
        )
        
        # Soft envelope: smooth attack (0.06s), steady, smooth decay
        if p < 0.15:
            env = 0.5 * (1 - math.cos(math.pi * p / 0.15))
        elif p > 0.65:
            decay_p = (p - 0.65) / 0.35
            env = 0.5 * (1 + math.cos(math.pi * decay_p))
        else:
            env = 1.0
            
        samples.append(signal * env * 0.75)
        
    write_wav("cookie_soft_meow.wav", samples)

# 2. Tiny Meow: Short, high, adorable kitten squeak / tiny mrow (~0.24s)
def gen_tiny_meow():
    duration = 0.24
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        p = i / n_samples
        
        # Higher pitch: 920 Hz rising to 1080 Hz, falling to 880 Hz
        if p < 0.3:
            f0 = 920 + (1080 - 920) * (p / 0.3)
        else:
            f0 = 1080 - (1080 - 880) * ((p - 0.3) / 0.7)
            
        vib = math.sin(2 * math.pi * 7.0 * t) * 8.0
        phase = 2 * math.pi * (f0 + vib) * t
        
        signal = (
            1.00 * math.sin(phase) +
            0.45 * math.sin(2 * phase) +
            0.18 * math.sin(3 * phase)
        )
        
        # Crisp cute envelope
        if p < 0.12:
            env = 0.5 * (1 - math.cos(math.pi * p / 0.12))
        else:
            decay_p = (p - 0.12) / 0.88
            env = math.exp(-3.5 * decay_p)
            
        samples.append(signal * env * 0.70)
        
    write_wav("cookie_tiny_meow.wav", samples)

# 3. Curious Chirp: Quick upward inquisitive feline trill (~0.20s)
def gen_curious_chirp():
    duration = 0.20
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        p = i / n_samples
        
        # Upward sweep 640 Hz -> 1180 Hz with trill
        f0 = 640 + (1180 - 640) * (p ** 1.3)
        trill = math.sin(2 * math.pi * 26.0 * t) * 35.0 # 26 Hz fast chirp flutter
        phase = 2 * math.pi * (f0 + trill) * t
        
        signal = (
            1.00 * math.sin(phase) +
            0.35 * math.sin(2 * phase) +
            0.15 * math.sin(3 * phase)
        )
        
        # Bell-shaped envelope
        env = math.sin(math.pi * p) ** 1.2
        samples.append(signal * env * 0.72)
        
    write_wav("cookie_curious_chirp.wav", samples)

# 4. Happy Meow: Cheerful, melodic warm purr-meow (~0.38s)
def gen_happy_meow():
    duration = 0.38
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        p = i / n_samples
        
        # Musical arch: 780 Hz -> 980 Hz -> 840 Hz -> 720 Hz
        f0 = 780 + 200 * math.sin(math.pi * p)
        vib = math.sin(2 * math.pi * 6.0 * t) * 14.0
        phase = 2 * math.pi * (f0 + vib) * t
        
        # Rich warm harmonics
        signal = (
            1.00 * math.sin(phase) +
            0.60 * math.sin(2 * phase) +
            0.30 * math.sin(3 * phase) +
            0.15 * math.sin(4 * phase)
        )
        
        # Smooth bell envelope
        if p < 0.18:
            env = 0.5 * (1 - math.cos(math.pi * p / 0.18))
        else:
            decay_p = (p - 0.18) / 0.82
            env = (0.5 * (1 + math.cos(math.pi * decay_p))) ** 1.2
            
        samples.append(signal * env * 0.75)
        
    write_wav("cookie_happy_meow.wav", samples)

# 5. Sleepy Murmur: Low cozy drowsy sigh / sleepy mumble (~0.35s)
def gen_sleepy_murmur():
    duration = 0.35
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        p = i / n_samples
        
        # Low glide: 380 Hz downward to 260 Hz
        f0 = 380 - (380 - 260) * (p ** 0.8)
        phase = 2 * math.pi * f0 * t
        
        signal = (
            1.00 * math.sin(phase) +
            0.40 * math.sin(2 * phase) +
            0.15 * math.sin(3 * phase)
        )
        
        # Gentle swell and fade
        env = math.sin(math.pi * p) ** 1.6
        samples.append(signal * env * 0.55)
        
    write_wav("cookie_sleepy_murmur.wav", samples)

# 6. Purr: Soothing rhythmic low-frequency diaphragm resonant purr (~1.6s seamless loop)
def gen_purr():
    duration = 1.60
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        
        # Fundamental ~92 Hz with subharmonics
        phase1 = 2 * math.pi * 92.0 * t
        phase2 = 2 * math.pi * 184.0 * t
        phase3 = 2 * math.pi * 46.0 * t # deep chest rumble
        
        # 26.5 Hz amplitude modulation representing breathing vibration
        # Exactly 42.4 cycles in 1.6s -> align to integer cycles for seamless looping:
        # 1.6s * 25.0 Hz = 40.0 cycles exactly!
        mod_rate = 25.0
        purr_mod = 0.55 + 0.45 * math.sin(2 * math.pi * mod_rate * t)
        
        # Sub-rumble harmonics
        signal = (
            0.70 * math.sin(phase1) +
            0.30 * math.sin(phase2) +
            0.40 * math.sin(phase3)
        )
        
        samples.append(signal * purr_mod * 0.50)
        
    write_wav("cookie_purr.wav", samples)

if __name__ == "__main__":
    gen_soft_meow()
    gen_tiny_meow()
    gen_curious_chirp()
    gen_happy_meow()
    gen_sleepy_murmur()
    gen_purr()
    print("All Cookie cat vocalizations generated successfully!")
