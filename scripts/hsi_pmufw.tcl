set zynq_root [lindex $argv 1]
source $zynq_root/scripts/hsi_common.tcl

if { ([string compare $target "zcu102"] == 0) || ([string compare $target "zcu106"] == 0 )} {
    # PMUFW
    hsi generate_app -hw $design -os standalone -proc psu_pmu_0 -app zynqmp_pmufw -compile -sw pmufw -dir pmufw
}
