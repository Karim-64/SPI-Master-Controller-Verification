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
add wave -noupdate -expand -group apb_if_group /top/apb/PCLK
add wave -noupdate -expand -group apb_if_group /top/apb/presetn
add wave -noupdate -expand -group apb_if_group /top/apb/psel
add wave -noupdate -expand -group apb_if_group /top/apb/penable
add wave -noupdate -expand -group apb_if_group /top/apb/pwrite
add wave -noupdate -expand -group apb_if_group /top/apb/tx_pop
add wave -noupdate -expand -group apb_if_group /top/apb/rx_push_valid
add wave -noupdate -expand -group apb_if_group /top/apb/busy_in
add wave -noupdate -expand -group apb_if_group /top/apb/transfer_done_pulse
add wave -noupdate -expand -group apb_if_group /top/apb/paddr
add wave -noupdate -expand -group apb_if_group /top/apb/pwdata
add wave -noupdate -expand -group apb_if_group /top/apb/rx_push_data
add wave -noupdate -expand -group apb_if_group /top/apb/pready
add wave -noupdate -expand -group apb_if_group /top/apb/pslverr
add wave -noupdate -expand -group apb_if_group /top/apb/cfg_en
add wave -noupdate -expand -group apb_if_group /top/apb/cfg_mstr
add wave -noupdate -expand -group apb_if_group /top/apb/cfg_lsb_first
add wave -noupdate -expand -group apb_if_group /top/apb/cfg_loopback
add wave -noupdate -expand -group apb_if_group /top/apb/tx_empty
add wave -noupdate -expand -group apb_if_group /top/apb/irq
add wave -noupdate -expand -group apb_if_group /top/apb/cfg_mode
add wave -noupdate -expand -group apb_if_group /top/apb/cfg_width
add wave -noupdate -expand -group apb_if_group /top/apb/ss_n
add wave -noupdate -expand -group apb_if_group /top/apb/cfg_delay
add wave -noupdate -expand -group apb_if_group /top/apb/cfg_clk_div
add wave -noupdate -expand -group apb_if_group /top/apb/tx_word
add wave -noupdate -expand -group apb_if_group /top/apb/prdata
add wave -noupdate -expand -group spi_if_grpup /top/spi/pclk
add wave -noupdate -expand -group spi_if_grpup /top/spi/tx_empty
add wave -noupdate -expand -group spi_if_grpup /top/spi/miso
add wave -noupdate -expand -group spi_if_grpup /top/spi/presetn
add wave -noupdate -expand -group spi_if_grpup /top/spi/cfg_en
add wave -noupdate -expand -group spi_if_grpup /top/spi/cfg_mstr
add wave -noupdate -expand -group spi_if_grpup /top/spi/cfg_lsb_first
add wave -noupdate -expand -group spi_if_grpup /top/spi/cfg_loopback
add wave -noupdate -expand -group spi_if_grpup /top/spi/cfg_mode
add wave -noupdate -expand -group spi_if_grpup /top/spi/cfg_width
add wave -noupdate -expand -group spi_if_grpup /top/spi/ss_n
add wave -noupdate -expand -group spi_if_grpup /top/spi/cfg_delay
add wave -noupdate -expand -group spi_if_grpup /top/spi/cfg_clk_div
add wave -noupdate -expand -group spi_if_grpup /top/spi/tx_word
add wave -noupdate -expand -group spi_if_grpup /top/spi/irq
add wave -noupdate -expand -group spi_if_grpup /top/spi/tx_pop
add wave -noupdate -expand -group spi_if_grpup /top/spi/rx_push_valid
add wave -noupdate -expand -group spi_if_grpup /top/spi/busy
add wave -noupdate -expand -group spi_if_grpup /top/spi/transfer_done_pulse
add wave -noupdate -expand -group spi_if_grpup /top/spi/sclk
add wave -noupdate -expand -group spi_if_grpup /top/spi/mosi
add wave -noupdate -expand -group spi_if_grpup /top/spi/rx_push_data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1543 ps} 0}
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
WaveRestoreZoom {0 ps} {5756 ps}
