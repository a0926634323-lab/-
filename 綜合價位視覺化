// 腳本名稱：V90.5_綜合價位視覺化 (指標版-含交易模擬)
// 類型：指標腳本
// 版本：V-Final-Indicator-Sim-Fix4 (修正 SetPlotLabel 區塊分號錯誤)
// 日期：2025-11-05
// 說明：此腳本整合 V90.5 策略，顯示每日優化價位，
//       並模擬「進場」與「出場」訊號，繪製損益曲線。
// ====================================================================================================
// 【！！！指標設定關鍵！！！】
//
// 1. K線頻率 (Chart Frequency):
//  - 【必要】請務必使用「日線 (D)」K線圖。
//
// 2. 資料讀取筆數 (Data Bars to Load):
//  - 腳本已使用 SetBarBack 自動設定，資料讀取筆數設定 300 筆即可。
//
// 3. 依賴關係 (【重要】):
//  - 此腳本必須搭配以下 "三個" 函數腳本才能正常運作：
//    1. 「_SimulatePeriodPerformance」 (V3 或更新版本)
//    2. 「_CheckIfPriceTooHigh_V1」 (V1.1 或更新版本)
//    3. 「_SimulateATR_V2」 (V2 或更新版本)
// ====================================================================================================

// ---------- 參數宣告區塊 (Inputs) ----------
input:
 // --- 週期優化參數 (from V81.2) ---
 Period1(5, "[優化]週期一"),
 Period2(10, "[優化]週期二"),
 Period3(20, "[優化]週期三"),

 // --- ATR 停損/停利 優化參數 (from 開盤價ATR) ---
 TP_Start(0.3, "[優化]停利倍數起始"),
 TP_End(5.0, "[優化]停利倍數結束"),
 TP_Step(0.1, "[優化]停利倍數步長"),
 SL_Start(0.3, "[優化]停損倍數起始"),
 SL_End(5.0, "[優化]停損倍數結束"),
 SL_Step(0.1, "[優化]停損倍數步長"),
 Limit_ATR_Ratio(2, "[優化]漲跌停ATR修正倍數"),

 // --- 支撐計算參數 (from V90.5) ---
 Support_Lookback_Days(100, "[支撐]回測天數(日)"),
 Tolerance_Percent(1.0, "[支撐]容忍百分比(%)"),
 ATR_Confirmation_Ratio(0.2, "[支撐]突破ATR緩衝係數(倍)"),
 ATR_Period(14, "[支撐]ATR計算週期(日)"),
 
 // --- 【*** 修正點 ***】 補上備援邏輯所需參數 ---
 Profit_Target_Percent(7, "[備援]ATR=0停利(%)"), // Fallback for ATR=0
 StopLoss_Fallback_Percent(5, "[備援]ATR=0停損(%)"), // Fallback for ATR=0

 // --- 高價過濾參數 (from V90.5) ---
 EnableHighFilter(True, "[過濾]啟用高價過濾(總開關)"),
 FilterNearHigh(True, "[過濾]啟用濾網1:近高點(開關)"),
 MaxDistPct(0.5, "[過濾]濾網1參數:距高點%(↓嚴格↑寬鬆)"),
 FilterMADev(True, "[過濾]啟用濾網2:均線乖離(開關)"),
 MaxDevPct(2.0, "[過濾]濾網2參數:超短均線%(↓嚴格↑寬鬆)"),
 FilterRSIOB(True, "[過濾]啟用濾網3:RSI過熱(開關)"),
 RSILimit(75, "[過濾]濾網3參數:RSI閾值(↓嚴格↑寬鬆)"),
 
 // --- N字波段目標價參數 (from 波段目標價) ---
 NPattern_Length(60, "[N字]波段計算天期"),
 NPattern_Shoulder(3, "[N字]轉折點肩寬(根)"),
 
 // --- 模擬交易參數 ---
 Start_Mode(2, "[模擬]損益起算模式", inputkind:=Dict(["從資料開頭", 1], ["指定日期起", 2])),
 Sim_Start_Date(20230101, "[模擬]手動指定起算日");

// ---------- 資料筆數設定 ----------
SetBarBack(Support_Lookback_Days + 60, "D");
SetTotalBar(300);

// ---------- 頻率檢查 ----------
if BarFreq <> "D" then
begin // BE_FreqCheck
 RaiseRunTimeError("此策略 K 線頻率【必要】請務必使用「日線 (D)」!");
end; // BE_FreqCheck

