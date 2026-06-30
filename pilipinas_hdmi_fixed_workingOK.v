// (c) fpga4fun.com & KNJN LLC 2013-2023
// Modified for Gowin Tang Nano 9K HDMI
// Philippine flag — waving sine effect, 1:2 ratio (128×64 px, half-size), centred 640×480
// Wave rate halved vs original (full cycle ~1.0s instead of ~0.5s)
// Static text "MABUHAY ANG PILIPINAS!" below flag
`default_nettype none
`define APICULA

module HDMI_test(
	input  clk,
	input  btn,
	output [3:0] led,
	output [2:0] tmds_d_p, tmds_d_n,
	output tmds_clk_p, tmds_clk_n
);

wire pixclk, clk_TMDS, lock;

reg [23:0] cnt = 0;
always @(posedge pixclk) cnt <= cnt + 1;
assign led = cnt[23:20];

`ifdef APICULA
wire clk_250;
pll_25 pll_25_inst(
	.clkin(clk), .clkout(clk_250), .clkoutd(pixclk), .lock(lock)
);
reg clk_250_r = 0;
always @(posedge clk_250) clk_250_r <= ~clk_250_r;
assign clk_TMDS = clk_250_r;
`else
pll_25 pll_25_inst(
	.clkin(clk), .clkout(clk_TMDS), .clkoutd(), .lock(lock)
);
clkdiv5 clkdiv5_inst(
	.hclkin(clk_TMDS), .clkout(pixclk), .resetn(lock)
);
`endif

////////////////////////////////////////////////////////////////////////
// VGA timing 640x480 @ 60Hz
////////////////////////////////////////////////////////////////////////
reg [9:0] CounterX = 0, CounterY = 0;
reg hSync, vSync, DrawArea;

always @(posedge pixclk) DrawArea <= (CounterX < 640) && (CounterY < 480);
always @(posedge pixclk) CounterX <= (CounterX == 799) ? 0 : CounterX + 1;
always @(posedge pixclk)
	if (CounterX == 799) CounterY <= (CounterY == 524) ? 0 : CounterY + 1;
always @(posedge pixclk) hSync <= (CounterX >= 656) && (CounterX < 752);
always @(posedge pixclk) vSync <= (CounterY >= 490) && (CounterY < 492);

reg vSync_d = 0;
always @(posedge pixclk) vSync_d <= vSync;

////////////////////////////////////////////////////////////////////////
// SINE WAVE ANIMATION
////////////////////////////////////////////////////////////////////////
reg [5:0] wave_phase = 0;
always @(posedge pixclk)
	if (vSync && !vSync_d) wave_phase <= wave_phase + 6'd1;

function automatic signed [6:0] sine_lut;
	input [5:0] idx;
	case (idx)
		6'd 0: sine_lut =  7'd0;   6'd 1: sine_lut =  7'd1;
		6'd 2: sine_lut =  7'd2;   6'd 3: sine_lut =  7'd3;
		6'd 4: sine_lut =  7'd4;   6'd 5: sine_lut =  7'd4;
		6'd 6: sine_lut =  7'd6;   6'd 7: sine_lut =  7'd6;
		6'd 8: sine_lut =  7'd7;   6'd 9: sine_lut =  7'd8;
		6'd10: sine_lut =  7'd8;   6'd11: sine_lut =  7'd9;
		6'd12: sine_lut =  7'd9;   6'd13: sine_lut =  7'd10;
		6'd14: sine_lut =  7'd10;  6'd15: sine_lut =  7'd10;
		6'd16: sine_lut =  7'd10;  6'd17: sine_lut =  7'd10;
		6'd18: sine_lut =  7'd10;  6'd19: sine_lut =  7'd10;
		6'd20: sine_lut =  7'd9;   6'd21: sine_lut =  7'd9;
		6'd22: sine_lut =  7'd8;   6'd23: sine_lut =  7'd8;
		6'd24: sine_lut =  7'd7;   6'd25: sine_lut =  7'd6;
		6'd26: sine_lut =  7'd6;   6'd27: sine_lut =  7'd4;
		6'd28: sine_lut =  7'd4;   6'd29: sine_lut =  7'd3;
		6'd30: sine_lut =  7'd2;   6'd31: sine_lut =  7'd1;
		6'd32: sine_lut =  7'd0;   6'd33: sine_lut = -7'd1;
		6'd34: sine_lut = -7'd2;   6'd35: sine_lut = -7'd3;
		6'd36: sine_lut = -7'd4;   6'd37: sine_lut = -7'd4;
		6'd38: sine_lut = -7'd6;   6'd39: sine_lut = -7'd6;
		6'd40: sine_lut = -7'd7;   6'd41: sine_lut = -7'd8;
		6'd42: sine_lut = -7'd8;   6'd43: sine_lut = -7'd9;
		6'd44: sine_lut = -7'd9;   6'd45: sine_lut = -7'd10;
		6'd46: sine_lut = -7'd10;  6'd47: sine_lut = -7'd10;
		6'd48: sine_lut = -7'd10;  6'd49: sine_lut = -7'd10;
		6'd50: sine_lut = -7'd10;  6'd51: sine_lut = -7'd10;
		6'd52: sine_lut = -7'd9;   6'd53: sine_lut = -7'd9;
		6'd54: sine_lut = -7'd8;   6'd55: sine_lut = -7'd8;
		6'd56: sine_lut = -7'd7;   6'd57: sine_lut = -7'd6;
		6'd58: sine_lut = -7'd6;   6'd59: sine_lut = -7'd4;
		6'd60: sine_lut = -7'd4;   6'd61: sine_lut = -7'd3;
		6'd62: sine_lut = -7'd2;   6'd63: sine_lut = -7'd1;
		default: sine_lut = 7'd0;
	endcase
endfunction

wire [5:0] wave_idx = CounterX[6:1] + wave_phase;
wire signed [6:0] wave_offset = sine_lut(wave_idx);

////////////////////////////////////////////////////////////////////////
// FLAG GEOMETRY (half-size)
////////////////////////////////////////////////////////////////////////
localparam signed [10:0] FLAG_Y      = 11'd174;
localparam        [9:0]  FLAG_HEIGHT = 10'd64;
localparam        [9:0]  FLAG_X      = 10'd256;
localparam        [9:0]  FLAG_WIDTH  = 10'd128;

wire signed [10:0] adj_Y = $signed({1'b0, CounterY}) - wave_offset;

wire in_flag_area = (CounterX >= FLAG_X) &&
                    (CounterX <  FLAG_X + FLAG_WIDTH) &&
                    (adj_Y    >= FLAG_Y) &&
                    (adj_Y    <  FLAG_Y + $signed({1'b0, FLAG_HEIGHT}));

wire [9:0] relX = CounterX - FLAG_X;
wire [6:0] relY = adj_Y[6:0] - FLAG_Y[6:0];

wire is_triangle = (relX <= {2'b0, relY}) &&
                   (relX <= (10'd63 - {2'b0, relY})) &&
                   (relX < 10'd64);

wire is_top_half = (adj_Y < FLAG_Y + 11'd32);

////////////////////////////////////////////////////////////////////////
// SUN
////////////////////////////////////////////////////////////////////////
wire [9:0] sun_dx = (relX > 10'd10) ? (relX - 10'd10) : (10'd10 - relX);
wire [6:0] sun_dy = (relY  > 7'd31) ? (relY  - 7'd31) : (7'd31  - relY);

wire sun_core = (sun_dx <= 10'd3 && sun_dy <= 7'd3) && (sun_dx + sun_dy <= 10'd4);

wire sun_rays =
	(sun_dx <= 10'd0  && sun_dy >= 7'd2  && sun_dy <= 7'd7)   ||
	(sun_dy <= 7'd0   && sun_dx >= 10'd2 && sun_dx <= 10'd7)  ||
	((sun_dx[6:0] == sun_dy || sun_dx[6:0] == sun_dy + 7'd1 || sun_dy == sun_dx[6:0] + 7'd1)
	    && sun_dx >= 10'd2 && sun_dx <= 10'd5)                 ||
	((relX + {2'b0, relY} >= 10'd41) && (relX + {2'b0, relY} <= 10'd43)
	    && sun_dx >= 10'd2 && sun_dx <= 10'd5);

wire is_sun = sun_core || sun_rays;

////////////////////////////////////////////////////////////////////////
// THREE STARS
////////////////////////////////////////////////////////////////////////
wire [9:0] s1_dx = (relX > 10'd2)   ? (relX - 10'd2)   : (10'd2   - relX);
wire [6:0] s1_dy = (relY  > 7'd5)   ? (relY  - 7'd5)   : (7'd5    - relY);
wire is_star1 = (s1_dx + s1_dy <= 10'd2) ||
                (s1_dx <= 10'd0 && s1_dy <= 7'd2) ||
                (s1_dy <= 7'd0  && s1_dx <= 10'd2);

wire [9:0] s2_dx = (relX > 10'd2)   ? (relX - 10'd2)   : (10'd2   - relX);
wire [6:0] s2_dy = (relY  > 7'd58)  ? (relY  - 7'd58)  : (7'd58   - relY);
wire is_star2 = (s2_dx + s2_dy <= 10'd2) ||
                (s2_dx <= 10'd0 && s2_dy <= 7'd2) ||
                (s2_dy <= 7'd0  && s2_dx <= 10'd2);

wire [9:0] s3_dx = (relX > 10'd27) ? (relX - 10'd27) : (10'd27 - relX);
wire [6:0] s3_dy = (relY  > 7'd32) ? (relY  - 7'd32) : (7'd32  - relY);
wire is_star3 = (s3_dx + s3_dy <= 10'd2) ||
                (s3_dx <= 10'd0 && s3_dy <= 7'd2) ||
                (s3_dy <= 7'd0  && s3_dx <= 10'd2);

wire is_gold = is_sun || is_star1 || is_star2 || is_star3;

////////////////////////////////////////////////////////////////////////
// TEXT: "MABUHAY ANG PILIPINAS!"
// 8x12 bitmap font, 3x scaled -> 24x36 per glyph, 26px stride
// 22 chars, width = 22*26-2 = 570, x_start = (640-570)/2 = 35
// y_start = 175 (below flag bottom ~162)
//
// Each character is handled by its own always block writing into
// a registered pixel bit.  This keeps each glyph as 12 small
// 8-bit constants that the synthesiser folds into LUT init — the
// lightest possible representation on GW1NR-9.
//
// txt_x, txt_y: pixel coordinates within the text bounding box
// char_col: which of the 8 font columns (0=left)
// char_row: which of the 12 font rows  (0=top)
// pix: the sampled font bit, registered one cycle
////////////////////////////////////////////////////////////////////////

localparam TX = 10'd35;   // text left edge
localparam TY = 10'd291;  // text top edge (vertically centered with flag on 480px screen)

wire in_txt_y = (CounterY >= TY) && (CounterY < TY + 10'd36);
wire in_txt_x = (CounterX >= TX) && (CounterX < TX + 10'd572);

wire [9:0] txt_x = CounterX - TX;
wire [9:0] txt_y = CounterY - TY;

// Which character slot (0..21) and pixel within it
wire [4:0] ch = (txt_x < 10'd26)  ? 5'd0  : (txt_x < 10'd52)  ? 5'd1  :
                (txt_x < 10'd78)  ? 5'd2  : (txt_x < 10'd104) ? 5'd3  :
                (txt_x < 10'd130) ? 5'd4  : (txt_x < 10'd156) ? 5'd5  :
                (txt_x < 10'd182) ? 5'd6  : (txt_x < 10'd208) ? 5'd7  :
                (txt_x < 10'd234) ? 5'd8  : (txt_x < 10'd260) ? 5'd9  :
                (txt_x < 10'd286) ? 5'd10 : (txt_x < 10'd312) ? 5'd11 :
                (txt_x < 10'd338) ? 5'd12 : (txt_x < 10'd364) ? 5'd13 :
                (txt_x < 10'd390) ? 5'd14 : (txt_x < 10'd416) ? 5'd15 :
                (txt_x < 10'd442) ? 5'd16 : (txt_x < 10'd468) ? 5'd17 :
                (txt_x < 10'd494) ? 5'd18 : (txt_x < 10'd520) ? 5'd19 :
                (txt_x < 10'd546) ? 5'd20 : 5'd21;

// x within the character slot (0..25); column index within glyph (0..7, 3px each)
wire [9:0] ch_left = (ch == 5'd0)  ? 10'd0   : (ch == 5'd1)  ? 10'd26  :
                     (ch == 5'd2)  ? 10'd52  : (ch == 5'd3)  ? 10'd78  :
                     (ch == 5'd4)  ? 10'd104 : (ch == 5'd5)  ? 10'd130 :
                     (ch == 5'd6)  ? 10'd156 : (ch == 5'd7)  ? 10'd182 :
                     (ch == 5'd8)  ? 10'd208 : (ch == 5'd9)  ? 10'd234 :
                     (ch == 5'd10) ? 10'd260 : (ch == 5'd11) ? 10'd286 :
                     (ch == 5'd12) ? 10'd312 : (ch == 5'd13) ? 10'd338 :
                     (ch == 5'd14) ? 10'd364 : (ch == 5'd15) ? 10'd390 :
                     (ch == 5'd16) ? 10'd416 : (ch == 5'd17) ? 10'd442 :
                     (ch == 5'd18) ? 10'd468 : (ch == 5'd19) ? 10'd494 :
                     (ch == 5'd20) ? 10'd520 : 10'd546;

wire [9:0] xic = txt_x - ch_left;          // 0..25 within char slot
wire [2:0] fcol = xic / 10'd3;             // font column 0..7  (true div3 of 3x-scaled coord)
wire [3:0] frow = txt_y / 10'd3;           // font row    0..11 (true div3 of 3x-scaled coord)
wire       in_glyph = (xic < 10'd24);      // gap pixels (24,25) are always off

// Per-character row bytes.  char_rom(ch, frow) -> the 8-bit row bitmap.
// We unroll into a single combinatorial case on {ch, frow} to avoid
// any function or array that could cause a large mux tree.
// MSB of each byte = leftmost pixel (font column 0).
// row_byte: select the 8-bit row bitmap for this char+row combo.
// Then font_bit = row_byte[7-fcol]  (MSB = column 0).
reg [7:0] font_rom [0:263];  // 22 glyphs x 12 rows, addr = ch*12 + frow
initial begin
    font_rom[  0] = 8'hc3;
    font_rom[  1] = 8'hc3;
    font_rom[  2] = 8'he7;
    font_rom[  3] = 8'he7;
    font_rom[  4] = 8'hdb;
    font_rom[  5] = 8'hdb;
    font_rom[  6] = 8'hc3;
    font_rom[  7] = 8'hc3;
    font_rom[  8] = 8'hc3;
    font_rom[  9] = 8'hc3;
    font_rom[ 10] = 8'h00;
    font_rom[ 11] = 8'h00;
    font_rom[ 12] = 8'h3c;
    font_rom[ 13] = 8'h66;
    font_rom[ 14] = 8'hc3;
    font_rom[ 15] = 8'hc3;
    font_rom[ 16] = 8'hff;
    font_rom[ 17] = 8'hc3;
    font_rom[ 18] = 8'hc3;
    font_rom[ 19] = 8'hc3;
    font_rom[ 20] = 8'hc3;
    font_rom[ 21] = 8'hc3;
    font_rom[ 22] = 8'h00;
    font_rom[ 23] = 8'h00;
    font_rom[ 24] = 8'hfc;
    font_rom[ 25] = 8'hc3;
    font_rom[ 26] = 8'hc3;
    font_rom[ 27] = 8'hc6;
    font_rom[ 28] = 8'hfc;
    font_rom[ 29] = 8'hc6;
    font_rom[ 30] = 8'hc3;
    font_rom[ 31] = 8'hc3;
    font_rom[ 32] = 8'hc6;
    font_rom[ 33] = 8'hfc;
    font_rom[ 34] = 8'h00;
    font_rom[ 35] = 8'h00;
    font_rom[ 36] = 8'hc3;
    font_rom[ 37] = 8'hc3;
    font_rom[ 38] = 8'hc3;
    font_rom[ 39] = 8'hc3;
    font_rom[ 40] = 8'hc3;
    font_rom[ 41] = 8'hc3;
    font_rom[ 42] = 8'hc3;
    font_rom[ 43] = 8'hc3;
    font_rom[ 44] = 8'h66;
    font_rom[ 45] = 8'h3c;
    font_rom[ 46] = 8'h00;
    font_rom[ 47] = 8'h00;
    font_rom[ 48] = 8'hc3;
    font_rom[ 49] = 8'hc3;
    font_rom[ 50] = 8'hc3;
    font_rom[ 51] = 8'hc3;
    font_rom[ 52] = 8'hff;
    font_rom[ 53] = 8'hc3;
    font_rom[ 54] = 8'hc3;
    font_rom[ 55] = 8'hc3;
    font_rom[ 56] = 8'hc3;
    font_rom[ 57] = 8'hc3;
    font_rom[ 58] = 8'h00;
    font_rom[ 59] = 8'h00;
    font_rom[ 60] = 8'h3c;
    font_rom[ 61] = 8'h66;
    font_rom[ 62] = 8'hc3;
    font_rom[ 63] = 8'hc3;
    font_rom[ 64] = 8'hff;
    font_rom[ 65] = 8'hc3;
    font_rom[ 66] = 8'hc3;
    font_rom[ 67] = 8'hc3;
    font_rom[ 68] = 8'hc3;
    font_rom[ 69] = 8'hc3;
    font_rom[ 70] = 8'h00;
    font_rom[ 71] = 8'h00;
    font_rom[ 72] = 8'hc3;
    font_rom[ 73] = 8'hc3;
    font_rom[ 74] = 8'h66;
    font_rom[ 75] = 8'h3c;
    font_rom[ 76] = 8'h18;
    font_rom[ 77] = 8'h18;
    font_rom[ 78] = 8'h18;
    font_rom[ 79] = 8'h18;
    font_rom[ 80] = 8'h18;
    font_rom[ 81] = 8'h18;
    font_rom[ 82] = 8'h00;
    font_rom[ 83] = 8'h00;
    font_rom[ 84] = 8'h00;
    font_rom[ 85] = 8'h00;
    font_rom[ 86] = 8'h00;
    font_rom[ 87] = 8'h00;
    font_rom[ 88] = 8'h00;
    font_rom[ 89] = 8'h00;
    font_rom[ 90] = 8'h00;
    font_rom[ 91] = 8'h00;
    font_rom[ 92] = 8'h00;
    font_rom[ 93] = 8'h00;
    font_rom[ 94] = 8'h00;
    font_rom[ 95] = 8'h00;
    font_rom[ 96] = 8'h3c;
    font_rom[ 97] = 8'h66;
    font_rom[ 98] = 8'hc3;
    font_rom[ 99] = 8'hc3;
    font_rom[100] = 8'hff;
    font_rom[101] = 8'hc3;
    font_rom[102] = 8'hc3;
    font_rom[103] = 8'hc3;
    font_rom[104] = 8'hc3;
    font_rom[105] = 8'hc3;
    font_rom[106] = 8'h00;
    font_rom[107] = 8'h00;
    font_rom[108] = 8'hc3;
    font_rom[109] = 8'he3;
    font_rom[110] = 8'hf3;
    font_rom[111] = 8'hdb;
    font_rom[112] = 8'hcf;
    font_rom[113] = 8'hc7;
    font_rom[114] = 8'hc3;
    font_rom[115] = 8'hc3;
    font_rom[116] = 8'hc3;
    font_rom[117] = 8'hc3;
    font_rom[118] = 8'h00;
    font_rom[119] = 8'h00;
    font_rom[120] = 8'h3c;
    font_rom[121] = 8'h66;
    font_rom[122] = 8'hc3;
    font_rom[123] = 8'hc0;
    font_rom[124] = 8'hc0;
    font_rom[125] = 8'hcf;
    font_rom[126] = 8'hc3;
    font_rom[127] = 8'hc3;
    font_rom[128] = 8'h66;
    font_rom[129] = 8'h3c;
    font_rom[130] = 8'h00;
    font_rom[131] = 8'h00;
    font_rom[132] = 8'h00;
    font_rom[133] = 8'h00;
    font_rom[134] = 8'h00;
    font_rom[135] = 8'h00;
    font_rom[136] = 8'h00;
    font_rom[137] = 8'h00;
    font_rom[138] = 8'h00;
    font_rom[139] = 8'h00;
    font_rom[140] = 8'h00;
    font_rom[141] = 8'h00;
    font_rom[142] = 8'h00;
    font_rom[143] = 8'h00;
    font_rom[144] = 8'hfc;
    font_rom[145] = 8'hc6;
    font_rom[146] = 8'hc3;
    font_rom[147] = 8'hc3;
    font_rom[148] = 8'hc6;
    font_rom[149] = 8'hfc;
    font_rom[150] = 8'hc0;
    font_rom[151] = 8'hc0;
    font_rom[152] = 8'hc0;
    font_rom[153] = 8'hc0;
    font_rom[154] = 8'h00;
    font_rom[155] = 8'h00;
    font_rom[156] = 8'h7e;
    font_rom[157] = 8'h18;
    font_rom[158] = 8'h18;
    font_rom[159] = 8'h18;
    font_rom[160] = 8'h18;
    font_rom[161] = 8'h18;
    font_rom[162] = 8'h18;
    font_rom[163] = 8'h18;
    font_rom[164] = 8'h18;
    font_rom[165] = 8'h7e;
    font_rom[166] = 8'h00;
    font_rom[167] = 8'h00;
    font_rom[168] = 8'hc0;
    font_rom[169] = 8'hc0;
    font_rom[170] = 8'hc0;
    font_rom[171] = 8'hc0;
    font_rom[172] = 8'hc0;
    font_rom[173] = 8'hc0;
    font_rom[174] = 8'hc0;
    font_rom[175] = 8'hc0;
    font_rom[176] = 8'hc0;
    font_rom[177] = 8'hff;
    font_rom[178] = 8'h00;
    font_rom[179] = 8'h00;
    font_rom[180] = 8'h7e;
    font_rom[181] = 8'h18;
    font_rom[182] = 8'h18;
    font_rom[183] = 8'h18;
    font_rom[184] = 8'h18;
    font_rom[185] = 8'h18;
    font_rom[186] = 8'h18;
    font_rom[187] = 8'h18;
    font_rom[188] = 8'h18;
    font_rom[189] = 8'h7e;
    font_rom[190] = 8'h00;
    font_rom[191] = 8'h00;
    font_rom[192] = 8'hfc;
    font_rom[193] = 8'hc6;
    font_rom[194] = 8'hc3;
    font_rom[195] = 8'hc3;
    font_rom[196] = 8'hc6;
    font_rom[197] = 8'hfc;
    font_rom[198] = 8'hc0;
    font_rom[199] = 8'hc0;
    font_rom[200] = 8'hc0;
    font_rom[201] = 8'hc0;
    font_rom[202] = 8'h00;
    font_rom[203] = 8'h00;
    font_rom[204] = 8'h7e;
    font_rom[205] = 8'h18;
    font_rom[206] = 8'h18;
    font_rom[207] = 8'h18;
    font_rom[208] = 8'h18;
    font_rom[209] = 8'h18;
    font_rom[210] = 8'h18;
    font_rom[211] = 8'h18;
    font_rom[212] = 8'h18;
    font_rom[213] = 8'h7e;
    font_rom[214] = 8'h00;
    font_rom[215] = 8'h00;
    font_rom[216] = 8'hc3;
    font_rom[217] = 8'he3;
    font_rom[218] = 8'hf3;
    font_rom[219] = 8'hdb;
    font_rom[220] = 8'hcf;
    font_rom[221] = 8'hc7;
    font_rom[222] = 8'hc3;
    font_rom[223] = 8'hc3;
    font_rom[224] = 8'hc3;
    font_rom[225] = 8'hc3;
    font_rom[226] = 8'h00;
    font_rom[227] = 8'h00;
    font_rom[228] = 8'h3c;
    font_rom[229] = 8'h66;
    font_rom[230] = 8'hc3;
    font_rom[231] = 8'hc3;
    font_rom[232] = 8'hff;
    font_rom[233] = 8'hc3;
    font_rom[234] = 8'hc3;
    font_rom[235] = 8'hc3;
    font_rom[236] = 8'hc3;
    font_rom[237] = 8'hc3;
    font_rom[238] = 8'h00;
    font_rom[239] = 8'h00;
    font_rom[240] = 8'h3e;
    font_rom[241] = 8'h63;
    font_rom[242] = 8'hc1;
    font_rom[243] = 8'hc0;
    font_rom[244] = 8'h78;
    font_rom[245] = 8'h1e;
    font_rom[246] = 8'h03;
    font_rom[247] = 8'h83;
    font_rom[248] = 8'hc6;
    font_rom[249] = 8'h7c;
    font_rom[250] = 8'h00;
    font_rom[251] = 8'h00;
    font_rom[252] = 8'h18;
    font_rom[253] = 8'h18;
    font_rom[254] = 8'h18;
    font_rom[255] = 8'h18;
    font_rom[256] = 8'h18;
    font_rom[257] = 8'h18;
    font_rom[258] = 8'h18;
    font_rom[259] = 8'h18;
    font_rom[260] = 8'h00;
    font_rom[261] = 8'h18;
    font_rom[262] = 8'h00;
    font_rom[263] = 8'h00;
end

// ch*12 = ch*8 + ch*4, done with shifts+add instead of a generic multiplier
// (lighter on LUTs/routing than ch * 12 on this small device)
wire [8:0] ch9 = {4'b0, ch};
wire [8:0] font_addr = (ch9 << 3) + (ch9 << 2) + {5'b0, frow};
wire [7:0] row_byte = font_rom[font_addr];
wire font_bit = in_txt_x && in_txt_y && in_glyph && row_byte[7-fcol];

////////////////////////////////////////////////////////////////////////
// RENDERING
////////////////////////////////////////////////////////////////////////
reg [7:0] red, green, blue;

always @(posedge pixclk) begin
	if (in_flag_area) begin
		if (is_triangle) begin
			if (is_gold) begin
				red <= 8'hFC; green <= 8'hD1; blue <= 8'h16;
			end else begin
				red <= 8'hFF; green <= 8'hFF; blue <= 8'hFF;
			end
		end else if (is_top_half) begin
			red <= 8'h00; green <= 8'h38; blue <= 8'hA8;
		end else begin
			red <= 8'hCE; green <= 8'h11; blue <= 8'h26;
		end
	end else if (font_bit) begin
		red <= 8'h00; green <= 8'hC8; blue <= 8'h46;
	end else begin
		red <= 8'h00; green <= 8'h00; blue <= 8'h00;
	end
end

////////////////////////////////////////////////////////////////////////
wire [9:0] TMDS_red, TMDS_green, TMDS_blue;
TMDS_encoder encode_R(.clk(pixclk), .VD(red),   .CD(2'b00),         .VDE(DrawArea), .TMDS(TMDS_red));
TMDS_encoder encode_G(.clk(pixclk), .VD(green), .CD(2'b00),         .VDE(DrawArea), .TMDS(TMDS_green));
TMDS_encoder encode_B(.clk(pixclk), .VD(blue),  .CD({vSync,hSync}), .VDE(DrawArea), .TMDS(TMDS_blue));

wire [2:0] tmds_d;
OSER10 tmds_serdes[2:0] (
	.Q(tmds_d),
	.D0({TMDS_red[0], TMDS_green[0], TMDS_blue[0]}),
	.D1({TMDS_red[1], TMDS_green[1], TMDS_blue[1]}),
	.D2({TMDS_red[2], TMDS_green[2], TMDS_blue[2]}),
	.D3({TMDS_red[3], TMDS_green[3], TMDS_blue[3]}),
	.D4({TMDS_red[4], TMDS_green[4], TMDS_blue[4]}),
	.D5({TMDS_red[5], TMDS_green[5], TMDS_blue[5]}),
	.D6({TMDS_red[6], TMDS_green[6], TMDS_blue[6]}),
	.D7({TMDS_red[7], TMDS_green[7], TMDS_blue[7]}),
	.D8({TMDS_red[8], TMDS_green[8], TMDS_blue[8]}),
	.D9({TMDS_red[9], TMDS_green[9], TMDS_blue[9]}),
	.PCLK(pixclk),
	.FCLK(clk_TMDS),
	.RESET(~lock)
);

ELVDS_OBUF tmds_bufds[3:0] (
	.I({pixclk, tmds_d}),
	.O({tmds_clk_p, tmds_d_p}),
	.OB({tmds_clk_n, tmds_d_n})
);
endmodule

////////////////////////////////////////////////////////////////////////
module TMDS_encoder(
	input clk,
	input [7:0] VD,
	input [1:0] CD,
	input VDE,
	output reg [9:0] TMDS = 0
);
wire [3:0] Nb1s = VD[0]+VD[1]+VD[2]+VD[3]+VD[4]+VD[5]+VD[6]+VD[7];
wire XNOR = (Nb1s>4'd4) || (Nb1s==4'd4 && VD[0]==1'b0);
wire [8:0] q_m = {~XNOR, q_m[6:0] ^ VD[7:1] ^ {7{XNOR}}, VD[0]};
reg [3:0] balance_acc = 0;
wire [3:0] balance = q_m[0]+q_m[1]+q_m[2]+q_m[3]+q_m[4]+q_m[5]+q_m[6]+q_m[7] - 4'd4;
wire balance_sign_eq = (balance[3] == balance_acc[3]);
wire invert_q_m = (balance==0 || balance_acc==0) ? ~q_m[8] : balance_sign_eq;
wire [3:0] balance_acc_inc = balance - ({q_m[8] ^ ~balance_sign_eq} & ~(balance==0 || balance_acc==0));
wire [3:0] balance_acc_new = invert_q_m ? balance_acc-balance_acc_inc : balance_acc+balance_acc_inc;
wire [9:0] TMDS_data = {invert_q_m, q_m[8], q_m[7:0] ^ {8{invert_q_m}}};
wire [9:0] TMDS_code = CD[1] ? (CD[0] ? 10'b1010101011 : 10'b0101010100) : (CD[0] ? 10'b0010101011 : 10'b1101010100);
always @(posedge clk) TMDS <= VDE ? TMDS_data : TMDS_code;
always @(posedge clk) balance_acc <= VDE ? balance_acc_new : 4'h0;
endmodule

////////////////////////////////////////////////////////////////////////
module pll_25 (
	output clkout,
	output clkoutd,
	input  clkin,
	output lock
);
	rPLL pll (
		.CLKOUT(clkout), .CLKOUTD(clkoutd), .CLKIN(clkin),
		.CLKFB(0), .RESET_P(0), .RESET(0),
		.FBDSEL(0), .IDSEL(0), .ODSEL(0),
		.DUTYDA(0), .PSDA(0), .FDLY(0), .LOCK(lock)
	);
	defparam pll.DEVICE = "GW1NR-9";
	defparam pll.FCLKIN = "27";
`ifdef APICULA
	defparam pll.FBDIV_SEL = 36;
	defparam pll.IDIV_SEL  = 3;
	defparam pll.ODIV_SEL  = 4;
