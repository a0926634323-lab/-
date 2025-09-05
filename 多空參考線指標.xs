// XQ (XS) Indicator Script
// 腳本名稱：多空參考線指標 (Multi_SR_Levels_Indicator)
// 版本：UserConfirmed_Plot_CurrentBar_Fix_V4 (S/R計算排除當日OHL)
// 日期：2025-05-25
// 腳本說明：此指標計算並繪製多種基於不同邏輯的支撐與壓力參考價位。
//           所有參考價位(含今日OHL)參與排序並可選擇繪製。
//           最終篩選出的「壓力一/二」與「支撐一/二」則會排除今日OHL作為候選。

//SetTotalBar(450); // 設定腳本計算的總K棒數為450根(此行為註解，目前無作用)

// ------ 腳本輸入參數定義 ------
input:
    Inp_OCASource(open, "ATR壓力參考基準價"),     // 輸入參數：ATR壓力計算的基準價格，預設為開盤價
    Inp_Na_Offset(0, "ATR壓力參考價期數"),       // 輸入參數：ATR壓力基準價格的期數偏移，預設為當期
    Inp_OCBSource(open, "ATR支撐參考基準價"),     // 輸入參數：ATR支撐計算的基準價格，預設為開盤價
    Inp_Nb_Offset(0, "ATR支撐參考價期數"),       // 輸入參數：ATR支撐基準價格的期數偏移，預設為當期
    Inp_LD_Period(75,"N期低點參考期數(標籤用)"), // 輸入參數：用於標籤顯示的N期低點計算週期，預設75期
    Inp_HD_Period(75,"N期高點參考期數(標籤用)"), // 輸入參數：用於標籤顯示的N期高點計算週期，預設75期
    Inp_ATRPeriod(6, "ATR計算週期"),       // 輸入參數：計算ATR指標的週期，預設6期
    Inp_ATRHFactor(6, "ATR壓力通道因子"),     // 輸入參數：計算ATR壓力通道的因子，預設值6
    Inp_ATRLFactor(6, "ATR支撐通道因子");     // 輸入參數：計算ATR支撐通道的因子，預設值6

// ------ 全域/持續性變數宣告 ------
Vars: 
    intrabarpersist g_maxLtOpen_S1(-999999),   // 宣告持續性變數：小於開盤價的最大支撐價位一，初始值為-999999
    intrabarpersist g_minGtOpen_R1(999999),   // 宣告持續性變數：大於開盤價的最小壓力價位一，初始值為999999
    intrabarpersist g_finalSupp1(0),                 // 宣告持續性變數：最終支撐價位一，初始值為0
    intrabarpersist g_finalRes1(0),                 // 宣告持續性變數：最終壓力價位一，初始值為0
    intrabarpersist g_finalSupp2(0),                 // 宣告持續性變數：最終支撐價位二，初始值為0
    intrabarpersist g_finalRes2(0), // 宣告持續性變數：最終壓力價位二，初始值為0
	intrabarpersist timeFT(false), // 宣告持續性變數：用於標記時間是否首次觸發，初始為false
	intrabarpersist time1(0); //壓力觸發時間                 // 宣告持續性變數：用於記錄壓力觸發的時間，初始值為0

// ------ 局部變數宣告 ------
Var: 
    i(0), j(0),                                 // 宣告局部變數 i, j 作為迴圈計數器，初始值為0
    idx_EmaGoldX(0),                           // 宣告局部變數：EMA黃金交叉點的K棒索引位置，初始值為0
    val_LowAtEmaGoldX(0),                       // 宣告局部變數：EMA黃金交叉點當根K棒的最低價，初始值為0
    idx_EmaDeathX(0),                           // 宣告局部變數：EMA死亡交叉點的K棒索引位置，初始值為0
    val_HighAtEmaDeathX(0),                     // 宣告局部變數：EMA死亡交叉點當根K棒的最高價，初始值為0
    factor_AtrDynamicSell(0.5),                 // 宣告局部變數：動態ATR賣出因子，初始值為0.5
    factor_AtrDynamicBuy(0.5),                 // 宣告局部變數：動態ATR買進因子，初始值為0.5
    val_OverallHigh300(0),                     // 宣告局部變數：近300期最高價，初始值為0
    val_OverallLow300(0),                       // 宣告局部變數：近300期最低價，初始值為0
    tmp_MinGtOpen_R1_current(999999),           // 宣告局部變數：暫存當前大於開盤價的最小壓力價位一，初始值為999999
    tmp_MaxLtOpen_S1_current(-999999),         // 宣告局部變數：暫存當前小於開盤價的最大支撐價位一，初始值為-999999
    tmp_MinGtOpen_R2_current(9999999),         // 宣告局部變數：暫存當前大於開盤價的次小壓力價位二，初始值為9999999
    tmp_MaxLtOpen_S2_current(-9999999),         // 宣告局部變數：暫存當前小於開盤價的次大支撐價位二，初始值為-9999999
    val_ATR_SellLevel(0),                       // 宣告局部變數：基於ATR計算的賣出壓力價位，初始值為0
    val_ATR_BuyLevel(0),                       // 宣告局部變數：基於ATR計算的買進支撐價位，初始值為0
    isHitResistance(false),                     // 宣告局部變數：是否觸碰到壓力的旗標，初始為false
    isHitSupport(false),                       // 宣告局部變數：是否觸碰到支撐的旗標，初始為false
    val_Plot30(0), val_Plot31(0), val_Plot32(0), val_Plot33(0); // 宣告局部變數：用於繪製最終支撐壓力線的數值，初始值為0

