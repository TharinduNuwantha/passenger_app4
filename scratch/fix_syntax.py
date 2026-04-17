import os

path = r'c:\myProjects\AASL_My\passenger_app2\passenger_app\lib\screens\home\home_screen.dart'
if not os.path.exists(path):
    print("File not found")
    exit(1)

with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f"Total lines: {len(lines)}")
# We checked indices:
# index 2287 is line 2288: "          const SizedBox(height: 20),"
# index 2792 is line 2793: "          // Advertisement carousel (auto-rotating every 5s)"
# We keep up to index 2287 (inclusive) -> lines[:2288]
# We keep from index 2792 (inclusive) -> lines[2792:]

if len(lines) > 2792:
    new_lines = lines[:2288] + lines[2792:]
    with open(path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print("Successfully cleaned the file.")
else:
    print("File too short, indices might be wrong.")
