onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Basic /slave_testbench/clk
add wave -noupdate -expand -group Basic /slave_testbench/reset
add wave -noupdate -expand -group Input /slave_testbench/write
add wave -noupdate -expand -group Input /slave_testbench/read
add wave -noupdate -expand -group Input /slave_testbench/address
add wave -noupdate -expand -group Input /slave_testbench/writedata
add wave -noupdate -expand -group Output /slave_testbench/readdata
add wave -noupdate -expand -group Test /slave_testbench/dut/k_counter
add wave -noupdate -expand -group Test /slave_testbench/dut/delayed_k
add wave -noupdate -expand -group Test /slave_testbench/dut/clear
add wave -noupdate -expand -group Test /slave_testbench/dut/enable
add wave -noupdate -expand -group Test /slave_testbench/dut/reada
add wave -noupdate -expand -group Test /slave_testbench/dut/readb
add wave -noupdate -expand -group Test /slave_testbench/dut/a_col
add wave -noupdate -expand -group Test /slave_testbench/dut/C_val
add wave -noupdate /slave_testbench/dut/c_arr/C_internal
add wave -noupdate /slave_testbench/dut/c_arr/C
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {136850 ps} 0}
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
WaveRestoreZoom {134379 ps} {139823 ps}