// ------ 計算 EMA(12/26) 交叉點相關的歷史支撐壓力參考 ------
idx_EmaGoldX = barslast(ema(close,12) cross over ema(close,26)); // 計算距離上次12期EMA向上穿越26期EMA（黃金交叉）的K棒數
if CurrentBar > idx_EmaGoldX then val_LowAtEmaGoldX = low[idx_EmaGoldX]; // 如果黃金交叉發生過，取得該根K棒的最低價

idx_EmaDeathX = barslast(ema(close,12) cross under ema(close,26)); // 計算距離上次12期EMA向下穿越26期EMA（死亡交叉）的K棒數
if CurrentBar > idx_EmaDeathX then val_HighAtEmaDeathX = high[idx_EmaDeathX]; // 如果死亡交叉發生過，取得該根K棒的最高價

// ------ 計算 ATR 動態通道的乘數因子 ------
if opend(0) > closeD(1) then factor_AtrDynamicSell = 0.6 else factor_AtrDynamicSell = 0.5; // 如果今日開盤價大於昨日收盤價，設定ATR賣出因子為0.6，否則為0.5
if opend(0) < closeD(1) then factor_AtrDynamicBuy = 0.6 else factor_AtrDynamicBuy = 0.5; // 如果今日開盤價小於昨日收盤價，設定ATR買進因子為0.6，否則為0.5

// ------ 計算基於ATR的動態壓力/支撐參考價 (用於Plot3 和 Plot4) ------
val_ATR_SellLevel = addSpread(Inp_OCASource[Inp_Na_Offset] + atr(Inp_ATRPeriod) / Inp_ATRHFactor, 0); // 計算ATR壓力價位 = 基準價 + ATR值 / 壓力因子，並對齊到最小跳動點
val_ATR_BuyLevel = addSpread(Inp_OCBSource[Inp_Nb_Offset] - atr(Inp_ATRPeriod) / Inp_ATRLFactor, 0); // 計算ATR支撐價位 = 基準價 - ATR值 / 支撐因子，並對齊到最小跳動點

// ------ 準備儲存各種參考價位的陣列 ------
Array: Arr[23,2](0);   // 宣告一個23列2欄的二維陣列Arr，用來儲存參考價位及其原始ID，初始值為0
Array: strArr[23](""); // 宣告一個包含23個元素的字串陣列strArr，用來儲存價位的文字標籤，初始值為空字串


