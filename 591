// ========================================================     
// 【AI 艦隊】 全自動突擊腳本 V7.580 (輕量極速版 / XQ0614 優化)     
// ========================================================     
     
// 【系統強制設定】將 8000 根大幅縮減至 500 根，減少系統極大負擔    
SetTotalBar(500);     
    
// ★ 僅保留日K與5分K核心，消滅無謂的跨頻率運算    
SetBarBack(30, "D");   // 滿足 vDailyMA20 與大趨勢判斷     
SetBarBack(60, "5");   // 滿足 5分K 跨頻率 MACD/EMA 計算
    
// ========================================================     
// 1. 外部參數設定區
// ========================================================     
Input: pTotalCapital(100, "01[系] 今日總可用資金(萬)");     
Input: pMasterNoLossSwitch(True, "02[出] 終極凹單模式(帳面虧損絕不出場)", inputkind:=dict(["任何虧損都不出場(True)", True], ["一般依條件(False)", False]));     
Input: pAntiGapDown(True, "03[進] 啟動防開高走低機制須等待冷卻時間", inputkind:=dict(["依開盤漲幅，強制觀望(True)", True], ["不啟用(False)", False]));     
Input: pUseBrokerPosCtrl(True, "04[系]真實帳戶庫存上限攔截管控", inputkind:=dict(["限制總數量(True)", True], ["不限制(False)", False]));
Input: pMaxBrokerPos(1, "05[系] 真實帳戶允許最大庫存總數(張/口)");

Input: pAutoGearMode(2, "06[進] AI 股性評估方式(決定進場依股價/依N日震幅)", inputkind:=dict(["1.依股價(5檔)", 1], ["2.依N日震幅", 2]));     
Input: pVolDays(5, "07[進] 震幅計算天數(若選2)");     
Input: pUseTickPriority(True, "08[進] 啟用Tick獲利效率排隊", inputkind:=dict(["高效率秒單(True)", True], ["不啟用(False)", False]));     

// 【已新增選項 6】
Input: pStrategyMode(1, "@09[進] 濾網大趨勢(日K)進場門檻1-6", inputkind:=dict(["1.過 20MA 就買標準(積極)", 1], ["2.做長波段多頭(穩健)", 2], ["3.糾結(抓盤整突破)", 3], ["4.想跟隨主力大單護盤(突擊)", 4], ["5.不限制(開盤趨勢戰法)", 5], ["6.日K多頭+開盤結構(2+5)", 6]));     
Input: pCatchUpMode(4, "10[進] 錯過「首發突破的訊號點」重啟上車方式1-4", inputkind:=dict(["1.無限制", 1], ["2.區間", 2], ["3.放棄", 3], ["4.MACD低接", 4]));     

Input: pTradeStyle(3, "@@14[戰略] 當今日交易大戰略 (當沖/波段/AI自動評估", inputkind:=dict(["1.全波段", 1], ["2.全當沖", 2], ["3.AI自適應判斷", 3]));     
Input: pAutoCloseDT(False, "15[出] 當沖13:20自動平倉", inputkind:=dict(["清倉(True)", True], ["手控(False)", False]));     

Input: pTradeQty(1, "16[系] 每次進場張數");     
Input: pMaxTrades(1, "17[系] 單日同商品最多進場次數");     
Input: pCoolDownBars(5, "18[進] 出場後強制冷卻K棒數");     

Input: pBaseTargetSW(4, "@@19[出] 波段停利：AI動態計算的(最低保底獲利%)"); 
Input: pBaseTargetDT(3, "@20[出] 當沖停利：AI動態計算的【最低保底獲利%】"); 
Input: pTargetProfit(15.0, "@21[出] 絕對獲利天花板(碰到無條件強制收割%)");     

Input: pMinSurgeProfit(2.0, "@23[出] 急拉停利: 最低獲利門檻(%)");
Input: pSurgePct(5, "@24[出] 急拉停利: 盤中低點起算急拉幅度(%)");
Input: pPullbackTicks(2, "@25[出] 瘋狗急拉：高檔回落即立刻賣出的【下跌檔位數】");
Input: pPullbackPct(1.0, "@26[出] 瘋狗急拉：高檔回落即立刻賣出的【下跌幅度%】");
Input: pSurgeBars(15, "27[出] 瘋狗急拉：尋找起漲低點的【回溯K棒視窗】"); 

Input: pAutoSellDyn(True, "28[出] 停利達標時的執行動作(市價砍倉/僅跳通知)", inputkind:=dict(["砍倉(True)", True], ["警示(False)", False]));     
Input: pATRMult(2.5, "29[出]  移動停利：容忍回檔的 ATR 寬鬆倍數");     
Input: pMinProfit(2.5, "30[出] 啟動防守機制(移停/破線)的【最低帳面獲利%】");     
Input: pStopLoss(25.0, "@31[出] 終極保命斷頭線(單筆總資金虧損極限%)");     
Input: pStrictBreak(False, "32[出] 破線停利態度(無情秒砍/給予下沉容忍空間)", inputkind:=dict(["秒砍(True)", True], ["容忍(False)", False]));     
Input: pBreakTolerance(15.0, "@33[出] 破線容忍度：允許短暫跌破均線的幅度(%)(看級別)");     
Input: pUseChipsHold(True, "34[出] 籌碼免死金牌(大戶大買則攔截破線停損指令)", inputkind:=dict(["大戶買超跌破不砍(True)", True], ["一般(False)", False]));

Input: pMomentum(1, "35[進] 今日買盤動能要求(必須紅K/僅需過昨收即可)", inputkind:=dict(["1.嚴格(須為紅K)", 1], ["2.寬鬆(只要過昨收)", 2]));     
Input: pGapMode(2, "36[進] 防追高(買在尖端)模式(固定極限/依近期震幅動態調整)", inputkind:=dict(["1.固定%", 1], ["2.動態(近期震幅)", 2]));     
Input: pFixedGap(3.5, "37[進] 固定防追高：今日已漲幅超過此(%)則拒絕買進");     
Input: pDynGapMult(0.8, "38[進] 動態防追高：近期震幅的寬鬆乘數");     
Input: pMaxBias(15.0, "39[進] 月線乖離極限(防止買在離均線太遠的高空%)");     
Input: pMinPrice(10.0, "40[進] 標的最低價過濾");     
Input: pMaxPrice(1000.0, "41[進] 標的最高價過濾");     
Input: pNoLossExit(True, "42[出] 觸碰保命停損時的最終動作(死不退場/正常砍倉)", inputkind:=dict(["虧損死不退場(True)", True], ["正常停損(False)", False]));     
Input: pUseTVLogic(False, "43[進] 啟動 TV 極穩健雙重確認(日K與核心短分K方向必須一致)", inputkind:=dict(["長線保護(True)", True], ["純動能(False)", False]));     
Input: pMAType(1, "44[系] 全系統依賴的均線數學模型(SMA/EMA/WMA...)", inputkind:=dict(["1.短E長S", 1], ["2.全EMA", 2], ["3.全WMA", 3], ["4.全SMA", 4], ["5.全RMA", 5]));     

