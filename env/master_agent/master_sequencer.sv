package master_sequencer_pkg;
    import uvm_pkg::*;
    // import master_shared_pkg::*;
    import master_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    class master_sequencer extends uvm_sequencer #(master_sequence_item);
        `uvm_component_utils(master_sequencer)

        function new(string name = "master_sequencer" , uvm_component parent = null);
            super.new(name,parent);    
        endfunction 
    endclass
endpackage