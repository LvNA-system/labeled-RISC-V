import os
import sh
import sys
import common as c
from pathlib import Path
from os.path import join as pjoin
from multiprocessing import Pool


num_tasks = 2
am_arch_suffix = '-riscv64-rocket.bin'

# ...../fpga/emu/
base_dir = str(Path(__file__).resolve().parents[1])
template_dir = pjoin(base_dir, 'run-template')
base_run_dir = pjoin(base_dir, 'run')

# rocket/emulator/
emulator_dir = pjoin(str(Path(__file__).resolve().parents[3]), 'emulator')
emulator = pjoin(emulator_dir,
                 'emulator-freechips.rocketchip.system-LvNABoomLinuxConfig')
emu_base = os.path.basename(emulator)
force_run = False  # ignore time stamps
# max_cycles = 40_000_000
max_cycles = 5_000_000


def create_emu_env(run_dir, bin_file):
    c.safe_mkdir(run_dir)
    template_files = os.listdir(template_dir)
    for f in template_files:
        if os.path.isfile(pjoin(template_dir, f)):
            sh.ln('-sf', pjoin(template_dir, f), run_dir)
    text_file = pjoin(run_dir, 'bin.txt')
    if not c.is_older(bin_file, text_file):
        c.hex_dump(bin_file, text_file)


def example_task(run_dir: str):
    os.chdir(run_dir)
    emu = sh.Command(emulator)
    options = [
        '+verbose',
        f'-m {max_cycles}',
        '.',  # this is run_dir
    ]
    func_name = sys._getframe(0).f_code.co_name
    emu(
        _out=pjoin(run_dir, f'{emu_base}-{func_name}-stdout.txt'),
        _err=pjoin(run_dir, f'{emu_base}-{func_name}-stderr.txt'),
        *options,
    )


def run_benchmark(app: str):
    print(app)
    run_dir = pjoin(base_run_dir, app)
    app_dir = c.get_am_app_dir(app)
    bin_file = app_dir + f'/build/{app}{am_arch_suffix}'

    if not os.path.isfile(bin_file):
        os.chdir(app_dir)
        sh.make()

    create_emu_env(run_dir, bin_file)

    c.avoid_repeating(emulator, bin_file, run_dir, force_run,
                      example_task, run_dir)


def main():
    apps = c.get_am_apps()
    if num_tasks > 1:
        p = Pool(num_tasks, )
        p.map(run_benchmark, apps)
    else:
        for app in apps:
            run_benchmark(app)


if __name__ == '__main__':
    main()