Input: pAutoBonus(True, "@@45[出] 停利天花板擴充啟動AI自適應獎金倍數", inputkind:=dict(["依股性(True)", True], ["固定(False)", False]));     
Input: pBonusMult(100.0, "@46[出] 固定動能獎金倍數(若上方設False)");     
     
// ★ 探底反彈與再次進場機制
Input: pEnableBuyBack(True, "50[進] 被洗出場或停利後的【自動低接/買回機制】", inputkind:=dict(["開啟(True)", True], ["關閉(False)", False]));  
input: pBandPullbackPct(2.5, "51[進] 低接門檻：距離上次出場價的【回檔深度%】");   
Input: pBuyBackBounceTicks(2, "52[進] 低接確認：觸底後向上反彈的【檔位數】"); 
Input: pBuyBackBouncePct(1.0, "53[進] 低接確認：觸底後向上反彈的【漲幅%】");
Input: pReEntryGapPct(3.0, "54[進] 防頻繁刷單：新訊號需距離上次停利價的【避開空間%】");
 
// ========================================================     
// 2. 宣告內部變數區  
// ========================================================     
Var: vDailyMA5(0), vDailyMA10(0), vDailyMA20(0), dMaxMA(0), dMinMA(0);
Var: vIsDailyBull(False), vIsMoney(False), vBias(0), vBiasDesc(""), vTrendText("");
Var: vRefPrice(0), vTodayRisePct(0), vDailyAmp(0), vNDayAmp(0), vAmpSum(0), j(0), initBias(0), initMA20(0);

Var: vDayOpen(0), vTrendEntry(False);

// 優化：只保留 5 分鐘級別變數
Var: ema5(0), ma5_5(0), vScore5(0), vMaxScore(0);
Var: macdValue1m(0), macdMA1m(0), macdOsc1m(0);
Var: vM_Val5(0), vM_MA5(0), vM_Osc5(0), macdOsc5m(0);
Var: vIsOscBull(False), vIsOscShrink(False);

Var: tvDailyMA20(0), tvDailyMA5(0), tv5mMA20(0), tv5mMA5(0);
Var: tvIsDailyResonance(False), tvIs5mResonance(False), tvPerfectResonance(True);
Var: vIsDayTradeSignal(False), vIsSwingSignal(False), vIsBerserk(False), vBerserkStr("");

Var: vAntiGapCond(True), vIsTrendReversal(False), vIsDipBuy(False), vChipCondition(True);
Var: vCond1(False), vCond2(False), vCrossPrice(0), vTriggerTime(0), vIntRatio(0), vDynamicCeiling(0);

Var: vBigPlayerNetBuy(0), vDailyVolume(0), vBigPlayerRatio(0), vIsChipProtect(False), vSChips("");

Var: vGapLimit(999.0), vGapPrice(99999.0), vNeededCap(0), vUpLimit(0), vTicksToLimit(0);
Var: vSpacePct(0), vTickSize(0), vTickYield(0), vPrioritySeconds(0), vRealPos(0);

Var: vIsTFBull(False), vIsTFBreak(False), vProfitPct(0), vMyATR(0), vDynStop(0);
Var: vDynamicTarget(0), vRealBonusMult(100.0), vRealMinProfitPrice(0), vRealTargetPrice(0);
Var: i(0), dTR(0), sumTR(0), vFinalScore(0), vCurrentBaseTarget(0), vTrailStopPrice(0);

Var: vMarketPct(0), vStockPct(0), vTSE_Ref(0), vStock_Ref(0);
Var: vStateCategory(""), vActionMsg(""), bIsMarketEvent(False), bIsStockEvent(False);

Var: vAllowEntry(True), vRejectReason(""), vAutoDailyTest(True), vAutoFilter(False);
Var: vSensitivityMode(""), vSGearStr(""), vDebugStr(""), vLastDebugStr(""); 
Var: vLastAlertStr(""), vCurrentAlertStr(""), vAILogStr(""), vTrackStr("");
Var: vS1(""), vS2(""), vS3(""), vS8(""), vS12(""), vS14(""), vS15(""), vS19(""), vS22("");
Var: vSMAType(""), vSTVLogic(""), vSMinProfit(""), vBreakoutPriceStr(""); 
Var: vModeStr(""), vDisplayEntryTime(0), vEndReportStr(""), vFinalProfitPct(0);
Var: vPrintMsg(""), vPopMsg(""), vTestPrinted(False);

// 【交易狀態專屬記憶鎖】
Var: IntrabarPersist vTradesToday(0), IntrabarPersist vLastExitBar(-999), IntrabarPersist vEntryType(0), IntrabarPersist vEntryDate(0);
Var: IntrabarPersist vTriggerPrice(0), IntrabarPersist vLockedTarget(0), IntrabarPersist vInitStop(0), IntrabarPersist vHighSinceEntry(0);
Var: IntrabarPersist vTickTargetPrice(0), IntrabarPersist vTickMinProfit(0);
Var: IntrabarPersist vFirstSignalTime(0), IntrabarPersist vFirstSignalPrice(0), IntrabarPersist vFirstSignalClose(0), IntrabarPersist vFirstSignalLow(0);
Var: IntrabarPersist vIntervalHigh(0), IntrabarPersist vIntervalLow(99999), IntrabarPersist vWaitTime(090000), IntrabarPersist vMorningHigh(0);
Var: IntrabarPersist vMorningLow(99999), IntrabarPersist vDayLow(99999), IntrabarPersist vTrackDayHigh(0), IntrabarPersist vTrackDayHighTime(0);
Var: IntrabarPersist vTrackDayLow(999999), IntrabarPersist vTrackDayLowTime(0), IntrabarPersist vSurgeMaxPrice(0), IntrabarPersist vHaltImmunityTime(0);
Var: vSurgeBase(0), vCondSurge(False), vCondSurgeProfit(False), vCondPullback(False), vSurgeTickSize(0), vRecentLow(0);
Var: IntrabarPersist vIsFilledPrinted(True), IntrabarPersist vDynAlerted(False), IntrabarPersist vRejectAlertPrinted(False);
Var: IntrabarPersist vSignalFired(False), IntrabarPersist vSignalFireTime(0), IntrabarPersist vHighestScoreToday(0);
Var: IntrabarPersist vDailyPosReported(False), IntrabarPersist vLastCategory(""), IntrabarPersist vMemMarket(0), IntrabarPersist vMemStock(0);
Var: IntrabarPersist vWaitBuyBack(False), IntrabarPersist vBottomTracking(999999), IntrabarPersist vOldEntryPrice(0);
Var: IntrabarPersist vLastExitPrice(0), IntrabarPersist vLastExitReasonType(0);

