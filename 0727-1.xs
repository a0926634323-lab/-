// --- 策略參數設定 ---
Input:
    // ZigZag 參數
    zz_deviation(10, "每個波段的滿足幅度(%)"),
    zz_depth(5, "判斷頂點的左右bar間隔"),

    // SAR 參數
    AFInitial(0.02, "SAR 加速因子起始值"),
    AFIncrement(0.02, "SAR 加速因子累加值"),
    AFMax(0.2, "SAR 加速因子最高值"),

    // 寶塔線/自定義趨勢反轉判斷參數
    Pagoda_MALength(10, "寶塔線MA期數"), // 寶塔線的MA期數
    Pagoda_TrendLen(3, "寶塔線趨勢反轉判斷天數"),
    // 將 Pagoda_ReversalMode 設為 quickedit，使其可在圖表上直接點選調整
    Pagoda_ReversalMode(1, "寶塔線趨勢反轉判斷模式", inputkind:=Dict(["依據K線圖高/低點",1],["依據寶塔線高低/點",2]), quickedit:=true),

    // 一目均衡表參數
    Ichimoku_ConvPeriod(9, "一目轉換線天期"),
    Ichimoku_BasePeriod(26, "一目基準線天期"),
    Ichimoku_LagPeriod(52, "一目先行帶B天期"),
    Ichimoku_Displacement(26, "一目位移天期"),
    Ichimoku_ThickCloudThreshold(2.5, "一目厚雲定義(%)"),

    // 時機儀表板參數
    // 將 Timing_AnalysisMode 設為 quickedit，使其可在圖表上直接點選調整
    Timing_AnalysisMode(1, "時機分析模式", inputkind:=Dict(["三重確認(VIX+類股+個股)",1], ["雙重確認(VIX+個股)",2], ["雙重確認(類股+個股)",3], ["單一確認(僅個股)",4]), quickedit:=true),
    VIX_MAPeriod(20, "VIX均線期數"),
    IndustryIndexSymbol("TSE23.TW", "對應類股指數代碼"),

    // 訊號繪圖控制
    // 繪圖訊號本身通常就是一個可勾選的 Plot，這裡保持為 Input TrueFalse
    PlotBuySignal(True, "繪製買進訊號"),

    // 個別條件啟用開關 - 這些通常不會直接顯示為圖上勾選框，但會在點擊指標名稱後的小視窗中顯示
    EnableZigZag(True, "啟用 ZigZag 上升階段"),
    EnableSAR(True, "啟用 SAR 上升趨勢"),
    EnablePagoda(True, "啟用 寶塔線翻紅"),
    EnableDKX(True, "啟用 DKX線 > DKXMA"),
    EnableIchimoku(True, "啟用 一目均衡表陽雲"),
    EnableTiming(True, "啟用 時機儀表板適合");

// --- 變數宣告 ---
// ZigZag 相關變數
Var: intrabarpersist pv_count(0);
Var: intrabarpersist pv_start_index(0);
Var: intrabarpersist pv_start_price(0);
Var: intrabarpersist pv_end_index(0);
Var: intrabarpersist pv_end_price(0);
Var: intrabarpersist pv_is_high(false);
Array: maxmin[2](0);
Var: intrabarpersist pivot_updated(false);
Var: _i(0), p_index(0), p_price(0), is_high(false), dev(0);

// SAR 相關變數
Var: SAR_Current(0);
Var: SAR_Previous(0);

// 寶塔線相關變數
Var: MID(0), DKX(0), DKXMA(0);
Var: intrabarpersist Pagoda_Condition1(false);
Var: intrabarpersist Pagoda_Condition2(false);
Var: intrabarpersist Pagoda_Name("");

// 一目均衡表相關變數
Var: Tenkan_Line(0), Kijun_Line(0), SenkouA_Line(0), SenkouB_Line(0);
Var: Current_KumoTop(0), Current_KumoBottom(0);
Var: Current_Kumo_isBull(false);
Var: Cloud_Thickness(0), Cloud_Thickness_Ratio(0);
Var: isThickCloud(false);

// 時機儀表板相關變數
Var: VIX_Close(0), VIX_MA(0);
Var: Industry_H(0), Industry_L(0), Industry_C(0);
Var: Industry_Tenkan(0), Industry_Kijun(0), Industry_SenkouA(0), Industry_SenkouB(0);
Var: Stock_Tenkan(0), Stock_Kijun(0), Stock_SenkouA(0), Stock_SenkouB(0);
Var: IsVixStable(false);
Var: IsIndustryTrendBullish(false);
Var: IsStockTrendBullish(false);
Var: FinalCondition(false);
Var: Status_Text("");

