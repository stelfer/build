import sys
import json
out = []
for f in sys.argv[2:]:
    with open(f) as file:
        js = json.load(file)
    out.extend(js)
json.dump(out, open(sys.argv[1], 'w'), indent=4)
