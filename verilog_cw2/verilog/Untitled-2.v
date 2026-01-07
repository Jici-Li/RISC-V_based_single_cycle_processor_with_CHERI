module tag_cache_dm #(//写出来这个缓存的基本信息：大小，需要的index和offset的数量等等
  parameter ADDR_W = 32,
  parameter LINE_BYTES = 16,
  parameter LINES = 64      
)(
  input  wire              clk,//两个不可更改的wire：时钟和复位
  input  wire              rst,

  input  wire              req_valid,
  //这个wire线是系统自动给我们输出该cache区域我们要找的地址里的数据是否是valid的，不可更改
  input  wire [ADDR_W-1:0] req_addr,
  //这个是系统在寻求下一个地址的输入
  output reg               req_ready,
  //这个是系统已经准备好接受下一个地址了

  output reg               resp_valid,
  //reg是我们可以更改的线，这是我们在找到原来没找到的数据并且放进地址以后给他更改为valid
  output reg               resp_hit,//这个我不理解


  output reg [31:0]        hit_count,
  output reg [31:0] 
    //同c里面的hit++，数量用32进制表示
  miss_count
    //这个就是对应的c里面的miss++
);


  localparam integer OFFSET_W = $clog2(LINE_BYTES);
  localparam integer INDEX_W  = $clog2(LINES);
  localparam integer TAG_W    = ADDR_W - OFFSET_W - INDEX_W;

  wire [INDEX_W-1:0] idx = req_addr[OFFSET_W + INDEX_W - 1 : OFFSET_W];
  wire [TAG_W-1:0]   tag = req_addr[ADDR_W-1 : OFFSET_W + INDEX_W];
  

  //这些就是计算offset index和tag的占位


  reg                valid [0:LINES-1];
  reg [TAG_W-1:0]     tags  [0:LINES-1];
  //把刚才计算完成的占位填进去

  wire hit = valid[idx] && (tags[idx] == tag);
//又valid又tag相同就hit
  integer i;

  always @(posedge clk) begin
    if (rst) begin//if里只能是1
      req_ready  <= 1'b1;
      resp_valid <= 1'b0;
      resp_hit   <= 1'b0;//hit ready valid都只有两种可能所以
      hit_count  <= 32'd0;
      miss_count <= 32'd0;//计数所以是32进制

      for (i = 0; i < LINES; i = i + 1) begin//与c相同的for循环，每条line寻找
        valid[i] <= 1'b0;//valid在i行处=1说明valid了
        tags[i]  <= {TAG_W{1'b0}};//这个也讲讲
      end
    end else begin
      resp_valid <= 1'b0; 

      if (req_valid && req_ready) begin//上面的wire，需要机器同意并且ready
        resp_valid <= 1'b1;
        resp_hit   <= hit;

        if (hit) begin
          hit_count <= hit_count + 1;
        end else begin
          miss_count <= miss_count + 1;

//与c全部相同，计数方式一一对应

    end
  end

endmodule