vRefPrice = GetField("參考價", "D", Default := 0);   
If vRefPrice = 0 Then vRefPrice = GetField("Close", "D")[1]; 
  
// ========================================================     
// 3. 換日記憶重置與環境評估
// ========================================================     
If IsFirstCall("Date") Then Begin // BE_100
    vTradesToday = 0; vLastExitBar = -999; vLastAlertStr = ""; vFirstSignalTime = 0; vFirstSignalPrice = 0;    
    vRejectAlertPrinted = False; vIntervalHigh = 0; vIntervalLow = 99999; vFirstSignalClose = 0; vFirstSignalLow = 0;    
    vMorningLow = 99999; vDayLow = 99999; vWaitTime = 090000; vMorningHigh = 0; 
    vWaitBuyBack = False; vBottomTracking = 999999; vOldEntryPrice = 0; vLastExitReasonType = 0; 
    vDailyPosReported = False; vSurgeMaxPrice = 0; vHighestScoreToday = 0;
    vTrackDayHigh = High; vTrackDayHighTime = Time; vTrackDayLow = Low; vTrackDayLowTime = Time;
  
    vAmpSum = 0;    
    For j = 1 to pVolDays Begin 
        If GetField("Close", "D")[j+1] > 0 Then 
            vAmpSum = vAmpSum + ((GetField("High", "D")[j] - GetField("Low", "D")[j]) / GetField("Close", "D")[j+1] * 100);
    End; 
    If pVolDays > 0 Then vNDayAmp = vAmpSum / pVolDays Else vNDayAmp = 0;    
  
    If pTradeStyle = 1 Then Begin 
        vAutoDailyTest = True; vS19 = "強制波段(看日均)";  
    End 
    Else If pTradeStyle = 2 Then Begin 
        vAutoDailyTest = False; vS19 = "強制當沖(看分均)";  
    End 
    Else Begin 
        initMA20 = Average(GetField("Close", "D"), 20);  
        If initMA20 > 0 Then initBias = (GetField("Close", "D")[1] - initMA20) / initMA20 * 100 Else initBias = 0;  
          
        If initBias > 8.0 or vNDayAmp >= 6.0 Then Begin 
            vAutoDailyTest = False; vS19 = "AI判定:當沖(避險打短)";  
        End 
        Else Begin 
            vAutoDailyTest = True;  vS19 = "AI判定:波段(趨勢穩健)";  
        End; 
    End; 
  
    // 【更新狀態 6】
    If pStrategyMode = 1 Then vS1 = "標準" Else If pStrategyMode = 2 Then vS1 = "多頭" Else If pStrategyMode = 3 Then vS1 = "糾結" Else If pStrategyMode = 4 Then vS1 = "大戶護盤" Else If pStrategyMode = 6 Then vS1 = "多頭+開盤結構" Else vS1 = "不限制(開盤趨勢)";     

    If pCatchUpMode = 1 Then vS2 = "無限制" Else If pCatchUpMode = 2 Then vS2 = "區間智慧K" Else If pCatchUpMode = 4 Then vS2 = "MACD縮腳" Else vS2 = "放棄";    
    If pAutoCloseDT Then vS3 = "清倉" Else vS3 = "留倉";    
    If pAutoSellDyn Then vS8 = "自動賣" Else vS8 = "僅警示";    
    If pMomentum = 1 Then vS14 = "紅K" Else vS14 = "過昨收";    
    If pNoLossExit Then vS22 = "虧損死不退場" Else vS22 = "正常停損";    
    If pMAType = 1 Then vSMAType = "短E長S" Else If pMAType = 2 Then vSMAType = "全EMA" Else If pMAType = 3 Then vSMAType = "全WMA" Else If pMAType = 4 Then vSMAType = "全SMA" Else vSMAType = "全RMA";    
    If pUseTVLogic Then vSTVLogic = "開啟" Else vSTVLogic = "關閉";    
    
    If vRefPrice > 0 Then Begin 
        If pGapMode = 1 Then vGapLimit = pFixedGap     
        Else Begin 
            If GetField("Close", "D")[2] > 0 and GetField("Close", "D")[3] > 0 Then Begin 
                vGapLimit = (((GetField("High", "D")[1] - GetField("Low", "D")[1]) / GetField("Close", "D")[2]) + ((GetField("High", "D")[2] - GetField("Low", "D")[2]) / GetField("Close", "D")[3])) / 2 * 100 * pDynGapMult;    
            End 
            Else vGapLimit = pFixedGap;     
            If vGapLimit < 1.5 Then vGapLimit = 1.5; If vGapLimit > 6.0 Then vGapLimit = 6.0;    
        End; 
        vGapPrice = vRefPrice * (1 + (vGapLimit / 100.0));    
        If pGapMode = 1 Then vS15 = "固定(" + NumToStr(vGapLimit, 1) + "%)" Else vS15 = "動態(" + NumToStr(vGapLimit, 1) + "%)";    
    End 
    Else Begin 
        vGapLimit = 999.0; vS15 = "防呆(無限制)";  
    End; 
    
    If vAutoDailyTest = True Then vBreakoutPriceStr = " |突破:日均線" Else vBreakoutPriceStr = " |突破:分K均線";    
    If pStrictBreak Then vS12 = "嚴格秒砍" Else vS12 = "容忍" + NumToStr(pBreakTolerance, 1) + "%";    
    vSMinProfit = NumToStr(pMinProfit, 1) + "%";    
    
    If pAutoGearMode = 1 Then vSGearStr = "股價位階(5檔)" Else vSGearStr = NumToStr(pVolDays, 0) + "日震幅(" + NumToStr(vNDayAmp, 2) + "%)";    
    If pUseChipsHold Then vSChips = "開啟" Else vSChips = "關閉";  
    
    vCurrentAlertStr = Symbol + "庫存:" + numToStr(filledAtBroker ,0) + " [自檢] 09:" + vS1 + " |10:" + vS2 + " |14:" + vS19 + vBreakoutPriceStr     
                     + " |21:" + NumToStr(pTargetProfit, 1) + "% |30:" + vSMinProfit + " |32:" + vS12 + " |35:" + vS14 + " |36:" + vS15 + " |均線:" + vSMAType + " |共振:" + vSTVLogic;    
    Print(NumToStr(Date, 0), NumToStr(Time, 0), vCurrentAlertStr);    
    
    vNeededCap = Open * 1000 * pTradeQty;    
    Print(NumToStr(Date, 0), NumToStr(Time, 0), Symbol, " [極速引擎啟動] Z[排檔]:", vSGearStr, " | D[預算]:", NumToStr(vNeededCap/10000, 2), "萬 / 0-A[總預算]:", NumToStr(pTotalCapital, 0), "萬");    
