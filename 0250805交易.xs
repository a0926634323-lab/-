// 腳本名稱：Bollinger_Strategy_Dual_Mode_Final_V5
// 說明：此腳本是一個日K逐筆模式下的交易策略，提供兩種交易模式：
//       保守模式（當日平倉後不重複進場）和積極模式（獲利平倉後可再進場）。
//----------------------------------------------------------------------
// 輸入參數區塊：讓使用者可以靈活調整策略參數
//----------------------------------------------------------------------
Input:    // 策略模式選擇：1=保守模式，2=積極模式。
    // 使用Dict來提供下拉式選單，避免輸入錯誤。
    StrategyMode(1, "策略模式", InputKind:=Dict(["保守模式-當日不重複進場", 1], ["積極模式-獲利可再進場", 2])), // 輸入參數：策略模式選擇，1為保守模式，2為積極模式。
	LM(1,"價格模式",InputKind:=Dict(["tick價", 1], ["3K高價", 2])), // 輸入參數：價格模式，1為使用Tick價，2為使用3根K棒高價。
	PA(1,"列警模式",InputKind:=Dict(["不列警", 0],["列印", 1], ["警示", 2])), // 輸入參數：警示模式，0為不列警，1為列印，2為警示。
	PM(6,"或價位>150獲利幾元出場"), // 輸入參數：當股價大於150時，獲利多少元出場。
 	MaxConsecutiveRedK(3, "連續陽K最大天數"), // 輸入參數：允許進場前的最大連續紅K棒天數。
 	BLVolumeThreshold(2000, "布林天期均量大於"), //布林天期均量大於 2000 張 // 輸入參數：進場條件之一，布林帶週期的平均成交量需大於此門檻值（單位：張）。
    // 買入訊號判斷的起始時間，格式為HHMMSS，例如132000代表下午13:20:00。
    TP1(132000, "判斷時間>="),    // 輸入參數：每日允許開始判斷進場訊號的時間點。
    // 布林中軌的計算天期。
    Length(10, "布林中軌天期"),    // 輸入參數：布林通道中軌（移動平均線）的計算天期。
    // 寶塔線的判斷天期。
    TowerLength(3, "寶塔線天期"),    // 輸入參數：寶塔線突破判斷的天期。
    // 停利比率，例如1.05代表獲利5%時平倉。
    FAP(1.05, "停利比"),    // 輸入參數：波段停利的比率（例如1.05代表獲利5%）。
    // 停損比率，例如0.7代表虧損30%時平倉。
    FSL(0.7, "停損比率%"),    // 輸入參數：波段停損的比率（例如0.7代表虧損30%，應為0.97代表虧損3%較合理，此處可能為筆誤）。
    // 新增：當日買進的部位，達到此獲利比率時立即平倉。預設1.025為2.5%獲利。
    IntradayProfit(1.025, "當日進場獲利%平倉"),    // 輸入參數：當日進場部位的短線停利比率（例如1.025代表獲利2.5%）。
    // 標準差的計算天期。
    StdDevPeriod(5, "標準差計算天期"),    // 輸入參數：計算價格波動標準差的天期。
    // 判斷非盤整期的門檻值。
    StdDevThreshold(0.5, "標準差門檻值"),    // 輸入參數：判斷市場是否為非盤整期的波動門檻。
    // 再進場邏輯所需的高成交量門檻。
    // HighVolumeThreshold(1000, "高成交量門檻"),     // (此行為註解，目前無作用) 輸入參數：高成交量門檻。
    // 新增：再進場的時間間隔（分鐘）。
    ReentryTimeDiff(30, "再進場等待時間(分鐘)"),    // 輸入參數：積極模式下，獲利了結後需等待的最小時間間隔（分鐘）。
    // 新增：再進場的價格回檔幅度（%）。
    ReentryPriceDrop(2, "再進場價格回檔%");// 輸入參數：積極模式下，等待再進場時，價格需從前次出場價回檔的百分比。
