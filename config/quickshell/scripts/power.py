#!/usr/bin/env python3
import sys, subprocess, json

def get_power():
    perc = 100
    state = 'fully-charged'
    try:
        bat = subprocess.check_output(['sh', '-c', 'upower -i $(upower -e | grep -i bat | head -n1) 2>/dev/null'], stderr=subprocess.DEVNULL).decode('utf-8')
        for line in bat.split('\n'):
            if 'percentage:' in line:
                perc = int(line.split(':')[1].strip().replace('%', ''))
            elif 'state:' in line:
                state = line.split(':')[1].strip()
    except Exception:
        pass

    profile = 'balanced'
    try:
        profile = subprocess.check_output(['powerprofilesctl', 'get'], stderr=subprocess.DEVNULL).decode('utf-8').strip()
    except Exception:
        pass

    return {
        'percentage': perc,
        'state': state,
        'profile': profile
    }

if __name__ == '__main__':
    action = sys.argv[1] if len(sys.argv) > 1 else 'get'
    if action == 'get':
        print(json.dumps(get_power()))
    elif action == 'set_profile':
        prof = sys.argv[2] if len(sys.argv) > 2 else 'balanced'
        subprocess.run(['powerprofilesctl', 'set', prof], stderr=subprocess.DEVNULL)
