package apb_sequencer_pkg;
    import uvm_pkg::*;
    // import apb_shared_pkg::*;
    import apb_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    class apb_sequencer extends uvm_sequencer #(apb_sequence_item);
        `uvm_component_utils(apb_sequencer)

        function new(string name = "apb_sequencer" , uvm_component parent = null);
            super.new(name,parent);    
        endfunction 
    endclass
endpackage