// ---------- 宣告【一般】計算用變數 ----------
var:
 // --- 當日計算變數 ---
 bull_bear_line_today(0),
 atr_value_daily(0),
 Best_Support_Price(0),
 action_command(0),
 IsTooHigh(False),
 Optimized_Period(0),
 
 // --- V81.2 / V65 週期優化與排序 ---
 score_p1(0), score_p2(0), score_p3(0),
 bull_bear_line_p1(0), 
 bull_bear_line_p2(0), 
 bull_bear_line_p3(0), 
 
 // --- V46 支撐/壓力 變數 ---
 g_finalSupp1(0), // 支撐一
 g_finalRes1(0),  // 壓力一
 action_command_text(""),
 continuation_days(0),
 Bull_Signal_Price(0),
 Bear_Signal_Price(0),

 // --- N字波段 變數 ---
 A_Price(0), B_Price(0), C_Price(0),
 Target_100(0), Target_1618(0),
 _A_Bar(0), 

 // --- 開盤價ATR 優化變數 ---
 _optimized_tp_multiple(0),
 _optimized_sl_multiple(0),
 _take_profit_target(0), // T日計算的 "預估" 停利價
 _stop_loss_target(0),  // T日計算的 "預估" 停損價
 _tp_label_extra(""),
 _sl_label_extra(""),
 best_ps_score(0), // V79 最佳停利%損益
 Was_TP_Hit_Today(False), // 觸及獲利 (V2.8)
 
 // --- 迴圈與內部計算用 ---
 d_high(0), d_low(0), d_open(0), d_close(0), d_truerange(0),
 d_bull_bear_line(0), j_d(0),
 d_avg_a(0), d_avg_b(0), d_avg_c(0), d_avg_d(0),
 d_hit_a(false), d_hit_b(false), d_hit_c(false), d_hit_d(false),
 score_a_yesterday(0), score_b_yesterday(0), score_c_yesterday(0), score_d_yesterday(0),
 highest_score(0), best_avg_price_today(0),
 bull_bear_state_today(0), bull_bear_state_yesterday(0),
 i(0), highest_profit(-999999), best_period_found(20);

// ---------- 宣告【IntrabarPersist】模擬交易變數 ----------
variable:
 intrabarpersist sim_position(0),
 intrabarpersist sim_entry_price(0),
 intrabarpersist sim_tp_target(0),  // T+1 實際進場後設定的 "真實" 停利價
 intrabarpersist sim_sl_target(0),  // T+1 實際進場後設定的 "真實" 停損價
 intrabarpersist sim_cumulative_pl(0),
 intrabarpersist sim_current_pl(0),
 intrabarpersist entry_signal_today(false),
 intrabarpersist sim_active(false),
 intrabarpersist first_active_bar(true),
 intrabarpersist sim_entry_bar(0),    // K棒編號
 intrabarpersist last_trade_N(0),      // 上次持有天數
 intrabarpersist last_exit_type(""); // 上次出場類型

// ---------- 宣告計算用陣列 ----------
Array: d_Arr[8,1](0); // 支撐壓力候選陣列
Array: periods[3](0); // 週期優化用
Array: p_results[3](0); // 週期優化結果
Array: PerfData[3,3](0); // V81.2/V65 排序用 [i,1]:P&L, [i,2]:Period, [i,3]:多空價

// ========== 每日計算區塊 ==========

// --- 1. 取得日K資料 ---
d_high = High;
d_low = Low;
d_open = Open;
d_close = Close;
d_truerange = TrueRange;
atr_value_daily = Average(d_truerange, ATR_Period)[1];

// --- 2. 【V81.2 / V65 邏輯】優化並排序最佳趨勢週期 ---
periods[1] = Period1; periods[2] = Period2; periods[3] = Period3;
for i = 1 to 3 begin // BE_Opt_P
 p_results[i] = CallFunction("_SimulatePeriodPerformance", periods[i], Support_Lookback_Days, 1.05);
end; // BE_Opt_P

// 儲存 V81.2 的週期損益分數
score_p1 = p_results[1]; // 週期1損益 (輸出)
score_p2 = p_results[2]; // 週期2損益 (輸出)
score_p3 = p_results[3]; // 週期3損益 (輸出)

// 2.1 計算三個週期的多空價
bull_bear_line_p1 = (highest(d_high, Period1)[1] + lowest(d_low, Period1)[1]) / 2;
bull_bear_line_p2 = (highest(d_high, Period2)[1] + lowest(d_low, Period2)[1]) / 2;
bull_bear_line_p3 = (highest(d_high, Period3)[1] + lowest(d_low, Period3)[1]) / 2;

// 2.2 存入 PerfData 陣列 (V65 邏輯)
PerfData[1,1] = p_results[1]; PerfData[1,2] = Period1; PerfData[1,3] = bull_bear_line_p1;
PerfData[2,1] = p_results[2]; PerfData[2,2] = Period2; PerfData[2,3] = bull_bear_line_p2;
PerfData[3,1] = p_results[3]; PerfData[3,2] = Period3; PerfData[3,3] = bull_bear_line_p3;

