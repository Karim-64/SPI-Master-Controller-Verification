package apb_agent_pkg;
    import uvm_pkg::*;
    // import apb_shared_pkg::*;
    import apb_sequence_item_pkg::*;
    import apb_sequencer_pkg::*;
    import apb_driver_pkg::*;
    import apb_config_pkg::*;
    import apb_monitor_pkg::*;

    `include "uvm_macros.svh"
    class apb_agent extends uvm_agent;
        `uvm_component_utils(apb_agent)

        apb_config apb_cfg;
        apb_driver drv ; 
        apb_monitor mon;
        apb_sequencer sqr ; 
        uvm_analysis_port #(apb_sequence_item) agt_ap ; 

        function new (string name = "apb_agent" , uvm_component parent = null);
            super.new(name,parent);
        endfunction

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            if(!uvm_config_db#(apb_config)::get(this,"","apb_CFG",apb_cfg)) begin
                `uvm_fatal("build_phase","unable to get confg object")
            end
            if(apb_cfg.is_active == UVM_ACTIVE) begin
                drv =  apb_driver::type_id::create("drv",this);          
                sqr =  apb_sequencer::type_id::create("sqr",this);                    
            end
            mon =  apb_monitor::type_id::create("mon",this);          
            agt_ap = new ("agt_ap",this);
        endfunction

        function void connect_phase(uvm_phase phase);
            if(apb_cfg.is_active == UVM_ACTIVE) begin
                drv.seq_item_port.connect(sqr.seq_item_export);
                drv.vif_cfg = apb_cfg.apb_vif;
            end
            mon.vif_cfg = apb_cfg.apb_vif;
            mon.mon_ap.connect(agt_ap);
        endfunction
    endclass
endpackage