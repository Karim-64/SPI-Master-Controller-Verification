package master_test_pkg;
import master_env_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"
import master_config_pkg::*;
//   import master_shared_pkg::*;
import master_sequence_item_pkg::*;
import master_sequence_pkg::*;
import master_config_pkg::*;
import spi_core_config_pkg::*;
import apb_config_pkg::*;
import master_env_pkg::*;
import apb_env_pkg::*;
import spi_core_env_pkg::*;


class master_access_test extends uvm_test;
    `uvm_component_utils(master_access_test)
    master_env env;

    apb_env abp_env_inst;
    spi_core_env spi_core_env_inst;

    master_config master_cfg;
    apb_config apb_object_inst;
    spi_core_config spi_core_object_inst;
    virtual master_if master_vif;
    master_rst_sequence rst_seq;
    master_Write_read_sequence master_write_read_sequence;
    master_ctrl_sequence master_ctrl_seq;
    master_CLK_DIV_sequence master_clk_div_seq;
    master_Delay_sequence master_delay_seq;
    master_ss_ctrl_sequence master_ss_ctrl_seq;
    master_status_sequence master_status_seq;
    master_violate_write_read_sequance master_violate_write_read_seq;


    function new(string name = "master_access_test",uvm_component parent = null);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    
        env               = master_env::type_id::create("env", this);
        abp_env_inst      = apb_env::type_id::create("abp_env_inst", this);
        spi_core_env_inst = spi_core_env::type_id::create("spi_core_env_inst", this);
    
        master_cfg           = master_config::type_id::create("master_cfg");
        apb_object_inst      = apb_config::type_id::create("apb_object_inst");
        spi_core_object_inst = spi_core_config::type_id::create("spi_core_object_inst");
        rst_seq              = master_rst_sequence::type_id::create("rst_seq");
        master_write_read_sequence = master_Write_read_sequence::type_id::create("master_write_read_sequence");
        master_ctrl_seq = master_ctrl_sequence::type_id::create("master_ctrl_seq");
        master_clk_div_seq = master_CLK_DIV_sequence::type_id::create("master_clk_div_seq");
        master_delay_seq = master_Delay_sequence::type_id::create("master_delay_seq");
        master_ss_ctrl_seq = master_ss_ctrl_sequence::type_id::create("master_ss_ctrl_seq");
        master_status_seq = master_status_sequence::type_id::create("master_status_seq");
        master_violate_write_read_seq = master_violate_write_read_sequance::type_id::create("master_violate_write_read_seq");
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
        `uvm_info("run_phase","rst_seq stimulus generation started",UVM_LOW)
            rst_seq.start(env.agent.sqr);
        `uvm_info("run_phase","rst_seq stimulus generation ended",UVM_LOW)

        `uvm_info("run_phase","master_write_read_sequence stimulus generation started",UVM_LOW)
            master_write_read_sequence.start(env.agent.sqr);
        `uvm_info("run_phase","master_write_read_sequence stimulus generation ended",UVM_LOW)

        `uvm_info("run_phase","master_violate_write_read_seq stimulus generation started",UVM_LOW)
            master_violate_write_read_seq.start(env.agent.sqr);
        `uvm_info("run_phase","master_violate_write_read_seq stimulus generation ended",UVM_LOW)

        `uvm_info("run_phase","master_ctrl_sequence stimulus generation started",UVM_LOW)
            master_ctrl_seq.start(env.agent.sqr);
        `uvm_info("run_phase","master_ctrl_sequence stimulus generation ended",UVM_LOW)

        `uvm_info("run_phase","master_clk_div_sequence stimulus generation started",UVM_LOW)
            master_clk_div_seq.start(env.agent.sqr);
        `uvm_info("run_phase","master_clk_div_sequence stimulus generation ended",UVM_LOW)

        `uvm_info("run_phase","master_delay_sequence stimulus generation started",UVM_LOW)
            master_delay_seq.start(env.agent.sqr);
        `uvm_info("run_phase","master_delay_sequence stimulus generation ended",UVM_LOW)

        `uvm_info("run_phase","master_ss_ctrl_sequence stimulus generation started", UVM_LOW)
            master_ss_ctrl_seq.start(env.agent.sqr);
        `uvm_info("run_phase","master_ss_ctrl_sequence stimulus generation ended",UVM_LOW)

        `uvm_info("run_phase","master_status_sequence stimulus generation started", UVM_LOW)
            master_status_seq.start(env.agent.sqr);
        `uvm_info("run_phase","master_status_sequence stimulus generation ended", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass
endpackage