End; // BE_100

If Time >= 090000 and Time <= 132900 Then Begin 
    If High > vTrackDayHigh Then Begin vTrackDayHigh = High; vTrackDayHighTime = Time; End; 
    If Low < vTrackDayLow Then Begin vTrackDayLow = Low; vTrackDayLowTime = Time; End; 
End; 

vTrackStr = " | DayH=" + NumToStr(vTrackDayHigh, 2) + " | DayL=" + NumToStr(vTrackDayLow, 2);

// ========================================================     
// 4. 大戶指標與大趨勢 (環境偵測)
// ========================================================     
If CurrentTime >= 090000 and CurrentTime <= 134500 Then Begin 
    vBigPlayerNetBuy = (GetField("買進特大單量", "D", default:=0) + GetField("買進大單量", "D", default:=0)) - (GetField("賣出特大單量", "D", default:=0) + GetField("賣出大單量", "D", default:=0)); 
    vDailyVolume = GetField("Volume", "D");
    If vDailyVolume > 0 Then vBigPlayerRatio = (vBigPlayerNetBuy / vDailyVolume) * 100.0 Else vBigPlayerRatio = 0;
    If pUseChipsHold and ((vBigPlayerRatio > 3.0 and vBigPlayerNetBuy > 150) or (vBigPlayerNetBuy > 1500)) Then vIsChipProtect = True Else vIsChipProtect = False;
End Else Begin vBigPlayerNetBuy = 0; vIsChipProtect = False; End; 

If pMAType = 1 or pMAType = 4 Then Begin 
    vDailyMA5 = Average(GetField("Close", "D"), 5); vDailyMA10 = Average(GetField("Close", "D"), 10); vDailyMA20 = Average(GetField("Close", "D"), 20);     
End 
Else If pMAType = 2 Then Begin 
    vDailyMA5 = xf_EMA("D", GetField("Close", "D"), 5); vDailyMA10 = xf_EMA("D", GetField("Close", "D"), 10); vDailyMA20 = xf_EMA("D", GetField("Close", "D"), 20);    
End 
Else If pMAType = 3 Then Begin 
    vDailyMA5 = WMA( GetField("Close", "D"), 5); vDailyMA10 = WMA( GetField("Close", "D"), 10); vDailyMA20 = WMA(GetField("Close", "D"), 20);    
End 
Else If pMAType = 5 Then Begin 
    vDailyMA5 = xf_EMA("D", GetField("Close", "D"), 9); vDailyMA10 = xf_EMA("D", GetField("Close", "D"), 19); vDailyMA20 = xf_EMA("D", GetField("Close", "D"), 39);     
End; 
    
dMaxMA = MaxList(vDailyMA5, vDailyMA10, vDailyMA20); dMinMA = MinList(vDailyMA5, vDailyMA10, vDailyMA20);     
If dMinMA > 0 and (dMaxMA / dMinMA) <= 1.03 Then vTrendText = "[糾結]" Else If vDailyMA5 > vDailyMA10 and vDailyMA10 > vDailyMA20 Then vTrendText = "[多頭]" Else vTrendText = "[標準]";     
If vDailyMA20 <= 0 Then Return;     
  
// 【已新增模式 6 的日K判斷：與模式2完全相同】
If pStrategyMode = 1 Then vIsDailyBull = GetField("Close", "D") > vDailyMA20     
Else If pStrategyMode = 2 Then vIsDailyBull = GetField("Close", "D") > vDailyMA20 and vDailyMA5 > vDailyMA10 and vDailyMA10 > vDailyMA20     
Else If pStrategyMode = 3 Then vIsDailyBull = GetField("Close", "D") > vDailyMA20 and (dMaxMA / dMinMA) <= 1.03
Else If pStrategyMode = 4 Then vIsDailyBull = GetField("Close", "D") > vDailyMA20 and ((vBigPlayerRatio > 3.0 and vBigPlayerNetBuy > 150) or (vBigPlayerNetBuy > 1500))     
Else If pStrategyMode = 6 Then vIsDailyBull = GetField("Close", "D") > vDailyMA20 and vDailyMA5 > vDailyMA10 and vDailyMA10 > vDailyMA20 
Else vIsDailyBull = True; // 這是模式 5

vDayOpen = GetField("Open", "D");
If vRefPrice > 0 Then Begin 
    If vDayOpen < vRefPrice Then vTrendEntry = (Close < vTrackDayHigh and Close > Close[1])
    Else If vDayOpen > vRefPrice Then vTrendEntry = (Low < vTrackDayHigh and Close > Close[1])
    Else vTrendEntry = (Close > Close[1]);
    
    vTodayRisePct = (Close - vRefPrice) / vRefPrice * 100; vDailyAmp = (GetField("High", "D") - GetField("Low", "D")) / vRefPrice * 100;    
End Else Begin vTrendEntry = True; vTodayRisePct = 0; vDailyAmp = 0; End; 

vIsDailyBull = vIsDailyBull and vTrendEntry;
If pMomentum = 1 Then vIsMoney = Close > vRefPrice and Close >= Open Else vIsMoney = Close > vRefPrice;    
If vDailyMA20 > 0 Then vBias = (Close - vDailyMA20) / vDailyMA20 * 100 Else vBias = 0;     
     
// ========================================================     
// 5. 輕量化核心短線掃描 (僅鎖定 5分K)
// ========================================================     
If pMAType = 1 or pMAType = 2 Then Begin 
    ema5 = xfMin_EMA("5", GetField("Close", "5"), 20); ma5_5 = xfMin_EMA("5", GetField("Close", "5"), 5);
End 
Else If pMAType = 3 Then Begin 
    ema5 = WMA(GetField("Close", "5"), 20); ma5_5 = WMA(GetField("Close", "5"), 5);
End 
Else If pMAType = 4 Then Begin 
    ema5 = Average(GetField("Close", "5"), 20); ma5_5 = Average(GetField("Close", "5"), 5);
End 
Else If pMAType = 5 Then Begin 
    ema5 = xfMin_EMA("5", GetField("Close", "5"), 39); ma5_5 = xfMin_EMA("5", GetField("Close", "5"), 9);
End; 

If ema5 <= 0 Then Return;    
    
MACD(Close, 12, 26, 9, macdValue1m, macdMA1m, macdOsc1m);  
xfMin_MACD("5", GetField("Close", "5"), 12, 26, 9, vM_Val5, vM_MA5, vM_Osc5);  
  
If ema5 > 0 Then vScore5 = (GetField("Close", "5") - ema5) / ema5 Else vScore5 = 0;     

