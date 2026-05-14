package master_scoreboard_pkg;
    import uvm_pkg::*;
    // import master_shared_pkg::*;
    import master_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    
    class master_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(master_scoreboard)
        
        uvm_analysis_export #(master_sequence_item) sb_export;
        uvm_tlm_analysis_fifo #(master_sequence_item) sb_;
        master_sequence_item sb_seq_item;
        
        int error_count , correct_count ;
        
        function new (string name = "master_scoreboard" , uvm_component parent = null);
            super.new(name,parent);
        endfunction

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            sb_export = new("sb_export",this);
            sb_ = new("sb_",this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            sb_export.connect(sb_.analysis_export);
        endfunction

        task run_phase (uvm_phase phase);
            super.run_phase(phase);
            
        endtask

        function void report_phase (uvm_phase phase);
            super.report_phase(phase);
            `uvm_info ("report_phase",$sformatf("Correct_count = %d , Error_count = %d",correct_count,error_count),UVM_MEDIUM);
        endfunction
    endclass
    
endpackage