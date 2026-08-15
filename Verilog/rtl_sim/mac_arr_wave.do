onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Controls /arr_ram_testbench/clk
add wave -noupdate -expand -group Controls /arr_ram_testbench/wren
add wave -noupdate -expand -group Controls /arr_ram_testbench/wradr
add wave -noupdate -expand -group Input /arr_ram_testbench/index
add wave -noupdate -expand -group Input /arr_ram_testbench/wradr
add wave -noupdate -expand -group Input /arr_ram_testbench/rdadr
add wave -noupdate -expand -group Input /arr_ram_testbench/writedata
add wave -noupdate -expand -group Output /arr_ram_testbench/readdata
add wave -noupdate -expand -group Output /arr_ram_testbench/busreaddata
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {225 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {1316 ps}
