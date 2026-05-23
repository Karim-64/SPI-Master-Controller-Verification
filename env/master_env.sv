package master_env_pkg;
import uvm_pkg::*;
import coverage_subscriber_pkg::*;

`include "uvm_macros.svh"
  // import master_shared_pkg::*;
  import master_sequence_item_pkg::*;
  import master_coverage_pkg::*;
  import master_agent_pkg::*;
  import master_scoreboard_pkg::*;


class master_env extends uvm_env;
  `uvm_component_utils(master_env)
  master_scoreboard sb; 
  master_agent agent; 
  master_coverage cov; 
  coverage_subscriber m_cov;
  
  function new (string name = "master_env",uvm_component parent = null);
    super.new(name,parent);
  endfunction
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    cov = master_coverage::type_id::create("cov",this);
    sb = master_scoreboard::type_id::create("sb",this); 
    agent = master_agent::type_id::create("agent",this); 
    m_cov = coverage_subscriber::type_id::create("m_cov", this);
  endfunction

  function void  connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.agt_ap.connect(cov.cov_export);
    agent.agt_ap.connect(sb.sb_export);
    agent.agt_ap.connect(m_cov.analysis_export);
  endfunction
  
endclass
endpackage