// 2.3 排序 PerfData (Bubble Sort, 由大到小)
variable: temp_val1(0), temp_val2(0), temp_val3(0);
for i = 1 to 2 begin // BE_Sort_Perf
 for j_d = i + 1 to 3 begin // BE_Sort_Perf_Inner
  if PerfData[i,1] < PerfData[j_d,1] then begin // BE_Swap
   // 交換 P&L, Period, 多空價
   temp_val1 = PerfData[i,1]; temp_val2 = PerfData[i,2]; temp_val3 = PerfData[i,3];
   PerfData[i,1] = PerfData[j_d,1]; PerfData[i,2] = PerfData[j_d,2]; PerfData[i,3] = PerfData[j_d,3];
   PerfData[j_d,1] = temp_val1; PerfData[j_d,2] = temp_val2; PerfData[j_d,3] = temp_val3;
  end; // BE_Swap
 end; // BE_Sort_Perf_Inner
end; // BE_Sort_Perf

// 2.4 找出績效最好的 (V-Final 原有邏輯)
Optimized_Period = PerfData[1,2]; // 最佳多空線週期 (輸出)
bull_bear_line_today = PerfData[1,3]; // 最佳多空線價位 (輸出)

// --- 3. 計算今日的交易參考價位與指令 (所有價位皆根據 [1] (昨日) 資料計算) ---
// 判斷多空狀態
if d_close[1] > bull_bear_line_today then bull_bear_state_today = 1
else if d_close[1] < bull_bear_line_today then bull_bear_state_today = -1
else bull_bear_state_today = 0;

bull_bear_state_yesterday = bull_bear_state_today[1];

action_command = 0; // 初始化交易指令
if bull_bear_state_today = 1 and bull_bear_state_yesterday <= 0 then
 action_command = 2 // 轉多訊號
else if bull_bear_state_today = 1 and bull_bear_state_yesterday = 1 then
 action_command = 1 // 多方持續
else if bull_bear_state_today = -1 and bull_bear_state_yesterday >= 0 then
 action_command = -2 // 轉空訊號
else if bull_bear_state_today = -1 and bull_bear_state_yesterday = -1 then
 action_command = -1; // 空方持續

// --- 4. 計算 V46 趨勢持續天數與文字 ---
if action_command = 1 then begin
 if action_command[1] = 1 or action_command[1] = 2 then
  continuation_days = continuation_days[1] + 1
 else
  continuation_days = 1;
end
else if action_command = -1 then begin
 if action_command[1] = -1 or action_command[1] = -2 then
  continuation_days = continuation_days[1] + 1
 else
  continuation_days = 1;
end
else begin
 continuation_days = 0;
end;

if action_command = 2 then action_command_text = "轉多訊號"
else if action_command = 1 then action_command_text = Text("多方持續(", NumToStr(continuation_days, 0), "日)")
else if action_command = -2 then action_command_text = "轉空訊號"
else if action_command = -1 then action_command_text = Text("空方持續(", NumToStr(continuation_days, 0), "日)")
else action_command_text = "無指令";
// action_command_text 為 操作指令(文字) (輸出)

// --- 5. 計算 轉多/轉空 訊號價位 (V46) ---
Bull_Signal_Price = 0; // 預設為0
Bear_Signal_Price = 0; // 預設為0
if action_command = 2 then Bull_Signal_Price = low; // 轉多訊號價位 (輸出)
if action_command = -2 then Bear_Signal_Price = high; // 轉空訊號價位 (輸出)

// --- 6. 計算 支撐一 (S1) / 壓力一 (R1) (V46 / V90.5 邏輯) ---
d_Arr[1,1] = highest(d_high, 5)[1];
d_Arr[2,1] = highest(d_high, 10)[1];
d_Arr[3,1] = highest(d_high, 20)[1];
d_Arr[4,1] = lowest(d_low, 5)[1];
d_Arr[5,1] = lowest(d_low, 10)[1];
d_Arr[6,1] = lowest(d_low, 20)[1];
d_Arr[7,1] = average(d_close, 60)[1];
d_Arr[8,1] = GetField("控盤者成本線", "D", Default := 0)[1];

var: d_tmp_MinGtOpen(999999), d_tmp_MaxLtOpen(-999999);
d_tmp_MinGtOpen = highest(d_high, 300)[1] * 1.1;
d_tmp_MaxLtOpen = Lowest(d_low, 300)[1] * 0.9;
for j_d = 1 to 8 begin // BE_Find_RS1
 if d_Arr[j_d,1] > d_open[1] and d_Arr[j_d,1] < d_tmp_MinGtOpen then d_tmp_MinGtOpen = d_Arr[j_d,1];
 if d_Arr[j_d,1] < d_open[1] and d_Arr[j_d,1] > d_tmp_MaxLtOpen then d_tmp_MaxLtOpen = d_Arr[j_d,1];
end; // BE_Find_RS1

g_finalRes1 = addSpread(d_tmp_MinGtOpen, 0); // 壓力一價位 (輸出)
g_finalSupp1 = addSpread(d_tmp_MaxLtOpen, 0); // 支撐一價位 (輸出)

