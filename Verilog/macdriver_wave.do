onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Basic /macdriver_testbench/clk
add wave -noupdate -expand -group Basic /macdriver_testbench/reset
add wave -noupdate -expand -group Output /macdriver_testbench/array
add wave -noupdate -expand -group Output /macdriver_testbench/done
add wave -noupdate -expand -group Internal /macdriver_testbench/dut/calculator/clear
add wave -noupdate -expand -group Internal /macdriver_testbench/dut/calculator/valid
add wave -noupdate -expand -group Internal /macdriver_testbench/dut/calculator/a
add wave -noupdate -expand -group Internal /macdriver_testbench/dut/calculator/b
add wave -noupdate -expand -group Internal /macdriver_testbench/dut/sum
add wave -noupdate -expand -group States /macdriver_testbench/dut/pps
add wave -noupdate -expand -group States /macdriver_testbench/dut/pns
add wave -noupdate -expand -group States /macdriver_testbench/dut/nps
add wave -noupdate -expand -group States /macdriver_testbench/dut/nns
add wave -noupdate -expand -group States /macdriver_testbench/dut/mps
add wave -noupdate -expand -group States /macdriver_testbench/dut/mns
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3738 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 102
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
configure wave -timelineunits ps
update
WaveRestoreZoom {3498 ps} {4496 ps}
