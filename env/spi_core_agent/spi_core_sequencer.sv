package spi_core_sequencer_pkg;
    import uvm_pkg::*;
    import spi_core_shared_pkg::*;
    import spi_core_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    class spi_core_sequencer extends uvm_sequencer #(spi_core_sequence_item);
        `uvm_component_utils(spi_core_sequencer)

        function new(string name = "spi_core_sequencer" , uvm_component parent = null);
            super.new(name,parent);    
        endfunction 
    endclass
endpackage