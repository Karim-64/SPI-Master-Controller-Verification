package master_monitor_pkg;
    import uvm_pkg::*;
    // import master_shared_pkg::*;
    import master_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    class master_monitor extends uvm_monitor ;
        `uvm_component_utils(master_monitor);

        virtual master_if vif_cfg; 
        master_sequence_item rsp_seq_item;

        uvm_analysis_port #(master_sequence_item) mon_ap;

        function new (string name = "master_monitor" , uvm_component parent = null);
            super.new(name,parent);
        endfunction

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            mon_ap = new("mon_ap",this);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
                forever begin
                    rsp_seq_item = master_sequence_item::type_id::create("rsp_seq_item");
                    @(negedge vif_cfg.pclk); 
                    rsp_seq_item.presetn = vif_cfg.presetn;
                    rsp_seq_item.psel = vif_cfg.psel;
                    rsp_seq_item.penable = vif_cfg.penable;
                    rsp_seq_item.pwrite = vif_cfg.pwrite;
                    rsp_seq_item.paddr = vif_cfg.paddr;
                    rsp_seq_item.pwdata = vif_cfg.pwdata;
                    rsp_seq_item.miso = vif_cfg.miso;
                    rsp_seq_item.pready = vif_cfg.pready;
                    rsp_seq_item.pslverr = vif_cfg.pslverr;
                    rsp_seq_item.prdata = vif_cfg.prdata;
                    rsp_seq_item.mosi = vif_cfg.mosi;
                    rsp_seq_item.ss_n = vif_cfg.ss_n;
                    rsp_seq_item.sclk = vif_cfg.sclk;
                    rsp_seq_item.irq = vif_cfg.irq;
                    rsp_seq_item.pready_exp = vif_cfg.pready_exp;
                    rsp_seq_item.pslverr_exp = vif_cfg.pslverr_exp;
                    rsp_seq_item.prdata_exp = vif_cfg.prdata_exp;
                    rsp_seq_item.mosi_exp = vif_cfg.mosi_exp;
                    rsp_seq_item.ss_n_exp = vif_cfg.ss_n_exp;
                    rsp_seq_item.sclk_exp = vif_cfg.sclk_exp;
                    rsp_seq_item.irq_exp = vif_cfg.irq_exp;
                    mon_ap.write(rsp_seq_item);
                    `uvm_info("run_phase",rsp_seq_item.convert2string_stimulus(),UVM_HIGH)
                end
        endtask   
    endclass
endpackage