// 腳本名稱：Bollinger_Strategy_Dual_Mode_Final_V5_Revised
// 說明：此腳本是一個日K逐筆模式下的交易策略，提供兩種交易模式：
//      保守模式（當日平倉後不重複進場）和積極模式（獲利平倉後可再進場）。
// 版本：V5_Rev5 (逐行註解與對齊最終版)

//----------------------------------------------------------------------
// 輸入參數區塊：讓使用者可以靈活調整策略參數
//----------------------------------------------------------------------
Input:
    // --- 策略與交易模式設定 ---
    StrategyMode(1, "策略模式", InputKind:=Dict(["保守模式-當日不重複進場", 1], ["積極模式-獲利可再進場", 2])), // 參數：1=保守模式(出場後當日不再進場), 2=積極模式(獲利出場後可再進場)。
	LM(1,"價格模式",InputKind:=Dict(["tick價", 1], ["3K高價", 2])), // 參數：進場時的委託價格模式，1=市價(tick價), 2=指定價格(取開盤/中軌/寶塔高點的最大值)。
	PA(1,"列警模式",InputKind:=Dict(["不列警", 0],["列印", 1], ["警示", 2])), // 參數：觸發進場訊號時的通知方式，0=不通知, 1=在執行紀錄列印, 2=彈出警示視窗。
    
    // --- 進場條件組合 ---
    UseCondition1(true, "啟用布林紅K(收>中軌)"), // 參數(布林值)：是否啟用「收盤價 > 布林中軌」作為進場條件之一。
    UseCondition2(true, "啟用日紅K(收>開)"),   // 參數(布林值)：是否啟用「紅K棒 (收盤 > 開盤)」作為進場條件之一。
    UseCondition3(true, "啟用寶塔紅K(收>前N高)"), // 參數(布林值)：是否啟用「寶塔線翻紅 (收盤 > 前N期高點)」作為進場條件之一。

    // --- 進場過濾條件 ---
 	MaxConsecutiveRedK(3, "連續強勢K最大天數"), // 參數：允許進場前，連續滿足強勢條件的最大天數。
 	BLVolumeThreshold(2000, "布林天期均量大於"), // 參數：進場條件之一，布林帶週期的前期平均成交量需大於此門檻值（單位：張）。
    TP1(132000, "判斷時間>="),    // 參數：每日允許開始判斷進場訊號的時間點 (格式為HHMMSS)。

    // --- 指標計算參數 ---
    Length(10, "布林中軌天期"),    // 參數：布林通道中軌（移動平均線）的計算天期。
    TowerLength(3, "寶塔線天期"),    // 參數：寶塔線突破判斷的天期。
    StdDevPeriod(5, "標準差計算天期"),    // 參數：計算價格波動標準差的天期。
    StdDevThreshold(0.5, "標準差門檻值"),    // 參數：判斷市場是否為非盤整期的波動門檻。

    // --- 出場條件 ---
    FAP(1.05, "停利比"),    // 參數：波段停利的比率（例如1.05代表獲利5%）。
    FSL(0.97, "停損比率%"),    // 參數：停損的比率 (例如0.97代表虧損3%)。
    IntradayProfit(1.025, "當日進場獲利%平倉"),    // 參數：當日進場部位的短線停利比率（例如1.025代表獲利2.5%）。
    PM(6,"或價位>150獲利幾元出場"), // 參數：當股價高於150元時，改為獲利N元即出場。

    // --- 積極模式再進場參數 ---
    ReentryTimeDiff(30, "再進場等待時間(分鐘)"),    // 參數：積極模式下，獲利了結後需等待的最小時間間隔（分鐘）。
    ReentryPriceDrop(2, "再進場價格回檔%");// 參數：積極模式下，等待再進場時，價格需從前次出場價回檔的百分比。