`else
	defparam pll.FBDIV_SEL = 36;
	defparam pll.IDIV_SEL  = 7;
	defparam pll.ODIV_SEL  = 8;
`endif
	defparam pll.CLKFB_SEL="internal";      defparam pll.CLKOUTD3_SRC="CLKOUT";
	defparam pll.CLKOUTD_BYPASS="false";    defparam pll.CLKOUTD_SRC="CLKOUT";
	defparam pll.CLKOUTP_BYPASS="false";    defparam pll.CLKOUTP_DLY_STEP=0;
	defparam pll.CLKOUTP_FT_DIR=1'b1;      defparam pll.CLKOUT_BYPASS="false";
	defparam pll.CLKOUT_DLY_STEP=0;        defparam pll.CLKOUT_FT_DIR=1'b1;
	defparam pll.DUTYDA_SEL="1000";        defparam pll.DYN_DA_EN="false";
	defparam pll.DYN_FBDIV_SEL="false";    defparam pll.DYN_IDIV_SEL="false";
	defparam pll.DYN_ODIV_SEL="false";     defparam pll.DYN_SDIV_SEL=10;
	defparam pll.PSDA_SEL="0000";
endmodule

////////////////////////////////////////////////////////////////////////
module clkdiv5 (
	output clkout,
	input  hclkin,
	input  resetn
);
	CLKDIV clkdiv_inst (
		.CLKOUT(clkout), .HCLKIN(hclkin), .RESETN(resetn), .CALIB(0)
	);
	defparam clkdiv_inst.DIV_MODE = "5";
	defparam clkdiv_inst.GSREN = "false";
endmodule