//----------------------------------------------------------------------
// 變數宣告區塊：用於儲存計算結果和策略狀態
//----------------------------------------------------------------------
Var: 
    MiddleBand(0),     // 宣告變數：儲存布林通道中軌的值。
    CurrentStdDev(0),  // 宣告變數：儲存當前價格標準差的值。
    // MyCostPrice 用於手動追蹤成本價，使用IntrabarPersist確保當日K棒內資料持續。
    IntrabarPersist MyCostPrice(0),    // 宣告持續性變數：手動追蹤的成本價，確保在當日K棒內值能被保存。
    // isWaitingForReentry 旗標：用於積極模式，在獲利出場後標記為等待再進場狀態。
    IntrabarPersist isWaitingForReentry(false),    // 宣告持續性變數：標記是否正在等待再進場機會（積極模式用）。
    // DayExitFlag 旗標：用於保守模式，在當日任何原因出場後標記為不再進場。
    IntrabarPersist DayExitFlag(false),    // 宣告持續性變數：標記當日是否已出場過（保守模式用）。
    // AlertFlag 旗標：用於控制警示發送，避免警示轟炸。
    IntrabarPersist AlertFlag(false),    // 宣告持續性變數：控制警示只觸發一次的旗標。
    // 新增：IntradayEntryFlag 旗標，用於標記當日是否有新買進部位。
    IntrabarPersist IntradayEntryFlag(false),    // 宣告持續性變數：標記當日是否有新建立的部位。
    // 新增：記錄平倉時間，用於再進場邏輯。
    IntrabarPersist MyExitTime(0),    // 宣告持續性變數：記錄獲利出場的時間點（積極模式用）。
    // 新增：記錄平倉價格，用於再進場邏輯。
    IntrabarPersist MyExitPrice(0), // 宣告持續性變數：記錄獲利出場的價格（積極模式用）。
 	ConsecutiveRedK(0); // 新增：用來計算連續陽K的天數 // 宣告變數：用於計算連續紅K棒的天數。
//----------------------------------------------------------------------
// 每日初始化區塊：每天開盤時，重置所有狀態變數
//----------------------------------------------------------------------
// CurrentBar = 1 或 Date <> Date[1] 是一個標準的判斷「換日」條件。
// 確保所有狀態變數在每個新的交易日都能被正確初始化。
if isfirstCall("Date") then begin   // 如果是新交易日的第一筆資料
    DayExitFlag = false; // 重置保守模式的出場旗標。
    isWaitingForReentry = false; // 重置積極模式的再進場旗標。
    AlertFlag = false; // 重置警示旗標。
    IntradayEntryFlag = false; // 重置當沖進場旗標。
    MyExitTime = 0; // 重置出場時間。
    MyExitPrice = 0; // 重置出場價格。
    // 將自訂成本價初始化為系統的持倉成本，以正確處理跨日留倉部位。
    MyCostPrice = FilledAvgPrice; // 將自訂成本價初始化為系統的持倉成本，以處理留倉部位。
end;
//----------------------------------------------------------------------
// 指標計算區塊
//----------------------------------------------------------------------
// 計算布林通道中軌，使用收盤價的平均。
MiddleBand = Average(Close, Length); // 計算布林通道中軌（指定天期的收盤價簡單移動平均）。
// 計算當前收盤價的標準差，用於衡量市場波動性。
CurrentStdDev = StandardDev(Close, StdDevPeriod, 2);  // 計算收盤價在指定期間的樣本標準差。
 // 定義進場條件
Condition1 = Close > MiddleBand;                                // 條件1：收盤價高於布林中軌，代表趨勢向上。
Condition2 = Close > Open;                                      // 條件2：日K線翻紅，代表當日買方力量強於賣方。
Condition3 = Close > Highest(High, TowerLength)[1];             // 條件3：寶塔線翻紅，代表股價突破前N日高點，動能強勁。
Condition4 = CurrentStdDev > StdDevThreshold;                   // 條件4：標準差大於門檻值，代表市場處於高波動的非盤整期。
 // 計算連續陽K棒的天數 
 // 如果今天收盤價高於開盤價，則連續天數加1 
 // 如果今天收盤價小於或等於開盤價，則連續天數歸零 
 if condition1 then begin   // 如果滿足條件1（收盤價大於中軌）
     ConsecutiveRedK = ConsecutiveRedK[1] + 1; // 連續紅K天數在前一天的基礎上加1。
 end else begin   // 否則
     ConsecutiveRedK = 0; // 連續紅K天數歸零。
            end;
 Condition5 = ConsecutiveRedK <= MaxConsecutiveRedK;				// 條件5: 連續陽K天數在設定範圍內
