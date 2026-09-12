#!/usr/bin/env python3
import sys, subprocess, json

def get_audio():
    try:
        out = subprocess.check_output(['wpctl', 'get-volume', '@DEFAULT_AUDIO_SINK@'], stderr=subprocess.DEVNULL).decode('utf-8')
        out_vol = int(float(out.split()[1]) * 100) if len(out.split()) > 1 else 50
        out_muted = '[MUTED]' in out
    except Exception:
        out_vol, out_muted = 50, False

    try:
        inp = subprocess.check_output(['wpctl', 'get-volume', '@DEFAULT_AUDIO_SOURCE@'], stderr=subprocess.DEVNULL).decode('utf-8')
        inp_vol = int(float(inp.split()[1]) * 100) if len(inp.split()) > 1 else 50
        inp_muted = '[MUTED]' in inp
    except Exception:
        inp_vol, inp_muted = 50, False

    return {
        'output': out_vol,
        'output_muted': out_muted,
        'input': inp_vol,
        'input_muted': inp_muted
    }

if __name__ == '__main__':
    action = sys.argv[1] if len(sys.argv) > 1 else 'get'
    if action == 'get':
        print(json.dumps(get_audio()))
    elif action == 'set_output':
        v = float(sys.argv[2]) / 100.0
        subprocess.run(['wpctl', 'set-volume', '@DEFAULT_AUDIO_SINK@', f'{v:.2f}'], stderr=subprocess.DEVNULL)
    elif action == 'set_input':
        v = float(sys.argv[2]) / 100.0
        subprocess.run(['wpctl', 'set-volume', '@DEFAULT_AUDIO_SOURCE@', f'{v:.2f}'], stderr=subprocess.DEVNULL)
    elif action == 'toggle_output_mute':
        subprocess.run(['wpctl', 'set-mute', '@DEFAULT_AUDIO_SINK@', 'toggle'], stderr=subprocess.DEVNULL)
    elif action == 'toggle_input_mute':
        subprocess.run(['wpctl', 'set-mute', '@DEFAULT_AUDIO_SOURCE@', 'toggle'], stderr=subprocess.DEVNULL)