// --- 7. 計算 "最佳" 均價支撐 (V90.5 核心邏輯) ---
d_avg_a = (d_bull_bear_line + d_open[1]) / 2;
d_avg_b = (d_bull_bear_line + g_finalRes1) / 2;
d_avg_c = (d_open[1] + g_finalRes1) / 2;
d_avg_d = (d_bull_bear_line + d_open[1] + g_finalRes1) / 3;

d_hit_a = (d_low <= d_avg_a * (1 + Tolerance_Percent/100) and d_low >= d_avg_a * (1 - Tolerance_Percent/100));
d_hit_b = (d_low <= d_avg_b * (1 + Tolerance_Percent/100) and d_low >= d_avg_b * (1 - Tolerance_Percent/100));
d_hit_c = (d_low <= d_avg_c * (1 + Tolerance_Percent/100) and d_low >= d_avg_c * (1 - Tolerance_Percent/100));
d_hit_d = (d_low <= d_avg_d * (1 + Tolerance_Percent/100) and d_low >= d_avg_d * (1 - Tolerance_Percent/100));

score_a_yesterday = CountIf(d_hit_a, Support_Lookback_Days)[1];
score_b_yesterday = CountIf(d_hit_b, Support_Lookback_Days)[1];
score_c_yesterday = CountIf(d_hit_c, Support_Lookback_Days)[1];
score_d_yesterday = CountIf(d_hit_d, Support_Lookback_Days)[1];

highest_score = Maxlist(score_a_yesterday, score_b_yesterday, score_c_yesterday, score_d_yesterday);
best_avg_price_today = 0;
if highest_score > 0 then begin // BE_Find_Best_S
 if score_a_yesterday = highest_score then best_avg_price_today = d_avg_a
 else if score_b_yesterday = highest_score then best_avg_price_today = d_avg_b
 else if score_c_yesterday = highest_score then best_avg_price_today = d_avg_c
 else if score_d_yesterday = highest_score then best_avg_price_today = d_avg_d;
end; // BE_Find_Best_S

if best_avg_price_today > 0 then Best_Support_Price = best_avg_price_today
else if bull_bear_line_today > 0 then Best_Support_Price = bull_bear_line_today
else Best_Support_Price = d_open[1];
// Best_Support_Price 為 最佳支撐價 (輸出)

// --- 8. 【開盤價ATR 邏輯】優化最佳停利/停損倍數 ---
// 8.1 優化 停利 (TP)
var: loop_counter(1), current_tp_multiple(0);
Array: tp_results[](0);
current_tp_multiple = TP_Start;
highest_profit = -999999;
_optimized_tp_multiple = TP_Start; // 最佳停利倍數 (輸出)

while current_tp_multiple <= TP_End begin // BE_Opt_TP
 Array_SetMaxIndex(tp_results, loop_counter);
 tp_results[loop_counter] = CallFunction("_SimulateATR_V2", current_tp_multiple, 99.0, Support_Lookback_Days, ATR_Period);
 current_tp_multiple += TP_Step;
 loop_counter += 1;
end; // BE_Opt_TP
for loop_counter = 1 to Array_GetMaxIndex(tp_results) begin // BE_Find_Best_TP
 if tp_results[loop_counter] > highest_profit then begin
  highest_profit = tp_results[loop_counter];
  _optimized_tp_multiple = TP_Start + (loop_counter - 1) * TP_Step;
 end;
end; // BE_Find_Best_TP

// 8.2 優化 停損 (SL)
highest_profit = -999999; loop_counter = 1;
var: current_sl_multiple(0);
Array: sl_results[](0);
current_sl_multiple = SL_Start;
_optimized_sl_multiple = SL_Start; // 最佳停損倍數 (輸出)

while current_sl_multiple <= SL_End begin // BE_Opt_SL
 Array_SetMaxIndex(sl_results, loop_counter);
 sl_results[loop_counter] = CallFunction("_SimulateATR_V2", _optimized_tp_multiple, current_sl_multiple, Support_Lookback_Days, ATR_Period);
 current_sl_multiple += SL_Step;
 loop_counter += 1;
end; // BE_Opt_SL
for loop_counter = 1 to Array_GetMaxIndex(sl_results) begin // BE_Find_Best_SL
 if sl_results[loop_counter] > highest_profit then begin
  highest_profit = sl_results[loop_counter];
  _optimized_sl_multiple = SL_Start + (loop_counter - 1) * SL_Step;
 end;
end; // BE_Find_Best_SL

best_ps_score = highest_profit; // 最佳獲利%損益 (輸出)

// --- 9. 計算 T日 "預估" 價位 (供 Plot 顯示) ---
// (指標腳本在日K下, OpenD(0) == Open)
if atr_value_daily > 0 then begin // BE_Calc_Targets
 _take_profit_target = Open + (_optimized_tp_multiple * atr_value_daily); // 最佳停利價 (輸出)
 _stop_loss_target = Open - (_optimized_sl_multiple * atr_value_daily); // 最佳停損價 (輸出)
