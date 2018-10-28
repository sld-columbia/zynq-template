
# Generate the device tree and boot loader through SDK
if { [string compare $target "zc706"] == 0 } {
    puts "Target Board is zc706"
} elseif { [string compare $target "zc702"] == 0 } {
    puts "Target Board is zc702"
} elseif { [string compare $target "zcu102"] == 0 } {
    puts "Target Board is zcu102"
} elseif { [string compare $target "zcu106"] == 0 } {
    puts "Target Board is zcu106"
} else {
    puts "Board part number is invalid!"
    exit
}

open_hw_design system_wrapper.hdf
set_repo_path $devtree

