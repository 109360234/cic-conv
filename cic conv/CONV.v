
`timescale 1ns/10ps

module  CONV(clk,reset,busy,ready,iaddr,idata,cwr,caddr_wr,cdata_wr,crd,caddr_rd,cdata_rd,csel);
input clk;
input reset;
input ready;
output busy;
output [11:0] iaddr;
input signed [19:0] idata;
output crd;
input [19:0] cdata_rd;
output [11:0] caddr_rd;
output cwr;
output [19:0] cdata_wr;
output [11:0] caddr_wr;
output [2:0] csel;
reg busy;
reg [11:0] iaddr;
reg crd;
reg [11:0] caddr_rd;
reg cwr;
reg signed [19:0] cdata_wr;
reg [11:0] caddr_wr;
reg [2:0] csel;
reg [3:0] cs;
reg [3:0] ns;
reg [3:0] counterRead;
reg [5:0] index_X,index_Y;
wire [5:0] X,XX,Y,YY;
reg signed [43:0] convTemp; 
wire signed [20:0] roundTemp;
assign roundTemp = convTemp[35:15] + 21'd1; 
reg signed [19:0] k_temp;
reg signed [19:0] BiasTemp;
//kernel 0
parameter K1 = 20'h0A89E ;
parameter K2 = 20'h092D5 ;
parameter K3 = 20'h06D43 ;
parameter K4 = 20'h01004 ;
parameter K5 = 20'hF8F71 ;
parameter K6 = 20'hF6E54 ;
parameter K7 = 20'hFA6D7 ;
parameter K8 = 20'hFC834 ;
parameter K9 = 20'hFAC19 ;
parameter Bias_0 = 20'h01310;

//kernel 1
parameter K10 = 20'hFDB55 ;
parameter K11 = 20'h02992 ;
parameter K12 = 20'hFC994 ;
parameter K13 = 20'h050FD ;
parameter K14 = 20'h02F20 ;
parameter K15 = 20'h0202D ;
parameter K16 = 20'h03BD7 ;
parameter K17 = 20'hFD369 ;
parameter K18 = 20'h05E68 ;
parameter Bias_1 = 20'hF7295;
//parameter
parameter idle = 4'd0;
parameter convrd = 4'd1;
parameter L0wr = 4'd2;
parameter convrd_K1 = 4'd3;
parameter L0wr_K1 = 4'd4;
parameter L0rd = 4'd5;
parameter MAX_POOLING = 4'd6;
parameter L1wr = 4'd7;
parameter L0rd_K1 = 4'd8;
parameter MAX_POOLING_K1 = 4'd9;
parameter L1wr_K1 = 4'd10;
parameter L1rd_K0 = 4'd11;
parameter L2wr_K0 = 4'd12;
parameter L1rd_K1 = 4'd13;
parameter L2wr_K1 = 4'd14;
parameter FINISH = 4'd15;

//FSM
always@(posedge clk or posedge reset)
begin
    if(reset) cs <= idle;
    else cs <= ns;
end

always@(*)
begin
    case (cs)
        idle:
            begin
                if(ready == 1'd1) ns = convrd;
                else ns = idle;
            end
        convrd:
            begin
                if(counterRead == 4'd11) ns = L0wr;
                else ns = convrd;
            end
        L0wr:
            begin
                if(index_X == 6'd63 && index_Y == 6'd63) ns = convrd_K1;
                else ns = convrd;
            end
        convrd_K1:
            begin
                if(counterRead == 4'd11) ns = L0wr_K1;
                else ns = convrd_K1;
            end
        L0wr_K1:
            begin
                if(index_X == 6'd63 && index_Y == 6'd63) ns = L0rd;
                else ns = convrd_K1;
            end
        L0rd:
            begin
                if(counterRead == 4'd4) ns = MAX_POOLING;
                else ns = L0rd;
            end
        MAX_POOLING: 
            begin
                ns = L1wr;
            end
        L1wr:
            begin
                if(index_X == 6'd62 && index_Y == 6'd62) ns = L0rd_K1;
                else ns = L0rd;
            end
        L0rd_K1:
            begin
                if(counterRead == 4'd4) ns = MAX_POOLING_K1;
                else ns = L0rd_K1;
            end
        MAX_POOLING_K1:
            begin
                ns = L1wr_K1;
            end
        L1wr_K1:
            begin
                if(index_X == 6'd62 && index_Y == 6'd62) ns = L1rd_K0;
                else ns = L0rd_K1;
            end
        L1rd_K0:
            begin
                ns = L2wr_K0;
            end
        L2wr_K0:
            begin
                if(index_X == 6'd62 && index_Y == 6'd62) ns = L1rd_K1;
                else ns = L1rd_K0;
            end
        L1rd_K1:
            begin
                ns = L2wr_K1;
            end
        L2wr_K1:
            begin
                if(index_X == 6'd62 && index_Y == 6'd62) ns = FINISH;
                else ns = L1rd_K1;
            end
        FINISH: 
            begin
                ns = FINISH;
            end
        default:
            begin
                ns = idle;
            end 
    endcase    
end

reg signed [19:0] idatatemp;
wire signed [43:0] sumconv;
assign sumconv = k_temp * idatatemp;
//conv 
always@(posedge clk or posedge reset)
begin
    if(reset) convTemp <= 44'd0; 
    else if(cs == convrd || cs == convrd_K1)
    begin
        idatatemp <= idata;
        case(counterRead)
        
        4'd0:   convTemp <= 44'd0;
        4'd2:   if(index_X != 6'd0 && index_Y != 6'd0)  convTemp <= sumconv;
        4'd3:   if(index_Y != 6'd0) convTemp <= convTemp + sumconv;
        4'd4:   if(index_Y != 6'd0 && index_X != 6'd63) convTemp <= convTemp + sumconv;
        4'd5:   if(index_X != 6'd0) convTemp <= convTemp + sumconv;
        4'd6:   convTemp <= convTemp + sumconv;
        4'd7:   if(index_X != 6'd63) convTemp <= convTemp + sumconv;
        4'd8:   if(index_X != 6'd0 && index_Y != 6'd63) convTemp <= convTemp + sumconv;
        4'd9:   if(index_Y != 6'd63) convTemp <= convTemp + sumconv;
        4'd10:   if(index_Y != 6'd63 && index_X != 6'd63) convTemp <= convTemp + sumconv;
        4'd11:  convTemp <= convTemp + {BiasTemp,16'd0};

        endcase
    end
end
always@(*)
begin
    if(cs == convrd)
    begin
         case(counterRead)
        4'd2: k_temp = K1;
        4'd3: k_temp = K2;
        4'd4: k_temp = K3;
        4'd5: k_temp = K4;
        4'd6: k_temp = K5;
        4'd7: k_temp = K6;
        4'd8: k_temp = K7;
        4'd9: k_temp = K8;
        4'd10: k_temp = K9;
        default: k_temp = 20'd0;
        endcase
        BiasTemp = Bias_0;
    end
    else
    begin
        case(counterRead)
        4'd2: k_temp = K10;
        4'd3: k_temp = K11;
        4'd4: k_temp = K12;
        4'd5: k_temp = K13;
        4'd6: k_temp = K14;
        4'd7: k_temp = K15;
        4'd8: k_temp = K16;
        4'd9: k_temp = K17;
        4'd10: k_temp = K18;
        default: k_temp = 20'd0;
        endcase
        BiasTemp = Bias_1;
    end 
end

assign XX = index_X - 6'd1;
assign X = index_X + 6'd1;
assign YY = index_Y - 6'd1;
assign Y = index_Y + 6'd1;

always@(posedge clk or posedge reset)
begin
    if(reset) index_X <= 6'd0;
    else if(cs == L0wr || cs == L0wr_K1) 
    begin
        if(index_X == 6'd63) index_X <= 6'd0;
        else index_X <= index_X + 6'd1;
    end
    else if(cs == L1wr || cs == L1wr_K1 || cs == L2wr_K0 || cs == L2wr_K1)
    begin
        if(index_X == 6'd62) index_X <= 6'd0;
        else index_X <= index_X + 6'd2;
    end
end

always@(posedge clk or posedge reset)
begin
    if(reset) index_Y <= 6'd0;
    else if(cs == L0wr || cs == L0wr_K1)
    begin
        if(index_X == 6'd63) index_Y <= index_Y + 6'd1;
    end
    else if(cs == L1wr || cs == L1wr_K1 || cs == L2wr_K0 || cs == L2wr_K1)
    begin
        if(index_X == 6'd62) index_Y <= index_Y + 6'd2;
    end
end



//counter
always@(posedge clk or posedge reset)
begin
    if(reset) counterRead <= 4'd0;
    else if(counterRead == 4'd11) counterRead <= 4'd0;
    else if(counterRead == 4'd4 && (cs == L0rd ||cs == L0rd_K1) ) counterRead <= 4'd0;
    else if(cs == convrd || cs == convrd_K1 || cs == L0rd || cs == L0rd_K1) counterRead <= counterRead + 4'd1;
end

//busy
always@(posedge clk or posedge reset)
begin
    if(reset) busy <= 1'd0;
    else if(ready == 1'd1) busy <= 1'd1;
    else if(cs == FINISH )busy <= 1'd0;
end

//cwr 
always@(posedge clk or posedge reset)
begin
    if(reset) cwr <= 1'd0;
    else if(cs == L0wr || cs == L0wr_K1) cwr <= 1'd1;
    else if(cs == L2wr_K0 || cs == L2wr_K1) cwr <= 1'd1;
    else if(ns == L1wr || ns == L1wr_K1) cwr <= 1'd1;
    else cwr <= 1'd0; 
end
//crd
always@(posedge clk or posedge reset)
begin
    if(reset) crd <= 1'd0;
    else if(cs == L0rd || cs == L0rd_K1) crd <= 1'd1;
    else if(cs == L1rd_K0 || cs == L1rd_K1) crd <= 1'd1;
    else crd<= 1'd0;
end
//csel
always@(posedge clk or posedge reset)
begin
    if(reset) csel <=3'd0;
    else if(ns == L1wr) csel <= 3'b011;
    else if(ns == L1wr_K1) csel <= 3'b100;
    else if(cs == L1rd_K0) csel <= 3'b011;
    else if(cs == L1rd_K1) csel <= 3'b100;
    else if(cs == L2wr_K0 || cs == L2wr_K1) csel <= 3'b101;
    else if(cs == L0wr) csel <= 3'b001;
    else if(cs == L0wr_K1) csel <= 3'b010;
    else if(cs == L0rd) csel <= 3'b001; 
    else if(cs == L0rd_K1) csel <= 3'b010;
end

//iaddr
always@(posedge clk or posedge reset)
begin
    if(reset)  iaddr <= 12'd0; 
    else if(cs == convrd || cs == convrd_K1)
    begin
        case(counterRead)
        4'd0: iaddr <= {YY,XX};
        4'd1: iaddr <= {YY,index_X};
        4'd2: iaddr <= {YY,X};
        4'd3: iaddr <= {index_Y,XX};
        4'd4: iaddr <= {index_Y,index_X};
        4'd5: iaddr <= {index_Y,X};
        4'd6: iaddr <= {Y,XX};
        4'd7: iaddr <= {Y,index_X};
        4'd8: iaddr <= {Y,X};
        default: iaddr <= 6'd0;
        endcase
    end

    
   
end

always@(posedge clk or posedge reset)
begin
    if(reset) caddr_rd <= 12'd0;
    else if(cs == L0rd || cs == L0rd_K1)
    begin
        case(counterRead)
        4'd0: caddr_rd <= {index_Y,index_X};
        4'd1: caddr_rd <= {index_Y,X};
        4'd2: caddr_rd <= {Y,index_X};
        4'd3: caddr_rd <= {Y,X};
        default: caddr_rd <= 6'd0;
        endcase
    end
    else if(cs == L1rd_K0 || cs == L1rd_K1) caddr_rd <= {index_Y[5:1],index_X[5:1]};

end

always@(posedge clk or posedge reset)
begin
    if(reset) caddr_wr <= 12'd0;
    else if(cs == L0wr || cs == L0wr_K1) caddr_wr <= {index_Y,index_X};
    else if(ns == L1wr || ns == L1wr_K1) caddr_wr <= {index_Y[5:1],index_X[5:1]};
    else if(cs == L2wr_K0) caddr_wr <= ({index_Y[5:1],index_X[5:1]}<<1'd1) ;
    else if(cs == L2wr_K1) caddr_wr <= ({index_Y[5:1],index_X[5:1]}<<1'd1) +1'd1;
end

//cdata_wr
always@(posedge clk or posedge reset)
begin
    if(reset) cdata_wr <= 20'd0;
    else if(cs == L0wr || cs == L0wr_K1)
    begin
        if(roundTemp[20]) cdata_wr <= 20'd0;
        else cdata_wr <= roundTemp[20:1];
    end
    else if(cs == L0rd || cs == L0rd_K1)
    begin
        if(counterRead == 4'd1) cdata_wr <= cdata_rd;
        else 
        begin
            if(cdata_rd > cdata_wr) cdata_wr <= cdata_rd;
            else cdata_wr <= cdata_wr;
        end
    end
    else if(cs == L2wr_K0 || cs == L2wr_K1)
    begin
        cdata_wr <= cdata_rd;
    end
end



endmodule