end; // BE_Calc_Targets

// 9.1 檢查漲跌停 (V2.8 邏輯)
var: _up_limit(0), _down_limit(0);
_up_limit = GetField("漲停價", "D");
_down_limit = GetField("跌停價", "D");
_tp_label_extra = ""; // 停利標籤註記 (輸出)
_sl_label_extra = ""; // 停損標籤註記 (輸出)

if _up_limit > 0 and _take_profit_target > _up_limit then
begin // BE_LimitTP
 var: _next_best_tp(0);
 _next_best_tp = _up_limit - (atr_value_daily * Limit_ATR_Ratio);
 _tp_label_extra = Text(" (今日佳:", NumToStr(_next_best_tp, 2), ")");
end; // BE_LimitTP

if _down_limit > 0 and _stop_loss_target < _down_limit then
begin // BE_LimitSL
 var: _next_best_sl(0);
 _next_best_sl = _down_limit + (atr_value_daily * Limit_ATR_Ratio);
 _sl_label_extra = Text(" (今日佳:", NumToStr(_next_best_sl, 2), ")");
end; // BE_LimitSL

// 9.2 檢查今日是否達標 (用於Plot)
Was_TP_Hit_Today = False;
if _take_profit_target > 0 and High >= _take_profit_target then
 Was_TP_Hit_Today = True; // 今日觸及獲利 (輸出)

// --- 10. 計算高價過濾 (V90.5) ---
Var: ShortMA_Value(0), RSI_Value(0);
ShortMA_Value = Average(Close, 5);
RSI_Value = RSI(Close, 14);
IsTooHigh = False;
if EnableHighFilter then begin // BE_HighFilter
 IsTooHigh = CallFunction("_CheckIfPriceTooHigh_V1",
  Close, High, ShortMA_Value, RSI_Value,
  FilterNearHigh, MaxDistPct, FilterMADev, MaxDevPct, FilterRSIOB, RSILimit
 );
end; // BE_HighFilter

// --- 11. 計算 N字波段目標價 (from 波段目標價) ---
var: _B_Price(0), _B_Bar(0), _C_Price(0), _C_Bar(0), Wave_1_Length(0);
_B_Price = SwingHigh(H, NPattern_Length, NPattern_Shoulder, NPattern_Shoulder, 1);
_B_Bar = SwingHighBar(H, NPattern_Length, NPattern_Shoulder, NPattern_Shoulder, 1);
_C_Price = SwingLow(L, NPattern_Length, NPattern_Shoulder, NPattern_Shoulder, 1);
_C_Bar = SwingLowBar(L, NPattern_Length, NPattern_Shoulder, NPattern_Shoulder, 1);

Target_100 = 0; // N字目標價 (輸出)
Target_1618 = 0; // 1.618目標價 (輸出)
A_Price = 0; B_Price = 0; C_Price = 0; // A, B, C 點 (輸出)

if _B_Bar > 0 and _C_Bar > 0 then begin // BE_N_Pattern
 if _B_Bar < _C_Bar then begin // B點 在 C點 之前 (A-B-C 漲多拉回) // BE_N_ABC
  A_Price = SwingLow(L, NPattern_Length, NPattern_Shoulder, NPattern_Shoulder, 2);
  _A_Bar = SwingLowBar(L, NPattern_Length, NPattern_Shoulder, NPattern_Shoulder, 2);
  if _A_Bar > _B_Bar then begin // 確認 A-B-C 順序 // BE_N_Confirm
   B_Price = _B_Price;
   C_Price = _C_Price;
   Wave_1_Length = B_Price - A_Price;
   if Wave_1_Length > 0 then begin // BE_N_Calc
    Target_100 = C_Price + Wave_1_Length;
    Target_1618 = C_Price + (Wave_1_Length * 1.618);
   end; // BE_N_Calc
  end; // BE_N_Confirm
 end; // BE_N_ABC
end; // BE_N_Pattern


// ========== 模擬交易邏輯 ==========

// --- 1. 計算進場條件 (V90.5) ---
var: Condition_Entry(False);
Condition_Entry = (
 IsTooHigh = False           // 1. 未觸發高價過濾
 and action_command = 1      // 2. 日K趨勢為「多方持續」
 and Close > bull_bear_line_today + (ATR_Confirmation_Ratio * atr_value_daily) // 3. 【關鍵】今日收盤價 需有效突破 (多空線 + ATR緩衝區)
 and Close > Best_Support_Price   // 4. 今日收盤價 同時也需高於今日計算出的最佳支撐價
);

entry_signal_today = Condition_Entry; // 儲存今日訊號 (T日)

// --- 2. 啟動模擬 ---
if sim_active = false then begin
  if (Start_Mode = 1 and CurrentBar > 1) or 
     (Start_Mode = 2 and Date >= Sim_Start_Date) then 
  begin
     sim_active = true;
  end;
