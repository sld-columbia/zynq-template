set zynq_root [lindex $argv 1]
source $zynq_root/scripts/hsi_common.tcl

if { ([string compare $target "zc706"] == 0) || ([string compare $target "zc702"] == 0 )} {

    # FSBL
    hsi generate_app -hw $design -os standalone -proc ps7_cortexa9_0 -app zynq_fsbl -compile -sw fsbl -dir fsbl
}

if { ([string compare $target "zcu102"] == 0) || ([string compare $target "zcu106"] == 0 )} {
    # FSBL
    hsi generate_app -hw $design -os standalone -proc psu_cortexa53_0 -app zynqmp_fsbl -compile -sw fsbl -dir fsbl
}
