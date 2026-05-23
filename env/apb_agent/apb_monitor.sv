package apb_monitor_pkg;
    import uvm_pkg::*;
    // import apb_shared_pkg::*;
    import apb_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    class apb_monitor extends uvm_monitor ;
        `uvm_component_utils(apb_monitor);

        virtual apb_if vif_cfg; 
        apb_sequence_item rsp_seq_item;

        uvm_analysis_port #(apb_sequence_item) mon_ap;

        function new (string name = "apb_monitor" , uvm_component parent = null);
            super.new(name,parent);
        endfunction

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            mon_ap = new("mon_ap",this);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                rsp_seq_item = apb_sequence_item::type_id::create("rsp_seq_item");
                @(negedge vif_cfg.PCLK); 
                rsp_seq_item.presetn             = vif_cfg.presetn;
                rsp_seq_item.psel                = vif_cfg.psel;
                rsp_seq_item.penable             = vif_cfg.penable;
                rsp_seq_item.pwrite              = vif_cfg.pwrite;
                rsp_seq_item.paddr               = vif_cfg.paddr;
                rsp_seq_item.pwdata              = vif_cfg.pwdata;
                rsp_seq_item.tx_pop              = vif_cfg.tx_pop;
                rsp_seq_item.rx_push_valid       = vif_cfg.rx_push_valid;
                rsp_seq_item.rx_push_data        = vif_cfg.rx_push_data;
                rsp_seq_item.busy_in             = vif_cfg.busy_in;
                rsp_seq_item.transfer_done_pulse = vif_cfg.transfer_done_pulse;
                
                rsp_seq_item.pready_exp        = vif_cfg.pready_exp;
                rsp_seq_item.pslverr_exp       = vif_cfg.pslverr_exp;
                rsp_seq_item.cfg_en_exp        = vif_cfg.cfg_en_exp;
                rsp_seq_item.cfg_mstr_exp      = vif_cfg.cfg_mstr_exp;
                rsp_seq_item.cfg_lsb_first_exp = vif_cfg.cfg_lsb_first_exp;
                rsp_seq_item.cfg_loopback_exp  = vif_cfg.cfg_loopback_exp;
                rsp_seq_item.tx_empty_exp      = vif_cfg.tx_empty_exp;
                rsp_seq_item.irq_exp           = vif_cfg.irq_exp;
                rsp_seq_item.cfg_mode_exp      = vif_cfg.cfg_mode_exp;
                rsp_seq_item.cfg_width_exp     = vif_cfg.cfg_width_exp;
                rsp_seq_item.ss_n_exp          = vif_cfg.ss_n_exp;
                rsp_seq_item.cfg_delay_exp     = vif_cfg.cfg_delay_exp;
                rsp_seq_item.cfg_clk_div_exp   = vif_cfg.cfg_clk_div_exp;
                rsp_seq_item.tx_word_exp       = vif_cfg.tx_word_exp;
                rsp_seq_item.prdata_exp        = vif_cfg.prdata_exp;
                
                rsp_seq_item.pready     = vif_cfg.pready;   
                rsp_seq_item.pslverr    = vif_cfg.pslverr;
                rsp_seq_item.cfg_en     = vif_cfg.cfg_en;
                rsp_seq_item.cfg_mstr   = vif_cfg.cfg_mstr;
                rsp_seq_item.cfg_lsb_first = vif_cfg.cfg_lsb_first;
                rsp_seq_item.cfg_loopback  = vif_cfg.cfg_loopback;
                rsp_seq_item.tx_empty    = vif_cfg.tx_empty;
                rsp_seq_item.irq         = vif_cfg.irq;
                rsp_seq_item.cfg_mode    = vif_cfg.cfg_mode;
                rsp_seq_item.cfg_width   = vif_cfg.cfg_width;
                rsp_seq_item.ss_n        = vif_cfg.ss_n;
                rsp_seq_item.cfg_delay   = vif_cfg.cfg_delay;
                rsp_seq_item.cfg_clk_div = vif_cfg.cfg_clk_div;
                rsp_seq_item.tx_word     = vif_cfg.tx_word;
                rsp_seq_item.prdata      = vif_cfg.prdata;
                mon_ap.write(rsp_seq_item);
                `uvm_info("run_phase",rsp_seq_item.convert2string_stimulus(),UVM_HIGH)
            end
        endtask   
    endclass
endpackage