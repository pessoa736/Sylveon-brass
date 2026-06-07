import sys, urllib.request, json, os, subprocess

mod_name = sys.argv[1]
version_hint = sys.argv[2]
if not mod_name or not version_hint:
    sys.exit(1)

def run_cmd(args):
    subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def try_modrinth():
    req = urllib.request.Request(f"https://api.modrinth.com/v2/project/{mod_name}")
    req.add_header("User-Agent", "Mozilla/5.0")
    try:
        project_data = json.loads(urllib.request.urlopen(req).read())
        project_id = project_data['id']
        
        req = urllib.request.Request(f"https://api.modrinth.com/v2/project/{project_id}/version")
        req.add_header("User-Agent", "Mozilla/5.0")
        versions = json.loads(urllib.request.urlopen(req).read())
        
        for v in versions:
            if version_hint in v['version_number'] or any(version_hint in f['filename'] for f in v['files']):
                return project_id, v['id']
    except Exception as e:
        return None, None
    return None, None

def try_curseforge():
    req = urllib.request.Request(f"https://api.cfwidget.com/minecraft/mc-mods/{mod_name}")
    req.add_header("User-Agent", "Mozilla/5.0")
    try:
        project_data = json.loads(urllib.request.urlopen(req).read())
        addon_id = project_data['id']
        
        for f in project_data.get('files', []):
            if version_hint in f['name'] or version_hint in f.get('display', ''):
                return addon_id, f['id']
    except Exception as e:
        return None, None
    return None, None

def try_modrinth_search():
    import urllib.parse
    req = urllib.request.Request(f"https://api.modrinth.com/v2/search?limit=1&query={urllib.parse.quote(mod_name)}")
    req.add_header("User-Agent", "Mozilla/5.0")
    try:
        res = json.loads(urllib.request.urlopen(req).read())
        if res['hits']:
            pid = res['hits'][0]['project_id']
            # Search versions
            req2 = urllib.request.Request(f"https://api.modrinth.com/v2/project/{pid}/version")
            req2.add_header("User-Agent", "Mozilla/5.0")
            versions = json.loads(urllib.request.urlopen(req2).read())
            for v in versions:
                if version_hint in v['version_number'] or any(version_hint in f['filename'] for f in v['files']):
                    return pid, v['id']
    except Exception:
        pass
    return None, None

cf_pid, cf_fid = try_curseforge()
if cf_pid and cf_fid:
    print(f"CF {cf_pid} {cf_fid}")
    sys.exit(0)

mr_pid, mr_vid = try_modrinth()
if not mr_pid:
    mr_pid, mr_vid = try_modrinth_search()

if mr_pid and mr_vid:
    print(f"MR {mr_pid} {mr_vid}")
    sys.exit(0)

sys.exit(1)
