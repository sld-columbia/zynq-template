set target $::env(BOARD)

# Generate the device tree and boot loader through SDK
if { [string compare $target "zc706"] == 0 } {
    puts "Target Board is zc706"
} elseif { [string compare $target "zc702"] == 0 } {
    puts "Target Board is zc702"
} else {
    puts "Board part number is invalid!"
    exit
}

open_hw_design $target/$target.sdk/system_wrapper.hdf
set_repo_path ../device-tree-xlnx/
create_sw_design device-tree -os device_tree -proc ps7_cortexa9_0
generate_target -dir $target\_dtb
generate_app -hw system_wrapper -os standalone -proc ps7_cortexa9_0 -app zynq_fsbl -compile -sw fsbl -dir $target\_fsbl