vMaxScore = vScore5; 
If pAutoBonus Then vRealBonusMult = MinList(50.0 + (vNDayAmp * 20.0), 300.0) Else vRealBonusMult = pBonusMult;   
If vMaxScore > vHighestScoreToday Then vHighestScoreToday = vMaxScore;

vFinalScore = vMaxScore; 
If GetField("漲停價", "D") > 0 and Close >= GetField("漲停價", "D") * 0.99 Then Begin 
    If vFinalScore < vHighestScoreToday Then vFinalScore = vHighestScoreToday; 
End; 

If vAutoDailyTest = True Then vCurrentBaseTarget = pBaseTargetSW Else vCurrentBaseTarget = pBaseTargetDT;
vDynamicTarget = MinList(vCurrentBaseTarget + (vFinalScore * vRealBonusMult), pTargetProfit);

vIsBerserk = (vNDayAmp >= 8.5 or (vRefPrice > 0 and GetField("Open", "D") >= vRefPrice * 1.03));
macdOsc5m = vM_Osc5;

If vIsBerserk = True Then Begin 
    vIsOscBull = True; vIsOscShrink = True; 
End Else Begin 
    vIsOscBull = (macdOsc5m > 0) and (macdOsc1m > macdOsc1m[1]);    
    vIsOscShrink = (macdOsc5m < 0 and macdOsc5m > macdOsc5m[1]) and (macdOsc1m > macdOsc1m[1]);    
End; 
    
If pUseTVLogic Then Begin 
    tvIsDailyResonance = (GetField("Close", "D") > vDailyMA20) and (vDailyMA5 > vDailyMA20);    
    tv5mMA20 = ema5; tv5mMA5 = ma5_5;    
    tvIs5mResonance = (GetField("Close", "5") > tv5mMA20) and (tv5mMA5 > tv5mMA20);    
    tvPerfectResonance = tvIsDailyResonance and tvIs5mResonance;    
End Else tvPerfectResonance = True; 
    
If vAutoDailyTest Then Begin 
    vIsTFBull = True; vIsTFBreak = Close < vDailyMA20; vCrossPrice = vDailyMA20; vCond1 = True; vCond2 = True;        
End Else Begin 
    vChipCondition = True; vCrossPrice = ema5; 
    vIsTFBull = GetField("Close", "5") > vCrossPrice and GetField("Close", "5") > ma5_5; 
    vIsTFBreak = GetField("Close", "5") < vCrossPrice;        
    vCond1 = True; 
    vCond2 = ma5_5 Crosses Above ema5;        
End; 
    
If Close < 10 Then vTickSize = 0.01 Else If Close < 50 Then vTickSize = 0.05 Else If Close < 100 Then vTickSize = 0.1    
Else If Close < 500 Then vTickSize = 0.5 Else If Close < 1000 Then vTickSize = 1 Else vTickSize = 5;    
    
vUpLimit = GetField("漲停價", "D"); If vUpLimit = 0 Then vUpLimit = GetField("Close", "D")[1] * 1.1;     
If vUpLimit > 0 Then Begin vTicksToLimit = (vUpLimit - Close) / vTickSize; vSpacePct = (vUpLimit - Close) / Close * 100; End; 
    
vNeededCap = Close * 1000 * pTradeQty; vTickYield = (vTickSize / Close) * 100;    
If pUseTickPriority = True Then Begin 
    If vTickYield >= 0.45 Then vPrioritySeconds = 0 Else If vTickYield >= 0.20 Then vPrioritySeconds = 3 Else vPrioritySeconds = 8;          
End Else vPrioritySeconds = 0;                
    
If vNeededCap > (pTotalCapital * 10000) Then Begin 
    vSensitivityMode = "【財務防禦】"; vAutoFilter = (macdOsc5m > macdOsc5m[1] and macdOsc5m[1] > macdOsc5m[2]);        
End Else If pAutoGearMode = 1 Then Begin 
    If Close >= 500 Then Begin vSensitivityMode = "【高價敏銳】"; vAutoFilter = (macdOsc5m > 0); End 
    Else If Close >= 100 Then Begin vSensitivityMode = "【中價穩健】"; vAutoFilter = (macdOsc5m > macdOsc5m[1]); End 
    Else Begin vSensitivityMode = "【低價防禦】"; vAutoFilter = (macdOsc5m > macdOsc5m[1] and macdOsc5m[1] > macdOsc5m[2]); End; 
End Else Begin 
    If vNDayAmp < 3.0 Then Begin vSensitivityMode = "【冷靜微敏】"; vAutoFilter = (macdOsc5m > 0); End 
    Else If vNDayAmp < 6.0 Then Begin vSensitivityMode = "【正常穩健】"; vAutoFilter = (macdOsc5m > macdOsc5m[1]); End 
    Else Begin vSensitivityMode = "【瘋狗防禦】"; vAutoFilter = (macdOsc5m > macdOsc5m[1] and macdOsc5m[1] > macdOsc5m[2]); End; 
End; 

If vIsBerserk = True and vNeededCap <=(pTotalCapital * 10000) Then Begin vSensitivityMode = "【瘋狗卸甲】"; vAutoFilter = True; End; 
If vIsBerserk = True Then vBerserkStr = "True" Else vBerserkStr = "False";

// ========================================================     
// 6. 進場指揮所 (新增結構條件獨立判斷)
// ========================================================     
// (1) 判斷冷卻時間
If pAntiGapDown = True Then Begin 
    If Time = 090000 or (Date <> Date[1]) Then Begin 
        If vTodayRisePct <= -2.0 Then vWaitTime = 090200 Else If vTodayRisePct <= 0 Then vWaitTime = 090100 Else If vTodayRisePct < 2.0 Then vWaitTime = 090100 Else If vTodayRisePct < 4.0 Then vWaitTime = 090300 Else vWaitTime = 090500;     
    End; 
End Else Begin 
    // 不啟用冷卻機制時，時間設為開盤，但不跳過高低點紀錄
    If Time = 090000 or (Date <> Date[1]) Then vWaitTime = 090000;
End; 

// (2) 結構運算與條件放行
If Time <= vWaitTime Then Begin 
    If High > vMorningHigh Then vMorningHigh = High; // 紀錄早盤高點，供轉強突破判斷
    If Low < vMorningLow Then vMorningLow = Low; 
    vDayLow = vMorningLow; 
    vIsTrendReversal = False; 
    vIsDipBuy = False; 
    vAntiGapCond = False; // 冷卻期內絕不放行
