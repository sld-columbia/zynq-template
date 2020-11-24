set zynq_root [lindex $argv 1]
source $zynq_root/scripts/hsi_common.tcl

if { ([string compare $target "zc706"] == 0) || ([string compare $target "zc702"] == 0 )} {

    # Device tree
    hsi create_sw_design -os device_tree -proc ps7_cortexa9_0 system_dt
    hsi generate_target -dir dt
    if { ([string compare $target "zc702"] == 0)} {
	hsi set_property CONFIG.periph_type_overrides "{BOARD zc702}" [hsi get_os]
    }
    if { ([string compare $target "zc706"] == 0)} {
	hsi set_property CONFIG.periph_type_overrides "{BOARD zc706}" [hsi get_os]
    }
    hsi set_property CONFIG.bootargs "console=ttyPS0,115200 earlyprintk root=/dev/mmcblk0p2 rw rootwait" [get_os]
    hsi generate_target -dir dt
}

if { [string compare $target "zcu102"] == 0 } {
    # Device tree
    hsi create_sw_design -os device_tree -proc psu_cortexa53_0 system_dt
    hsi generate_target -dir dt
    hsi set_property CONFIG.periph_type_overrides "{BOARD zcu102-rev1.0}" [hsi get_os]
    hsi generate_target -dir dt
}

if { [string compare $target "zcu106"] == 0 } {
    # Device tree
    hsi create_sw_design -os device_tree -proc psu_cortexa53_0 system_dt
    hsi generate_target -dir dt
    hsi set_property CONFIG.periph_type_overrides "{BOARD zcu106-revA}" [hsi get_os]
    hsi generate_target -dir dt
}