// ------ 填充陣列：計算各種指標價位 ------
Arr[1,1] = close[4];  //扣收日價位                         // 將4期前的收盤價存入陣列 (作為扣抵價參考)
Arr[2,1] = close[9];                         // 將9期前的收盤價存入陣列 (作為扣抵價參考)
Arr[3,1] = close[19];                         // 將19期前的收盤價存入陣列 (作為扣抵價參考)
Arr[4,1] = highest(High, 5)[1]; //前N期最高價                       // 將前5期的最高價存入陣列
Arr[5,1] = highest(High, 10)[1];               // 將前10期的最高價存入陣列
Arr[6,1] = Highest(High, 25)[1];               // 將前25期的最高價存入陣列
Arr[7,1] = val_LowAtEmaGoldX;   //前次12/26EMA金叉低               // 將前次EMA黃金交叉時的最低價存入陣列
Arr[8,1] = highest(High, 300)[1];             // 將前300期的最高價存入陣列
Arr[9,1] = lowest(Low, 5)[1];                 // 將前5期的最低價存入陣列
Arr[10,1] = round(High, 2);                    // ID 10: 今日最高價 // 將今日最高價(四捨五入至小數點後兩位)存入陣列，ID為10
Arr[11,1] = round(open, 2);                    // ID 11: 今日開盤價 // 將今日開盤價(四捨五入至小數點後兩位)存入陣列，ID為11
Arr[12,1] = round(low, 2);                     // ID 12: 今日最低價 // 將今日最低價(四捨五入至小數點後兩位)存入陣列，ID為12
Arr[13,1] = lowest(Low, 25)[1];               // 將前25期的最低價存入陣列
Arr[14,1] = val_HighAtEmaDeathX;    //前次12/26EMA死叉低           // 將前次EMA死亡交叉時的最高價存入陣列
Arr[15,1] = lowest(Low, 300)[1];               // 將前300期的最低價存入陣列
Arr[16,1] = open + atr(3) * factor_AtrDynamicSell; //開盤+動態ATR壓力 // 將開盤價加上動態ATR計算出的壓力價位存入陣列
Arr[17,1] = open - atr(3) * factor_AtrDynamicBuy;  //開盤-動態ATR壓力 // 將開盤價減去動態ATR計算出的支撐價位存入陣列
Arr[18,1] = close[59]; //扣收日價位                       // 將59期前的收盤價存入陣列 (作為扣抵價參考)
Arr[19,1] = close[119];                       // 將119期前的收盤價存入陣列 (作為扣抵價參考)
if CurrentBar >= 1 then                         // 如果是第一根K棒或之後
 Arr[20,1] = GetField("控盤者成本線", Default := 0)[1] // 取得前一日的「控盤者成本線」欄位值，若無資料則為0
else // 否則
    Arr[20,1] =  GetField("控盤者成本線", Default := 0);         // (此行邏輯上在CurrentBar < 1時執行，實際上不會發生) 取得當日的「控盤者成本線」
Arr[21,1] = lowest(Low, 60)[1];               // 將前60期的最低價存入陣列
Arr[22,1] = highest(High, 60)[1];             // 將前60期的最高價存入陣列
Arr[23,1] = average(Close, 60)[1];             // 將前60期的收盤價平均值存入陣列


for i = 1 to 23 begin Arr[i,2] = i; end; // 迴圈：將原始索引(1到23)存入陣列的第二欄，作為排序前的ID
array_sort2d(Arr, 1, 23, 1, false);      // 將整個二維陣列Arr，從第1列到第23列，依照第1欄(價位)進行降冪排序(由大到小)

// ------ 準備排序後價位對應的「文字標籤」 ------
for i = 1 to 23 begin // 迴圈：遍歷排序後的陣列
    switch (Arr[i, 2]) begin // 根據其原始ID(Arr[i,2])，賦予對應的文字標籤
        case 1: strArr[i] = "5期前扣收";    case 2: strArr[i] = "10期前扣收"; // 案例1：ID為1時，標籤為"5期前扣收"；案例2：ID為2時，標籤為"10期前扣收"
        case 3: strArr[i] = "20期前扣收";   case 4: strArr[i] = "前5期高點"; // 案例3：ID為3時，標籤為"20期前扣收"；案例4：ID為4時，標籤為"前5期高點"
        case 5: strArr[i] = "前10期高點";   case 6: strArr[i] = "前25期高點"; // 案例5：ID為5時，標籤為"前10期高點"；案例6：ID為6時，標籤為"前25期高點"
        case 7: strArr[i] = "前次12/26EMA金叉低"; case 8: strArr[i] = "前300期高點"; // 案例7：ID為7時，標籤為"前次12/26EMA金叉低"；案例8：ID為8時，標籤為"前300期高點"
        case 9: strArr[i] = "前5期低點";   case 10: strArr[i] = "今日最高";     // 案例9：ID為9時，標籤為"前5期低點"；案例10：ID為10時，標籤為"今日最高"
        case 11: strArr[i] = "今日開盤";   case 12: strArr[i] = "今日最低";     // 案例11：ID為11時，標籤為"今日開盤"；案例12：ID為12時，標籤為"今日最低"
        case 13: strArr[i] = "前25期低點"; case 14: strArr[i] = "前次12/26EMA死叉高"; // 案例13：ID為13時，標籤為"前25期低點"；案例14：ID為14時，標籤為"前次12/26EMA死叉高"
        case 15: strArr[i] = "前300期低點";case 16: strArr[i] = "開盤+動態ATR壓力"; // 案例15：ID為15時，標籤為"前300期低點"；案例16：ID為16時，標籤為"開盤+動態ATR壓力"
        case 17: strArr[i] = "開盤-動態ATR支撐";case 18: strArr[i] = "60期前扣收";   // 案例17：ID為17時，標籤為"開盤-動態ATR支撐"；案例18：ID為18時，標籤為"60期前扣收"
        case 19: strArr[i] = "120期前扣收";case 20: strArr[i] = "控盤線(前一日)"; // 案例19：ID為19時，標籤為"120期前扣收"；案例20：ID為20時，標籤為"控盤線(前一日)"
        case 21: strArr[i] = "前60期低點"; case 22: strArr[i] = "前60期高點";   // 案例21：ID為21時，標籤為"前60期低點"；案例22：ID為22時，標籤為"前60期高點"
        case 23: strArr[i] = "前60期均線"; default: strArr[i] = "未定義ID"+NumToStr(Arr[i,2],0); // 案例23：ID為23時，標籤為"前60期均線"；預設情況：標籤為"未定義ID"加上其ID
    end;
