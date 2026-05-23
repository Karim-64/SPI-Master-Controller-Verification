package master_agent_pkg;
    import uvm_pkg::*;
    // import master_shared_pkg::*;
    import master_sequence_item_pkg::*;
    import master_sequencer_pkg::*;
    import master_driver_pkg::*;
    import master_config_pkg::*;
    import master_monitor_pkg::*;

    `include "uvm_macros.svh"
    class master_agent extends uvm_agent;
        `uvm_component_utils(master_agent)

        master_config master_cfg;
        master_driver drv ; 
        master_monitor mon;
        master_sequencer sqr ; 
        uvm_analysis_port #(master_sequence_item) agt_ap ; 

        function new (string name = "master_agent" , uvm_component parent = null);
            super.new(name,parent);
        endfunction

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            
            if(!uvm_config_db#(master_config)::get(this,"","Master_CFG",master_cfg)) begin
                `uvm_fatal("build_phase","unable to get confg object")
            end
            if(master_cfg.is_active == UVM_ACTIVE) begin
                drv =  master_driver::type_id::create("drv",this);          
                sqr =  master_sequencer::type_id::create("sqr",this);                    
            end
            mon =  master_monitor::type_id::create("mon",this);          
            agt_ap = new ("agt_ap",this);
        endfunction

        function void connect_phase(uvm_phase phase);
            if(master_cfg.is_active == UVM_ACTIVE) begin
                drv.seq_item_port.connect(sqr.seq_item_export);
                drv.vif_cfg = master_cfg.master_vif;
            end
            mon.vif_cfg = master_cfg.master_vif;
            mon.mon_ap.connect(agt_ap);
        endfunction
    endclass
endpackage