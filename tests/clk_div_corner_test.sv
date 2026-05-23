package clk_div_corner_test_pkg;
import uvm_pkg::*;
import master_env_pkg::*;
import master_config_pkg::*;
import master_sequence_item_pkg::*;
import master_config_pkg::*;
import spi_core_config_pkg::*;
import apb_config_pkg::*;
import master_env_pkg::*;
import apb_env_pkg::*;
import spi_core_env_pkg::*;
import div_sequence_pkg::*;


`include "uvm_macros.svh"

class clk_div_corner_test extends uvm_test;
	`uvm_component_utils(clk_div_corner_test)
    master_env env;
    apb_env abp_env_inst;
    spi_core_env spi_core_env_inst;

    master_config master_cfg;
    apb_config apb_object_inst;
    spi_core_config spi_core_object_inst;
    virtual master_if master_vif;
    div_rst_sequence div_rst_seq;
    div_sequence div_seq;

    function new(string name = "clk_div_corner_test",uvm_component parent = null);
      super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
    super.build_phase(phase);
        env               = master_env::type_id::create("env", this);
	    abp_env_inst      = apb_env::type_id::create("abp_env_inst", this);
	    spi_core_env_inst = spi_core_env::type_id::create("spi_core_env_inst", this);
        master_cfg                  = master_config::type_id::create("master_cfg");
        apb_object_inst             = apb_config::type_id::create("apb_object_inst");
        spi_core_object_inst        = spi_core_config::type_id::create("spi_core_object_inst");
        div_rst_seq                 = div_rst_sequence::type_id::create("div_rst_seq");
        div_seq                     = div_sequence::type_id::create("div_seq");

       if (!uvm_config_db#(virtual master_if)::get(this, "", "MASTER_IF", master_cfg.master_vif))
            `uvm_fatal("build_phase", "Unable to get master virtual interface")
 	   if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_core_IF", spi_core_object_inst.spi_vif))
        	`uvm_fatal("build_phase", "Unable to get spi_core virtual interface")
    
       if (!uvm_config_db#(virtual apb_if)::get(this, "", "APB_IF", apb_object_inst.apb_vif))  
            `uvm_fatal("build_phase", "Unable to get APB virtual interface")
       master_cfg.is_active           = UVM_ACTIVE;
       apb_object_inst.is_active      = UVM_PASSIVE;
       spi_core_object_inst.is_active = UVM_PASSIVE;

        uvm_config_db#(master_config)::set(this,  "*", "Master_CFG",    master_cfg);
        uvm_config_db#(apb_config)::set(this,     "*", "apb_CFG",       apb_object_inst);
        uvm_config_db#(spi_core_config)::set(this,"*", "spi_core_CFG",  spi_core_object_inst);
    endfunction

    task run_phase (uvm_phase phase);
      super.run_phase(phase);
      phase.raise_objection(this);
      `uvm_info("run_phase","div_rst_seq stimulus generation started",UVM_LOW)
          div_rst_seq.start(env.agent.sqr);
      `uvm_info("run_phase","div_rst_seq stimulus generation ended",UVM_LOW)

      `uvm_info("run_phase","div_seq stimulus generation started",UVM_LOW)
          div_seq.start(env.agent.sqr);
      `uvm_info("run_phase","div_seq stimulus generation ended",UVM_LOW)
      phase.drop_objection(this);
  endtask
endclass

endpackage