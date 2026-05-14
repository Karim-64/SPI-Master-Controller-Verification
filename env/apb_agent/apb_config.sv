package apb_config_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
class apb_config extends uvm_object;
    `uvm_object_utils(apb_config)
   virtual apb_if apb_vif;
   
   uvm_active_passive_enum is_active;
   function new (string name = "apb_config");
    super.new(name);
   endfunction
endclass
endpackage