## labeled-RISC-V

Use `smp-default` branch from https://github.com/LvNA-system/labeled-RISC-V.git to build rocketchip bitstream and riscv-linux image (may need to remove old `sw/riscv-pk` repo to make sure BBL can get updated).

## DTS

BBL now fetches uart address from device tree. So we need to add information to the generated dts found in `fpga/build/generated-src/`.

Add this block after interrupt-controller (make sure the label `L23` is not duplicated):

```dts
L23: serial@60000000 {
    compatible = "sifive,uart0";
    interrupt-parent = <&L1>;
    interrupts = <3>;
    reg = <0x0 0x60000000 0x0 0x1000>;
    reg-names = "control";
};
```

And change `riscv,ndev = <2>` under interrupt-controller to `riscv,ndev = <3>`.

## Use Openocd

### Remote Bit Bang

Build `prm-sw/app/rbb-server` for your fpga board.
**Remember to change the axi-jtag memory mapping address defined in `prm-sw/platform/platform-fpga/src/map.h`.**

After resetting rocketchip and loading riscv-linux image with corresponding device tree binary,
launch `prm-sw/app/rbb-server/build/rbb-server-fpga` on PS side of the board.

### Run Openocd

Save the following script as `fpga.cfg` at your host and change `<fpga board ip>` to the ip address of the board's PS side:

```Tcl
interface remote_bitbang
remote_bitbang_host <fpga board ip>
remote_bitbang_port 8080

set _CHIPNAME riscv
jtag newtap $_CHIPNAME dap -irlen 5

set _CORE_0 $_CHIPNAME.cpu0

target create $_CORE_0 riscv -chain-position $_CHIPNAME.dap

bindto 0.0.0.0
init
```

And then run `openocd -f fpga.cfg` to get connected with rbb server, wait until openocd listens on ports.

### Openocd commands and scripts

#### Telnet

Run `telnet 127.0.0.1 4444` to access the openocd repl. Basically we can use the following two commands to access RISC-V's debug module (dm):

1. `riscv dmi_read addr`
2. `riscv dmi_write addr data`

The available dm registers and meanings of their fields can be found in [riscv debug spec](https://github.com/riscv/riscv-debug-spec/blob/task_group_vote/riscv-debug-draft.pdf).
Those added by Labeled-RISC-V can be found in `src/main/scala/devices/debug/dm_registers.scala` with `CP_` as prefix.

Writing specific fields or completing a complex operation is inconvenient by directly access dm registers.
Therefore it is recommended to use scripts to do these operations.

##### Script

Example scripts utilizing openocd's tcl port can be found in [openocd's source code](https://github.com/riscv/riscv-openocd/tree/riscv/contrib/rpc_examples).

Labeled-RISC-V repo has already contained a bunch of scripts focusing on the interaction with debug module and control plane.
You can find them in `labeled-RISC-V/fpga/openocd_rpc`.

Here are explanations of some frequently-used scripts:

1. halt: `./halt <hartid>` halts a specific core (hart). It can fail to work and need retry.
2. resume: `./resume <hartid>` resumes a specific core (hart), It can fail to work and need retry as well.
3. set_cp: set controlplane property for selected core (token bucket, etc.) or selected dsid (waymask), run `./set_cp` for the usage.
4. get_cp：get controlplane property from selected core (token bucket, etc.) or selected dsid (waymask), run `./get_cp` for the usage.
5. log: `./log enable|disable` must be executed right after `./halt <hartid>` succeeding. It can enable or disable rocket core's commit log (when emulating).
6. get_mem, put_mem: read and write physical memory through system bus (coherency enabled).
7. others: basically some wraps of multiple dmi read/write commands, or the reader for the dm registers or CSR with the same name. Reading CSR has side effects, only recommended when crashed.

### Emulation

Under `fpga/emu`, execute `make run-emu DEBUG=1` to run emulation with debug interface enabled. It can heavily slowen the emulating performance.
Change port in `fpga.cfg` to get connected to the emulator. The emulator can only continue to execute after openocd being launched.

## DSID

Each core has a different dsid. Currently it is only used to get waymask. Other properties like token bucket and traffic are hard-wired to each core.

To make a program run with a specific dsid, currently we can use `taskset <core-mask> <command>` or `taskset <core-mask> -p <pid>` to bind it to a specific core.
`<core-mask>` is in decimal or hexadecimal. The bit with value 1 means this core is allowed.
