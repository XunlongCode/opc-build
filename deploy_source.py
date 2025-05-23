import os
import sys
import tarfile
import shutil
import json
import subprocess

SOURCE_PATH = "./source"
SOURCE_FILE = f"{SOURCE_PATH}/code-oss-dev.tgz"
TEMP_PATH = "./temp"
QUALITY = f"{os.getenv('VSCODE_QUALITY', 'stable')}"
VSCODE_PATH = "./vscode"


def run_command(command, capture_output=True, cwd=None):
    try:
        if capture_output:
            result = subprocess.run(
                command,
                check=True,
                text=True,
                capture_output=True,
                encoding="utf-8",  # 明确指定编码为 UTF-8
                cwd=cwd,
            )
            return result.stdout.strip()
        else:
            return subprocess.run(
                command, stdout=sys.stdout, stderr=sys.stderr, shell=False
            )

    except subprocess.CalledProcessError as e:
        print(f"Error running command: {e}")
        sys.exit(1)


def clean_up():
    if os.path.exists(TEMP_PATH):
        shutil.rmtree(TEMP_PATH)

    if os.path.exists(VSCODE_PATH):
        shutil.rmtree(VSCODE_PATH)

    if os.path.exists(f"./upstream/{QUALITY}.json"):
        os.remove(f"./upstream/{QUALITY}.json")


def deploy_source(source_path=SOURCE_FILE, output_path=TEMP_PATH):
    output_path = os.path.join(output_path, "package")
    # Check if the source file exists
    if not os.path.exists(source_path):
        print(f"Source file '{source_path}' does not exist.")
        sys.exit(1)

    # Check if the output directory exists
    if not os.path.exists(output_path):
        os.makedirs(output_path)

    # Uncompress the source file
    try:
        tarfile.open(source_path, "r:gz").extractall(
            output_path, filter="fully_trusted"
        )
        print(f"Source file '{source_path}' uncompressed successfully.")
    except Exception as e:
        print(f"Error uncompressing source file '{source_path}': {e}")


def move_files():
    shutil.copy(f"{SOURCE_PATH}/{QUALITY}.json", "./upstream")
    shutil.move(f"{TEMP_PATH}/package", VSCODE_PATH)


def set_env():
    env_file = os.getenv("GITHUB_ENV")
    print(f"github env file: {env_file}")
    if not env_file:
        return

    quality_json_path = f"./upstream/{QUALITY}.json"
    quality_json = json.loads(open(quality_json_path, "r").read())
    print(quality_json)
    with open(env_file, "a") as e:
        e.write(f"MS_TAG={quality_json['tag']}\n")
        e.write(f"MS_COMMIT={quality_json['commit']}\n")


def install_codicons():
    # 备份原package
    shutil.move(
        f"{VSCODE_PATH}/extensions/orangepiaicode/package.json",
        f"{VSCODE_PATH}/extensions/orangepiaicode/package.json.bak",
    )
    shutil.move(
        f"{VSCODE_PATH}/extensions/orangepiaicode/package-lock.json",
        f"{VSCODE_PATH}/extensions/orangepiaicode/package-lock.json.bak",
    )
    shutil.move(
        f"{VSCODE_PATH}/extensions/orangepicode-core/package.json",
        f"{VSCODE_PATH}/extensions/orangepicode-core/package.json.bak",
    )

    # 安装codicons
    npm_path = shutil.which("npm")
    run_command(
        [npm_path, "init", "-y"], cwd=f"{VSCODE_PATH}/extensions/orangepiaicode"
    )
    run_command(
        [npm_path, "init", "-y"],
        cwd=f"{VSCODE_PATH}/extensions/orangepicode-core",
    )
    run_command(
        [npm_path, "install", "@vscode/codicons"],
        cwd=f"{VSCODE_PATH}/extensions/orangepiaicode",
    )
    run_command(
        [npm_path, "install", "@vscode/codicons"],
        cwd=f"{VSCODE_PATH}/extensions/orangepicode-core",
    )

    # 恢复原package
    shutil.move(
        f"{VSCODE_PATH}/extensions/orangepiaicode/package.json.bak",
        f"{VSCODE_PATH}/extensions/orangepiaicode/package.json",
    )
    shutil.move(
        f"{VSCODE_PATH}/extensions/orangepiaicode/package-lock.json.bak",
        f"{VSCODE_PATH}/extensions/orangepiaicode/package-lock.json",
    )
    shutil.move(
        f"{VSCODE_PATH}/extensions/orangepicode-core/package.json.bak",
        f"{VSCODE_PATH}/extensions/orangepicode-core/package.json",
    )


def main():
    clean_up()

    deploy_source()
    move_files()

    install_codicons()

    set_env()


if __name__ == "__main__":
    main()