end;

// ------ 繪製排序後的23條水平線及其標籤 ------
Plot(1, Arr[1,1], checkbox := 0); SetPlotLabel(1, strArr[1]); // 繪製第1條線：價位為排序後的第一個價位，預設不顯示，並設定其標籤
Plot(2, Arr[2,1], checkbox := 0); SetPlotLabel(2, strArr[2]); // 繪製第2條線：價位為排序後的第二個價位，預設不顯示，並設定其標籤
Plot(43, val_ATR_SellLevel, checkbox := 0); // 繪製第43條線：價位為ATR壓力參考價，預設不顯示
    if Inp_OCASource = open then SetPlotLabel(43, text("開盤+ATR(", NumToStr(Inp_ATRPeriod,0), "/", NumToStr(Inp_ATRHFactor,1), ")")) // 如果基準價是開盤價，設定對應的標籤
    else if Inp_OCASource = close then SetPlotLabel(43, text("收盤+ATR(", NumToStr(Inp_ATRPeriod,0), "/", NumToStr(Inp_ATRHFactor,1), ")")) // 如果基準價是收盤價，設定對應的標籤
    else SetPlotLabel(43, "ATR壓力參考"); // 否則使用通用標籤
Plot(44, val_ATR_BuyLevel, checkbox := 0); // 繪製第44條線：價位為ATR支撐參考價，預設不顯示
    if Inp_OCBSource = open then SetPlotLabel(44, text("開盤-ATR(", NumToStr(Inp_ATRPeriod,0), "/", NumToStr(Inp_ATRLFactor,1), ")")) // 如果基準價是開盤價，設定對應的標籤
    else if Inp_OCBSource = close then SetPlotLabel(44, text("收盤-ATR(", NumToStr(Inp_ATRPeriod,0), "/", NumToStr(Inp_ATRLFactor,1), ")")) // 如果基準價是收盤價，設定對應的標籤
    else SetPlotLabel(44, "ATR支撐參考"); // 否則使用通用標籤
