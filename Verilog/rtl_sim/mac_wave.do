onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group {Input Vectors} /mac_testbench/a
add wave -noupdate -expand -group {Input Vectors} /mac_testbench/b
add wave -noupdate -expand -group Controls /mac_testbench/clk
add wave -noupdate -expand -group Controls /mac_testbench/clear
add wave -noupdate -expand -group Controls /mac_testbench/valid
add wave -noupdate -expand -group Output /mac_testbench/sum
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
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
WaveRestoreZoom {0 ps} {12632 ps}
