module stopwatch (CLK, RSTn, PSW, RSW, SEG_A, SEG_B, SEG_C, SEG_D, LED);
  input CLK,RSTn;// CLK:1kHzの入力クロック,RSTn:‘0’がリセット状態を表す
  input [3:0]PSW;//4つの押しボタンに接続されており,最下位ビットが左側,最上位ビットが右側に対応,PSW[3]:スタート,PSW[2]:ストップ,PSW[1]:クリア
  input [3:0]RSW;//ロータリースイッチで 4’d0~4’d9 の数値が得られる
  output [7:0] SEG_A, SEG_B, SEG_C, SEG_D;//はそれぞれ 7 セグメント LED への 8 ビットの出力信号
  output [7:0] LED;

wire [7:0] SEG_A , SEG_B , SEG_C , SEG_D, LED;
reg [3:0]time_tens = 4'b0, time_ones = 4'b0, time_tenth = 4'b0, time_hundredth = 4'b0;
reg [1:0] state = 2'b00;
reg [3:0] count = 4'd0;
reg flag = 0;


// 1/100秒の1の位をカウント
always @(posedge CLK or negedge RSTn) begin
	if (RSTn == 0 || (state == 2'b10 && PSW[1] == 1)) begin //リセットかクリアの場合
		time_hundredth <= 0;
	end else if(flag) begin //フラグが上がっている時
		if (time_hundredth == 4'd9) begin//繰り上がりの場合(0.09秒)
			time_hundredth <= 0; 
		end else begin
			time_hundredth <= time_hundredth + 1;//繰り上がらない場合は1増やす
		end
	end
end

// 1/100秒の10の位をカウント
always @(posedge CLK or negedge RSTn) begin
	if (RSTn == 0 || (state == 2'b10 && PSW[1] == 1)) begin //リセットかクリアの場合
		time_tenth <= 0;
	end else if(flag) begin //フラグが上がっている時
		if(time_tenth == 4'd9 && time_hundredth == 4'd9) begin //繰り上がりの場合(0.99秒)
			time_tenth <= 0;
		end else if(time_hundredth == 4'd9) begin //0.09秒の時に1増やす
			time_tenth <= time_tenth + 1;
		end
	end
end

// 秒の1の位をカウント
always @(posedge CLK or negedge RSTn) begin
	if (RSTn == 0 || (state == 2'b10 && PSW[1] == 1)) begin //リセットかクリアの場合
		time_ones <= 0;
	end else if(flag) begin //フラグが上がっている時
		if(time_ones == 4'd9 && time_tenth == 4'd9 && time_hundredth == 4'd9) begin //繰り上がりの場合(9.99秒)
			time_ones <= 0;
		end else if(time_tenth == 4'd9 && time_hundredth == 4'd9) begin //0.99秒の時に1増やす
			time_ones <= time_ones + 1;
		end
	end
end

// 秒の10の位をカウント
always @(posedge CLK or negedge RSTn) begin
	if (RSTn == 0 || (state == 2'b10 && PSW[1] == 1)) begin //リセットかクリアの場合
		time_tens <= 0;
	end else if(flag) begin //フラグが上がっている時
		if(time_tens == 4'd9 && time_ones == 4'd9 && time_tenth == 4'd9 && time_hundredth == 4'd9) begin //繰り上がりの場合(99.99秒)
			time_tens <= 0;
		end else if(time_ones == 4'd9 && time_tenth == 4'd9 && time_hundredth == 4'd9) begin //9.99秒の時に1増やす
			time_tens <= time_tens + 1;
		end
	end
end

always @(posedge CLK or negedge RSTn) begin //クロックをカウント
	if(!RSTn) //リセット時
		count <= 4'd0;
	else if (state == 2'b01) begin //カウント動作状態のみ
		if ( count == 4'd9) 
			count <= 4'd0; //10クロック目で0に戻す
		else 
			count <= count + 1;
	end
end

always @(posedge CLK or negedge RSTn) begin
	if(!RSTn) //リセット時
		flag <= 0;
	else begin	
		if ( count == 4'd8 )
			flag <= 1; //9クロック目の立ち上がりの時にflagを上げるようにする
		else
			flag <= 0;
	end
end

// ステートマシンを使ってストップウォッチを制御
always @(posedge CLK or negedge RSTn) begin
	if (!RSTn) begin //リセットの場合
		state <= 2'b00;
	end else begin	
		case (state)
			2'b00:  // 初期状態
				if (PSW[3]) //スタート
					state <= 2'b01;
			2'b01:  // カウント動作状態
				if (PSW[2]) //ストップ
					state <= 2'b10;
			2'b10:  //カウント停止状態
				if (PSW[1]) //クリア
					state <= 2'b00;
			default:
				state <= 2'b00;
		endcase
	end
end

	DEC7SEG DEC_hundredth (CLK, time_hundredth , SEG_D, RSTn); //7セグメントLEDに変換
	DEC7SEG DEC_tenth     (CLK, time_tenth     , SEG_C, RSTn);
	DEC7SEG_point DEC_ones(CLK, time_ones      , SEG_B, RSTn);
	DEC7SEG DEC_tens      (CLK, time_tens      , SEG_A, RSTn);
	
assign LED = 8'b00000000;

endmodule


module DEC7SEG (CLK, HEX, LED, RSTn); 

input  [3:0] HEX;
input CLK, RSTn;
output [7:0] LED;
reg [7:0]LED;

// 7Segment decoder 
always @(posedge CLK or negedge RSTn) begin
	if(!RSTn)
			LED <= 8'b11111100;
	else  begin 
		case( HEX )
		4'h0: LED <= 8'b11111100;	// 0
		4'h1: LED <= 8'b01100000;	// 1
		4'h2: LED <= 8'b11011010;	// 2
		4'h3: LED <= 8'b11110010;	// 3
		4'h4: LED <= 8'b01100110;	// 4
		4'h5: LED <= 8'b10110110;	// 5
		4'h6: LED <= 8'b10111110;	// 6
		4'h7: LED <= 8'b11100000;	// 7
		4'h8: LED <= 8'b11111110;	// 8
		4'h9: LED <= 8'b11110110;	// 9
		default: LED <= 8'b00000000;	// ?
		endcase
	end
end


endmodule
module DEC7SEG_point (CLK, HEX, LED, RSTn); //小数点がある場合

input  [3:0] HEX;
input CLK, RSTn;
output [7:0] LED;
reg [7:0]LED;

// 7Segment decoder 
always @(posedge CLK or negedge RSTn) begin
	if(!RSTn)
			LED <= 8'b11111101;
	else  begin 
		case( HEX )
		4'h0: LED <= 8'b11111101;	// 0
		4'h1: LED <= 8'b01100001;	// 1
		4'h2: LED <= 8'b11011011;	// 2
		4'h3: LED <= 8'b11110011;	// 3
		4'h4: LED <= 8'b01100111;	// 4
		4'h5: LED <= 8'b10110111;	// 5
		4'h6: LED <= 8'b10111111;	// 6
		4'h7: LED <= 8'b11100001;	// 7
		4'h8: LED <= 8'b11111111;	// 8
		4'h9: LED <= 8'b11110111;	// 9
		default: LED <= 8'b00000001;	// ?
		endcase
	end
end


endmodule

