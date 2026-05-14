package spi_core_env_pkg;
import uvm_pkg::*;

`include "uvm_macros.svh"
  import spi_core_shared_pkg::*;
  import spi_core_sequence_item_pkg::*;
  import spi_core_coverage_pkg::*;
  import spi_core_agent_pkg::*;
  import spi_core_scoreboard_pkg::*;

class spi_core_env extends uvm_env;
  `uvm_component_utils(spi_core_env)
  spi_core_scoreboard sb; 
  spi_core_agent agent; 
  spi_core_coverage cov; 
  
  function new (string name = "spi_core_env",uvm_component parent = null);
    super.new(name,parent);
  endfunction
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    cov = spi_core_coverage::type_id::create("cov",this);
    sb  = spi_core_scoreboard::type_id::create("sb",this); 
    agent = spi_core_agent::type_id::create("agent",this); 
  endfunction  
  function void  connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.agt_ap.connect(cov.cov_export);
    agent.agt_ap.connect(sb.sb_export);
  endfunction
  
endclass
endpackage