End Else Begin 
    If Low < vDayLow Then vDayLow = Low;    
    
    // 【情境A】開低走低 -> 回檔確認買進 (Trend Reversal)
    If vDayOpen < vRefPrice and Close crosses above ma5_5 and Close > vMorningHigh Then 
        vIsTrendReversal = True
    Else 
        vIsTrendReversal = False;
        
    // 【情境B】開高走高 -> 回檔確認買進 (Buy the Dip)
    If vDayOpen > vRefPrice and Low > vDayOpen and Close > Close[1] Then 
        vIsDipBuy = True
    Else 
        vIsDipBuy = False;
        
    // (3) 根據外部參數決定 vAntiGapCond 是否放行
    // 【修改處】如果選了模式 5、模式 6，或是啟用了防開高走低，則必須嚴格等待結構確認才放行
    If pStrategyMode = 5 or pStrategyMode = 6 or pAntiGapDown = True Then Begin 
        If vIsTrendReversal = True or vIsDipBuy = True Then 
            vAntiGapCond = True 
        Else 
            vAntiGapCond = False;    
    End Else Begin 
        // 如果是模式 1~4 且沒開防高低限制，只要過了冷卻期就放行
        vAntiGapCond = True; 
    End;
End; 
    
Var: vFinalOscBull(False); If vIsBerserk = True Then vFinalOscBull = True Else vFinalOscBull = vIsOscBull; 

vIsDayTradeSignal = vIsDailyBull and vIsMoney and vIsTFBull and vFinalOscBull and (vTodayRisePct <= vGapLimit) and (vBias <= pMaxBias) and (Close >= pMinPrice and Close <= pMaxPrice) and tvPerfectResonance and vAntiGapCond and vAutoFilter;    
vIsSwingSignal = vIsDailyBull and vCond1 and vCond2 and vFinalOscBull and (vTodayRisePct <= vGapLimit) and (vBias <= pMaxBias) and (Close >= pMinPrice and Close <= pMaxPrice) and tvPerfectResonance and vAntiGapCond and vAutoFilter; 
 
If Position = 0 and vFirstSignalTime > 0 Then Begin 
    If Close < ema5 or Close < vFirstSignalLow Then Begin 
        vFirstSignalTime = 0; vFirstSignalPrice = 0; vFirstSignalClose = 0; vFirstSignalLow = 0; vIntervalHigh = 0; vIntervalLow = 99999; vRejectAlertPrinted = False; vSurgeMaxPrice = 0; 
    End; 
End; 

If (vIsSwingSignal or vIsDayTradeSignal) and vFirstSignalPrice = 0 Then Begin 
    vFirstSignalPrice = Close; vFirstSignalTime = Time; vFirstSignalClose = Close; vFirstSignalLow = Low; vIntervalHigh = Close; vIntervalLow = Low;    
End; 
    
If vFirstSignalPrice > 0 Then Begin 
    If Close > vIntervalHigh Then vIntervalHigh = Close; If Low < vIntervalLow Then vIntervalLow = Low;    
End; 
    
// ========================================================    
// 8. 訊號執行與排隊 
// ======================================================== 
vRealPos = FilledAtBroker;
If Position = 0 and (pUseBrokerPosCtrl = False or (vRealPos + pTradeQty) <= pMaxBrokerPos) Then Begin 

    // 打勾低接機制
    If vWaitBuyBack = True Then Begin 
        If Low < vBottomTracking Then vBottomTracking = Low; 
        If vLastExitBar = -999 or (CurrentBar - vLastExitBar) >= pCoolDownBars Then Begin 
            If (Close < vOldEntryPrice) or (Close <= vLastExitPrice * (1 - pBandPullbackPct / 100)) Then Begin 
                If (Close - vBottomTracking >= pBuyBackBounceTicks * vTickSize) or ((Close - vBottomTracking) / vBottomTracking * 100 >= pBuyBackBouncePct) Then Begin 
                    SetPosition(pTradeQty, addSpread(Close,1), label:="【探底反彈買回】");
                    vOldEntryPrice = Close; vEntryType = 1; vEntryDate = Date; vInitStop = 0; vTradesToday = vTradesToday + 1; vTriggerPrice = Close; vLockedTarget = vDynamicTarget; vDynAlerted = False; vIsFilledPrinted = False; vSurgeMaxPrice = Close; vWaitBuyBack = False; 
                    Return;
                End; 
            End; 
        End; 
    End; 
        
    vAllowEntry = True; vRejectReason = "";    
    If vTradesToday >= pMaxTrades Then Begin vAllowEntry = False; vRejectReason = "次數上限"; End; 
    If vNeededCap > (pTotalCapital*10000 * 1.5) Then Begin vAllowEntry = False; vRejectReason = "資金超限"; End; 
    If vLastExitBar <> -999 and (CurrentBar - vLastExitBar) < pCoolDownBars Then Begin vAllowEntry = False; vRejectReason = "冷卻中"; End; 
    If vLastExitReasonType = 1 And vLastExitPrice > 0 and AbsValue(Close - vLastExitPrice) / vLastExitPrice * 100.0 < pReEntryGapPct Then Begin vAllowEntry = False; vRejectReason = "避開區間"; End; 
    
    If vFirstSignalTime > 0 and Time > vFirstSignalTime Then Begin 
        If pCatchUpMode = 2 Then Begin 
            If vIntervalHigh > vIntervalLow Then vIntRatio = (Close - vIntervalLow) / (vIntervalHigh - vIntervalLow) Else vIntRatio = 0.5;    
            vDynamicCeiling = vFirstSignalLow + ((vFirstSignalClose - vFirstSignalLow) * vIntRatio);    
            If Close > vDynamicCeiling Then Begin vAllowEntry = False; vRejectReason = "位階過高"; End; 
            If Close < ema5 Then Begin vAllowEntry = False; vRejectReason = "跌破均線"; End; 
        End Else If pCatchUpMode = 3 Then Begin vAllowEntry = False; vRejectReason = "嚴格放棄";
        End Else If pCatchUpMode = 4 Then Begin 
            vDynamicCeiling = vFirstSignalClose * 1.005;        
            If (vIsOscShrink = False) and (vIsOscBull = False) Then Begin vAllowEntry = False; vRejectReason = "MACD未縮腳"; End 
            Else If Close > vDynamicCeiling Then Begin vAllowEntry = False; vRejectReason = "不追高"; End; 
            If Close < ema5 Then Begin vAllowEntry = False; vRejectReason = "跌破均線"; End; 
        End; 
    End; 
    
    If (vLastExitReasonType = -1) and (Date = GetFieldDate("Date")) Then Begin vAllowEntry = False; vRejectReason = "今日已停損"; End; 
    If pUseTVLogic and tvPerfectResonance = False Then Begin vAllowEntry = False; vRejectReason = "共振消失"; End; 
    If vIsSwingSignal = False and vIsDayTradeSignal = False Then vAllowEntry = False; 
    
    If vAllowEntry = True Then Begin 
        Condition99 = False;    
        If vPrioritySeconds = 0 Then Condition99 = True    
        Else Begin 
            If vSignalFired = False Then Begin vSignalFired = True; vSignalFireTime = CurrentTime; End; 
            If vSignalFired = True and TimeDiff(CurrentTime, vSignalFireTime, "S") >= vPrioritySeconds Then Begin Condition99 = True; vSignalFired = False; End; 
        End; 

        If Condition99 = True Then Begin 
            
            // --- 【波段進場判斷】 ---
            If vIsSwingSignal and Position[1] = 0 Then Begin 
                If vIsTrendReversal Then 
                    SetPosition(pTradeQty, addSpread(Close, 1), label:="【波段轉強】")
                Else If vIsDipBuy Then 
                    SetPosition(pTradeQty, addSpread(Close, 1), label:="【波段回檔】")
                Else 
                    SetPosition(pTradeQty, addSpread(Close, 1), label:="波段進場");
                    
                vEntryType = 2; vEntryDate = Date; vInitStop = 0; vTradesToday = vTradesToday + 1; vTriggerPrice = Close; vLockedTarget = vDynamicTarget; vDynAlerted = False; vIsFilledPrinted = False; vSurgeMaxPrice = Close;        
                Print(NumToStr(Date, 0), NumToStr(Time, 0), Symbol, " [波段進場] ", vSensitivityMode, " 價:", NumToStr(Close, 2), " 目標:", NumToStr(vDynamicTarget, 2), "%");
            End 
            
            // --- 【當沖進場判斷】 ---
            Else If vIsDayTradeSignal and Position[1] = 0 Then Begin 
                If vIsTrendReversal Then 
                    SetPosition(pTradeQty, addSpread(Close, 1), label:="【當沖轉強】")
                Else If vIsDipBuy Then 
                    SetPosition(pTradeQty, addSpread(Close, 1), label:="【當沖回檔】")
                Else 
                    SetPosition(pTradeQty, addSpread(Close, 1), label:="當沖進場");
                    
                vEntryType = 1; vEntryDate = Date; vInitStop = 0; vTradesToday = vTradesToday + 1; vTriggerPrice = Close; vLockedTarget = vDynamicTarget; vDynAlerted = False; vIsFilledPrinted = False; vSurgeMaxPrice = Close;        
                Print(NumToStr(Date, 0), NumToStr(Time, 0), Symbol, " [當沖進場] ", vSensitivityMode, " 價:", NumToStr(Close, 2), " 目標:", NumToStr(vDynamicTarget, 2), "%");
            End; 
        End; 
    End Else Begin 
        If vSignalFired = True Then vSignalFired = False;        
        If vRejectAlertPrinted = False and (vIsSwingSignal or vIsDayTradeSignal) Then Begin 
            vRejectAlertPrinted = True;        
        End; 
    End; 
