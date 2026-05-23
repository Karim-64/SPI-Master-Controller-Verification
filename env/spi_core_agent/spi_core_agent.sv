package spi_core_agent_pkg;
    import uvm_pkg::*;
    import spi_core_shared_pkg::*;
    import spi_core_sequence_item_pkg::*;
    import spi_core_sequencer_pkg::*;
    import spi_core_driver_pkg::*;
    import spi_core_config_pkg::*;
    import spi_core_monitor_pkg::*;

    `include "uvm_macros.svh"
    class spi_core_agent extends uvm_agent;
        `uvm_component_utils(spi_core_agent)

        spi_core_config spi_core_cfg;
        spi_core_driver drv ; 
        spi_core_monitor mon;
        spi_core_sequencer sqr ; 
        uvm_analysis_port #(spi_core_sequence_item) agt_ap ; 

        function new (string name = "spi_core_agent" , uvm_component parent = null);
            super.new(name,parent);
        endfunction

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            if(!uvm_config_db#(spi_core_config)::get(this,"","spi_core_CFG",spi_core_cfg)) begin
                `uvm_fatal("build_phase","unable to get confg object")
            end
            if(spi_core_cfg.is_active == UVM_ACTIVE) begin
                drv =  spi_core_driver::type_id::create("drv",this);          
                sqr =  spi_core_sequencer::type_id::create("sqr",this);                    
            end
            mon =  spi_core_monitor::type_id::create("mon",this);          
            agt_ap = new ("agt_ap",this);
        endfunction

        function void connect_phase(uvm_phase phase);
            // if(spi_core_cfg.is_active == UVM_ACTIVE) begin
            //     drv.seq_item_port.connect(sqr.seq_item_export);
            //     drv.vif_cfg = spi_core_cfg.spi_core_vif;
            // end
            mon.vif_cfg = spi_core_cfg.spi_vif;
            mon.mon_ap.connect(agt_ap);
        endfunction
    endclass
endpackage