Plot(3, Arr[3,1], checkbox := 0); SetPlotLabel(3, strArr[3]); // 繪製第3條線，並設定標籤
Plot(4, Arr[4,1], checkbox := 0); SetPlotLabel(4, strArr[4]); // 繪製第4條線，並設定標籤
Plot(5, Arr[5,1], checkbox := 0); SetPlotLabel(5, strArr[5]); // 繪製第5條線，並設定標籤
Plot(6, Arr[6,1], checkbox := 0); SetPlotLabel(6, strArr[6]); // 繪製第6條線，並設定標籤
Plot(7, Arr[7,1], checkbox := 0); SetPlotLabel(7, strArr[7]); // 繪製第7條線，並設定標籤
Plot(8, Arr[8,1], checkbox := 0); SetPlotLabel(8, strArr[8]); // 繪製第8條線，並設定標籤
Plot(9, Arr[9,1], checkbox := 0); SetPlotLabel(9, strArr[9]); // 繪製第9條線，並設定標籤
Plot(10, Arr[10,1], checkbox := 1); SetPlotLabel(10, strArr[10]); // 繪製第10條線(今日最高)，預設顯示，並設定標籤
Plot(11, Arr[11,1], checkbox := 0); SetPlotLabel(11, TEXT(strArr[11]," --中線--")); // 繪製第11條線(今日開盤)，預設不顯示，並設定標籤為 "今日開盤 --中線--"
Plot(12, Arr[12,1], checkbox := 0); SetPlotLabel(12, strArr[12]); // 繪製第12條線(今日最低)，預設不顯示，並設定標籤
Plot(13, Arr[13,1], checkbox := 0); SetPlotLabel(13, strArr[13]); // 繪製第13條線，並設定標籤
Plot(14, Arr[14,1], checkbox := 0); SetPlotLabel(14, strArr[14]); // 繪製第14條線，並設定標籤
Plot(15, Arr[15,1], checkbox := 0); SetPlotLabel(15, strArr[15]); // 繪製第15條線，並設定標籤
Plot(16, Arr[16,1], checkbox := 0); SetPlotLabel(16, strArr[16]); // 繪製第16條線，並設定標籤
Plot(17, Arr[17,1], checkbox := 0); SetPlotLabel(17, strArr[17]); // 繪製第17條線，並設定標籤
Plot(18, Arr[18,1], checkbox := 0); SetPlotLabel(18, strArr[18]); // 繪製第18條線，並設定標籤
Plot(19, Arr[19,1], checkbox := 0); SetPlotLabel(19, strArr[19]); // 繪製第19條線，並設定標籤
Plot(20, Arr[20,1], checkbox := 0); SetPlotLabel(20, strArr[20]); // 繪製第20條線，並設定標籤
Plot(21, Arr[21,1], checkbox := 0); SetPlotLabel(21, strArr[21]); // 繪製第21條線，並設定標籤
Plot(22, Arr[22,1], checkbox := 0); SetPlotLabel(22, strArr[22]); // 繪製第22條線，並設定標籤
Plot(23, Arr[23,1], checkbox := 0); SetPlotLabel(23, strArr[23]); // 繪製第23條線，並設定標籤

// ------ 初始化用於尋找S/R的極端參考值 ------
val_OverallHigh300 = highest(High, 300); // 取得近300期的最高價作為計算邊界的參考
val_OverallLow300 = Lowest(Low, 300);   // 取得近300期的最低價作為計算邊界的參考

tmp_MinGtOpen_R1_current = val_OverallHigh300 * 1.1;   // 初始化尋找壓力一的暫存變數，設定一個極大的初始值
tmp_MaxLtOpen_S1_current = val_OverallLow300 * 0.9;     // 初始化尋找支撐一的暫存變數，設定一個極小的初始值
tmp_MinGtOpen_R2_current = val_OverallHigh300 * 1.2;   // 初始化尋找壓力二的暫存變數，設定一個更大的初始值
tmp_MaxLtOpen_S2_current = val_OverallLow300 * 0.8;     // 初始化尋找支撐二的暫存變數，設定一個更小的初始值