End; 
    
// ========================================================     
// 7. 出場與防護指令
// ========================================================     
If Position > 0 Then Begin 
    If vEntryType = 0 and FilledAtBroker > 0 and FilledAvgPrice = 0 Then Return; 

    If vEntryType = 0 and FilledAvgPrice > 0 Then Begin 
        vEntryType = 2; vTriggerPrice = FilledAvgPrice; 
        vLockedTarget = MinList(Iff(vAutoDailyTest, pBaseTargetSW, pBaseTargetDT) + (vHighestScoreToday * vRealBonusMult), pTargetProfit);
        vIsFilledPrinted = True; vSurgeMaxPrice = Close; 
    End; 

    If vLockedTarget = 0 Then vLockedTarget = pTargetProfit;        
   
    If vInitStop = 0 and FilledAvgPrice > 0 Then Begin 
        vInitStop = FilledAvgPrice * (1 - (pStopLoss / 100.0));   
        vHighSinceEntry = MaxList(Close, FilledAvgPrice);  
        vRealMinProfitPrice = FilledAvgPrice * (1 + (pMinProfit / 100.0)); 
        vRealTargetPrice = FilledAvgPrice * (1 + (vLockedTarget / 100.0)); 
        vTickTargetPrice = vRealTargetPrice; vTickMinProfit = vRealMinProfitPrice;
    End; 
