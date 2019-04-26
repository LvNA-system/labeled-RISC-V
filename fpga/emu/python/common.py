import sh
import os
import errno
from pathlib import Path
import binascii as ba
from os.path import join as pjoin


# hex_dump == hexdump -ve '2/ "%08x " "\n"' $1 | awk '{print $2$1}' > $2
def hex_dump(in_file, out_file):
    assert os.path.isfile(in_file)
    with open(in_file, 'rb') as f, open(out_file, 'w') as out_f:
        chunks = iter(lambda : f.read(1), b'')
        hex_bytes = map(ba.hexlify, chunks)

        buffer = []
        for b in hex_bytes:
            buffer.append(b.decode())
            if len(buffer) == 8:
                buffer.reverse()
                out_f.write(''.join(buffer) + '\n')
                buffer.clear()


def safe_mkdir(dir: str):
    if not os.path.exists(dir):
        try:
            os.makedirs(dir)
        except OSError as e:
            # when another thread create this directory
            assert e.errno == errno.EEXIST


def is_older(left, right):
    if not os.path.isfile(right):
        return False
    assert os.path.isfile(left)
    return os.path.getmtime(left) < os.path.getmtime(right)


def avoid_repeating(
        emu: str, input_file: str, output_dir: str,
        force_run: bool,
        func, *args, **kwargs):
    # this function avoid repeated run for most common situations
    input_file_n = os.path.basename(input_file)
    emu_n = os.path.basename(emu)

    # python 3.6 please
    running_lock_name = f'running-{func.__name__}-{emu_n}-{input_file_n}'
    running_lock_file = pjoin(output_dir, running_lock_name)

    if os.path.isfile(running_lock_file):
        print('running lock found in {}, skip!'.format(output_dir))
        return
    else:
        sh.touch(running_lock_file)

    script_ts_dir = pjoin(str(Path(__file__).resolve().parent), 'ts')
    safe_mkdir(script_ts_dir)
    # python 3.6 please
    ts_name = f'ts-{func.__name__}-{emu_n}-{input_file_n}'

    out_ts_file = pjoin(output_dir, ts_name)
    if os.path.isfile(out_ts_file):
        out_ts = os.path.getmtime(out_ts_file)
    else:
        out_ts = 0.0

    script_ts_file = pjoin(script_ts_dir, ts_name)
    if not os.path.isfile(script_ts_file):
        sh.touch(script_ts_file)
    script_ts = os.path.getmtime(script_ts_file)

    program_ts = os.path.getmtime(emu)
    input_binary_ts = os.path.getmtime(input_file)

    cmd_ts = max(script_ts, program_ts, input_binary_ts)

    if out_ts < cmd_ts or force_run:
        try:
            func(*args, **kwargs)
            sh.touch(out_ts_file)
        except Exception as e:
            print(e)
        sh.rm(running_lock_file)
    else:
        print('none of the inputs is older than output, skip!')
        if os.path.isfile(running_lock_file):
            sh.rm(running_lock_file)


def get_am_apps():
    assert 'AM_HOME' in os.environ.keys()
    app_dir = pjoin(os.environ['AM_HOME'], 'apps')
    apps = os.listdir(app_dir)
    return apps


def get_am_app_dir(app: str):
    assert 'AM_HOME' in os.environ.keys()
    app_base_dir = pjoin(os.environ['AM_HOME'], 'apps')
    app_dir = pjoin(app_base_dir, app)
    assert os.path.isdir(app_dir)
    return app_dir


if __name__ == '__main__':
    hex_dump('/home/zyy/projects/nexus-am/apps/cache-flush/build/cache-flush'
             '-riscv64-rocket.bin', 'test.txt')