end;

// --- 3. 執行模擬交易 (日K: T日訊號, T+1日動作) ---
if sim_active then
begin // BE_SIM_Main
    
    // 【*** 修正點 ***】 預設隱藏所有出場訊號
    NoPlot(104);
    NoPlot(105);
    NoPlot(106);
    
    // 3.0 初始化 (僅在模擬啟動後的第一根bar執行)
    if first_active_bar = true then
    begin // BE_SIM_Init
        sim_position = 0;
        sim_cumulative_pl = 0;
        first_active_bar = false;
        sim_current_pl = 0;
        last_trade_N = 0;
        last_exit_type = "Init";
    end; // BE_SIM_Init

    // 3.1 檢查出場 (T日 H/L 檢查 T-1 日設定的目標)
    if sim_position[1] = 1 then // 昨日持有多單
    begin // BE_SIM_CheckExit
        // 載入昨日的部位與目標
        sim_tp_target = sim_tp_target[1];
        sim_sl_target = sim_sl_target[1];
        sim_entry_price = sim_entry_price[1];
        sim_cumulative_pl = sim_cumulative_pl[1];
        sim_entry_bar = sim_entry_bar[1];
        last_trade_N = last_trade_N[1];
        last_exit_type = last_exit_type[1];
        sim_position = 1; // 預設為繼續持有

        if Low <= sim_sl_target then // 觸及停損
        begin // BE_SIM_SL
            Plot105(sim_sl_target, "停損出場(T+N)", checkbox:=1); // 標示在停損價位
            sim_position = 0;
            sim_cumulative_pl = sim_cumulative_pl + (sim_sl_target - sim_entry_price);
            sim_current_pl = 0;
            last_trade_N = CurrentBar - sim_entry_bar;
            last_exit_type = "SL";
        end // BE_SIM_SL
        else if High >= sim_tp_target then // 觸及停利
        begin // BE_SIM_TP
            Plot104(sim_tp_target, "停利出場(T+N)", checkbox:=1); // 標示在停利價位
            sim_position = 0;
            sim_cumulative_pl = sim_cumulative_pl + (sim_tp_target - sim_entry_price);
            sim_current_pl = 0;
            last_trade_N = CurrentBar - sim_entry_bar;
            last_exit_type = "TP";
        end; // BE_SIM_TP
        
        // 檢查V90.5的轉空訊號 (作為附加出場條件)
        if sim_position = 1 and action_command < 0 then
        begin // BE_SIM_TrendExit
            Plot106(Close, "趨勢轉空出場(T+N)", checkbox:=1); // 標示在收盤價
            sim_position = 0;
            sim_cumulative_pl = sim_cumulative_pl + (Close - sim_entry_price); // 假設收盤出場
            sim_current_pl = 0;
            last_trade_N = CurrentBar - sim_entry_bar;
            last_exit_type = "Trend";
        end; // BE_SIM_TrendExit

        if sim_position = 1 then // 若未出場
        begin
            sim_current_pl = Close - sim_entry_price; // 更新浮動損益
        end;

    end // BE_SIM_CheckExit
    
    // 3.2 檢查進場 (T日 Open 執行 T-1 日的訊號)
    else if entry_signal_today[1] = true then // 昨日有進場訊號
    begin // BE_SIM_Entry
        sim_position = 1;
        sim_entry_price = Open; // ** T+1 的 Open **
        sim_cumulative_pl = sim_cumulative_pl[1];
        sim_entry_bar = CurrentBar;
        last_trade_N = last_trade_N[1];
        last_exit_type = last_exit_type[1];
        
        // 【*** 核心修正點 ***】
        // 在 T+1 進場時，才使用 T 日算好的 ATR 和 "倍數" 來計算 "真實" 的出場價
        var: entry_atr_val(0);
        entry_atr_val = atr_value_daily[1]; // 取得T-1日計算的ATR (T日[1] = T-1日)
        
        if entry_atr_val = 0 then entry_atr_val = atr_value_daily[2]; // 往前找
        if entry_atr_val = 0 then entry_atr_val = Average(TrueRange, ATR_Period)[1]; // 最後防呆
        
        if entry_atr_val > 0 then
        begin // BE_Set_Targets_On_Entry
            sim_tp_target = sim_entry_price + (_optimized_tp_multiple[1] * entry_atr_val);
            sim_sl_target = sim_entry_price - (_optimized_sl_multiple[1] * entry_atr_val);
        end // BE_Set_Targets_On_Entry
        else // 萬一 ATR 仍為 0
        begin // BE_Set_Targets_Fallback
             sim_tp_target = sim_entry_price * (1 + (Profit_Target_Percent/100)); 
             sim_sl_target = sim_entry_price * (1 - (StopLoss_Fallback_Percent/100)); 
        end; // BE_Set_Targets_Fallback
        
        // 【*** 核心修正點 ***】
        // 漲跌停檢查也必須移到 T+1
        var: _up_limit_entry(0), _down_limit_entry(0);
        _up_limit_entry = GetField("漲停價", "D");
        _down_limit_entry = GetField("跌停價", "D");

        if _up_limit_entry > 0 and sim_tp_target > _up_limit_entry then
        begin // BE_LimitTP_Entry
            sim_tp_target = _up_limit_entry - (entry_atr_val * Limit_ATR_Ratio);
        end; // BE_LimitTP_Entry

        if _down_limit_entry > 0 and sim_sl_target < _down_limit_entry then
        begin // BE_LimitSL_Entry
            sim_sl_target = _down_limit_entry + (entry_atr_val * Limit_ATR_Ratio);
        end; // BE_LimitSL_Entry
        
        sim_current_pl = Close - sim_entry_price;
    end // BE_SIM_Entry
    
    // 3.3 空手
    else
    begin // BE_SIM_Idle
        sim_position = 0;
        sim_entry_price = 0;
        sim_tp_target = 0;
        sim_sl_target = 0;
        sim_cumulative_pl = sim_cumulative_pl[1];
        sim_current_pl = 0;
        last_trade_N = last_trade_N[1];
        last_exit_type = last_exit_type[1];
    end; // BE_SIM_Idle
