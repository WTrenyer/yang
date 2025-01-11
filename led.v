module led_cercle (
    input  wire clk , rst_n,
    output wire [15:0] led 
);

reg [15:0] led_reg;
localparam idle             = 4'b0000;
localparam statu_left_right = 4'b0001;
localparam statu_right_left = 4'b0010;
localparam statu_mid_side   = 4'b0100;
localparam statu_side_mid   = 4'b1000;
localparam statu_end        = 4'b1010;
// 状态跳转逻辑
reg [3:0] statu , statu_next ;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        statu_next <= idle;
        statu      <= idle;
    end else begin
        statu <= statu_next;
        case (statu)
            idle:begin
                if (led_reg == {{1'b1},{15{1'b0}}}) begin
                    statu_next <= statu_left_right;   
                end

            end
            statu_left_right:begin
              if (led_reg[0] == 1 ) begin
                statu_next <= statu_right_left;
              end else begin
                statu_next <= statu_next;
              end
                
            end
            statu_right_left:begin
               if (led_reg[15] == 1 ) begin
                statu_next <= statu_mid_side;
              end else begin
                statu_next <= statu_next;
              end
            end
            statu_mid_side:begin
              if (led_reg[15] == 1 && led_reg[0] == 1 ) begin
                statu_next <= statu_side_mid;
              end else begin
                statu_next <= statu_next;
              end
            end
            statu_side_mid:begin
              if (led_reg[7] == 1 && led_reg[8] == 1 ) begin
                statu_next <= idle;
              end else begin
                statu_next <= statu_next;
              end
            end

        endcase
    end
        
end






// 计数器给信号模块S
localparam counter_number = 50;
reg [25:0] counter ;
reg counter_fleg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 26'b0;
        counter_fleg <= 1'b0;
    end else begin
        if (counter == counter_number) begin
            counter <= 26'b0;
            counter_fleg <= 1'b1;
        end else begin
            counter <= counter + 1'b1;
            counter_fleg <= 1'b0;
        end
    end
end

// led给数逻辑
reg [1:0]first_come;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        led_reg <= 16'b0;
        first_come <= 2'b0;

    end else if(counter_fleg) begin
        case (statu)
            idle:begin
                led_reg <= {{1'b1},{15{1'b0}}};
            end
            statu_left_right:begin
                led_reg <= {led_reg[0],led_reg[15:1]};
            end
            statu_right_left:begin
                led_reg <= {led_reg[14:0],led_reg[15]};
            end
            statu_mid_side:begin
                if (first_come == 2'b01) begin
                    led_reg[15:8] <={led_reg[14:8],led_reg[15]} ;
                    led_reg[7:0]  <= {led_reg[0],led_reg[7:1]};
                end else begin
                    led_reg [15:8]  <= {{7{1'b0}},1'b1};
                    led_reg [7:0]   <= {1'b1,{7{1'b0}}};
                    first_come <= 2'b01;
                end

            end
            statu_side_mid:begin
                if (first_come == 2'b10) begin
                    led_reg[15:8] <={led_reg[8],led_reg[15:9]} ;
                    led_reg[7:0]  <= {led_reg[6:0],led_reg[7]};
                end else begin
                    led_reg [15:8]  <= {1'b1,{7{1'b0}}};
                    led_reg [7:0]   <= {{7{1'b0}},1'b1};
                    first_come <= 2'b10;
                end
            end
            
        endcase
    end
end

assign led = led_reg;


    
endmodule