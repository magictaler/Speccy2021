# README #

ZX Spectrum Emulator running on ARTY Z7-20 hardware for Vivado 2017.3

Features:
- HDMI output with scandoubler and multiple resolutions;
- Emulation of classic 48K / 128K models;
- USB host mode, HID keyboard support;
- Emulation of standard beeper and AY-8910, audio output is through ARTY's onboard mono amplifier;
- Emulation of tape recorder;
- FAT16/32 file system on SD card, basic shell for navigation;
- At the moment the emulator supports TAP, TZX and SNA file formats but the list is growing...

Disclaimer for original ZX-Spectrum estets and purists:
- This is not cycle-accurate emulator, it has non-standard video controller and
  won't be able to emulate 100% compatible version of the ZX-Spectrum. Complex
  border effects do not work either;

Based on the original "Arty-Z7-20-hdmi-out" example from Digilent

Inspired by the Speccy2010 project

Copyright (C) 2021 Magictale Electronics
http://magictale.com

Getting started:

* Build the PL code locally by executing the following commands in the:

       Vivado directory:
        
        + Create the project file from the block diagram, wrapper and constraints file:
            vivado -mode batch -source create_project_file.tcl
        
        + Synthesise, place & route and generate bitfile for use in SDK:
            vivado -mode batch -source create_sdk_files.tcl

* Execute the following command in the SDK/hdmi_out_demo directory:
    + xsdk -batch create_sdk.tcl 0

* Now the SDK can be opened with the following command:
    + xsdk -workspace .

* The boot image can be created with the following comand:
    + xsdk -batch bootgen_sdk.tcl 0