end; // BE_SIM_Main


// ========== 繪圖區塊 (Plots) ==========

// --- 繪製主要訊號 (Main Chart Signals) ---
if entry_signal_today then 
    Plot100(Low * 0.98, "進場訊號(T)", checkbox:=1) // 進場訊號 (當日收盤)
else
    NoPlot(100);

if Was_TP_Hit_Today then
    Plot101(High * 1.02, "今日觸及(預估停利)", checkbox:=1) // 盤中觸及(非出場)
else
    NoPlot(101);
 
if Bull_Signal_Price > 0 then
    Plot102(Bull_Signal_Price * 0.99, "轉多訊號", checkbox:=0) // 轉多訊號價位
else
    NoPlot(102);

if Bear_Signal_Price > 0 then
    Plot103(Bear_Signal_Price * 1.01, "轉空訊號", checkbox:=0) // 轉空訊號價位
else
    NoPlot(103);

// 模擬出場訊號 (在 BE_SIM_CheckExit 中繪製)
Plot104(0, "停利出場(T+N)", checkbox:=1);
NoPlot(104);
Plot105(0, "停損出場(T+N)", checkbox:=1);
NoPlot(105);
Plot106(0, "趨勢轉空出場(T+N)", checkbox:=1);
NoPlot(106);

// --- 繪製關鍵價位 (Main Chart Lines) ---
Plot6(bull_bear_line_today, "最佳多空線價位", checkbox:=1);
Plot4(Best_Support_Price, "最佳支撐價", checkbox:=1);

// 【*** 修正點 ***】 繪製T日 "預估" 價位 (標籤用)
Plot2(_take_profit_target, "最佳停利價(預估)", checkbox:=1);
Plot3(_stop_loss_target, "最佳停損價(預估)", checkbox:=1);

// 【*** 新增 ***】 繪製T+1 "實際" 停損利 (持倉時)
if sim_position = 1 then 
begin
    Plot300(sim_tp_target, "持倉停利價", checkbox:=1);
    Plot301(sim_sl_target, "持倉停損價", checkbox:=1);
end
else
begin
    NoPlot(300);
    NoPlot(301);
end;


Plot7(g_finalRes1, "壓力一價位", checkbox:=0);
Plot8(g_finalSupp1, "支撐一價位", checkbox:=0);
Plot11(Target_100, "N字目標價", checkbox:=0);
Plot12(Target_1618, "1.618目標價", checkbox:=0);
Plot13(A_Price, "N字_A起漲低點", checkbox:=0);
Plot14(B_Price, "N字_B轉折高點", checkbox:=0);
Plot15(C_Price, "N字_C拉回低點", checkbox:=0);

// --- 繪製次要價位 (Main Chart Lines, 來自 V65 排序) ---
Plot29(PerfData[2,3], "排名2_多空價", checkbox:=0);
Plot32(PerfData[3,3], "排名3_多空價", checkbox:=0);

// --- 繪製數據指標 (Sub-Chart) ---
Plot18(action_command, "操作指令(代碼)", checkbox:=1);
Plot23(best_ps_score, "最佳停利%損益", checkbox:=1);
Plot24(score_p1, "週期1損益", checkbox:=1);
Plot25(score_p2, "週期2損益", checkbox:=1);
Plot26(score_p3, "週期3損益", checkbox:=1);
Plot30(PerfData[2,1], "排名2_損益", checkbox:=0);
Plot33(PerfData[3,1], "排名3_損益", checkbox:=0);
Plot5(Optimized_Period, "最佳多空線週期", checkbox:=0);
Plot28(PerfData[2,2], "排名2_週期", checkbox:=0);
Plot31(PerfData[3,2], "排名3_週期", checkbox:=0);
Plot16(_optimized_tp_multiple, "最佳停利倍數", checkbox:=0);
Plot17(_optimized_sl_multiple, "最佳停損倍數", checkbox:=0);

