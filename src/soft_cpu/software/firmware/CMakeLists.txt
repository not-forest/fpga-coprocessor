cmake_minimum_required(VERSION 3.14)

add_subdirectory(../hal_bsp hal_bsp)

include(../hal_bsp/toolchain.cmake)

project(coproc_firmware)

enable_language(ASM)
enable_language(C)
enable_language(CXX)

add_executable(coproc_firmware.elf)

target_sources(coproc_firmware.elf
    PRIVATE
        firmware.h
        main.c
        sys_io.c
)

target_include_directories(coproc_firmware.elf
    PRIVATE
    PUBLIC
)

target_link_libraries(coproc_firmware.elf
    PRIVATE
        -T "${BspLinkerScript}" -nostdlib
        "${ExtraArchiveLibraries}"
        -Wl,--start-group "${BspLibraryName}" -lc -lstdc++ -lgcc -lm -Wl,--end-group
)

# Create objdump from ELF.
set(objdump coproc_firmware.elf.objdump)
add_custom_command(
    OUTPUT "${objdump}"
    DEPENDS coproc_firmware.elf
    COMMAND "${ToolchainObjdump}" "${ToolchainObjdumpFlags}" coproc_firmware.elf >
            "${objdump}"
    COMMENT "Creating ${objdump}."
    VERBATIM
)
add_custom_target(create-objdump ALL DEPENDS "${objdump}")

# Report space free for stack + heap. Note that the file below is never created
# so the report is always output on build.
set(stack_report_file coproc_firmware.elf.stack_report)
add_custom_command(
    OUTPUT "${stack_report_file}"
    DEPENDS coproc_firmware.elf
    COMMAND niosv-stack-report -p "${ToolchainPrefix}" coproc_firmware.elf
    COMMENT "Reporting memory available for stack + heap in coproc_firmware.elf."
    VERBATIM
)
add_custom_target(niosv-stack-report ALL DEPENDS "${stack_report_file}")

# Generate HEX file(s) from coproc_firmware.elf using elf2hex tool.
# Note : If ECC Full is enabled, width of 39 is set for NiosV TCM. Otherwise, 32.
add_custom_command(
    OUTPUT "SRAM.hex"
    DEPENDS coproc_firmware.elf
    COMMAND elf2hex coproc_firmware.elf -o SRAM.hex -b 0x00028000 -w 32 -e 0x0002CFFF -r 4
    COMMENT "Creating SRAM.hex."
    VERBATIM
)
add_custom_target(create-hex ALL DEPENDS "SRAM.hex")
