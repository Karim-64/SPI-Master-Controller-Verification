package spi_core_config_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
class spi_core_config extends uvm_object;
    `uvm_object_utils(spi_core_config)
   virtual spi_if spi_vif;
   
   uvm_active_passive_enum is_active;
   function new (string name = "spi_core_config");
    super.new(name);
   endfunction
endclass
endpackage