// --- 繪製模擬損益曲線 ---
if sim_active then
    Plot200(sim_cumulative_pl + sim_current_pl, "模擬總損益", checkbox:=1)
else
    NoPlot(200);

Plot202(0, "上次出場N值", checkbox:=1); // 佔位
if last_exit_type <> "Init" and last_exit_type <> "" then
    Plot202(last_trade_N, "上次出場N值", checkbox:=1)
else
    NoPlot(202);

// 繪製K棒 (確保在主圖)
plotk(201,open,high,low,close, "K棒", checkbox:=1);

// ========== 設定動態標籤 (SetPlotLabel) ==========
// 【*** 核心修正點：補上所有分號 ***】

// --- V65/V81.2 績效排名標籤 (用於副圖) ---
SetPlotLabel(6, Text("@多空線(", NumToStr(Optimized_Period, 0), "): ", NumToStr(bull_bear_line_today, 2))); 
SetPlotLabel(24, Text("週期 ", NumToStr(Period1,0), " (", NumToStr(bull_bear_line_p1, 2), ") 損益: ")); 
SetPlotLabel(25, Text("週期 ", NumToStr(Period2,0), " (", NumToStr(bull_bear_line_p2, 2), ") 損益: ")); 
SetPlotLabel(26, Text("週期 ", NumToStr(Period3,0), " (", NumToStr(bull_bear_line_p3, 2), ") 損益: ")); 
SetPlotLabel(29, Text("排名2_多空價(", NumToStr(PerfData[2,2], 0), "): ", NumToStr(PerfData[2,3], 2)));
SetPlotLabel(32, Text("排名3_多空價(", NumToStr(PerfData[3,2], 0), "): ", NumToStr(PerfData[3,3], 2)));
SetPlotLabel(30, "排名2_損益");
SetPlotLabel(33, "排名3_損益");
SetPlotLabel(28, "排名2_週期");
SetPlotLabel(31, "排名3_週期");

// --- V90.5 / V81.2 支撐標籤 ---
SetPlotLabel(4, Text("@最佳支撐: ", NumToStr(Best_Support_Price, 2)));
SetPlotLabel(7, Text("壓力一: ", NumToStr(g_finalRes1, 2)));
SetPlotLabel(8, Text("支撐一: ", NumToStr(g_finalSupp1, 2)));

// --- V46 操作指令標籤 ---
SetPlotLabel(18, Text("@操作指令: ", action_command_text));

// --- 開盤價ATR 標籤 ---
SetPlotLabel(2, Text("@最佳獲利目標(", NumToStr(_optimized_tp_multiple, 1), "倍): ", NumToStr(_take_profit_target, 2), _tp_label_extra));
SetPlotLabel(3, Text("最佳停損目標(", NumToStr(_optimized_sl_multiple, 1), "倍): ", NumToStr(_stop_loss_target, 2), _sl_label_extra));
SetPlotLabel(23, Text("最佳停利%損益: ", NumToStr(best_ps_score, 2)));

// --- N字波段 標籤 ---
SetPlotLabel(11, "N字(100%)目標價");
SetPlotLabel(12, "Fib(1.618%)目標價");
SetPlotLabel(13, "N字_A起漲低點");
SetPlotLabel(14, "N字_B轉折高點");
SetPlotLabel(15, "N字_C拉回低點");

// --- 訊號 標籤 ---
SetPlotLabel(100, "進場訊號(T)");
SetPlotLabel(101, "今日觸及(預估停利)");
SetPlotLabel(102, "轉多訊號");
SetPlotLabel(103, "轉空訊號");
SetPlotLabel(104, "停利出場(T+N)");
SetPlotLabel(105, "停損出場(T+N)");
SetPlotLabel(106, "趨勢轉空出場(T+N)");

// --- 模擬交易 標籤 ---
if sim_position = 1 then
begin
    SetPlotLabel(200, Text("模擬總損益(持倉): ", NumToStr(sim_cumulative_pl + sim_current_pl, 2), " [進場價: ", NumToStr(sim_entry_price, 2), "]"));
    SetPlotLabel(300, Text("持倉停利價: ", NumToStr(sim_tp_target, 2)));
    SetPlotLabel(301, Text("持倉停損價: ", NumToStr(sim_sl_target, 2)));
end
else
begin
    SetPlotLabel(200, Text("模擬總損益(空手): ", NumToStr(sim_cumulative_pl + sim_current_pl, 2)));
    SetPlotLabel(300, "持倉停利價");
    SetPlotLabel(301, "持倉停損價");
end;

SetPlotLabel(202, Text("上次出場N=", NumToStr(last_trade_N,0), " (", last_exit_type, ")")); 
SetPlotLabel(201, "K棒");
