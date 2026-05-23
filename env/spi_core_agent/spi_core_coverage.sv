package spi_core_coverage_pkg;
    import uvm_pkg::*;
    import spi_core_shared_pkg::*;
    import spi_core_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    class spi_core_coverage extends uvm_component;
        `uvm_component_utils(spi_core_coverage)
        uvm_analysis_export #(spi_core_sequence_item) cov_export;
        uvm_tlm_analysis_fifo #(spi_core_sequence_item) cov_fifo;
        spi_core_sequence_item seq_item_cov;
        
        /*covergroups*/
        
        function new(string name = "spi_core_coverage",uvm_component parent = null);
            super.new(name , parent);
            // create covergroup

        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase (phase);
            cov_export = new("cov_export",this);
            cov_fifo = new("cov_fifo",this);
        endfunction

        function void  connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            cov_export.connect(cov_fifo.analysis_export);
        endfunction

        task run_phase (uvm_phase phase);
            super.run_phase (phase);
            forever begin
                cov_fifo.get(seq_item_cov);
                /*sample covergroups*/
            end
        endtask
    endclass 
endpackage