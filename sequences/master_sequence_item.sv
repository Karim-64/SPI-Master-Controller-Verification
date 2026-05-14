
package master_sequence_item_pkg;
import uvm_pkg::*;
import master_shared_pkg::*;
`include "uvm_macros.svh"
// `define WRITE_ADDR_ins 3'b000
// `define WRITE_DATA_ins 3'b001
// `define READ_ADDR_ins  3'b110
// `define READ_DATA_ins  3'b111

class master_sequence_item extends uvm_sequence_item;
    `uvm_object_utils(master_sequence_item)

    // input signals
    rand bit presetn;
    rand bit psel;
    rand bit penable;
    rand bit pwrite;
    rand bit [7:0] paddr;
    rand bit [31:0] pwdata;
    rand bit miso;

    // dut output signal
    bit pready, pready_exp;
    bit pslverr, pslverr_exp;
    bit [31:0] prdata, prdata_exp;
    bit mosi, mosi_exp;
    bit [3:0] ss_n, ss_n_exp;
    bit sclk, sclk_exp;
    bit irq, irq_exp;

    //For modes test
    rand logic [1:0]  mode_r;
    rand logic        lsb_first_r;
    rand logic [1:0]  width_cfg_r;
    rand logic [31:0] data_r;
    rand logic [7:0]  ss_n_r;
    rand logic [15:0] div_r;

    function new(string name = "master_sequence_item");
        super.new(name);
    endfunction

    logic oldpsel = 1'b0;
    logic newpsel;
    logic oldpenable = 1'b0;
    logic newpenable;
    logic oldpwrite = 1'b0;
    logic [7:0] oldpaddr  = 8'b0;
    logic [31:0] oldpwdata = 32'b0;
    logic flag = 1;

    // Expected setup -> access -> idle sequence 
    function void pre_randomize();
        if({psel,penable} === 2'b11 || flag)
        begin
            {newpsel,newpenable} = 2'b00;
            flag =0;
        end
        else if({psel,penable} == 2'b10)
        begin
            {newpsel,newpenable} = 2'b11;
        end
        else if({psel,penable} == 2'b00)
        begin
            {newpsel,newpenable} = 2'b10;
        end
    endfunction

    function void post_randomize();
        oldpsel    = newpsel;
        oldpenable = newpenable;
        oldpwrite  = pwrite;
        oldpaddr   = paddr;
        oldpwdata  = pwdata;
    endfunction

    /*constraint blocks*/
    constraint main_c{
        psel == newpsel;
        penable == newpenable;
        paddr[1:0] == 2'b0;     // make it 4 byte allgigned
    }

    // when test FIFO FULL & overflow add the presetn presetn == 1;
    constraint TX_write_c {
        presetn dist {1:/90 , 0:/10};
        paddr == 8'h08;
        pwrite == 1;
        if({psel,penable} == 2'b00 || {psel,penable} == 2'b10)
        {
            pwdata dist {
                32'h00000000 :/ 40,
                32'hFFFFFFFF :/ 40,
                32'h55555555 :/ 40,
                32'hAAAAAAAA :/ 40,
                [32'h00000001 : 32'hFFFFFFFE] :/ 20
            };
        }
        else if({psel,penable} == 2'b11)
        {
            pwdata == oldpwdata;
            paddr  == oldpaddr;
            pwrite == oldpwrite;
        }
    }
    // must be modifired
    constraint RX_read_c {
         presetn dist {1:/90 , 0:/10};
        paddr == 8'h0C;
        pwrite == 0;
        if({psel,penable} == 2'b10 || {psel,penable} == 2'b11)
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;
        }
    }

    constraint ctrl_c{
        presetn dist {1:/90 , 0:/10};
        paddr == 8'h00;
        if({psel,penable} == 2'b00 || {psel,penable} == 2'b10)
        {
            pwrite dist {1:/50 , 0:/50};    // pwrite changes in idle state

            pwdata[0] dist {1:/50 , 0:/50};
            pwdata[1] == 1;
            pwdata[3:2] dist {2'b00:/25 , 2'b01:/25 , 2'b10:/25 , 2'b11:/25};
            pwdata[4] dist {1:/50 , 0:/50};
            pwdata[5] dist {1:/25 , 0:/75};
            pwdata[7:6] dist {2'b00:/30 , 2'b01:/35 , 2'b10:/35};
        }
        else if({psel,penable} == 2'b11)
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;               // pwdata stable at setup and access states
        }
    }

    constraint ctrl_mstr_off_c{
        presetn == 1;
        paddr == 8'h00;
        pwrite == 1;
        if({psel,penable} == 2'b00 || {psel,penable} == 2'b10)
        {

            pwdata[0] == 1;
            pwdata[1] == 0;
            pwdata[3:2] dist {2'b00:/25 , 2'b01:/25 , 2'b10:/25 , 2'b11:/25};
            pwdata[4] dist {1:/50 , 0:/50};
            pwdata[5] dist {1:/25 , 0:/75};
            pwdata[7:6] dist {2'b00:/30 , 2'b01:/35 , 2'b10:/35};
        }
        else if({psel,penable} == 2'b11)
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;               // pwdata stable at setup and access states
        }
    }


    constraint status_read_c{
       presetn == 1;
        paddr == 8'h04;
        pwrite == 0;
        if({psel,penable} == 2'b11)
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;
        }
    }

    constraint clk_div_c{
       presetn dist {1:/90 , 0:/10};

        paddr == 8'h10;

        if({psel,penable} == 2'b11)
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;
        }
        else{
            pwdata[15:0] dist {0:/25 , 1:/25 , 8:/25 , 16:/25};
            pwrite dist {1:/90 , 0:/10};
        }
    }

    constraint int_EN_c {
         presetn dist {1:/90 , 0:/10};
        paddr  == 8'h18;
        if(({psel,penable} == 2'b11))
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;
        }
            else
        {
            pwrite dist {1:/90 , 0:/10};
            pwdata dist {
            32'h00000000 :/ 10,   // enable TX_EMPTY interrupt
            32'h00000001 :/ 10,   // enable TX_EMPTY interrupt
            32'h00000002 :/ 10,   // enable RX_FULL interrupt
            32'h00000004 :/ 10,   // enable TX_OVF interrupt
            32'h00000008 :/ 10,   // enable RX_OVF interrupt
            32'h00000010 :/ 10    // enable TRANSFER_DONE interrupt
            };
        }
    }

    constraint clr_STAT_c {
        presetn dist {1:/90 , 0:/10};
        paddr  == 8'h1C;
        if(({psel,penable} == 2'b11))
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;
        }
        else
        {
            pwrite dist {1:/90 , 0:/10};
            pwdata dist {
                32'h00000001 :/ 10,   // clear TX_EMPTY interrupt
                32'h00000002 :/ 10,   // clear RX_FULL interrupt
                32'h00000004 :/ 10,   // clear TX_OVF interrupt
                32'h00000008 :/ 10,   // clear RX_OVF interrupt
                32'h00000010 :/ 10  // clear TRANSFER_DONE interrupt
            };
        }
    }

    constraint delay_c {
     presetn dist {1:/90 , 0:/10};
        paddr  == 8'h20;
        pwrite dist {1:/90 , 0:/10};
        if(({psel,penable} == 2'b11))
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;
        }
        else{
            pwdata[31:8] == 0;

            pwdata[7:0] dist {
                    8'd0   :/ 20,
                    8'd1   :/ 20,
                    8'd2   :/ 20,
                    8'd4   :/ 20,
                    8'd8   :/ 20,
                    8'd16  :/ 20,
                    8'd32  :/ 20,
                    8'd255 :/ 20
            };
        }
    }

    constraint ss_ctrl_c{
        presetn dist {1:/90 , 0:/10};
        paddr == 8'h14;
        if(({psel,penable} == 2'b11))
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;
        }
        else
        {
            pwrite dist {1:/50 , 0:/50};
            pwdata[31:8] == 0;

            pwdata[7:0] dist {

                // no slave enabled
                // 8'b0000_0000 :/ 10,

                // slave0 selected
                8'b0000_0001 :/ 15,

                // slave1 selected
                8'b0000_0010 :/ 15,

                // slave2 selected
                8'b0000_0100 :/ 15,

                // slave3 selected
                8'b0000_1000 :/ 15,

                // enabled but inactive
                // 8'b1111_1111 :/ 10,

                // multiple slaves active
                // 8'b0000_0011 :/ 5,
                // 8'b0000_0110 :/ 5,
                // 8'b0000_1100 :/ 5,

                // all slaves active
                8'b0000_1111 :/ 5
            };

            pwdata[7:0] != 8'b0000_0000;
            pwdata[7:0] != 8'b1111_1111;
        }
    }

    constraint status {
        presetn dist {1:/90 , 0:/10};
        paddr == 8'h04;
        pwrite == 0;
        if({psel,penable} == 2'b11)
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;
        }
    }


    constraint TX_FULL_OVF_c{
        presetn == 1;
        paddr == 8'h08;
        pwrite == 1;
        if({psel,penable} == 2'b11)
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;
        }
    }

    constraint RX_EMPTY_c{
         presetn == 1;
        paddr == 8'h0C;
        pwrite == 0;
        if({psel,penable} == 2'b11)
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;
        }
    }

    constraint TX_empty{
         presetn == 1;
        if({psel,penable} == 2'b11)
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;
        }
        else{
            paddr != 8'h08;
        }
    }

    //for modes test
    constraint modes_crossing_c {
        mode_r dist { 
            2'b00 := 1, 
            2'b01 := 1, 
            2'b10 := 1, 
            2'b11 := 1 
        };
        ss_n_r[3:0] inside {[1:15]};
        // ss_n_r[7:4] dist {4'b0000:/85, [0:15]:/15}
        $countones(~ss_n_r[7:4]) >= 1;
        (ss_n_r[3:0] & ~ss_n_r[7:4]) != 4'b0000;
        lsb_first_r dist { 
            1'b0 := 1, 
            1'b1 := 1 
        };
        width_cfg_r dist { 
            2'b00 := 1, 
            2'b01 := 1, 
            2'b10 := 1 
        };
        div_r dist {[0:1]:/10, [2:1024]:/50, [1024:$]:/30, 65535:/10 }; 
    }
    


    function string convert2string();
        return $sformatf(
            " presetn = %0b, psel = %0b, penable = %0b, pwrite = %0b, paddr = 0x%0h, pwdata = 0x%0h, miso = %0b || pready = %0b, pslverr = %0b, prdata = 0x%0h, mosi = %0b, ss_n = %0b, sclk = %0b, irq = %0b",
            presetn,
            psel,
            penable,
            pwrite,
            paddr,
            pwdata,
            miso,
            pready,
            pslverr,
            prdata,
            mosi,
            ss_n,
            sclk,
            irq
        );
    endfunction

    function string convert2string_stimulus();
        return $sformatf(
            "Stimulus -->  presetn = %0b, psel = %0b, penable = %0b, pwrite = %0b, paddr = 0x%0h, pwdata = 0x%0h, miso = %0b",
            presetn,
            psel,
            penable,
            pwrite,
            paddr,
            pwdata,
            miso
        );
    endfunction
endclass
endpackage