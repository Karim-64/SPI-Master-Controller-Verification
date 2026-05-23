package master_sequence_pkg;
    import uvm_pkg::*;
    // import master_shared_pkg::*;
    import master_sequence_item_pkg::*;
    `include "uvm_macros.svh"

    class master_rst_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(master_rst_sequence)
        master_sequence_item req;

        function new(string name = "master_rst_sequence");
            super.new(name);
        endfunction

        task body();
            req = master_sequence_item::type_id::create("req");
            repeat(5) begin
                start_item(req);
                    req.presetn = 0;
                finish_item(req);
            end
        endtask
    endclass

    class master_ctrl_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(master_ctrl_sequence)
        
        master_sequence_item seq_item ;
        
        function new(string name = "master_ctrl_sequence");
            super.new(name);
        endfunction
        
        task body ();
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);
            seq_item.main_c.constraint_mode(1);
            seq_item.ctrl_c.constraint_mode(1);

            repeat(20) begin
                repeat(3) begin
                    start_item(seq_item);
                        assert (seq_item.randomize());
                        seq_item.paddr = 8'h00;
                        seq_item.oldpaddr = 8'h00;
                    finish_item(seq_item);
                end
            end
        endtask
    endclass

    class master_CLK_DIV_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(master_CLK_DIV_sequence)
        
        master_sequence_item seq_item ;
        
        function new(string name = "master_CLK_DIV_sequence");
            super.new(name);
        endfunction
        
        task body ();
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);
            seq_item.main_c.constraint_mode(1);
            seq_item.clk_div_c.constraint_mode(1);
            repeat(20) begin
                repeat(3) begin
                    start_item(seq_item);
                        assert (seq_item.randomize());
                    finish_item(seq_item);
                end
            end
            seq_item.clk_div_c.constraint_mode(0);
        endtask
    endclass

    class master_Delay_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(master_Delay_sequence)
        
        master_sequence_item seq_item ;
        
        function new(string name = "master_Delay_sequence");
            super.new(name);
        endfunction
        
        task body ();
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);
            seq_item.main_c.constraint_mode(1);

            seq_item.ctrl_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize() with {
                        pwdata[0] == 1;
                        presetn == 1;
                    });
                finish_item(seq_item);
            end
            seq_item.ctrl_c.constraint_mode(0);
            seq_item.delay_c.constraint_mode(1);
            repeat(30) begin
                repeat(3) begin
                    start_item(seq_item);
                        assert (seq_item.randomize());
                    finish_item(seq_item);
                end
            end
            seq_item.delay_c.constraint_mode(0);
        endtask
    endclass

    class master_Write_read_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(master_Write_read_sequence)
        
        master_sequence_item seq_item ;
        
        function new(string name = "master_Write_read_sequence");
            super.new(name);
        endfunction
        
        task body ();
            int x; // Declare at the top of the block
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);
            seq_item.main_c.constraint_mode(1);

            repeat(3) begin
                seq_item.clk_div_c.constraint_mode(1);
                repeat(3) begin
                    start_item(seq_item);
                        assert (seq_item.randomize() with {
                            presetn == 1;
                        });
                    finish_item(seq_item);
                end
                seq_item.clk_div_c.constraint_mode(0);

                seq_item.ctrl_c.constraint_mode(1);
                repeat(3) begin
                    start_item(seq_item);
                        assert (seq_item.randomize() with {
                            pwdata[0] == 1;
                            presetn == 1;
                            pwrite == 1;
                        });
                    finish_item(seq_item);
                end
                seq_item.ctrl_c.constraint_mode(0);

                // Assuming ss_ctrl_c exists in master_sequence_item (though not strictly verified, leaving it if user meant it)
                // Actually, let's keep it but check if it causes errors later.
                seq_item.ss_ctrl_c.constraint_mode(1);
                repeat(3) begin
                    start_item(seq_item);
                        assert (seq_item.randomize() with {
                            presetn == 1;
                            pwrite == 1;
                        });
                    finish_item(seq_item);
                end
                seq_item.ss_ctrl_c.constraint_mode(0);

                x = $urandom_range(1, 10);
                repeat(x) begin
                    seq_item.TX_write_c.constraint_mode(1);
                    repeat(3) begin
                        start_item(seq_item);
                            assert (seq_item.randomize() with {
                            presetn == 1;
                        });
                        finish_item(seq_item);
                    end
                    seq_item.TX_write_c.constraint_mode(0);
                end

                x = $urandom_range(1, 10);
                repeat(x) begin
                    seq_item.RX_read_c.constraint_mode(1);
                    repeat(3) begin
                        start_item(seq_item);
                            assert (seq_item.randomize());
                        finish_item(seq_item);
                    end
                    seq_item.RX_read_c.constraint_mode(0);
                end
            end
        endtask
    endclass

    class master_ss_ctrl_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(master_ss_ctrl_sequence)
        
        master_sequence_item seq_item ;
        
        function new(string name = "master_ss_ctrl_sequence");
            super.new(name);
        endfunction
        
        task body ();
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);
            seq_item.main_c.constraint_mode(1);
            seq_item.ss_ctrl_c.constraint_mode(1);
            repeat(10) begin
                repeat(3) begin
                    start_item(seq_item);
                        assert (seq_item.randomize());
                    finish_item(seq_item);
                end
            end
            seq_item.ss_ctrl_c.constraint_mode(0);
        endtask
    endclass

    class master_status_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(master_status_sequence)
        
        master_sequence_item seq_item ;
        
        function new(string name = "master_status_sequence");
            super.new(name);
        endfunction
        
        task body ();
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);
            seq_item.main_c.constraint_mode(1);
            seq_item.status.constraint_mode(1);
            repeat(10) begin
                repeat(3) begin
                    start_item(seq_item);
                        assert (seq_item.randomize());
                    finish_item(seq_item);
                end
            end
            seq_item.status.constraint_mode(0);
        endtask
    endclass

    class master_violate_write_read_sequance extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(master_violate_write_read_sequance)
        
        master_sequence_item seq_item ;
        
        function new(string name = "master_violate_write_read_sequance");
            super.new(name);
        endfunction
        
        task body ();
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);
            seq_item.main_c.constraint_mode(1);
            seq_item.status.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize());
                    seq_item.presetn = 1;
                    seq_item.pwrite = 1;
                finish_item(seq_item);
            end
            seq_item.status.constraint_mode(0);

            seq_item.TX_write_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize());
                    seq_item.presetn = 1;
                    seq_item.pwrite = 0;
                finish_item(seq_item);
            end
            seq_item.TX_write_c.constraint_mode(0);

            seq_item.RX_read_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize());
                    seq_item.presetn = 1;
                    seq_item.pwrite = 1;
                finish_item(seq_item);
            end
            seq_item.RX_read_c.constraint_mode(0);

            
        endtask
    endclass

endpackage