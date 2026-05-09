
import re

file_path = r'd:\Work\Trading_app\green_rabbit_v2\lib\features\market\presentation\pages\instrument_detail_page.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

stack = []
current_method = None

for i, line in enumerate(lines):
    # find method starts
    match = re.search(r'Widget\s+(_\w+)\(', line)
    if match:
        current_method = match.group(1)
    
    for char in line:
        if char == '{':
            stack.append(current_method)
        elif char == '}':
            if stack:
                finished_method = stack.pop()
                if not stack:
                    # Class closed?
                    print(f"CLASS/TOP LEVEL CLOSED at line {i+1} after {finished_method}")

print(f"End of scan. Stack depth is {len(stack)}. Current stack: {stack}")