//----------------------------------------------------------------------
// 變數宣告區塊
//----------------------------------------------------------------------
Var:
    MiddleBand(0),     // 變數：儲存布林通道中軌的值。
    CurrentStdDev(0),  // 變數：儲存當前價格標準差的值。
    IntrabarPersist MyCostPrice(0),    // 持續變數：手動追蹤的成本價，確保在當日K棒內值能被保存。
    IntrabarPersist isWaitingForReentry(false),    // 持續變數：標記是否正在等待再進場機會（積極模式用）。
    IntrabarPersist DayExitFlag(false),    // 持續變數：標記當日是否已出場過（保守模式用）。
    IntrabarPersist AlertFlag(false),    // 持續變數：控制警示只觸發一次的旗標。
    IntrabarPersist IntradayEntryFlag(false),    // 持續變數：標記當日是否有新建立的部位。
    IntrabarPersist MyExitTime(0),    // 持續變數：記錄獲利出場的時間點（積極模式用）。
    IntrabarPersist MyExitPrice(0), // 持續變數：記錄獲利出場的價格（積極模式用）。
 	ConsecutiveRedK(0), // 變數：用於計算連續強勢K棒的天數。
    IntrabarPersist InitialOrderSent(false), // 持續變數：標記「首次進場單」是否已送出，解決重複觸發問題。
    isAllRedConditions(false); // 變數：用於判斷是否同時滿足所有強勢紅K條件。

//----------------------------------------------------------------------
// 每日初始化區塊
//----------------------------------------------------------------------
if isfirstCall("Date") then begin   // 判斷是否為新交易日的第一筆資料(或第一筆運算)
    DayExitFlag = false; // 重置「保守模式」的當日出場旗標。
    isWaitingForReentry = false; // 重置「積極模式」的等待再進場旗標。
    AlertFlag = false; // 重置警示旗標。
    IntradayEntryFlag = false; // 重置當日新進場旗標。
    MyExitTime = 0; // 重置出場時間紀錄。
    MyExitPrice = 0; // 重置出場價格紀錄。
    InitialOrderSent = false; // 每日重置「首次下單已送出」的旗標。
    MyCostPrice = FilledAvgPrice; // 將自訂成本價初始化為系統的持倉成本，以處理留倉部位。
end; // 每日初始化區塊結束

//----------------------------------------------------------------------
// 指標計算區塊
//----------------------------------------------------------------------
MiddleBand = Average(Close, Length); // 計算布林通道中軌（指定天期的收盤價簡單移動平均）。
CurrentStdDev = StandardDev(Close, StdDevPeriod, 2);  // 計算收盤價在指定期間的樣本標準差。

// 定義進場條件
Condition1 = Close > MiddleBand;                     // 條件1 (布林紅K)：收盤價高於布林中軌，代表趨勢偏多。
Condition2 = Close > Open;                         // 條件2 (日紅K)：日K線為紅K，代表當日買方力量較強。
Condition3 = Close > Highest(High, TowerLength)[1];  // 條件3 (寶塔紅K)：寶塔線翻紅，代表股價突破前N日高點，動能強勁。
Condition4 = CurrentStdDev > StdDevThreshold;       // 條件4 (波動過濾)：標準差大於門檻值，代表市場處於高波動的非盤整期。

// 根據使用者輸入的開關，動態組合強勢紅K條件
isAllRedConditions = true; // 先假設條件成立，作為判斷的初始值。
if UseCondition1 then isAllRedConditions = isAllRedConditions and Condition1; // 如果啟用布林紅K，則將其結果納入`and`運算。
if UseCondition2 then isAllRedConditions = isAllRedConditions and Condition2; // 如果啟用日紅K，則將其結果納入`and`運算。
if UseCondition3 then isAllRedConditions = isAllRedConditions and Condition3; // 如果啟用寶塔紅K，則將其結果納入`and`運算。

// 根據組合後的「強勢紅K」條件來計算連續天數
if isAllRedConditions then begin // 如果滿足組合的強勢紅K條件
    ConsecutiveRedK = ConsecutiveRedK[1] + 1; // 連續天數在前一天的基礎上加1。
