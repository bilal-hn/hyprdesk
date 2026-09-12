#!/usr/bin/env python3
import sys, subprocess, json

def get_wifi_list():
    try:
        # Rescan first asynchronously if needed
        out = subprocess.check_output(['nmcli', '-t', '-f', 'IN-USE,SSID,SIGNAL,SECURITY', 'dev', 'wifi', 'list'], stderr=subprocess.DEVNULL).decode('utf-8')
        networks = []
        seen = set()
        for line in out.strip().split('\n'):
            if not line: continue
            parts = line.split(':')
            if len(parts) >= 3:
                in_use = (parts[0].strip() == '*')
                ssid = parts[1].strip()
                if not ssid or ssid in seen:
                    continue
                seen.add(ssid)
                signal = int(parts[2]) if parts[2].strip().isdigit() else 0
                sec = parts[3].strip() if len(parts) > 3 else ''
                networks.append({'ssid': ssid, 'signal': signal, 'active': in_use, 'security': sec})
        networks.sort(key=lambda x: (not x['active'], -x['signal']))
        return networks
    except Exception:
        return []

def connect(ssid, password=None):
    try:
        cmd = ['nmcli', 'dev', 'wifi', 'connect', ssid]
        if password:
            cmd += ['password', password]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print(json.dumps({'status': 'ok', 'ssid': ssid}))
    except subprocess.CalledProcessError as e:
        print(json.dumps({'status': 'error', 'message': e.stderr.decode('utf-8')}))

def disconnect():
    try:
        devs = subprocess.check_output(['nmcli', '-t', '-f', 'DEVICE,TYPE', 'dev'], stderr=subprocess.DEVNULL).decode('utf-8')
        for line in devs.strip().split('\n'):
            if ':wifi' in line:
                dev = line.split(':')[0]
                subprocess.run(['nmcli', 'dev', 'disconnect', dev], check=True)
                break
        print(json.dumps({'status': 'ok'}))
    except Exception as e:
        print(json.dumps({'status': 'error', 'message': str(e)}))

def toggle_wifi():
    try:
        status = subprocess.check_output(['nmcli', 'radio', 'wifi'], stderr=subprocess.DEVNULL).decode('utf-8').strip()
        new_state = 'off' if status == 'enabled' else 'on'
        subprocess.run(['nmcli', 'radio', 'wifi', new_state], check=True)
        print(json.dumps({'status': 'ok', 'enabled': new_state == 'on'}))
    except Exception as e:
        print(json.dumps({'status': 'error', 'message': str(e)}))

def get_status():
    try:
        status = subprocess.check_output(['nmcli', 'radio', 'wifi'], stderr=subprocess.DEVNULL).decode('utf-8').strip()
        return {'enabled': status == 'enabled'}
    except Exception:
        return {'enabled': False}

if __name__ == '__main__':
    action = sys.argv[1] if len(sys.argv) > 1 else 'list'
    if action == 'list':
        print(json.dumps(get_wifi_list()))
    elif action == 'connect':
        ssid = sys.argv[2] if len(sys.argv) > 2 else ''
        pw = sys.argv[3] if len(sys.argv) > 3 else None
        connect(ssid, pw)
    elif action == 'disconnect':
        disconnect()
    elif action == 'toggle':
        toggle_wifi()
    elif action == 'status':
        print(json.dumps(get_status()))
