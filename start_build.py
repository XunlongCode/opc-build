import subprocess
import sys
import platform

install_dependencies = "i" in sys.argv

base_commands = [
    {"cwd": "extensions/orangepicode-theme", "commands": ["yarn", "yarn build"]},
    {
        "cwd": "extensions/orangepiaicode",
        "commands": [
            "yarn install:all",
            "yarn build:webview",
            "yarn build:esbuild",
        ],
    },
    {"cwd": "extensions/orangepicode-core", "commands": ["yarn", "yarn compile"]},
    {
        "cwd": "extensions/orangepicode-core/webview-ui",
        "commands": ["yarn", "yarn build"],
    },
]


def run_command(cwd, command):
    if not install_dependencies:
        if command == "npm i" or command == "yarn" or command == "yarn install:all":
            return

    print(f"\n* Running: `{command}` in `{cwd}`")
    try:
        return subprocess.run(command, cwd=cwd, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Command failed with exit code {e.returncode}: {command}")
        sys.exit(e.returncode)
    except KeyboardInterrupt:
        sys.exit(130)


def get_package_commands():
    system = platform.system()
    commands = []

    if system == "Windows":
        commands = [
            "yarn gulp vscode-win32-x64 --max-old-space-size=8192",
            "yarn gulp vscode-win32-x64-inno-updater --max-old-space-size=8192",
            "yarn gulp vscode-win32-x64-user-setup --max-old-space-size=8192",
        ]
    elif system == "Darwin":
        commands = ["yarn gulp vscode-darwin-arm64 --max-old-space-size=8192"]
    elif system == "Linux":
        commands = ["yarn gulp vscode-linux-x64 --max-old-space-size=8192"]

    return [{"cwd": ".", "commands": commands}]


def run():
    if install_dependencies:
        run_command(".", "npm i")

    for group in base_commands:
        cwd = group["cwd"]
        for cmd in group["commands"]:
            run_command(cwd, cmd)

    # for group in get_package_commands():
    #     cwd = group["cwd"]
    #     for cmd in group["commands"]:
    #         run_command(cwd, cmd)


if __name__ == "__main__":
    run()
