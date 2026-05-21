package apb_sequence_item_pkg;
import uvm_pkg::*;
// import apb_shared_pkg::*;
`include "uvm_macros.svh"
`define WRITE_ADDR_ins 3'b000
`define WRITE_DATA_ins 3'b001
`define READ_ADDR_ins  3'b110
`define READ_DATA_ins  3'b111

class apb_sequence_item extends uvm_sequence_item;
    `uvm_object_utils(apb_sequence_item)
    
    // randomized signals
    rand bit presetn;
    rand bit psel;
    rand bit penable;
    rand bit pwrite;
    rand bit tx_pop;              
    rand bit rx_push_valid;       
    rand bit busy_in;             
    rand bit transfer_done_pulse; 
    rand bit [7:0]   paddr;
    rand bit [31:0]  pwdata;
    rand bit [31:0]  rx_push_data;

    // non-randomized signals
    logic pready;
    logic pslverr;
    logic cfg_en;
    logic cfg_mstr;
    logic cfg_lsb_first;
    logic cfg_loopback;
    logic tx_empty;
    logic irq;
    logic [1:0]   cfg_mode;
    logic [1:0]   cfg_width;
    logic [3:0]   ss_n;
    logic [7:0]   cfg_delay;
    logic [15:0]  cfg_clk_div;
    logic [31:0]  tx_word;
    logic [31:0]  prdata;

    // expected signals from golden model
    logic pready_exp;
    logic pslverr_exp;
    logic cfg_en_exp;
    logic cfg_mstr_exp;
    logic cfg_lsb_first_exp;
    logic cfg_loopback_exp;
    logic tx_empty_exp;
    logic irq_exp;
    logic [1:0]   cfg_mode_exp;
    logic [1:0]   cfg_width_exp;
    logic [3:0]   ss_n_exp;
    logic [7:0]   cfg_delay_exp;
    logic [15:0]  cfg_clk_div_exp;
    logic [31:0]  tx_word_exp;
    logic [31:0]  prdata_exp;

     
    function new(string name = "apb_sequence_item");
        super.new(name);
    endfunction
    // save old values 
    logic oldpsel = 1'b0;
    logic newpsel;
    logic oldpenable = 1'b0;
    logic newpenable;
    logic oldpwrite = 1'b0; 
    logic [7:0] oldpaddr  = 8'b0;
    logic [31:0] oldpwdata = 32'b0;
    logic flag = 1;

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

    constraint ctrl_c{
        presetn dist {1:/90 , 0:/10};
        paddr == 8'h00;
        if({psel,penable} == 2'b00)
        {
            pwrite dist {1:/50 , 0:/50};    // pwrite changes in idle state

            pwdata[0] dist {1:/50 , 0:/50};
            pwdata[1] == 1;
            pwdata[3:2] dist {2'b00:/25 , 2'b01:/25 , 2'b10:/25 , 2'b11:/25};
            pwdata[4] dist {1:/50 , 0:/50};
            pwdata[5] dist {1:/25 , 0:/75};
            pwdata[7:6] dist {2'b00:/30 , 2'b01:/35 , 2'b10:/35};
        }
        else if({psel,penable} == 2'b10 || {psel,penable} == 2'b11)
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;               // pwdata stable at setup and access states
        }
    }

    constraint write_read_c{
        presetn dist {1:/90 , 0:/10};
        if({psel,penable} == 2'b00)
        {
            pwrite dist {1:/50 , 0:/50};
            paddr dist {8'h08:/50 , 8'h0c:/50,[8'h24:$]:/5};
            pwdata dist {
                32'h00000000 :/ 40,
                32'hFFFFFFFF :/ 40,
                32'h55555555 :/ 40,
                32'hAAAAAAAA :/ 40,
                [32'h00000001 : 32'hFFFFFFFE] :/ 20
            };
        }
        else if({psel,penable} == 2'b10 || {psel,penable} == 2'b11)
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;
        }

        rx_push_data dist {
            32'h00000000 :/ 40,
            32'hFFFFFFFF :/ 40,
            32'h55555555 :/ 40,
            32'hAAAAAAAA :/ 40,
            [32'h00000001 : 32'hFFFFFFFE] :/ 20
        };
    }

    constraint TX_FULL_OVF_c{
        presetn == 1;
        paddr == 8'h08;
        pwrite == 1;
        if({psel,penable} == 2'b10 || {psel,penable} == 2'b11)
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;
        }
    }

    // ============ Should be updated ==============

    constraint TX_empty{
        presetn == 1;
        pwdata == oldpwdata;
        paddr == oldpaddr;
        paddr != 8'h08;
        pwrite == oldpwrite;
        if({psel,penable} == 2'b11)
        {
            tx_pop == 1;
        }
        else{
            tx_pop == 0;
        }
    }

    constraint RX_EMPTY_c{
        presetn == 1;
        paddr == 8'h0C;
        pwrite == 0;
        if({psel,penable} == 2'b10 || {psel,penable} == 2'b11)
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;
        }
    }

    // ============ Should be updated ==============

    constraint RX_FULL_c{
        presetn == 1;
        rx_push_data dist {
            32'h00000000 :/ 40,
            32'hFFFFFFFF :/ 40,
            32'h55555555 :/ 40,
            32'hAAAAAAAA :/ 40,
            [32'h00000001 : 32'hFFFFFFFE] :/ 20
        };
        if({psel,penable} == 2'b11)
        {
            rx_push_valid == 1;
        }
        else{
            rx_push_valid == 0;
        }
        pwdata == oldpwdata;
        paddr == oldpaddr;
        paddr != 8'h08;
        pwrite == oldpwrite;
    }

    constraint status_read_c{
        presetn == 1;
        paddr == 8'h04;
        pwrite == 0;
        if({psel,penable} == 2'b10 || {psel,penable} == 2'b11)
        {
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;
        }
    }

    constraint clk_div_c{
        presetn dist {1:/90 , 0:/10};

        paddr == 8'h10;

        if({psel,penable} == 2'b11 || ({psel,penable} == 2'b10))
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

    // ============= Doen not needed =============
   constraint ss_ctrl_c{
        presetn dist {1:/90 , 0:/10};
        paddr == 8'h14;
        if(({psel,penable} == 2'b11) || ({psel,penable} == 2'b10))
        {   
            pwdata == oldpwdata;
            paddr == oldpaddr;
            pwrite == oldpwrite;
        }
        else
        {   
            pwrite dist {1:/90 , 0:/10};
            pwdata[31:8] == 0;

            pwdata[7:0] dist {

            // no slave enabled
            8'b0000_0000 :/ 10,

            // slave0 selected
            8'b0000_0001 :/ 15,

            // slave1 selected
            8'b0000_0010 :/ 15,

            // slave2 selected
            8'b0000_0100 :/ 15,

            // slave3 selected
            8'b0000_1000 :/ 15,

            // enabled but inactive
            8'b1111_1111 :/ 10,

            // multiple slaves active
            8'b0000_0011 :/ 5,
            8'b0000_0110 :/ 5,
            8'b0000_1100 :/ 5,

            // all slaves active
            8'b0000_1111 :/ 5
        };
        }
    }
    constraint int_EN_c {
    presetn dist {1:/90 , 0:/10};
    paddr  == 8'h18;
    if(({psel,penable} == 2'b11) || ({psel,penable} == 2'b10))
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
        32'h00000010 :/ 10  // enable TRANSFER_DONE interrupt
        };
    }
}

   
    constraint clr_STAT_c {
        presetn dist {1:/90 , 0:/10};
        paddr  == 8'h1C;
        if(({psel,penable} == 2'b11) || ({psel,penable} == 2'b10))
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
    pwrite dist {1:/50 , 0:/50};
    if(({psel,penable} == 2'b11) || ({psel,penable} == 2'b10))
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
            8'd2   :/ 10,
            8'd4   :/ 10,
            8'd8   :/ 10,
            8'd16  :/ 10,
            8'd32  :/ 10,
            8'd255 :/ 10   
        };
    }
}

    function string convert2string();
        return $sformatf("presetn=%0d psel=%0d penable=%0d pwrite=%0d tx_pop=%0d rx_push_valid=%0d busy_in=%0d transfer_done_pulse=%0d, paddr=%0d pwdata=%0d rx_push_data=%0d pready=%0d pslverr=%0d cfg_en=%0d cfg_mstr=%0d cfg_lsb_first=%0d cfg_loopback=%0d, tx_empty=%0d irq=%0d cfg_mode=%0b cfg_width=%0b ss_n=%0b cfg_delay=%0d cfg_clk_div=%0d tx_word=%0d prdata=%0d",
                          presetn, psel, penable, pwrite, tx_pop, rx_push_valid, busy_in, transfer_done_pulse,
                          paddr, pwdata, rx_push_data, pready, pslverr, cfg_en, cfg_mstr, cfg_lsb_first, cfg_loopback,
                          tx_empty, irq, cfg_mode, cfg_width, ss_n, cfg_delay, cfg_clk_div, tx_word, prdata);
    endfunction

    function string convert2string_stimulus();
        return $sformatf("presetn=%0d psel=%0d penable=%0d pwrite=%0d tx_pop=%0d rx_push_valid=%0d busy_in=%0d transfer_done_pulse=%0d, paddr=%0d pwdata=%0d rx_push_data=%0d",
                          presetn, psel, penable, pwrite, tx_pop, rx_push_valid, busy_in, transfer_done_pulse,
                          paddr, pwdata, rx_push_data);
    endfunction        
endclass
endpackage