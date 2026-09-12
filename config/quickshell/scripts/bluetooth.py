#!/usr/bin/env python3
import sys, subprocess, json

def get_status():
    try:
        out = subprocess.check_output(['bluetoothctl', 'show'], stderr=subprocess.DEVNULL).decode('utf-8')
        powered = 'Powered: yes' in out
        discovering = 'Discovering: yes' in out
        return {'powered': powered, 'discovering': discovering}
    except Exception:
        return {'powered': False, 'discovering': False}

def get_devices():
    try:
        paired_out = subprocess.check_output(['bluetoothctl', 'devices', 'Paired'], stderr=subprocess.DEVNULL).decode('utf-8')
        devices = []
        for line in paired_out.strip().split('\n'):
            if not line.startswith('Device'): continue
            parts = line.split(' ', 2)
            if len(parts) >= 3:
                mac = parts[1]
                name = parts[2]
                # Check if connected
                info = subprocess.check_output(['bluetoothctl', 'info', mac], stderr=subprocess.DEVNULL).decode('utf-8')
                connected = 'Connected: yes' in info
                icon = 'audio-headset' if any(x in name.lower() for x in ['airpod', 'earbud', 'headphone', 'headset', 'audio', 'buds', 'yopod']) else 'bluetooth'
                devices.append({
                    'mac': mac,
                    'name': name,
                    'connected': connected,
                    'paired': True,
                    'icon': icon
                })
        devices.sort(key=lambda d: not d['connected'])
        return devices
    except Exception:
        return []

def toggle_power():
    status = get_status()
    new_state = 'off' if status['powered'] else 'on'
    subprocess.run(['bluetoothctl', 'power', new_state], stderr=subprocess.DEVNULL)
    print(json.dumps({'status': 'ok', 'powered': new_state == 'on'}))

def toggle_scan():
    status = get_status()
    new_state = 'off' if status['discovering'] else 'on'
    subprocess.run(['bluetoothctl', 'scan', new_state], stderr=subprocess.DEVNULL)
    print(json.dumps({'status': 'ok', 'discovering': new_state == 'on'}))

def connect(mac):
    subprocess.run(['bluetoothctl', 'connect', mac], stderr=subprocess.DEVNULL)
    print(json.dumps({'status': 'ok'}))

def disconnect(mac):
    subprocess.run(['bluetoothctl', 'disconnect', mac], stderr=subprocess.DEVNULL)
    print(json.dumps({'status': 'ok'}))

if __name__ == '__main__':
    action = sys.argv[1] if len(sys.argv) > 1 else 'list'
    if action == 'list':
        print(json.dumps(get_devices()))
    elif action == 'status':
        print(json.dumps(get_status()))
    elif action == 'toggle_power':
        toggle_power()
    elif action == 'toggle_scan':
        toggle_scan()
    elif action == 'connect':
        mac = sys.argv[2] if len(sys.argv) > 2 else ''
        connect(mac)
    elif action == 'disconnect':
        mac = sys.argv[2] if len(sys.argv) > 2 else ''
        disconnect(mac)
