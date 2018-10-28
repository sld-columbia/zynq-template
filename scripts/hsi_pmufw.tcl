set target [lindex $argv 0]
set zynq_root [lindex $argv 1]
set devtree $zynq_root/device-tree-xlnx

source $zynq_root/scripts/hsi_common.tcl

if { ([string compare $target "zcu102"] == 0) || ([string compare $target "zcu106"] == 0 )} {
    # PMUFW
    generate_app -hw system_wrapper -os standalone -proc psu_pmu_0 -app zynqmp_pmufw -compile -sw pmufw -dir pmufw
}