// --- 回溯資料天數設定 ---
SetTotalBar(Ichimoku_LagPeriod + Ichimoku_Displacement + 5);
SetBackBar(Ichimoku_LagPeriod + Ichimoku_Displacement + 5);

// --- 每日初始化 (針對日線頻率的策略，若為分鐘頻率則需調整) ---
If Date <> Date[1] Then Begin
    pv_count = 0;
    pivot_updated = false;
    Pagoda_Condition1 = false;
    Pagoda_Condition2 = false;
    Pagoda_Name = "";
End;

// --- 1. ZigZag 指標計算 ---
pivot_updated = false;
maxmin[1] = SwingHighBar(High, zz_depth + 1, zz_depth, zz_depth, 1);
maxmin[2] = SwingLowBar(Low, zz_depth + 1, zz_depth, zz_depth, 1);

For _i = 1 to 2 Begin
    If maxmin[_i] >= 0 Then Begin
        If _i = 1 Then is_high = true Else is_high = false;
        
        If is_high Then p_price = High[maxmin[_i]]
        Else p_price = Low[maxmin[_i]];
        
        p_index = CurrentBar - maxmin[_i];

        If pv_count = 0 Then Begin
            pv_count = 1;
            pv_start_index = p_index;
            pv_start_price = p_price;
            pv_end_index = p_index;
            pv_end_price = p_price;
            pv_is_high = is_high;
            pivot_updated = true;
        End Else Begin      
            If pv_is_high = is_high Then Begin
                If (is_high And p_price > pv_end_price) Or (Not is_high And p_price < pv_end_price) Then Begin
                    If pv_count = 1 Then Begin
                        pv_start_index = p_index;
                        pv_start_price = p_price;
                    End;
                    pv_end_index = p_index;
                    pv_end_price = p_price;
                    pivot_updated = true;
                End;
            End Else Begin
                dev = 100 * (p_price - pv_end_price) / pv_end_price;
                If (Not pv_is_high And dev >= zz_deviation) Or (pv_is_high And dev <= -1 * zz_deviation) Then Begin
                    pv_count = pv_count + 1;
                    pv_start_index = pv_end_index;
                    pv_start_price = pv_end_price;
                    pv_end_index = p_index;
                    pv_end_price = p_price;
                    pv_is_high = is_high;
                    pivot_updated = true;
                End;
            End;     
            If pivot_updated Then Break;
        End;
    End;
End;

// ZigZag 上升階段判斷
Var: IsZigZagAscending(false);
If pv_count > 0 Then IsZigZagAscending = pv_is_high;

// --- 2. SAR 指標計算 ---
SAR_Current = SAR(AFInitial, AFIncrement, AFMax);
SAR_Previous = SAR(AFInitial, AFIncrement, AFMax)[1];
Var: IsSARRising(false);
IsSARRising = (SAR_Current > SAR_Previous);

// --- 3. 寶塔線指標計算 (部分邏輯) ---
MID = (close*3 + open + high + low) / 6;
DKX = WMA(MID, 20);
DKXMA = Average(DKX, Pagoda_MALength);

Var: value3_pagoda(0), value4_pagoda(0);
value3_pagoda = MaxList(close, close[1]);
value4_pagoda = MinList(close, close[1]);

Var: Pagoda_UpperBoundary(0), Pagoda_LowerBoundary(0);
If Pagoda_ReversalMode = 1 Then Begin
    Pagoda_UpperBoundary = Highest(high[1], Pagoda_TrendLen);
    Pagoda_LowerBoundary = Lowest(low[1], Pagoda_TrendLen);
End Else If Pagoda_ReversalMode = 2 Then Begin
    Pagoda_UpperBoundary = Highest(value3_pagoda[1], Pagoda_TrendLen);
    Pagoda_LowerBoundary = Lowest(value4_pagoda[1], Pagoda_TrendLen);
End;

If Close Cross Over Pagoda_UpperBoundary Then Begin
    Pagoda_Condition1 = True;
    Pagoda_Condition2 = False;
End Else If Close Cross Under Pagoda_LowerBoundary Then Begin
    Pagoda_Condition1 = False;
    Pagoda_Condition2 = True;
End;

// 判斷寶塔線是否為「翻紅」
If Not Pagoda_Condition1[1] And Pagoda_Condition1 Then Pagoda_Name = "翻紅";

Var: IsPagodaTurningRed(false);
IsPagodaTurningRed = (Pagoda_Name = "翻紅");

// 新增條件：DKX線 > 多空線的移動平均線
Var: IsDKXAboveMA(false);
IsDKXAboveMA = (DKX > DKXMA);

