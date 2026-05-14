onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group master_if_group /top/masterif/pclk
add wave -noupdate -group master_if_group /top/masterif/sclk
add wave -noupdate -group master_if_group /top/masterif/presetn
add wave -noupdate -group master_if_group /top/masterif/psel
add wave -noupdate -group master_if_group /top/masterif/penable
add wave -noupdate -group master_if_group /top/masterif/pwrite
add wave -noupdate -group master_if_group /top/masterif/paddr
add wave -noupdate -group master_if_group /top/masterif/pwdata
add wave -noupdate -group master_if_group /top/masterif/miso
add wave -noupdate -group master_if_group /top/masterif/pready
add wave -noupdate -group master_if_group /top/masterif/pslverr
add wave -noupdate -group master_if_group /top/masterif/prdata
add wave -noupdate -group master_if_group /top/masterif/mosi
add wave -noupdate -group master_if_group /top/masterif/ss_n
add wave -noupdate -group master_if_group /top/masterif/irq
add wave -noupdate -group APB_Group /top/apb/PCLK
add wave -noupdate -group APB_Group /top/apb/presetn
add wave -noupdate -group APB_Group /top/apb/psel
add wave -noupdate -group APB_Group /top/apb/penable
add wave -noupdate -group APB_Group /top/apb/pwrite
add wave -noupdate -group APB_Group /top/apb/tx_pop
add wave -noupdate -group APB_Group /top/apb/rx_push_valid
add wave -noupdate -group APB_Group /top/apb/busy_in
add wave -noupdate -group APB_Group /top/apb/transfer_done_pulse
add wave -noupdate -group APB_Group /top/apb/paddr
add wave -noupdate -group APB_Group /top/apb/pwdata
add wave -noupdate -group APB_Group /top/apb/rx_push_data
add wave -noupdate -group APB_Group /top/apb/pready
add wave -noupdate -group APB_Group /top/apb/pslverr
add wave -noupdate -group APB_Group /top/apb/cfg_en
add wave -noupdate -group APB_Group /top/apb/cfg_mstr
add wave -noupdate -group APB_Group /top/apb/cfg_lsb_first
add wave -noupdate -group APB_Group /top/apb/cfg_loopback
add wave -noupdate -group APB_Group /top/apb/tx_empty
add wave -noupdate -group APB_Group /top/apb/irq
add wave -noupdate -group APB_Group /top/apb/cfg_mode
add wave -noupdate -group APB_Group /top/apb/cfg_width
add wave -noupdate -group APB_Group /top/apb/ss_n
add wave -noupdate -group APB_Group /top/apb/cfg_delay
add wave -noupdate -group APB_Group /top/apb/cfg_clk_div
add wave -noupdate -group APB_Group /top/apb/tx_word
add wave -noupdate -group APB_Group /top/apb/prdata
add wave -noupdate -group APB_Group /top/apb/pready_exp
add wave -noupdate -group APB_Group /top/apb/pslverr_exp
add wave -noupdate -group APB_Group /top/apb/cfg_en_exp
add wave -noupdate -group APB_Group /top/apb/cfg_mstr_exp
add wave -noupdate -group APB_Group /top/apb/cfg_lsb_first_exp
add wave -noupdate -group APB_Group /top/apb/cfg_loopback_exp
add wave -noupdate -group APB_Group /top/apb/tx_empty_exp
add wave -noupdate -group APB_Group /top/apb/irq_exp
add wave -noupdate -group APB_Group /top/apb/cfg_mode_exp
add wave -noupdate -group APB_Group /top/apb/cfg_width_exp
add wave -noupdate -group APB_Group /top/apb/ss_n_exp
add wave -noupdate -group APB_Group /top/apb/cfg_delay_exp
add wave -noupdate -group APB_Group /top/apb/cfg_clk_div_exp
add wave -noupdate -group APB_Group /top/apb/tx_word_exp
add wave -noupdate -group APB_Group /top/apb/prdata_exp
add wave -noupdate -group SPI_GROUP /top/spi/pclk
add wave -noupdate -group SPI_GROUP /top/spi/tx_empty
add wave -noupdate -group SPI_GROUP /top/spi/miso
add wave -noupdate -group SPI_GROUP /top/spi/presetn
add wave -noupdate -group SPI_GROUP /top/spi/cfg_en
add wave -noupdate -group SPI_GROUP /top/spi/cfg_mstr
add wave -noupdate -group SPI_GROUP /top/spi/cfg_lsb_first
add wave -noupdate -group SPI_GROUP /top/spi/cfg_loopback
add wave -noupdate -group SPI_GROUP /top/spi/cfg_mode
add wave -noupdate -group SPI_GROUP /top/spi/cfg_width
add wave -noupdate -group SPI_GROUP /top/spi/ss_n
add wave -noupdate -group SPI_GROUP /top/spi/cfg_delay
add wave -noupdate -group SPI_GROUP /top/spi/cfg_clk_div
add wave -noupdate -group SPI_GROUP /top/spi/tx_word
add wave -noupdate -group SPI_GROUP /top/spi/irq
add wave -noupdate -group SPI_GROUP /top/spi/tx_pop
add wave -noupdate -group SPI_GROUP /top/spi/rx_push_valid
add wave -noupdate -group SPI_GROUP /top/spi/busy
add wave -noupdate -group SPI_GROUP /top/spi/transfer_done_pulse
add wave -noupdate -group SPI_GROUP /top/spi/sclk
add wave -noupdate -group SPI_GROUP /top/spi/mosi
add wave -noupdate -group SPI_GROUP /top/spi/rx_push_data
add wave -noupdate -group SPI_GROUP /top/spi/tx_pop_expected
add wave -noupdate -group SPI_GROUP /top/spi/rx_push_valid_expected
add wave -noupdate -group SPI_GROUP /top/spi/busy_expected
add wave -noupdate -group SPI_GROUP /top/spi/transfer_done_pulse_expected
add wave -noupdate -group SPI_GROUP /top/spi/sclk_expected
add wave -noupdate -group SPI_GROUP /top/spi/mosi_expected
add wave -noupdate -group SPI_GROUP /top/spi/rx_push_data_expected
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {34070797 ps} 0}
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
WaveRestoreZoom {33938906 ps} {34417952 ps}
