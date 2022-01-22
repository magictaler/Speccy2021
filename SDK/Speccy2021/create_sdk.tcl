#*****************************************************************************************
# This script will built the Vivado SDK project from the following
# sources:
#    "speccy2021_top.hdf"
#    "Speccy2021/src"
#    "bootimage/Speccy2021.bif"
#    "bootimage/Speccy2021_debug.bif"
#*****************************************************************************************

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "[file normalize "."]"

set c_project_name "Speccy2021"
set hw_project_name "Speccy2021_hw_platform"
set bsp_project_cpu0_name "Speccy2021_cpu0_bsp"
set fsbl_project_name "fsbl"
set fsbl_bsp_project_name "fsbl_bsp"
set hdf_project_name "speccy2021_top"

source "../common/shared_procs.tcl"

# Set the build number the first variable passed on the command line or 0 if none given
if { $argc == 0 } {
    set build_number 0
} else {
    set build_number [lindex $argv 0]
}

set build_config "all"

# Get the other named command line arguments, first is --config all/debug/release
if { $argc >= 2 } {
    set index 1
    while {$index < $argc} {
        if {[string equal [lindex $argv $index] "--config"]} {
            incr index
            set build_config [string tolower [lindex $argv $index]]
        }
        if {[string equal [lindex $argv $index] "--clean"]} {
            puts "Clean project directories selected. Running clean script"
            set force_clean true
            source clean_all.tcl
        }
        incr index
    }
    puts "Build config selected: $build_config"
}

# If no valid build config is selected, default to all.
if { $build_config != "all" && $build_config != "release" && $build_config != "debug"} {
    puts "Invalid build config selected, defaulting to all"
    set build_config "all"
}

puts "Speccy2021 hardware project $c_project_name"

# Check HDF exists
set hdf_file_name ${hdf_project_name}.hdf
if { ![file exists ${hdf_file_name}] } {
    puts "File $hdf_file_name is missing, exiting."
    exit 1
}

# Set the workspace to the current directory. From now on the results of all other
# commands will end up here.
setws .

# Take the FPGA Build's top_level_wrapper.hdf and create a hardware package
createhw -name $hw_project_name -hwspec $hdf_file_name

# Create main BSP
# Use the hardware package and create a board support package (BSP) for standalone
# Configure the main BSP to contain the correct libraries and parameters
createbsp -name $bsp_project_cpu0_name -hwproject $hw_project_name -proc [get_processor_name $hw_project_name] -os freertos901_xilinx

# Configure freertos kernel
configbsp -bsp $bsp_project_cpu0_name tick_rate 1000
#configbsp -bsp $bsp_project_cpu0_name total_heap_size 262144
configbsp -bsp $bsp_project_cpu0_name minimal_stack_size 512

# Enable floating point context in tasks.  This is necessary for avoiding corruption of floating point
# registers (used by floating point operations and some GCC library functions) when context switching.
configbsp -bsp $bsp_project_cpu0_name -append extra_compiler_flags "-DconfigUSE_TASK_FPU_SUPPORT=2 -DLWIP_SO_RCVTIMEO=1 -DconfigSUPPORT_STATIC_ALLOCATION=1"

# Add and configure Light Weight IP (lwip) library
setlib -bsp $bsp_project_cpu0_name -lib lwip141
configbsp -bsp $bsp_project_cpu0_name api_mode SOCKET_API
configbsp -bsp $bsp_project_cpu0_name lwip_dhcp true
configbsp -bsp $bsp_project_cpu0_name phy_link_speed CONFIG_LINKSPEED100
configbsp -bsp $bsp_project_cpu0_name emac_number 1

# Wait for 4 seconds to allow xilinx to free up resources to avoid future builds failing.
puts "Waiting for xilinx to release control of header files"
after 4000

regenbsp -bsp $bsp_project_cpu0_name

# Create FSBL BSP
# Use the hardware package and create a board support package (BSP)
# Configure the main BSP to contain the correct libraries and parameters
createbsp -name $fsbl_bsp_project_name -hwproject $hw_project_name -proc [get_processor_name $hw_project_name] -os standalone
setlib -bsp $fsbl_bsp_project_name -lib xilffs

# Add and configure Xilinx In-serial Flash (xilisf) library
setlib -bsp $fsbl_bsp_project_name -lib xilisf
configbsp -bsp $fsbl_bsp_project_name serial_flash_family 5
configbsp -bsp $fsbl_bsp_project_name serial_flash_interface 3

# Wait for 2 seconds to allow xilinx to free up resources to avoid future builds failing.
puts "Waiting for xilinx to release control of header files"
after 4000

regenbsp -bsp $fsbl_bsp_project_name

# Create first stage bootloader
createapp -name $fsbl_project_name -app {Empty Application} -bsp $fsbl_bsp_project_name -hwproject ${hw_project_name} -proc [get_processor_name $hw_project_name] -os standalone
file delete "$origin_dir/$fsbl_project_name/src/lscript.ld"
add_linked_resource "$origin_dir/$fsbl_project_name" "src/ps7_init.c" "WORKSPACE_LOC/$hw_project_name/ps7_init.c" 1

# Create an empty application in the demo directory where we already keep our sources.
# This way our sources are added to the empty project
createapp -name $c_project_name -app {Empty Application} -bsp $bsp_project_cpu0_name -hwproject ${hw_project_name} -proc [get_processor_name $hw_project_name] -os freertos901_xilinx
file delete "$c_project_name/src/lscript.ld"

