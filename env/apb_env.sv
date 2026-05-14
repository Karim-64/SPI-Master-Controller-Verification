package apb_env_pkg;
import uvm_pkg::*;

`include "uvm_macros.svh"
  // import apb_shared_pkg::*;
  import apb_sequence_item_pkg::*;
  import apb_coverage_pkg::*;
  import apb_agent_pkg::*;
  import apb_scoreboard_pkg::*;

class apb_env extends uvm_env;
  `uvm_component_utils(apb_env)
  apb_scoreboard sb; 
  apb_agent agent; 
  apb_coverage cov; 
  
  function new (string name = "apb_env",uvm_component parent = null);
    super.new(name,parent);
  endfunction
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    cov = apb_coverage::type_id::create("cov",this);
    sb = apb_scoreboard::type_id::create("sb",this); 
    agent = apb_agent::type_id::create("agent",this); 
  endfunction  
  function void  connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.agt_ap.connect(cov.cov_export);
    agent.agt_ap.connect(sb.sb_export);
  endfunction
  
endclass
endpackage