//----------------------------------------------------------------------
// 交易邏輯主體：根據模式執行不同的買賣策略
//----------------------------------------------------------------------
if StrategyMode = 1  then begin // 模式1：保守模式 - 當日出場後不再進場
    // 進場條件：當所有訊號都滿足，且當日未出場過時才進場
    if Position = 0 and filled=0 and CurrentTime >= TP1 and Condition1 and Condition2 and Condition3 and Condition4 and DayExitFlag = false and getField("處置股", "D")=false // 判斷條件：目前無倉位、時間符合、所有進場條件成立、非處置股、當日未曾出場
 		and Condition5 and average(volume[1],Length) > BLVolumeThreshold then begin // 且連續紅K天數未超標、前期均量大於門檻
        // 發出市價買進指令，標記為「保守-符合進場條件」。
        SetPosition(1, maxList(open,MiddleBand,Highest(High, TowerLength)[1]), label:="保守-符合進場條件"); // 執行買進指令，以開盤價、中軌價、寶塔線前期高點三者中的最高價作為委託價
		print("收價-",close,"布中K-",MiddleBand,"日K-",open,"寶塔K-",Highest(High, TowerLength)[1]);    // 印出進場時的相關價格資訊供除錯或分析。
    end;
        // 成交後才更新成本價：當有新部位成交時（Filled從0變為>0），才更新成本價。
    // Filled > Filled[1] 判斷，確保只在部位增加時執行。
    if Filled > Filled[1] then begin   // 部位成交後執行的邏輯：當成交部位確實增加時
        MyCostPrice = FilledAvgPrice;       // 更新手動追蹤的成本價為系統計算的成交均價。
        IntradayEntryFlag = true; // 標記為當日新進場。
    end;
    // 出場條件：當有部位時，判斷是否達到停利或停損點。
    // Position > 0 和 Filled > 0 確保有實際庫存才賣出。
    if Position > 0 and Filled > 0 then begin   // 保守模式出場條件判斷：當持有多頭部位時
        // 修正：將停利條件（FAP）判斷移到前面，優先追求較高的獲利
        if Close >= FilledAvgPrice * FAP then begin // 停利條件 (例如 5%) // 波段停利條件：當價格達到成本價的停利百分比。
            SetPosition(0, getField("收盤價", "Tick"), label:="保守-觸及停利條件");   // 執行市價賣出指令，平倉所有部位。
            DayExitFlag = true; // 鎖定當日，防止後續進場。
            IntradayEntryFlag = false; // 出場後重置。
        end else if IntradayEntryFlag and Close >= MyCostPrice * IntradayProfit then begin // 當日獲利平倉條件 (例如 2.5%) // 當日短線停利條件：若為當日進場的部位，且價格達到短線停利目標。
            SetPosition(0, getField("收盤價", "Tick"), label:="保守-當日獲利平倉");   // 執行市價賣出指令，平倉所有部位。
            DayExitFlag = true; // 鎖定當日，防止後續進場。
            IntradayEntryFlag = false; // 出場後重置。
        end;
        // 停損條件
        if Close <= filledAvgPrice * FSL then begin   // 停損條件：當價格跌至成本價的停損百分比。
            SetPosition(0, getField("收盤價", "Tick"), label:="保守-觸及停損條件");   // 執行市價賣出指令，平倉所有部位。
            DayExitFlag = true; // 鎖定當日，防止後續進場。
            IntradayEntryFlag = false; // 出場後重置。
        end;
    end;
