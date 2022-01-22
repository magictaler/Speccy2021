#*****************************************************************************************
# This script will built the ./work/hdmi_zx_video_controller.xpr Vivado project file from the following
# sources:
#    "tcl/top_level_zx_spectrum_video_controller.tcl"
#    "constraints/ArtyZ7_B.xdc"
#*****************************************************************************************

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "[file normalize "."]"

# Make and cd to the the work directory where the project should be created
set work_directory "[file normalize "$origin_dir/work"]"
file mkdir $work_directory
cd $work_directory

# Set the directory path for the original project from where this script was exported
set orig_proj_dir "[file normalize "$origin_dir"]"

# Create project
create_project speccy2021 -force

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Parse command line arguments. Supported arguments: build, board
# Set the build number the first variable in -tclargs or 0 if none given

# defaults
set board arty-z7-20
set part "xc7z020clg400-1"
set brd_part "digilentinc.com:arty-z7-20:part0:1.0"

# Get the other named command line arguments
if { $argc >= 1 } {
    set index 1
    while {$index < $argc} {
        if {[string equal [lindex $argv $index] "board"]} {
            incr index
            if {[string equal [lindex $argv $index] "zedboard"]} {
                set part "xc7z020clg484-1"
                set board [lindex $argv $index]
            }
        }
        incr index
        puts $index
    }
}

puts "INFO: Creating project for $board board with part $part"

# Set project properties
set obj [get_projects speccy2021]
set_property "default_lib" "xil_defaultlib" $obj
set_property "ip_cache_permissions" "read write" $obj
set_property "part" $part $obj
set_property "board_part" $brd_part $obj
set_property "ip_output_repo" "speccy2021.cache/ip" $obj
set_property "sim.ip.auto_export_scripts" "1" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj
set_property "xpm_libraries" "XPM_CDC" $obj
set_property "xsim.array_display_limit" "64" $obj
set_property "xsim.trace_limit" "65536" $obj
set_property "ip_repo_paths" "$origin_dir/ip_repo" $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Call script to create block diagram for selected hardware
set origin_dir_bak $origin_dir
source $origin_dir/tcl/top_level_speccy2021.tcl
set origin_dir $origin_dir_bak

# Add VHDL top architecture - a few examples below
add_files -norecurse $origin_dir/sources/zx_video/zx_video_top.vhd
add_files -norecurse $origin_dir/sources/zx_video/zx_video.vhd
add_files -norecurse $origin_dir/sources/zx_video/zx_ctrl.vhd
add_files -norecurse $origin_dir/sources/speccy2021_top.vhd
add_files -norecurse $origin_dir/sources/zx_addr_data_bus/zx_addr_data_bus_top.vhd
add_files -norecurse $origin_dir/sources/zx_addr_data_bus/zx_addr_data_bus.vhd
add_files -norecurse $origin_dir/sources/zx_main/zx_main_top.vhd
add_files -norecurse $origin_dir/sources/z80/T80.vhd
add_files -norecurse $origin_dir/sources/z80/T80_ALU.vhd
add_files -norecurse $origin_dir/sources/z80/T80_MCode.vhd
add_files -norecurse $origin_dir/sources/z80/T80_Pack.vhd
add_files -norecurse $origin_dir/sources/z80/T80_Reg.vhd
#add_files -norecurse $origin_dir/sources/z80/T80a.vhd
#add_files -norecurse $origin_dir/sources/z80/T80s.vhd
add_files -norecurse $origin_dir/sources/z80/T80se.vhd
add_files -norecurse $origin_dir/sources/zx_sound/pwm.vhd
add_files -norecurse $origin_dir/sources/zx_sound/zx_sound_mixer.vhd
add_files -norecurse $origin_dir/sources/zx_sound/zx_sound_top.vhd
add_files -norecurse $origin_dir/sources/zx_sound/ym2149_volmix.vhd
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/speccy2021_top.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zx_video/zx_video_top.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zx_video/zx_video.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zx_video/zx_ctrl.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zx_addr_data_bus/zx_addr_data_bus_top.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zx_addr_data_bus/zx_addr_data_bus.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zx_main/zx_main_top.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/z80/T80.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/z80/T80_ALU.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/z80/T80_MCode.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/z80/T80_Pack.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/z80/T80_Reg.vhd]
#set_property file_type {VHDL 2008} [get_files $origin_dir/sources/z80/T80a.vhd]
#set_property file_type {VHDL 2008} [get_files $origin_dir/sources/z80/T80s.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/z80/T80se.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zx_sound/zx_sound_top.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zx_sound/pwm.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zx_sound/zx_sound_mixer.vhd]
set_property file_type {VHDL 2008} [get_files $origin_dir/sources/zx_sound/ym2149_volmix.vhd]
add_files -norecurse $origin_dir/ip_repo/fifo_512_64/fifo_512_64.xci
add_files -norecurse $origin_dir/ip_repo/fifo_1024_16/fifo_1024_16.xci

upgrade_ip [get_ips] -log ip_upgrade.log
export_ip_user_files -of_objects [get_ips] -no_script -sync -force -quiet

# Generate the wrapper 
set design_name [get_bd_designs]
puts "INFO: design_name: $design_name"
#make_wrapper -files [get_files $design_name.bd] -top -force -quiet -import

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "top" "speccy2021_top" $obj

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Add constraints
add_files -fileset constrs_1 -quiet $origin_dir/constraints

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
# Empty (no sources present)

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property "top" "test_pattern_top" $obj

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
  create_run -name synth_1 -part $part -flow {Vivado Synthesis 2016} -strategy "Vivado Synthesis Defaults" -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2016" [get_runs synth_1]
}
set obj [get_runs synth_1]
set_property "part" "$part" $obj

# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
  create_run -name impl_1 -part $part -flow {Vivado Implementation 2016} -strategy "Vivado Implementation Defaults" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
  set_property flow "Vivado Implementation 2016" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property "part" "$part" $obj
set_property "steps.write_bitstream.args.readback_file" "0" $obj
set_property "steps.write_bitstream.args.verbose" "0" $obj

# set the current impl run
current_run -implementation [get_runs impl_1]

# Set the build constant to the build number given as parameter. If not given
# then it is left to the value in the block diagram. This value must be left
# at 0.
open_bd_design [file normalize "$work_directory/speccy2021.srcs/sources_1/bd/speccy2021/speccy2021.bd"]

save_bd_design

close_bd_design [get_bd_designs system]

set_property source_mgmt_mode DisplayOnly [current_project]

set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]

puts "INFO: Project created:speccy2021"
