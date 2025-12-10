import os
import glob

paths = glob.glob("./VSCode-linux-*")


def create_code_tunnel(path):
    bin_path = os.path.join(path, "bin")

    os.makedirs(bin_path, exist_ok=True)

    code_tunnel = "code-tunnel"
    code_tunnel_path = f"{bin_path}/{code_tunnel}"

    f = open(code_tunnel_path, "w")
    f.write("""#!/usr/bin/env sh
echo "Please download the CLI from https://code.visualstudio.com/Download and use it to replace me."
""")
    f.close()

    os.chmod(code_tunnel_path, 0o755)
    print(f"Created {code_tunnel_path}")


if __name__ == "__main__":
    for path in paths:
        create_code_tunnel(path)

    print("Done")