end else begin // 否則
    ConsecutiveRedK = 0; // 連續天數歸零。
end; // 連續天數計算區塊結束
Condition5 = ConsecutiveRedK <= MaxConsecutiveRedK;	// 條件5 (過熱過濾): 連續強勢的天數在設定範圍內。

//----------------------------------------------------------------------
// 交易邏輯主體
//----------------------------------------------------------------------
if StrategyMode = 1  then begin // --- 模式1：保守模式 ---
    // --- 進場邏輯 ---
    if Position = 0 and filled=0 and CurrentTime >= TP1 and isAllRedConditions and Condition4 and DayExitFlag = false and getField("處置股", "D")=false
 		and Condition5 and average(volume[1],Length) > BLVolumeThreshold then begin
        SetPosition(1, maxList(open,MiddleBand,Highest(High, TowerLength)[1]), label:="保守-符合進場條件");
		print("收價-",close,"布中K-",MiddleBand,"日K-",open,"寶塔K-",Highest(High, TowerLength)[1]);
    end; // 保守模式進場邏輯區塊結束
    
    // --- 成交後更新成本價 ---
    if Filled > Filled[1] then begin // 判斷成交部位是否剛增加
        MyCostPrice = FilledAvgPrice; // 更新手動追蹤的成本價。
        IntradayEntryFlag = true; // 標記為當日新進場的部位。
    end; // 成交後更新區塊結束
    
    // --- 出場邏輯 ---
    if Position > 0 and Filled > 0 then begin // 判斷是否持有多頭部位
        if Close >= FilledAvgPrice * FAP then begin // 判斷是否觸及波段停利點
            SetPosition(0, market, label:="保守-觸及停利條件");   // 平倉所有部位。
            DayExitFlag = true; // 設定當日已出場旗標，今日不再進場。
            IntradayEntryFlag = false; // 重置當日進場旗標。
        end else if IntradayEntryFlag and Close >= MyCostPrice * IntradayProfit then begin // 若未達波段停利，則判斷是否觸及當日短線停利點
            SetPosition(0, market, label:="保守-當日獲利平倉");   // 平倉所有部位。
            DayExitFlag = true; // 設定當日已出場旗標，今日不再進場。
            IntradayEntryFlag = false; // 重置當日進場旗標。
        end; // 停利判斷結束
        
        if Close <= filledAvgPrice * FSL then begin // 獨立判斷是否觸及停損點
            SetPosition(0, market, label:="保守-觸及停損條件");   // 平倉所有部位。
            DayExitFlag = true; // 設定當日已出場旗標，今日不再進場。
            IntradayEntryFlag = false; // 重置當日進場旗標。
        end; // 停損判斷結束
    end; // 持倉判斷區塊結束