# Get the version info from the version.c and print it
set file [open "$c_project_name/src/version.c"]
while {[gets $file line] != -1} {
    if {[regexp {VERSION_([A-Z]+).*([0-9]+)} $line matched version_part value]} {
        dict set version [string tolower $version_part] $value
    }
}
close $file
set version_string [dict get $version major]_[dict get $version minor]_[dict get $version bugfix]_$build_number
puts "Building version: [string map {_ .} $version_string]"

# Use our own linker files instead of autogenerated
file copy -force "lscripts/$c_project_name/lscript.ld" "$c_project_name/src/"
file copy -force "lscripts/$fsbl_project_name/lscript.ld" "$fsbl_project_name/src/"

after 3000

if { $build_config == "release" || $build_config == "all" } {
    # Build the release version of the Demo and the FSBL
    configapp -app $c_project_name build-config Release
    configapp -app $fsbl_project_name build-config Release

    # Set the build number
    puts "Add macro: BUILD_NUMBER=$build_number"

    # Configure FSBL
    configapp -app $fsbl_project_name define-compiler-symbols "BUILD_NUMBER=$build_number"
    configapp -app $fsbl_project_name define-compiler-symbols "PROJECT=FSBL_APP"
    configapp -app $fsbl_project_name include-path "\"\${workspace_loc:/$hw_project_name}\""

    # Configure main project
    configapp -app $c_project_name define-compiler-symbols "BUILD_NUMBER=$build_number"
    configapp -app $c_project_name define-compiler-symbols "CS_PLATFORM=CS_P_ZYNQ"
    configapp -app $c_project_name define-compiler-symbols "MG_LOCALS"
    configapp -app $c_project_name define-compiler-symbols "CS_NDEBUG"
    configapp -app $c_project_name define-compiler-symbols "PROJECT=SPECCY2021_APP"
    configapp -app $c_project_name define-compiler-symbols "CPU0"
    configapp -app $c_project_name define-compiler-symbols "CFG_TUSB_RHPORT0_MODE=OPT_MODE_HOST"
    configapp -app $c_project_name define-compiler-symbols "CFG_TUSB_MCU=OPT_MCU_ZYNQ70XX"
    configapp -app $c_project_name define-compiler-symbols "CFG_TUSB_OS=OPT_OS_FREERTOS"
    configapp -app $c_project_name define-compiler-symbols "CFG_TUH_ENUMERATION_BUFSIZE=512"
    configapp -app $c_project_name define-compiler-symbols "configSUPPORT_STATIC_ALLOCATION=1"
    configapp -app $c_project_name define-compiler-symbols "FILE_SYSTEM_INTERFACE_SD"
    configapp -app $c_project_name linker-misc { -Xlinker --defsym=_STACK_SIZE=0x200000 }
    configapp -app $c_project_name linker-misc { -Xlinker --defsym=_HEAP_SIZE=0x200000 }
    configapp -app $c_project_name libraries "m"

    projects -build
}

if { $build_config == "debug" || $build_config == "all" } {
    # Build the debug version of the Demo and the FSBL
    # The debug version is build last, so the project remains configured for the debug
    # after it has been generated. This is easier for developers using the project files.
    configapp -app $c_project_name build-config Debug
    configapp -app $fsbl_project_name build-config Debug

    # Set the build number
    puts "Add macro: BUILD_NUMBER=$build_number"

    # Configure FSBL
    configapp -app $fsbl_project_name define-compiler-symbols "BUILD_NUMBER=$build_number"
    configapp -app $fsbl_project_name define-compiler-symbols "FSBL_DEBUG_INFO"
    configapp -app $fsbl_project_name define-compiler-symbols "FSBL_PERF"
    configapp -app $fsbl_project_name define-compiler-symbols "PROJECT=FSBL_APP"
    configapp -app $fsbl_project_name include-path "\"\${workspace_loc:/$hw_project_name}\""

    # Configure main application
    configapp -app $c_project_name define-compiler-symbols "BUILD_NUMBER=$build_number"
    configapp -app $c_project_name define-compiler-symbols "CS_PLATFORM=CS_P_ZYNQ"
    configapp -app $c_project_name define-compiler-symbols "MG_LOCALS"
    configapp -app $c_project_name define-compiler-symbols "DEBUG"
    configapp -app $c_project_name define-compiler-symbols "PROJECT=SPECCY2021_APP"
    configapp -app $c_project_name define-compiler-symbols "CPU0"
    configapp -app $c_project_name define-compiler-symbols "CFG_TUSB_RHPORT0_MODE=OPT_MODE_HOST"
    configapp -app $c_project_name define-compiler-symbols "CFG_TUSB_MCU=OPT_MCU_ZYNQ70XX"
    configapp -app $c_project_name define-compiler-symbols "CFG_TUSB_OS=OPT_OS_FREERTOS"
    configapp -app $c_project_name define-compiler-symbols "CFG_TUH_ENUMERATION_BUFSIZE=512"
    configapp -app $c_project_name define-compiler-symbols "configSUPPORT_STATIC_ALLOCATION=1"
    configapp -app $c_project_name define-compiler-symbols "FILE_SYSTEM_INTERFACE_SD"
    configapp -app $c_project_name linker-misc { -Xlinker --defsym=_STACK_SIZE=0x200000 }
    configapp -app $c_project_name linker-misc { -Xlinker --defsym=_HEAP_SIZE=0x200000 }
    configapp -app $c_project_name libraries "m"

    projects -build
}

exit
