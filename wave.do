onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group master_if_group /top/masterif/pclk
add wave -noupdate -expand -group master_if_group /top/masterif/presetn
add wave -noupdate -expand -group master_if_group /top/masterif/psel
add wave -noupdate -expand -group master_if_group /top/masterif/penable
add wave -noupdate -expand -group master_if_group /top/masterif/pwrite
add wave -noupdate -expand -group master_if_group /top/masterif/paddr
add wave -noupdate -expand -group master_if_group /top/masterif/pwdata
add wave -noupdate -expand -group master_if_group /top/masterif/miso
add wave -noupdate -expand -group master_if_group /top/masterif/pready
add wave -noupdate -expand -group master_if_group /top/masterif/pslverr
add wave -noupdate -expand -group master_if_group /top/masterif/prdata
add wave -noupdate -expand -group master_if_group /top/masterif/mosi
add wave -noupdate -expand -group master_if_group /top/masterif/ss_n
add wave -noupdate -expand -group master_if_group /top/masterif/sclk
add wave -noupdate -expand -group master_if_group /top/masterif/irq
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {42704 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 371
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {22914 ps} {87215 ps}