end // 保守模式區塊結束
else if StrategyMode = 2 then begin // --- 模式2：積極模式 ---
    // --- 進場邏輯 ---
    if Position = 0 and filled=0 and CurrentTime >= TP1 and getField("處置股", "D")=false then begin // 判斷是否為可進場狀態 (無倉位、時間、非處置股)
        // 條件1：再進場
        if isWaitingForReentry and Close <= MyExitPrice * (1 - ReentryPriceDrop/100) and TimeDiff(CurrentTime, MyExitTime, "M") >= ReentryTimeDiff then begin
            SetPosition(1, market, label:="積極-回檔後再進場");
            isWaitingForReentry = false;
        end
        // 條件2：首次進場
        else if not isWaitingForReentry and InitialOrderSent = false and isAllRedConditions and Condition4 and Condition5 and average(volume[1],Length) > BLVolumeThreshold then begin
			if LM=2 then // 如果價格模式為2
            	SetPosition(1, maxList(open,MiddleBand,Highest(High, TowerLength)[1]), label:="L積極-符合進場條件"); // 使用指定價格進場
			if LM=1 then // 如果價格模式為1
			 	SetPosition(1, market, label:="M積極-符合進場條件"); // 使用市價進場
            
            InitialOrderSent = true; // 送出首次進場單後，立即設定旗標，防止重複觸發

			if PA=1 then // 如果警示模式為1 (列印)
				print("日期",Date,"漲跌幅",q_PriceChangeRatio,"收價-",close,"布中K-",MiddleBand,"日K-",open,"寶塔K-",Highest(High, TowerLength)[1]);
			if PA=2 then // 如果警示模式為2 (警示)
				alert("日期",numToStr(Date,0),"漲跌幅",numToStr(q_PriceChangeRatio,2),"收價=",numToStr(close,2), "布中K=",numToStr(MiddleBand,2),"日K=",numToStr(open,2),"寶塔K=",numToStr(Highest(High, TowerLength)[1],2));
		end; // 首次進場區塊結束
    end; // 可進場狀態區塊結束

    // --- 成交後更新成本價 ---
    if Filled > Filled[1] then begin // 判斷成交部位是否剛增加
        MyCostPrice = FilledAvgPrice; // 更新手動追蹤的成本價。
        IntradayEntryFlag = true; // 標記為當日新進場的部位。
    end; // 成交後更新區塊結束

    // --- 出場邏輯 ---
    if Position > 0 and Filled > 0 then begin // 判斷是否持有多頭部位
        // 停利條件1：達到波段停利 FAP
        if Close >= FilledAvgPrice * FAP then begin
            SetPosition(0, market, label:="積極-觸及停利條件FAP");
            MyExitTime = CurrentTime;      // 記錄獲利出場的時間，用於再進場的時間間隔判斷。
            MyExitPrice = Close;           // 記錄獲利出場的價格，用於再進場的價格回檔判斷。
            MyCostPrice = 0;               // 重置成本價。
            isWaitingForReentry = true;    // 啟動等待再進場的狀態。
            IntradayEntryFlag = false;     // 重置當日進場旗標。
        end
        // 停利條件2：股價大於150且獲利超過固定點數 PM
        else if Close > 150 and Close > FilledAvgPrice + PM then begin
            SetPosition(0, market, label:="積極-觸及 元停利");
            MyExitTime = CurrentTime;      // 記錄獲利出場的時間。
            MyExitPrice = Close;           // 記錄獲利出場的價格。
            MyCostPrice = 0;               // 重置成本價。
            isWaitingForReentry = true;    // 啟動等待再進場的狀態。
            IntradayEntryFlag = false;     // 重置當日進場旗標。
        end
        // 停利條件3：當日短線停利
        else if IntradayEntryFlag and Close >= FilledAvgPrice * IntradayProfit then begin
            SetPosition(0, market, label:="積極-當日獲利平倉");
            MyExitTime = CurrentTime;      // 記錄獲利出場的時間。
            MyExitPrice = Close;           // 記錄獲利出場的價格。
            MyCostPrice = 0;               // 重置成本價。
            isWaitingForReentry = true;    // 啟動等待再進場的狀態。
            IntradayEntryFlag = false;     // 重置當日進場旗標。
        end; // 停利判斷區塊結束

        // 停損條件 (獨立於停利條件之外進行判斷)
        if Close <= FilledAvgPrice * FSL then begin
            SetPosition(0, market, label:="積極-觸及停損條件");
            MyExitTime = 0;                // 停損出場，清除出場時間紀錄。
            MyExitPrice = 0;               // 停損出場，清除出場價格紀錄。
            MyCostPrice = 0;               // 重置成本價。
            isWaitingForReentry = false;   // 停損出場，關閉再進場的可能性。
            DayExitFlag = true;            // 【重要】停損後，當日不再進行任何交易。
            IntradayEntryFlag = false;     // 重置當日進場旗標。
        end; // 停損判斷區塊結束
    end; // 持倉判斷區塊結束
end; // 積極模式區塊結束
