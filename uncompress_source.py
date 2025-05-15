import os
import sys
import tarfile
import shutil

SOURCE_FILE = "./source/code-oss-dev.tgz"
TEMP_PATH = "./temp"
QUALITY = f"{os.getenv('VSCODE_QUALITY')}"


def uncompress_source(source_path=SOURCE_FILE, output_path=TEMP_PATH):
    # Check if the source file exists
    if not os.path.exists(source_path):
        print(f"Source file '{source_path}' does not exist.")
        sys.exit(1)

    # Check if the output directory exists
    if not os.path.exists(output_path):
        os.makedirs(output_path)

    # Uncompress the source file
    try:
        tarfile.open(source_path, "r:gz").extractall(output_path)
        print(f"Source file '{source_path}' uncompressed successfully.")
    except Exception as e:
        print(f"Error uncompressing source file '{source_path}': {e}")


def move_files():
    shutil.move(f"{TEMP_PATH}/package/{QUALITY}.json", "./upstream")
    shutil.move(f"{TEMP_PATH}/package", "./vscode")


def main():
    uncompress_source()
    move_files()


if __name__ == "__main__":
    main()