end else if StrategyMode = 2  then begin // 模式2：積極模式 - 獲利出場後可再進場
    // 進場邏輯：將兩種進場條件合併
    if Position = 0 and filled=0 and CurrentTime >= TP1 and Condition1 and Condition2 and Condition3 and Condition4 and getField("處置股", "D")=false // 判斷條件：目前無倉位、時間符合、所有進場條件成立、非處置股
 		and Condition5 and average(volume[1],Length) > BLVolumeThreshold then begin // 且連續紅K天數未超標、前期均量大於門檻
        // 判斷是否為回檔後再進場，若是則觸發，否則觸發初始進場
        if isWaitingForReentry and Close <= MyExitPrice * (1 - ReentryPriceDrop/100) and TimeDiff(CurrentTime, MyExitTime, "M") >= ReentryTimeDiff then begin // 判斷是否為「等待再進場」狀態，且價格回檔、時間間隔皆滿足條件。
             SetPosition(1, getField("收盤價", "Tick"), label:="積極-回檔後再進場");   // 若滿足再進場條件，則執行市價買進。
             isWaitingForReentry = false; // 成功再進場後，結束等待狀態
        end else if not isWaitingForReentry then begin // 如果不是在等待再進場狀態，則為首次進場。
		if LM=2 then             // 如果價格模式為2
             SetPosition(1, maxList(open,MiddleBand,Highest(High, TowerLength)[1]), label:="L積極-符合進場條件"); // 使用開盤價、中軌、寶塔線高點中的最大值作為委託價。
			if LM=1 then 			// 如果價格模式為1
			once SetPosition(1, getField("收盤價", "Tick"), label:="M積極-符合進場條件"); // 使用tick價市價委託，once確保在此K棒只執行一次。
			if PA=1 then once print("日期",Date,"漲跌幅",q_PriceChangeRatio,"收價-",close,"布中K-",MiddleBand,"日K-",open,"寶塔K-",Highest(High, TowerLength)[1]); // 如果警示模式為1(列印)，則執行一次print指令輸出相關資訊。
			if PA=2 then  alert("日期",numToStr(Date,0),"漲跌幅",numToStr(q_PriceChangeRatio,2),"收價=",numToStr(close,2), // 如果警示模式為2(警示)
 			"布中K=",numToStr(MiddleBand,2),"日K=",numToStr(open,2),"寶塔K=",numToStr(Highest(High, TowerLength)[1],2)); // 則觸發Alert警示，顯示相關資訊。
		end;
    end;
    // 成交後才更新成本價：
    if Filled > Filled[1] then begin   // 部位成交後執行的邏輯：當成交部位確實增加時
        MyCostPrice = FilledAvgPrice;       // 更新手動追蹤的成本價為系統計算的成交均價。
        IntradayEntryFlag = true; // 標記為當日新進場。
    end;
        // 出場邏輯：當有部位時，判斷停利或停損。
    if Position > 0 and Filled > 0 then begin   // 積極模式出場條件判斷：當持有多頭部位時
        // 修正：將停利條件（FAP）判斷移到前面，優先追求較高的獲利
        if Close >= FilledAvgPrice * FAP {or (close >150 and close > FilledAvgPrice+PM) } then // 停利條件 (例如 5%) // 波段停利條件 (註解中的條件目前無效)。
            SetPosition(0, getField("收盤價", "Tick"), label:="積極-觸及停利條件"); // 執行市價賣出指令，平倉所有部位。
 			if close >150 and close > FilledAvgPrice+PM then begin // 另一停利條件：當股價大於150且獲利超過指定點數。
 			SetPosition(0, getField("收盤價", "Tick"), label:="積極-觸及6元停利");           // 執行市價賣出指令，平倉所有部位。
            MyExitTime = CurrentTime; // 記錄出場時間。
            MyExitPrice = Close; // 記錄出場價格。
            MyCostPrice = 0;           // 重置成本價。
            isWaitingForReentry = true; // 獲利出場，進入等待再進場模式。
            IntradayEntryFlag = false; // 出場後重置。
        end else if IntradayEntryFlag and Close >= filledAvgPrice * IntradayProfit then begin // 當日獲利平倉條件 (例如 2.5%) // 當日短線停利條件：若為當日進場的部位，且價格達到短線停利目標。
            SetPosition(0, getField("收盤價", "Tick"), label:="積極-當日獲利平倉");   // 執行市價賣出指令，平倉所有部位。
            MyExitTime = CurrentTime; // 記錄出場時間。
            MyExitPrice = Close; // 記錄出場價格。
            MyCostPrice = 0;           // 重置成本價。
            isWaitingForReentry = true; // 獲利出場，進入等待再進場模式。
            IntradayEntryFlag = false; // 出場後重置。
        end;
        // 停損條件
        if Close <= FilledAvgPrice * FSL then begin   // 停損條件：當價格跌至成本價的停損百分比。
            SetPosition(0, getField("收盤價", "Tick"), label:="積極-觸及停損條件");   // 執行市價賣出指令，平倉所有部位。
            MyExitTime = 0; // 虧損出場，不記錄時間。
            MyExitPrice = 0; // 虧損出場，不記錄價格。
            MyCostPrice = 0;           // 重置成本價。
            isWaitingForReentry = false; // 虧損出場，不再次進場
            IntradayEntryFlag = false; // 出場後重置。
        end;
    end;
end;