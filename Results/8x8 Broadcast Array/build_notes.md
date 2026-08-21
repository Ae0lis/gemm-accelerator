## Note about Quartus warnings: 
This project is based on Terasic’s DE1-SoC Golden Hardware Reference Design, which is warning-heavy when compiled in Quartus Prime Lite 17.0. A clean build may produce hundreds of warnings, and warning totals can vary between Quartus views and tool configurations.

A known-good build should complete with zero errors, finish Analysis & Synthesis, Fitter, Assembler, and TimeQuest successfully, meet the 50 MHz fabric timing constraint, and infer 64 DSP blocks for the accelerator. Compare any new warnings against the known-good build rather than dismissing them automatically.

My successful hardware build also reports warnings for 72 pins without exact location assignments and one RUP/RDN/RZQ calibration pin. The bitstream nevertheless passed the documented 8×8 hardware test on my revision-G DE1-SoC. Anyone targeting another board or modifying the top-level design should review these assignments before programming the FPGA.