set target [lindex $argv 0]

# Create Vivado project
if { [string compare $target "zc706"] == 0 } {
    create_project $target -part xc7z045ffg900-2
} elseif { [string compare $target "zc702"] == 0 } {
    create_project $target -part xc7z020clg484-1
} elseif { [string compare $target "zcu102"] == 0 } {
    create_project $target -part xczu9eg-ffvb1156-2-e
} elseif { [string compare $target "zcu106"] == 0 } {
    create_project $target -part xczu7ev-ffvc1156-2-e
} else {
    puts "Board part number is invalid!"
    exit
}

set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects $target]
if { [string compare $target "zc706"] == 0 } {
    set_property "board_part" "xilinx.com:zc706:part0:1.4" $obj
} elseif { [string compare $target "zc702"] == 0 } {
    set_property "board_part" "xilinx.com:zc702:part0:1.4" $obj
} elseif { [string compare $target "zcu102"] == 0 } {
    set_property "board_part" "xilinx.com:zcu102:part0:3.3" $obj
} elseif { [string compare $target "zcu106"] == 0 } {
    set_property "board_part" "xilinx.com:zcu106:part0:2.3" $obj
}

set_property "default_lib" "xil_defaultlib" $obj
set_property "simulator_language" "Mixed" $obj

# Create Block Design
create_bd_design "system"

if { [string compare $target "zc706"] == 0 } {
    create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
    set_property -dict [list CONFIG.preset {ZC706}] [get_bd_cells processing_system7_0]
    apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
    connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
} elseif { [string compare $target "zc702"] == 0 } {
    create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
    set_property -dict [list CONFIG.preset {ZC702}] [get_bd_cells processing_system7_0]
    apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
    connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
} elseif { ([string compare $target "zcu102"] == 0) || ([string compare $target "zcu106"] == 0 )} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.3 zynq_ultra_ps_e_0
    apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]
    set_property -dict [list CONFIG.PSU__USE__M_AXI_GP0 {0} CONFIG.PSU__USE__M_AXI_GP1 {0}] [get_bd_cells zynq_ultra_ps_e_0]
    set_property -dict [list CONFIG.PSU__FPGA_PL0_ENABLE {0} CONFIG.PSU__USE__IRQ0 {0}] [get_bd_cells zynq_ultra_ps_e_0]
}

# Add customization here...

# Validate design
validate_bd_design

# Save design
save_bd_design

# Generate resources for synthesis
generate_target all [get_files $proj_dir/$target.srcs/sources_1/bd/system/system.bd]

# Create HDL wrapper
make_wrapper -files [get_files $proj_dir/$target.srcs/sources_1/bd/system/system.bd] -top
add_files -norecurse $proj_dir/$target.srcs/sources_1/bd/system/hdl/system_wrapper.v
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Run syntehsis and generate bitstream
launch_runs synth_1
wait_on_run -timeout 360 synth_1
get_ips
launch_runs impl_1 -to_step write_bitstream
wait_on_run -timeout 360 impl_1

