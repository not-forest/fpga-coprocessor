set_global_assignment -entity "coproc_soft_cpu" -library "lib_coproc_soft_cpu" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "coproc_soft_cpu" -library "lib_coproc_soft_cpu" -name IP_TOOL_VERSION "24.1"
set_global_assignment -entity "coproc_soft_cpu" -library "lib_coproc_soft_cpu" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_coproc_soft_cpu" -name SPD_FILE [file join $::quartus(sip_path) "../coproc_soft_cpu.spd"]
set_global_assignment -library "lib_coproc_soft_cpu" -name MISC_FILE [file join $::quartus(sip_path) "../../coproc_soft_cpu.qsys"]

set_global_assignment -library "lib_coproc_soft_cpu" -name MISC_FILE [file join $::quartus(sip_path) "coproc_soft_cpu.vhd"]
set_global_assignment -library "lib_coproc_soft_cpu" -name MISC_FILE [file join $::quartus(sip_path) "coproc_soft_cpu_rst_controller.vhd"]
set_global_assignment -library "lib_coproc_soft_cpu" -name MISC_FILE [file join $::quartus(sip_path) "coproc_soft_cpu_rst_controller_001.vhd"]
set_global_assignment -library "lib_coproc_soft_cpu" -name MISC_FILE [file join $::quartus(sip_path) "submodules/coproc_soft_cpu_CPU.vhd"]
