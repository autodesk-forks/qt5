import subprocess
import re

vswhere_output = subprocess.check_output(
    R"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe")
m = re.search(
    R"^installationPath: (.*\\Microsoft Visual Studio\\2017\\.*)$", vswhere_output, re.M)
print(m.group(1))
