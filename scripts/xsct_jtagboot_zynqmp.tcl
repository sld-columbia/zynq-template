# XSCT script
#

# Location of binaries
set host   [lindex $argv 0]
set port   [lindex $argv 1]
set images [lindex $argv 2]
set hwdesc [lindex $argv 3]
set bit    [lindex $argv 4]

# Set hardware server or 'localhost' if none given
if { [catch {connect -host $host -port $port -symbols}] != 0} {
  puts stderr "ERROR: Could not connect to ${host}:${port}."
  exit 1
}
puts stderr "*) Connected to ${host}:${port}"

puts stderr "*) PS reset"

targets -set -nocase -filter {name =~ "*TAP*"}
rst -por
after 2000

targets -set -nocase -filter {name =~ "*PMU*"}
stop
rst -system
after 2000

targets -set -nocase -filter {name =~ "*PSU*"}
stop
rst -system
after 2000


puts stderr "*) JTAG boot"

puts stderr "INFO: Configuring the FPGA..."
puts stderr "INFO: Downloading bitstream: $bit to the target."
fpga $bit

# Disable security gates for DAP, PL TAP & PMU
targets -set -nocase -filter {name =~ "*PSU*"}
mask_write 0xFFCA0038 0x1C0 0x1C0

# Download PMU firmware to MicroBlaze PMU
targets -set -nocase -filter {name =~ "*MicroBlaze PMU*"}
catch {stop}; after 1000
puts stderr "INFO: Downloading PMU firmware $images/pmufw.elf"
dow $images/pmufw.elf
after 2000
con

targets -set -nocase -filter {name =~ "*APU*"}
mwr 0xffff0000 0x14000000
mask_write 0xFD1A0104 0x501 0x0

# # Read boot mode
# set mode [expr [mrd -value 0xFF5E0200] & 0xf]
# puts stderr "INFO: Boot mode set to $mode"
# if {$mode != 0x100} {
#     puts stderr "INFO: Forcing Alternate boot mode to JTAG"
#     mwr 0xFF5E0200 0x100
# }

# Reset APU#0 and run psu_init
targets -set -nocase -filter {name =~ "*A53*#0"}
rst -processor
puts stderr "INFO: Run PSU initialization"
source $hwdesc/psu_init.tcl

# Download FSBL
rst -processor
puts stderr "INFO: Downloading FSBL $images/fsbl.elf"
dow $images/fsbl.elf
after 2000
# set bp_45_33_fsbl_bp [bpadd -addr &XFsbl_Exit]
# con -block -timeout 50
# bpremove $bp_45_33_fsbl_bp
con
after 5000;
catch {stop};
catch {stop};
psu_ps_pl_isolation_removal; psu_ps_pl_reset_config

# Download device tree
targets -set -nocase -filter {name =~ "*A53*#0"}
puts stderr "INFO: Downloading device tree blob: $images/system.dtb at 0x04000000"
dow -data "$images/system.dtb" 0x04000000
after 2000

# Download and run u-boot
puts stderr "INFO: Downloading U-Boot $images/u-boot.elf"
dow $images/u-boot.elf

# Download and run ATF
puts stderr "INFO: Downloading ATF $images/bl31.elf"
dow $images/bl31.elf

# Download Linux kernel
# puts stderr "INFO: Downloading Kernel: $images/Image at 0x80000"
# dow -data "$images/Image" 0x80000

con
exit