// ------ 從排序後的價位陣列中，找出最接近開盤價的兩檔支撐與兩檔壓力 ------
// **此處邏輯已修改：在挑選S/R時，排除今日的開盤價、最高價、最低價**
for i = 1 to 23 begin // 迴圈：遍歷所有排序後的參考價位
    // 檢查當前遍歷到的 Arr[i,1] 是否為今日開盤(ID=11)、最高(ID=10)或最低(ID=12)
    // 如果是，則不將其作為計算S/R的候選
    if not (Arr[i,2] = 10 or Arr[i,2] = 11 or Arr[i,2] = 12) then begin // 如果當前價位的原始ID不是今日最高(10)、開盤(11)或最低(12)
        // 尋找大於開盤價的最小壓力值(R1)和次小壓力值(R2)
        if Arr[i,1] > addSpread(opend(0), 0) then begin // 如果價位大於今日開盤價(已對齊跳動點)，則其為壓力候選
            if Arr[i,1] < tmp_MinGtOpen_R1_current then begin // 如果此壓力候選價位比當前找到的壓力一(R1)還小（更接近開盤價）
                tmp_MinGtOpen_R2_current = tmp_MinGtOpen_R1_current; // 則把原本的壓力一(R1)移到壓力二(R2)
                tmp_MinGtOpen_R1_current = Arr[i,1];                 // 並將此價位設為新的壓力一(R1)
            end else if Arr[i,1] < tmp_MinGtOpen_R2_current and Arr[i,1] <> tmp_MinGtOpen_R1_current then begin // 否則，如果此價位小於壓力二(R2)且不等於壓力一(R1)
                tmp_MinGtOpen_R2_current = Arr[i,1]; // 則將此價位設為新的壓力二(R2)
            end;
        end;
        
        // 尋找小於開盤價的最大支撐值(S1)和次大支撐值(S2)
        if Arr[i,1] < addSpread(opend(0), 0) then begin // 如果價位小於今日開盤價(已對齊跳動點)，則其為支撐候選
            if Arr[i,1] > tmp_MaxLtOpen_S1_current then begin // 如果此支撐候選價位比當前找到的支撐一(S1)還大（更接近開盤價）
                tmp_MaxLtOpen_S2_current = tmp_MaxLtOpen_S1_current; // 則把原本的支撐一(S1)移到支撐二(S2)
                tmp_MaxLtOpen_S1_current = Arr[i,1];               // 並將此價位設為新的支撐一(S1)
            end else if Arr[i,1] > tmp_MaxLtOpen_S2_current and Arr[i,1] <> tmp_MaxLtOpen_S1_current then begin // 否則，如果此價位大於支撐二(S2)且不等於支撐一(S1)
                tmp_MaxLtOpen_S2_current = Arr[i,1]; // 則將此價位設為新的支撐二(S2)
            end;
        end;
    end; 
end;

g_finalRes1 = tmp_MinGtOpen_R1_current;       // 將找到的壓力一存入全域變數
g_finalRes2 = tmp_MinGtOpen_R2_current;       // 將找到的壓力二存入全域變數
g_finalSupp1 = tmp_MaxLtOpen_S1_current;     // 將找到的支撐一存入全域變數
g_finalSupp2 = tmp_MaxLtOpen_S2_current;     // 將找到的支撐二存入全域變數

// ------ 繪製最終篩選出的支撐與壓力線 (Plot30-33) ------
val_Plot30 = addSpread(g_finalRes1, 0); // 將最終壓力一的價位對齊到最小跳動點
val_Plot31 = addSpread(g_finalSupp1, 0); // 將最終支撐一的價位對齊到最小跳動點
val_Plot32 = addSpread(g_finalRes2, 0); // 將最終壓力二的價位對齊到最小跳動點
val_Plot33 = addSpread(g_finalSupp2, 0); // 將最終支撐二的價位對齊到最小跳動點

if g_finalRes1 < val_OverallHigh300 * 1.09 then Plot(30, val_Plot30, checkbox := 1) else NoPlot(30); // 如果壓力一價位在合理範圍內，則繪製Plot30，預設顯示
SetPlotLabel(30, "壓力一"); // 設定Plot30的標籤為"壓力一"
if g_finalRes2 < val_OverallHigh300 * 1.19 and g_finalRes2 <> g_finalRes1 then Plot(32, val_Plot32, checkbox := 1) else NoPlot(32); // 如果壓力二價位在合理範圍內且不等於壓力一，則繪製Plot32，預設顯示
SetPlotLabel(32, "壓力二"); // 設定Plot32的標籤為"壓力二"
if g_finalSupp1 > val_OverallLow300 * 0.91 then Plot(31, val_Plot31, checkbox := 1) else NoPlot(31); // 如果支撐一價位在合理範圍內，則繪製Plot31，預設顯示
SetPlotLabel(31, "支撐一"); // 設定Plot31的標籤為"支撐一"
if g_finalSupp2 > val_OverallLow300 * 0.81 and g_finalSupp2 <> g_finalSupp1 then Plot(33, val_Plot33, checkbox := 1) else NoPlot(33); // 如果支撐二價位在合理範圍內且不等於支撐一，則繪製Plot33，預設顯示
SetPlotLabel(33, "支撐二"); // 設定Plot33的標籤為"支撐二"