// ★ 補回：庫存戰情與預計停利警示列印 ★
    If vDailyPosReported = False and FilledAvgPrice > 0 and vTickTargetPrice > 0 Then Begin 
        vDailyPosReported = True; 
        If vIsFilledPrinted = True Then Begin 
            vCurrentAlertStr = Symbol + " [庫存戰情] 均價:" + NumToStr(FilledAvgPrice, 2) + " | 預計停利:" + NumToStr(vRealTargetPrice, 2) + " | 死亡底線:" + NumToStr(vInitStop, 2);
            Print(NumToStr(Date, 0), NumToStr(Time, 0), vCurrentAlertStr);
            
            // 跳出視窗警示
            Alert(Symbol + " 庫存均價:" + NumToStr(FilledAvgPrice, 2) 
                         + " 今日預計停利:" + NumToStr(vTickTargetPrice, 2) 
                         + " 預計獲利:" + NumToStr((vTickTargetPrice - FilledAvgPrice) / FilledAvgPrice * 100, 2) + "%");
        End; 
    End; 

    // ★ 補回：進場成交回報與目標列印 ★
    If FilledAvgPrice > 0 and vIsFilledPrinted = False and vTriggerPrice > 0 Then Begin 
        vIsFilledPrinted = True;     
        vCurrentAlertStr = Symbol + " [成交回報] 均價:" + NumToStr(FilledAvgPrice, 2) + " | 觸發價:" + NumToStr(vTriggerPrice, 2) + " | 目標停利:" + NumToStr(vRealTargetPrice, 2) + " | 移停啟動:" + NumToStr(vRealMinProfitPrice, 2) + " | 死亡線:" + NumToStr(vInitStop, 2);     
        If vCurrentAlertStr <> vLastAlertStr Then Begin Print(NumToStr(Date, 0), NumToStr(Time, 0), vCurrentAlertStr); vLastAlertStr = vCurrentAlertStr; End;
    End; 
    
    If vInitStop > 0 Then Begin 
        vProfitPct = (Close - FilledAvgPrice) / FilledAvgPrice * 100;     
        If Close > vHighSinceEntry Then vHighSinceEntry = Close;     
              
        sumTR = 0;     
        For i = 0 to 13 Begin dTR = MaxList(GetField("High", "D")[i] - GetField("Low", "D")[i], AbsValue(GetField("High", "D")[i] - GetField("Close", "D")[i+1]), AbsValue(GetField("Low", "D")[i] - GetField("Close", "D")[i+1])); sumTR = sumTR + dTR; End; 
        vMyATR = sumTR / 14.0; vDynStop = MaxList(vHighSinceEntry - (vMyATR * pATRMult), vInitStop);     
        
        vRecentLow = Lowest(Low, pSurgeBars); 
        If (vRecentLow > 0) and ((Close - vRecentLow) / vRecentLow) >= (pSurgePct / 100.0) Then vCondSurge = True;

        If Time > 090500 and Time < 132000 and GetField("TickGroup", "Tick") = -1 Then Begin vSurgeMaxPrice = Close; vHaltImmunityTime = CurrentTime; End;
		
        If vCondSurge and Close > vSurgeMaxPrice Then vSurgeMaxPrice = Close; 
        vCondSurgeProfit = Close >= FilledAvgPrice * (1 + (pMinSurgeProfit / 100.0));

        If vSurgeMaxPrice < 10 Then vSurgeTickSize = 0.01 Else If vSurgeMaxPrice < 50 Then vSurgeTickSize = 0.05 Else If vSurgeMaxPrice < 100 Then vSurgeTickSize = 0.1 Else If vSurgeMaxPrice < 500 Then vSurgeTickSize = 0.5 Else If vSurgeMaxPrice < 1000 Then vSurgeTickSize = 1 Else vSurgeTickSize = 5;

        If vSurgeMaxPrice > 0 Then Begin 
            If vHaltImmunityTime > 0 and TimeDiff(CurrentTime, vHaltImmunityTime, "S") <= 15 Then vCondPullback = False
            Else vCondPullback = (vSurgeMaxPrice - Close >= pPullbackTicks * vSurgeTickSize) and ((vSurgeMaxPrice - Close) / vSurgeMaxPrice >= (pPullbackPct / 100.0));
		End Else vCondPullback = False;
              
        If (vLockedTarget > 0) and (Close >= vTickTargetPrice) Then Begin 
            If pAutoSellDyn Then Begin SetPosition(0, close, label:="達標停利"); vLastExitBar = CurrentBar; vLastExitReasonType = 1; vLastExitPrice = Close;  If pEnableBuyBack Then Begin vWaitBuyBack = True; vBottomTracking = Low; vOldEntryPrice = FilledAvgPrice; End; End Else vDynAlerted = True; 
        End 
        Else If ((vTodayRisePct >= 8.5) or (vDailyAmp >= 10.0)) and (Close >= vTickMinProfit) Then Begin 
            If pAutoSellDyn Then Begin SetPosition(0, close, label:="巨震鎖利"); vLastExitBar = CurrentBar; vLastExitReasonType = 1; vLastExitPrice = Close; If pEnableBuyBack Then Begin vWaitBuyBack = True; vBottomTracking = Low; vOldEntryPrice = FilledAvgPrice; End; End; 
        End 
        Else If (vEntryType = 1) and (pAutoCloseDT = True) and (Time >= 132000) and (pMasterNoLossSwitch = False or vProfitPct >= 0) Then Begin 
            SetPosition(0, close, label:="自動清倉"); vLastExitBar = CurrentBar; vLastExitReasonType = 1; vLastExitPrice = Close;  
        End 
        Else If (vEntryType = 2) and (Date = vEntryDate) and (vProfitPct >= 5.0) Then Begin 
            SetPosition(0, close, label:="首日暴利"); vLastExitBar = CurrentBar; vLastExitReasonType = 1; vLastExitPrice = Close;  If pEnableBuyBack Then Begin vWaitBuyBack = True; vBottomTracking = Low; vOldEntryPrice = FilledAvgPrice; End; 
        End 
        Else If (vEntryType = 2) and (vProfitPct >= pTargetProfit) Then Begin 
            SetPosition(0, close, label:="波段停利"); vLastExitBar = CurrentBar; vLastExitReasonType = 1; vLastExitPrice = Close;  If pEnableBuyBack Then Begin vWaitBuyBack = True; vBottomTracking = Low; vOldEntryPrice = FilledAvgPrice; End; 
        End 
        Else If (vEntryType = 1) and (vHighSinceEntry >= FilledAvgPrice * 1.03) Then Begin 
            vTrailStopPrice = vHighSinceEntry - (vMyATR * 0.5);  
            If (Close >= vTickMinProfit) and (Close <= vTrailStopPrice) Then Begin 
                SetPosition(0, close, label:="高檔鎖利"); vLastExitBar = CurrentBar; vLastExitReasonType = 1; vLastExitPrice = Close; If pEnableBuyBack Then Begin vWaitBuyBack = True; vBottomTracking = Low; vOldEntryPrice = FilledAvgPrice; End; 
            End; 
        End 
        Else If vCondSurge and vCondSurgeProfit and vCondPullback Then Begin 
            If pAutoSellDyn Then Begin SetPosition(0, Close, label:="急拉回檔"); vLastExitBar = CurrentBar; vLastExitReasonType = 1; vLastExitPrice = Close; If pEnableBuyBack Then Begin vWaitBuyBack = True; vBottomTracking = Low; vOldEntryPrice = FilledAvgPrice; End; End Else vDynAlerted = True; 
        End 
        Else If vIsTFBreak Then Begin 
            If vIsChipProtect Then Begin 
                // 大戶護盤，不動作
            End Else Begin 
                If close >= vTickMinProfit Then Begin 
                    SetPosition(0, close, label:="破線停利"); vLastExitBar = CurrentBar; vLastExitReasonType = 1; vLastExitPrice = Close;  
                End Else If pStrictBreak = True and (pMasterNoLossSwitch = False or vProfitPct >= 0) Then Begin 
                    SetPosition(0, close, label:="嚴格破線"); vLastExitBar = CurrentBar; vLastExitReasonType = -1; vLastExitPrice = Close;   
                End Else If (pStrictBreak = False) and (Close <= vCrossPrice * (1 - (pBreakTolerance / 100.0))) and (pMasterNoLossSwitch = False or vProfitPct >= 0)  Then Begin 
                    SetPosition(0, close, label:="容忍極限"); vLastExitBar = CurrentBar; vLastExitReasonType = -1; vLastExitPrice = Close;   
                End; 
            End; 
        End 
        Else If (pNoLossExit = False) and (Close <= vInitStop) and (pMasterNoLossSwitch = False or vProfitPct >= 0) Then Begin 
            SetPosition(0, close, label:="保命停損"); vLastExitBar = CurrentBar; vLastExitReasonType = -1; vLastExitPrice = Close;     
        End; 
    End; 
End; 

// ========================================================
If Time = 132900 Then Begin 
    If FilledAvgPrice > 0 Then vFinalProfitPct = (Close - FilledAvgPrice) / FilledAvgPrice * 100.0;
End; 

// 庫存異動通知
If isfirstcall("") and vRealPos <> vRealPos[1] Then alert("【庫存異動】", Symbol, " | 庫存:", NumToStr(vRealPos, 0));
