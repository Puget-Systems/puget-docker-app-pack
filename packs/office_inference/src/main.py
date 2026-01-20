import platform
import os
import sys

def main():
    print("="*60)
    print("   Puget Systems Docker Base App Pack - Hello World")
    print("="*60)
    print(f"Node Name:      {platform.node()}")
    print(f"System:         {platform.system()} {platform.release()}")
    print(f"Machine:        {platform.machine()}")
    print(f"Python Version: {sys.version.split()[0]}")
    print("-" * 60)
    print("Environment Check:")
    
    # Check if we are inside the expected directory structure
    cwd = os.getcwd()
    expected_path = "/home/puget-app-pack/app"
    
    if expected_path in cwd:
        print(f"[OK]  Running from standard path: {cwd}")
    else:
        print(f"[WARN] Running from non-standard path: {cwd}")
        print(f"       Expected to be within: {expected_path}")

    print("-" * 60)
    print("Volume Mount Check:")
    src_path = os.path.join(cwd, "src")
    if os.path.exists(src_path):
        print(f"[OK]  'src' directory is visible at: {src_path}")
    else:
        print(f"[FAIL] 'src' directory not found at: {src_path}")
        print("       Ensure your docker-compose volumes are correctly configured.")
        
    print("="*60)

if __name__ == "__main__":
    main()