// ------ 繪製觸及支撐/壓力的提示 (Plot34-36) ------
isHitResistance = false; // 初始化「觸及壓力」旗標為false
if (g_finalRes1 < val_OverallHigh300 * 1.09 and high > val_Plot30) then isHitResistance = true; // 如果壓力一有效且今日最高價超過壓力一，則設定旗標為true
if (not isHitResistance and g_finalRes2 < val_OverallHigh300 * 1.19 and g_finalRes2 <> g_finalRes1 and high > val_Plot32) then isHitResistance = true; // 如果尚未觸及壓力一，且壓力二有效且今日最高價超過壓力二，則設定旗標為true
if isHitResistance then Plot(34, high, checkbox := 1) else NoPlot(34); // 如果觸及壓力，則在最高價位置繪製Plot34，否則不繪製
SetPlotLabel(34,"碰壓力"); // 設定Plot34的標籤為"碰壓力"

isHitSupport = false; // 初始化「觸及支撐」旗標為false
if (g_finalSupp1 > val_OverallLow300 * 0.91 and low < val_Plot31) then isHitSupport = true; // 如果支撐一有效且今日最低價低於支撐一，則設定旗標為true
if (not isHitSupport and g_finalSupp2 > val_OverallLow300 * 0.81 and g_finalSupp2 <> g_finalSupp1 and low < val_Plot33) then isHitSupport = true; // 如果尚未觸及支撐一，且支撐二有效且今日最低價低於支撐二，則設定旗標為true
{if date <> date[1] and isHitSupport and timeFT=false then begin // {註解區塊：原意圖在換日時記錄首次觸及支撐的時間，但目前無作用}
time1=currentTime; // 記錄當前時間
timeFT=true; // 設定首次觸發旗標
end;} // }
if isHitSupport then // 如果觸及支撐
Plot(35, Low{time1}, checkbox := 1) else NoPlot(35); // 在最低價位置繪製Plot35，否則不繪製 (註：{time1}語法無效，應為Low)
SetPlotLabel(35,"碰支撐"); // 設定Plot35的標籤為"碰支撐"

    
if isHitResistance and isHitSupport then // 如果同時觸及支撐與壓力
    Plot(36, high - low, checkbox := 1) // 則繪製Plot36代表波動區間
else // 否則
    NoPlot(36); // 不繪製Plot36
SetPlotLabel(36,"波動觸發區間"); // 設定Plot36的標籤為"波動觸發區間"

// ------ 繪製其他參考線 (Plot37-39) ------
if high > val_ATR_SellLevel then // 如果最高價突破ATR壓力參考線
    Plot(37, val_ATR_SellLevel, checkbox := 0) // 則繪製Plot37
else // 否則
    NoPlot(37); // 不繪製
SetPlotLabel(37,"突破ATR壓力參考"); // 設定Plot37的標籤為"突破ATR壓力參考"

Var: val_60PeriodLow_Ref(0); // 宣告局部變數：前60期最低價參考值，初始為0
val_60PeriodLow_Ref = Lowest(Low,60)[1]; // 計算前60期的最低價
if low < val_60PeriodLow_Ref then // 如果最低價跌破前60期最低價參考
    Plot(38, val_60PeriodLow_Ref, checkbox := 0) // 則繪製Plot38
else // 否則
    NoPlot(38); // 不繪製
SetPlotLabel(38,"跌破前60期低參考"); // 設定Plot38的標籤為"跌破前60期低參考"
//PlotK(39, open, high, low, close, "K線"); // 註解行：原意圖繪製K線圖於Plot39，目前無作用
// -----
//if open > close[1] then plot40(open,"開平高") ; // 註解行：原意圖在開盤高於昨收時繪製開盤價，目前無作用
//if open < close[1] then  plot41(open,"開低"); // 註解行：原意圖在開盤低於昨收時繪製開盤價，目前無作用
//如果沒撐住- 收盤價小於等於支撐1明日可能續跌 // 使用者註解：如果沒撐住- 收盤價小於等於支撐1明日可能續跌
if close[1] <= plot31[1] and close[1] < plot30[1]  then plot49(low-plot31[1],"預測跌"); // 如果昨日收盤價低於或等於支撐一且低於壓力一，繪製今日最低價與支撐一的差值，命名為"預測跌"
if close[1] <= plot31[1] and close[1] < plot30[1] and low-plot31[1] <=0 then plot50(low-plot31[1],"Low真的跌"); // 在前述條件下，如果今日最低價真的跌破支撐一，繪製其差值，命名為"Low真的跌"
if close[1] <= plot31[1] and close[1] < plot30[1] and low-plot31[1] > 0 then plot51(plot31,"預測蝶梅跌可買"); // 在前述條件下，如果今日最低價並未跌破支撐一(守住)，則繪製支撐一價位，命名為"預測蝶梅跌可買"