// --- 4. 一目均衡表指標計算 ---
Tenkan_Line = (Highest(High, Ichimoku_ConvPeriod) + Lowest(Low, Ichimoku_ConvPeriod)) / 2;
Kijun_Line = (Highest(High, Ichimoku_BasePeriod) + Lowest(Low, Ichimoku_BasePeriod)) / 2;
SenkouA_Line = (Tenkan_Line + Kijun_Line) / 2;
SenkouB_Line = (Highest(High, Ichimoku_LagPeriod) + Lowest(Low, Ichimoku_LagPeriod)) / 2;

// 當前雲層顏色判斷
Var: IsIchimokuPositiveCloud(false);
If CurrentBar > Ichimoku_Displacement Then Begin
    If SenkouA_Line[Ichimoku_Displacement] > SenkouB_Line[Ichimoku_Displacement] Then
        IsIchimokuPositiveCloud = true
    Else
        IsIchimokuPositiveCloud = false;
End;

// --- 5. 時機儀表板指標計算 ---
VIX_Close = GetSymbolField("VIX.TF", "Close", "D");
VIX_MA = Average(VIX_Close, VIX_MAPeriod);

Industry_H = GetSymbolField(IndustryIndexSymbol, "High", "D");
Industry_L = GetSymbolField(IndustryIndexSymbol, "Low", "D");
Industry_C = GetSymbolField(IndustryIndexSymbol, "Close", "D");
Industry_Tenkan = (Highest(Industry_H, Ichimoku_ConvPeriod) + Lowest(Industry_L, Ichimoku_ConvPeriod)) / 2;
Industry_Kijun = (Highest(Industry_H, Ichimoku_BasePeriod) + Lowest(Industry_L, Ichimoku_BasePeriod)) / 2;
Industry_SenkouA = (Industry_Tenkan + Industry_Kijun) / 2;
Industry_SenkouB = (Highest(Industry_H, Ichimoku_LagPeriod) + Lowest(Industry_L, Ichimoku_LagPeriod)) / 2;

Stock_Tenkan = (Highest(High, Ichimoku_ConvPeriod) + Lowest(Low, Ichimoku_ConvPeriod)) / 2;
Stock_Kijun = (Highest(High, Ichimoku_BasePeriod) + Lowest(Low, Ichimoku_BasePeriod)) / 2;
Stock_SenkouA = (Stock_Tenkan + Stock_Kijun) / 2;
Stock_SenkouB = (Highest(High, Ichimoku_LagPeriod) + Lowest(Low, Ichimoku_LagPeriod)) / 2;

IsVixStable = (VIX_Close < VIX_MA);
IsIndustryTrendBullish = (Industry_C > Industry_SenkouA[Ichimoku_Displacement]) And (Industry_C > Industry_SenkouB[Ichimoku_Displacement]) And (Industry_Tenkan > Industry_Kijun);
IsStockTrendBullish = (Close > Stock_SenkouA[Ichimoku_Displacement]) And (Close > Stock_SenkouB[Ichimoku_Displacement]) And (Stock_Tenkan > Stock_Kijun);

FinalCondition = false;
Switch (Timing_AnalysisMode)
Begin
    Case 1: // 三重確認
        FinalCondition = IsVixStable And IsIndustryTrendBullish And IsStockTrendBullish;
    Case 2: // 雙重確認 (VIX+個股)
        FinalCondition = IsVixStable And IsStockTrendBullish;
    Case 3: // 雙重確認 (類股+個股)
        FinalCondition = IsIndustryTrendBullish And IsStockTrendBullish;
    Case 4: // 單一確認 (僅個股)
        FinalCondition = IsStockTrendBullish;
End;

Var: IsTimingSuitable(false);
IsTimingSuitable = FinalCondition;

// --- 最終買進條件組合 ---
// 買進條件：
// 1. ZigZag 為上升階段 (IsZigZagAscending)
// 2. SAR 為上升趨勢 (IsSARRising)
// 3. 寶塔線為「翻紅」 (IsPagodaTurningRed)
// 4. DKX線 > 多空線的移動平均線 (IsDKXAboveMA)
// 5. 一目均衡表為「陽雲」 (IsIchimokuPositiveCloud)
// 6. 時機儀表板為「適合」 (IsTimingSuitable)

If (NOT EnableZigZag OR IsZigZagAscending)
    And (NOT EnableSAR OR IsSARRising)
    And (NOT EnablePagoda OR IsPagodaTurningRed)
    And (NOT EnableDKX OR IsDKXAboveMA)
    And (NOT EnableIchimoku OR IsIchimokuPositiveCloud)
    And (NOT EnableTiming OR IsTimingSuitable) Then
Begin
    // 如果 PlotBuySignal 為 True，則繪製買進訊號
    If PlotBuySignal Then Plot1(close, "買進訊號");
End;

// 由於未提供出場條件，此策略將僅進行買進訊號繪製。
// 在實際交易中，應設定明確的出場條件，如停損、停利或趨勢反轉等。
