// ========================================================     
// 【AI 艦隊】 全自動突擊腳本 V7.579 修正版 (全域軌跡 + 動態急拉停利 + 防洗頻完全體 + 動態基底)     
// ========================================================     
     
// 【系統強制設定】要求系統去伺服器下載 8000 根 K 棒資料，確保所有的均線都能算出精準的數值    
SetTotalBar(8000);     
    
// ★ 強制預載各時區原始K棒，徹底消滅跨頻率空值報錯    
// 【機制解析】在 XQ 中，若要跨頻率呼叫資料 (如 1分K 呼叫 日K)，必須預先宣告 SetBarBack，否則執行時會因無足夠資料而報錯中斷。 
SetBarBack(30, "D");   // 滿足 vDailyMA20 與 AI戰略判斷     
SetBarBack(30, "60");  // 滿足 vCond1 (60分K 的 20SMA)     
SetBarBack(120, "30"); // 滿足 xfMin_EMA 30分K的 39EMA (需117根)     
SetBarBack(120, "15"); // 滿足 xfMin_EMA 15分K的 39EMA     
SetBarBack(120, "10"); // 滿足 xfMin_EMA 10分K的 39EMA     
SetBarBack(120, "5");  // 滿足 xfMin_EMA  5分K的 39EMA  
SetBarBack(120, "2");   
SetBarBack(120, "3");  
    
// ========================================================     
// 1. 外部參數設定區 (實戰兵推手冊 V7.579 完全體)
// ========================================================     
// 【第零層：究極凹單與總預算】     
// ========================================================     
Input: pTotalCapital(100, "01[系] 今日總可用資金(萬)");     
// 【實戰兵推手冊】
// 為何設：作為系統的財務天花板，防止自動交易買過頭導致違約交割。
// 改了會怎樣：影響資金濾網。若單筆進場額外超過預算 1.5 倍直接擋單；若單筆額度大於預算，啟動「財務防禦(極穩)」模式。
// 實戰長怎樣：設100萬，碰到千金股(單張100萬起跳)，系統會自動提高 MACD 濾網標準，確認趨勢極度穩健才敢出手。
// 影響代碼處：BE_612 (風控狀態)、BE_704 區段 (擋單邏輯)。

Input: pMasterNoLossSwitch(True, "02[出] 終極凹單模式(帳面虧損絕不出場)", inputkind:=dict(["任何虧損都不出場(True)", True], ["一般依條件(False)", False]));     
// 【實戰兵推手冊】
// 為何設：凌駕於一切技術指標之上的終極「死不認賠」開關。
// 改了會怎樣：若為 True，即使觸發破線或停損，只要帳面獲利(vProfitPct)小於0，系統指令就會被強制攔截沒收。
// 實戰長怎樣：今日主力惡意洗盤，但你判斷「管他的，這檔一定會拉」，打開此開關，系統就會陪你扛到底。
// 影響代碼處：BE_900.6.6.1.1、BE_900.6.13、BE_900.6.13.1、BE_900.6.13.2 (所有停損/破線出場條件)。

Input: pAntiGapDown(True, "03[進] 啟動防開高走低機制須等待冷卻時間", inputkind:=dict(["依開盤漲幅，強制觀望(True)", True], ["不啟用(False)", False]));     
// 【實戰兵推手冊】
// 為何設：防禦早盤「騙線誘多」的動態冷卻器。
// 改了會怎樣：設 False 開盤 09:00:00 秒進；設 True 則依開盤漲幅，強制觀望到 09:01~09:05，確立早盤低點(vMorningLow)。
// 實戰長怎樣：台股跳空開高 3%，系統強制冷卻至 09:03，確認開盤底線沒被跌破才允許進場，防接掉下來的刀子。
// 影響代碼處：BE_616 ~ BE_700.2.1。

Input: pUseBrokerPosCtrl(True, "04[系]真實帳戶庫存上限攔截管控", inputkind:=dict(["限制總數量(True)", True], ["不限制(False)", False]));
Input: pMaxBrokerPos(1, "05[系] 真實帳戶允許最大庫存總數(張/口)");
// 【實戰兵推手冊】
// 為何設：直接與券商「真實庫存」連動的防暴衝機制，體現守法自制的紀律。
// 改了會怎樣：進場前系統會先查帳戶(FilledAtBroker)，若真實庫存已達上限，直接拒絕送單。
// 實戰長怎樣：設上限為 1，即使軟體重開、網路斷線導致系統內部虛擬紀錄歸零，只要帳戶裡還有一張，就絕對不會重複下單。
// 影響代碼處：BE_704 (核心進場閘門)。

// ========================================================     
// 【Z層：自適應股性排檔引擎】     
// ========================================================     
Input: pAutoGearMode(2, "06[進] AI 股性評估方式(決定進場依股價/依N日震幅)", inputkind:=dict(["1.依股價(5檔)", 1], ["2.依N日震幅", 2]));     
Input: pVolDays(5, "07[進] 震幅計算天數(若選2)");     
// 【實戰兵推手冊】
// 為何設：決定 AI 如何評斷股票的「個性」。
// 改了會怎樣：選 1 依照股價級距(低/中/高/千金)分配敏感度；選 2 則根據過去 N 日平均震幅 (vNDayAmp) 判斷。
// 實戰長怎樣：選 2 且天數設 5。若某檔股票近 5 天上下洗盤震幅高達 8%，系統判定為「瘋狗股性」，進場條件自動變嚴；若平穩，則敏銳出手。
// 影響代碼處：BE_100.1、BE_613、BE_614。

Input: pUseTickPriority(True, "08[進] 啟用Tick獲利效率排隊", inputkind:=dict(["高效率秒單(True)", True], ["不啟用(False)", False]));     
// 【實戰兵推手冊】
// 為何設：防滑價與高勝率的「排隊濾網」。
// 改了會怎樣：系統判斷跳動一檔的獲利(TickYield)多寡，獲利空間越厚，等待秒數越短(0秒)；越薄則強迫等待(3秒或8秒)。
// 實戰長怎樣：跳一檔賺 0.5% 的優質標的，訊號一亮直接0秒市價搶；跳一檔賺不到 0.2% 的毛躁標的，強迫排隊8秒，確認動能沒熄火才買。
// 影響代碼處：BE_610、BE_800.6.1 ~ BE_800.6.3.2。

// ========================================================     
// 【第一層：核心戰術切換】     
// ========================================================     
Input: pStrategyMode(1, "@09[進] 濾網大趨勢(日K)進場門檻1-4", inputkind:=dict(["1.過 20MA 就買標準(積極)", 1], ["2.做長波段多頭(穩健)", 2], ["3.糾結(抓盤整突破)", 3], ["4.想跟隨主力大單護盤(突擊)", 4]));     
// 【實戰兵推手冊】
// 為何設：決定日K大趨勢的門檻。
// 改了會怎樣：影響 vIsDailyBull 變數的嚴格度。
// 實戰長怎樣：想抓強勢反彈選 1 (過 20MA 就幹)；想做長波段選 2 (5>10>20 多頭排列才買)；想抓壓縮突破選 3 (均線發散小於3%且突破才買)；想跟隨主力籌碼選 4 (大單淨買超高佔比才買)。
// 影響代碼處：BE_404。

Input: pCatchUpMode(4, "10[進] 錯過「首發突破的訊號點」重啟上車方式1-4", inputkind:=dict(["1.無限制", 1], ["2.區間", 2], ["3.放棄", 3], ["4.MACD低接", 4]));     
// 【實戰兵推手冊】
// 為何設：錯過「第一時間突破點」時，如何補票上車。
// 改了會怎樣：決定訊號發生後的進場容許度。選 4 最智慧。
// 實戰長怎樣：選 4 (MACD縮腳)，即使錯過第一根，只要價格沒過首發高點，且 MACD 綠柱開始縮腳或翻紅，系統就允許補單接回。
// 影響代碼處：BE_800.1 ~ BE_800.1.1.1.1。

Input: pMACDFreqMode(2, "11[進] MACD參考時區大腦總開關", inputkind:=dict(["0.停用", 0], ["1.手動固定", 1], ["2.自動最佳時區", 2]));     
Input: pMACDFixedFreq("5", "12[進] 手動強制作業的 MACD 時區(上方手動時)", inputkind:=dict(["1分鐘", "1"], ["2分鐘", "2"], ["3分鐘", "3"], ["5分鐘", "5"], ["10分鐘", "10"], ["15分鐘", "15"], ["30分鐘", "30"], ["60分鐘", "60"]));     
Input: pTFTarget(2, "13[進] 跨頻率掃描：最佳發動週期鎖定", inputkind:=dict(["1.爆發動能(最大乖離)", 1], ["2.安全起漲(最小正乖離)", 2]));  
// 【實戰兵推手冊】
// 為何設：做為 MACD 多週期共振的戰術指揮中樞，決定系統跨頻率切入的核心邏輯。
// 改了會怎樣：決定系統在掃描 1~30 分 K 時的選點偏好。選 1 (爆發動能)，會動態鎖定當下攻擊斜率最陡、正乖離最大的週期，追擊強勢波段；選 2 (安全起漲)，則優先尋找剛突破均線、正乖離最小的週期。
// 實戰長怎樣：設定為 2 時，系統會在多個短天期中，精準篩選出「底部剛打好、防守最嚴密」的那一個最佳頻率，買在風險極低的起漲第一根。
// 影響代碼處：BE_504、BE_505、BE_600、BE_601~BE_605。

Input: pTradeStyle(3, "@@14[戰略] 當今日交易大戰略 (當沖/波段/AI自動評估", inputkind:=dict(["1.全波段", 1], ["2.全當沖", 2], ["3.AI自適應判斷", 3]));     
Input: pAutoCloseDT(False, "15[出] 當沖13:20自動平倉", inputkind:=dict(["清倉(True)", True], ["手控(False)", False]));     
// 【實戰兵推手冊】
// 為何設：決定當日操作的終極戰略目標。
// 改了會怎樣：選 3，AI 依前日乖離與震幅決定今天打波段還當沖；若當沖模式且 pAutoCloseDT 設 True，時間一到強制平倉。
// 實戰長怎樣：若標的昨天已噴漲 8%，選 3 系統會判斷風險過高，今日自動降級為「當沖模式」打短；若設了自動平倉，13:20 一到不管賺賠立刻市價賣出。
// 影響代碼處：BE_100.2 ~ BE_100.4.2 (波段/當沖判定)、BE_900.6.6.1.1 (時間結算)。

// ========================================================     
// 【第二層：資金與部位控管】     
// ========================================================     
Input: pTradeQty(1, "16[系] 每次進場張數");     
Input: pMaxTrades(1, "17[系] 單日同商品最多進場次數");     
Input: pCoolDownBars(5, "18[進] 出場後強制冷卻K棒數");     
// 【實戰兵推手冊】
// 為何設：硬派的交易紀律與防連環虧損機制。
// 改了會怎樣：限制單次買進量、當日進出總次數，以及被洗出場後的面壁思過時間。
// 實戰長怎樣：若剛停損出場，即使訊號立刻又亮起，系統會強制等待 5 根 K 棒走完才允許再次進場，強迫冷靜，不淪為無腦刷單。
// 影響代碼處：BE_704 區段 (進場次數與冷卻條件檢查)。

// ========================================================     
// 【第三層：獲利與風控防線】     
// ========================================================     
Input: pBaseTargetSW(4, "@@19[出] 波段停利：AI動態計算的(最低保底獲利%)"); 
Input: pBaseTargetDT(3, "@20[出] 當沖停利：AI動態計算的【最低保底獲利%】"); 
Input: pTargetProfit(15.0, "@21[出] 絕對獲利天花板(碰到無條件強制收割%)");     
// 【實戰兵推手冊】
// 為何設：設定 AI 動態計算目標價的「保底基準」與「天花板」。
// 改了會怎樣：動態停利目標 = 基底 + (得分 * 獎金倍數)。不會超過 pTargetProfit 的天花板。
// 實戰長怎樣：打當沖時，不管 AI 怎麼算，系統起跳要求至少抓 2.5% 獲利；波段若碰觸到 15% 天花板，無條件強制收割入袋。
// 影響代碼處：BE_508 (vDynamicTarget 計算與封頂)、BE_900.6.7。

Input: pMinSurgeProfit(2.0, "@23[出] 急拉停利: 最低獲利門檻(%)");
Input: pSurgePct(5, "@24[出] 急拉停利: 盤中低點起算急拉幅度(%)");
Input: pPullbackTicks(2, "@25[出] 瘋狗急拉：高檔回落即立刻賣出的【下跌檔位數】");
Input: pPullbackPct(1.0, "@26[出] 瘋狗急拉：高檔回落即立刻賣出的【下跌幅度%】");
Input: pSurgeBars(15, "27[出] 瘋狗急拉：尋找起漲低點的【回溯K棒視窗】"); 
// 【實戰兵推手冊】
// 為何設：專抓「瘋狗流急拉」的獵殺網，防止紙上富貴。
// 改了會怎樣：利用 pSurgeBars 尋找近期相對低點，只要從低點拉抬超過 pSurgePct，就進入急拉備戰。
// 實戰長怎樣：近 15 根 K 棒內股價急拉 4.5% (進入瘋狗狀態)。此時只要帳面賺超過 2.0%，且從最高點回落 2 個 Tick (或跌 1%)，立刻市價收割，完美抓轉折。
// 影響代碼處：BE_900.2.1 區段 (急拉條件)、BE_900.6.10.1 (急拉出場)。

Input: pAutoSellDyn(True, "28[出] 停利達標時的執行動作(市價砍倉/僅跳通知)", inputkind:=dict(["砍倉(True)", True], ["警示(False)", False]));     
Input: pATRMult(2.5, "29[出]  移動停利：容忍回檔的 ATR 寬鬆倍數");     
Input: pMinProfit(2.0, "30[出] 啟動防守機制(移停/破線)的【最低帳面獲利%】");     
// 【實戰兵推手冊】
// 為何設：獲利保護與執行方式。
// 改了會怎樣：pAutoSellDyn 決定達標是真賣還是只跳通知；ATR 為跟隨高點移動停利的寬容度；pMinProfit 為啟動防守的最低門檻。
// 實戰長怎樣：帳面獲利超過 1.5% 後，系統啟動 ATR 防線或破線停利準備。若 pAutoSellDyn 為 True，觸發條件一到，不帶感情直接市價賣出。
// 影響代碼處：BE_800.11.1 (vTickMinProfit)、BE_900.2.1 區段 (vDynStop)、BE_900.6.3/BE_900.6.6.1/BE_900.6.11 (停利執行)。

Input: pStopLoss(25.0, "@31[出] 終極保命斷頭線(單筆總資金虧損極限%)");     
Input: pStrictBreak(False, "32[出] 破線停利態度(無情秒砍/給予下沉容忍空間)", inputkind:=dict(["秒砍(True)", True], ["容忍(False)", False]));     
Input: pBreakTolerance(15.0, "@33[出] 破線容忍度：允許短暫跌破均線的幅度(%)(看級別)");     
// 【實戰兵推手冊】
// 為何設：守法自制交易性格的核心「虧損防線」。
// 改了會怎樣：決定跌破支撐均線時的砍倉態度。
// 實戰長怎樣：容忍度設 15%，跌破均線時系統不會毛躁秒砍，給予下沉空間；但只要觸碰到 pStopLoss 的 20% 絕對死線，無情斷頭保護總資金。
// 影響代碼處：BE_800.11.1、BE_900.6.13、BE_900.6.13.1 (破線判斷)、BE_900.6.13.2.1 (保命停損執行)。

Input: pUseChipsHold(True, "34[出] 籌碼免死金牌(大戶大買則攔截破線停損指令)", inputkind:=dict(["大戶買超跌破不砍(True)", True], ["一般(False)", False]));
// 【實戰兵推手冊】
// 為何設：籌碼面與技術面的深度結合，防主力假跌破真洗盤。
// 改了會怎樣：若技術面跌破出場均線，但系統算出版面「特大單+大單」仍大買，會攔截平倉指令。
// 實戰長怎樣：股價跌破 5MA 理應出場，但系統偵測大戶淨買超超過 500 張，判定主力只是在洗散戶，系統強勢續抱。
// 影響代碼處：BE_900.6.12 (攔截破線出場)。

// ========================================================     
// 【第四層：進階進場濾網】     
// ========================================================     
Input: pMomentum(1, "35[進] 今日買盤動能要求(必須紅K/僅需過昨收即可)", inputkind:=dict(["1.嚴格(須為紅K)", 1], ["2.寬鬆(只要過昨收)", 2]));     
Input: pGapMode(2, "36[進] 防追高(買在尖端)模式(固定極限/依近期震幅動態調整)", inputkind:=dict(["1.固定%", 1], ["2.動態(近期震幅)", 2]));     
Input: pFixedGap(3.5, "37[進] 固定防追高：今日已漲幅超過此(%)則拒絕買進");     
Input: pDynGapMult(0.8, "38[進] 動態防追高：近期震幅的寬鬆乘數");     
Input: pMaxBias(15.0, "39[進] 月線乖離極限(防止買在離均線太遠的高空%)");     
// 【實戰兵推手冊】
// 為何設：防追高買在尖端，以及確認當日買盤力道。
// 改了會怎樣：pMomentum 影響判斷紅黑K；pGapMode 若選動態，系統會根據前兩天高低落差乘以 pDynGapMult 算出今日合理的追高極限；pMaxBias 則防止買在離月線太遠的地方。
// 實戰長怎樣：選動態防追高(2)，若前兩天震幅死魚，今日追高上限可能只有 1.5%；若前兩天震幅達 10%，系統放寬允許追高至 6%。
// 影響代碼處：BE_100.5 ~ BE_100.6 (計算 vGapLimit)、BE_404 (vIsMoney、vBias)、BE_700.3.3.1.1.1 (訊號過濾)。

// ========================================================     
// 【第五層：基礎環境與特例過濾】     
// ========================================================     
Input: pMinPrice(10.0, "40[進] 標的最低價過濾");     
Input: pMaxPrice(1000.0, "41[進] 標的最高價過濾");     
Input: pNoLossExit(True, "42[出] 觸碰保命停損時的最終動作(死不退場/正常砍倉)", inputkind:=dict(["虧損死不退場(True)", True], ["正常停損(False)", False]));     
Input: pUseTVLogic(False, "43[進] 啟動 TV 極穩健雙重確認(日K與30分K大方向必須一致)", inputkind:=dict(["長線保護(True)", True], ["純動能(False)", False]));     
Input: pMAType(1, "44[系] 全系統依賴的均線數學模型(SMA/EMA/WMA...)", inputkind:=dict(["1.短E長S", 1], ["2.全EMA", 2], ["3.全WMA", 3], ["4.全SMA", 4], ["5.全RMA", 5]));     
// 【實戰兵推手冊】
// 為何設：定義戰場基本盤。
// 改了會怎樣：設定股價操作區間。pNoLossExit 專門針對「保命停損」的防線做豁免；TVLogic 引入日線與 30 分鐘線的長線雙重共振；pMAType 改變整個系統(長短週期)所依賴的均線數學模型。
// 實戰長怎樣：設價格 10~1000 濾掉雞蛋水餃與極端高價股；啟動 TVLogic，系統會強迫大趨勢(日K)與中波段(30分K)方向完全一致才允許出手，極度穩健。
// 影響代碼處：BE_400~BE_403、BE_500~BE_503 (均線模型)、BE_606 (TVLogic)、BE_700.3.3.1.1.1 (股價區間)、BE_900.6.13.2.1 (停損凹單)。

// ========================================================     
// 【第八層：自適應動能獎金】     
// ========================================================     
Input: pAutoBonus(True, "@@45[出] 停利天花板擴充啟動AI自適應獎金倍數", inputkind:=dict(["依股性(True)", True], ["固定(False)", False]));     
Input: pBonusMult(100.0, "@46[出] 固定動能獎金倍數(若上方設False)");     
// 【實戰兵推手冊】
// 為何設：停利目標空間的「彈性擴充引擎」。
// 改了會怎樣：設 True，系統不看固定倍數，改看近期平均震幅 (vNDayAmp)。股性越瘋狗，倍數給越高。
// 實戰長怎樣：遇到連續大震盪的強勢股，系統會自動把獎金倍數調升(最高達300)，讓停利目標價跟著推高，讓利潤充分奔跑，不提早下車。
// 影響代碼處：BE_506、BE_507 (計算 vRealBonusMult)。     
 
// ========================================================     
// 【第九層：探底反彈與再次進場機制】     
// ========================================================     
Input: pEnableBuyBack(True, "50[進] 被洗出場或停利後的【自動低接/買回機制】", inputkind:=dict(["開啟(True)", True], ["關閉(False)", False]));  
input: pBandPullbackPct(2.5, "51[進] 低接門檻：距離上次出場價的【回檔深度%】");   
Input: pBuyBackBounceTicks(2, "52[進] 低接確認：觸底後向上反彈的【檔位數】"); 
Input: pBuyBackBouncePct(1.0, "53[進] 低接確認：觸底後向上反彈的【漲幅%】");
Input: pReEntryGapPct(3.0, "54[進] 防頻繁刷單：新訊號需距離上次停利價的【避開空間%】");
 
// ========================================================     
// 2. 宣告內部變數區 (實戰 100% 全變數獨立註解版)   
// ========================================================     

// ========================================================
// 【A區】日線大趨勢與位階判讀
// ========================================================
Var: vDailyMA5(0);             // 日K線 5日移動平均線 (短天期趨勢)
Var: vDailyMA10(0);          // 日K線 10日移動平均線 (中天期趨勢)
Var: vDailyMA20(0);          // 日K線 20日移動平均線 (月線，生命線)
Var: dMaxMA(0);              // 日K三條均線中的最大值 (用於計算均線糾結度)
Var: dMinMA(0);              // 日K三條均線中的最小值 (用於計算均線糾結度)
Var: vIsDailyBull(False);    // 大趨勢是否達標 (True代表站上月線或呈現多頭排列)
Var: vIsMoney(False);        // 今日是否有實質買盤動能 (True代表收紅K或大於昨收)
Var: vBias(0);               // 股價與 20日均線 的正負乖離率 (%)
Var: vBiasDesc("");          // 乖離率位階的文字描述 (安全 / 強勢 / 警戒 / 危險)
Var: vTrendText("");         // 日均線排列狀態文字描述 (糾結 / 多頭 / 標準)
Var: vRefPrice(0);           // 今日平盤參考價 (昨收)
Var: vTodayRisePct(0);       // 今日盤中即時漲幅 (%)
Var: vDailyAmp(0);           // 今日盤中最高與最低點的震幅 (%)
Var: vNDayAmp(0);            // 過去 N 日的平均震幅 (%)，用來判斷股性是否為瘋狗
Var: vAmpSum(0);             // 過去 N 日震幅加總 (計算平均震幅的暫存變數)
Var: j(0);                   // 迴圈用變數 (計算N日震幅用)
Var: initBias(0);            // 開盤計算用：昨日 20日乖離率 (戰略判定用)
Var: initMA20(0);            // 開盤計算用：昨日 20日均線值 (戰略判定用)

// ========================================================
// 【B區】多時區 AI 共振運算大腦 (跨頻率 MACD 與 均線)
// ========================================================
Var: vBestTF(30);            // AI 綜合評分後，挑出當下最佳的發動時區 (分K)
Var: vCheckTF(30);           // 盤中用來反覆檢查趨勢是否破壞的參考時區
Var: _targetFreq("");        // 暫存要呼叫的目標頻率字串

// 各時區「長週期均線」 (決定該時區方向)
Var: ema1(0), ema2(0), ema3(0);       // 1、2、3 分鐘 K 線的長週期均線
Var: ema5(0), ema10(0), ema15(0), ema30(0); // 5、10、15、30 分鐘 K 線的長週期均線

// 各時區「短週期均線」 (用來與 ema 產生交叉判定)
Var: ma5_5(0), ma10_5(0), ma15_5(0), ma30_5(0); // 各時區短週期 5MA 均線

// 各時區「均線乖離得分」 (分數越高代表突破越猛)
Var: vScore1(0), vScore2(0), vScore3(0);  // 1、2、3 分鐘均線乖離得分
Var: vScore5(0), vScore10(0), vScore15(0), vScore30(0); // 5、10、15、30 分鐘得分
Var: vMaxScore(0);           // 所有時區中最高的分數 (爆發動能模式用)
Var: vMinPosScore(999.0);    // 所有時區中最小的正乖離分數 (安全起漲模式用)

// 各時區 MACD 運算值 (DIF:Val, MACD:MA, 柱狀體:Osc)
Var: macdValue1m(0), macdMA1m(0), macdOsc1m(0); // 1分K MACD
Var: vM_Val2(0), vM_MA2(0), vM_Osc2(0);         // 2分K MACD
Var: vM_Val3(0), vM_MA3(0), vM_Osc3(0);         // 3分K MACD
Var: vM_Val5(0), vM_MA5(0), vM_Osc5(0);         // 5分K MACD
Var: vM_Val10(0), vM_MA10(0), vM_Osc10(0);      // 10分K MACD
Var: vM_Val15(0), vM_MA15(0), vM_Osc15(0);      // 15分K MACD
Var: vM_Val30(0), vM_MA30(0), vM_Osc30(0);      // 30分K MACD
Var: vM_Val60(0), vM_MA60(0), vM_Osc60(0);      // 60分K MACD
Var: macdOsc5m(0);           // 指向 AI 當前選定大時區的 MACD 柱狀體

// MACD 共振判斷開關
Var: vIsOscBull(False);      // 大時區翻紅且小時區轉強 (MACD多頭共振)
Var: vIsOscShrink(False);    // 大時區在水下但綠柱正在縮腳 (MACD抄底共振)
Var: _calcFreq(5);           // 內部轉換用：將手動頻率參數轉為數值

// ========================================================
// 【C區】TV 共振與進階環境濾網
// ========================================================
Var: tvDailyMA20(0), tvDailyMA5(0);       // TV 共振邏輯：日均線
Var: tv30mMA20(0), tv30mMA5(0);           // TV 共振邏輯：30分K均線
Var: tvIsDailyResonance(False);           // TV 共振：日線是否多頭
Var: tvIs30mResonance(False);             // TV 共振：30分K是否多頭
Var: tvPerfectResonance(True);            // TV 共振：長短線是否完美共振同步

Var: vIsDayTradeSignal(False);            // 最終確認：當沖進場訊號亮起
Var: vIsSwingSignal(False);               // 最終確認：波段進場訊號亮起
Var: vIsBerserk(False);                   // 極限瘋狗開關 (True: 放寬條件無腦追擊)
Var: vBerserkStr("");                     // 供文字 Log 使用的瘋狗狀態字串
Var: vAntiGapCond(True);                  // 防開高走低(ORB) 檢驗是否通過
Var: vIsORB_Break(False);                 // 股價是否突破早盤最高點
Var: vIsRebound(False);                   // 股價是否從盤中低點反彈確認
Var: vChipCondition(True);                // 籌碼濾網是否通過 (預設True)
Var: vCond1(False), vCond2(False);        // 波段模式專屬的輔助過濾條件
Var: vCrossPrice(0);                      // 監控跌破出場的底線均線價格
Var: vTriggerTime(0);                     // 記錄訊號觸發的時間點
Var: vIntRatio(0);                        // 智慧上車：區間位置比例計算
Var: vDynamicCeiling(0);                  // 智慧上車：動態進場天花板價

// ========================================================
// 【D區】大戶籌碼護盤防禦網 (The Golden Filter)
// ========================================================
Var: vBigPlayerNetBuy(0);    // 當日大戶淨買超張數 (特大單+大單)
Var: vDailyVolume(0);        // 當日累計總成交量
Var: vBigPlayerRatio(0);     // 大單淨買超佔全天成交量比例 (%)
Var: vIsChipProtect(False);  // 護盤免死金牌 (True: 攔截破線，強勢續抱)
Var: vSChips("");            // 護盤狀態的 Log 字串

// ========================================================
// 【E區】資金控管、滑價與排隊機制
// ========================================================
Var: vGapLimit(999.0);       // 動態防追高上限 (%)
Var: vGapPrice(99999.0);     // 動態防追高上限換算出的絕對價格
Var: vNeededCap(0);          // 單次進場所需消耗的總資金 (元)
Var: vUpLimit(0);            // 該檔股票今日漲停價
Var: vTicksToLimit(0);       // 距離漲停板還剩下幾個 Tick (檔位)
Var: vSpacePct(0);           // 距離漲停板還剩下幾 % 的空間
Var: vTickSize(0);           // 該檔股票跳動一檔的金額差距 (0.01 / 0.1 / 1 / 5)
Var: vTickYield(0);          // 股價跳動一檔能帶來的獲利百分比 (%)
Var: vPrioritySeconds(0);    // Tick獲利過薄時，系統強迫等待的秒數 (防滑價)
Var: vRealPos(0);            // 透過 FilledAtBroker 抓取的券商真實庫存量

// ========================================================
// 【F區】出場、停利與動態目標結算
// ========================================================
Var: vIsTFBull(False);       // 檢查分時線目前是否仍處於多頭
Var: vIsTFBreak(False);      // 檢查分時線是否已經跌破 (觸發破線出場)
Var: vProfitPct(0);          // 系統算出的當前帳面損益 (%)
Var: vMyATR(0);              // 近期真實波幅點數 (計算 ATR 移動停利用)
Var: vDynStop(0);            // 利用 ATR 算出的動態下彎防守線
Var: vDynamicTarget(0);      // AI 算出的當下合理停利目標 (%)
Var: vRealBonusMult(100.0);  // 依據股性計算出的動能目標加給倍數
Var: vRealMinProfitPrice(0); // 啟動移動防守機制的實際觸發價
Var: vRealTargetPrice(0);    // 最終預計市價賣出的目標價格
Var: i(0), dTR(0), sumTR(0); // 計算 ATR 使用的迴圈與數學暫存變數
Var: vFinalScore(0);         // 內部結算：最終修正後的 AI 得分
Var: vCurrentBaseTarget(0);  // 內部結算：當前模式對應的停利基底 %
Var: vTrailStopPrice(0);     // 內部結算：當沖高檔回檔保利防守價

// ========================================================
// 【G區】戰場環境風險監控 (大盤 vs 個股)
// ========================================================
Var: vMarketPct(0);          // 大盤加權指數今日漲跌幅 (%)
Var: vStockPct(0);           // 該檔個股今日漲跌幅 (%)
Var: vTSE_Ref(0);            // 大盤加權指數昨日收盤價
Var: vStock_Ref(0);          // 該檔個股昨日收盤價
Var: vStateCategory("");     // 判讀出的市場環境 (如：雙重強攻、逆勢妖股)
Var: vActionMsg("");         // 對應環境狀態要給使用者的戰術提示字串
Var: bIsMarketEvent(False);  // 大盤是否觸發暴漲/暴跌事件
Var: bIsStockEvent(False);   // 個股是否觸發暴漲/暴跌事件

// ========================================================
// 【H區】系統流程控制與 Log 輸出字串暫存
// ========================================================
Var: vAllowEntry(True);      // 核心進場閘門 (False 則攔截下單)
Var: vRejectReason("");      // 紀錄被擋單的具體原因 (印在日誌中)
Var: vAutoDailyTest(True);   // 日線測試布林值
Var: vAutoFilter(False);     // 是否通過位階與股性的 AI 自動過濾
Var: vSensitivityMode("");   // 股性敏感度字串 (千金級 / 瘋狗等)
Var: vSGearStr("");          // 引擎排檔顯示字串
Var: vDebugStr(""), vLastDebugStr(""); 
Var: vLastAlertStr(""), vCurrentAlertStr(""); 
Var: vAILogStr("");          // 專門為 AI 大數據庫準備的格式化日誌字串
Var: vTrackStr("");          // 全日高低軌跡字串
Var: vS1(""), vS2(""), vS3(""), vS8(""), vS12(""), vS14(""), vS15(""), vS19(""), vS22(""); // 外部參數的中文翻譯暫存
Var: vSMAType(""), vSTVLogic(""), vSMinProfit(""), vBreakoutPriceStr(""); 
Var: vModeStr("");           // 內部訊息：AI 啟動模式文字 (爆發/安全)
Var: vDisplayEntryTime(0);   // 內部訊息：系統接管時的進場時間暫存
Var: vEndReportStr("");      // 內部訊息：收盤總結報告格式字串
Var: vFinalProfitPct(0);     // 內部訊息：收盤最終損益 % 計算結果
Var: vPrintMsg(""), vPopMsg(""); // 內部訊息：風控環境變動文字組合
Var: vTestPrinted(False);    // 內部訊息：介面強制測試列印開關旗標

// ========================================================
// 【交易狀態專屬記憶鎖 (IntrabarPersist)】
// 盤中逐筆洗價時，必須嚴格保留記憶，絕對不能被 Tick 重置的關鍵變數
// ========================================================

// 1. 部位與次數記憶
Var: IntrabarPersist vTradesToday(0);       // 今天對這檔股票已經進場了幾次
Var: IntrabarPersist vLastExitBar(-999);    // 上次賣出時的 K 棒編號 (算冷卻期用)
Var: IntrabarPersist vEntryType(0);         // 記憶這筆單是 當沖(1) 還是 波段(2)
Var: IntrabarPersist vEntryDate(0);         // 記憶這筆單是哪一天買的
Var: IntrabarPersist vLockTF(30);           // 記憶進場時 AI 鎖定的是哪一個分 K 時區

// 2. 價格防線記憶
Var: IntrabarPersist vTriggerPrice(0);      // 進場觸發當下的成交均價
Var: IntrabarPersist vLockedTarget(0);      // 買進瞬間鎖死的停利目標 % (防盤中亂跳)
Var: IntrabarPersist vInitStop(0);          // 買進瞬間算出的保命斷頭價
Var: IntrabarPersist vHighSinceEntry(0);    // 買進後，股價創下的歷史最高點 (移停用)
Var: IntrabarPersist vTickTargetPrice(0);   // 四捨五入成跳動檔位的停利目標價
Var: IntrabarPersist vTickMinProfit(0);     // 四捨五入成跳動檔位的移動停利啟動價

// 3. 首發訊號與尋底軌跡記憶
Var: IntrabarPersist vFirstSignalTime(0);   // 第一根訊號發生的時間點
Var: IntrabarPersist vFirstSignalPrice(0);  // 第一根訊號發生時的市價
Var: IntrabarPersist vFirstSignalClose(0);  // 第一根訊號發生時的 K 棒收盤價
Var: IntrabarPersist vFirstSignalLow(0);    // 第一根訊號發生時的 K 棒最低價
Var: IntrabarPersist vIntervalHigh(0);      // 首發訊號過後，盤中震盪的最高價
Var: IntrabarPersist vIntervalLow(99999);   // 首發訊號過後，盤中震盪的最低價

// 4. 早盤 ORB 防護與全日極值追蹤
Var: IntrabarPersist vWaitTime(090000);     // 防開高走低機制需等待到的時間點
Var: IntrabarPersist vMorningHigh(0);       // 早盤觀察區間的最高點
Var: IntrabarPersist vMorningLow(99999);    // 早盤觀察區間的最低點 (今日鐵底)
Var: IntrabarPersist vDayLow(99999);        // 全天走勢中的最低點
Var: IntrabarPersist vTrackDayHigh(0);      // 今日全天極限最高點
Var: IntrabarPersist vTrackDayHighTime(0);  // 創下今日最高點的時間
Var: IntrabarPersist vTrackDayLow(999999);  // 今日全天極限最低點
Var: IntrabarPersist vTrackDayLowTime(0);   // 創下今日最低點的時間

// 5. 瘋狗急拉停利專屬記憶
Var: IntrabarPersist vSurgeMaxPrice(0);     // 急拉進入瘋狗狀態後的最高價
Var: IntrabarPersist vHaltImmunityTime(0);  // ★ 新增：記錄暫緩交易剛恢復出關的時間
Var: vSurgeBase(0);                         // 急拉計算的基準點 (非記憶)
Var: vCondSurge(False);                     // 狀態：目前是否處於急拉中
Var: vCondSurgeProfit(False);               // 狀態：急拉幅度是否大於獲利門檻
Var: vCondPullback(False);                  // 狀態：急拉後是否已經發生回檔
Var: vSurgeTickSize(0);                     // 急拉區間的對應檔位大小
Var: vRecentLow(0);                         // 滾動視窗內的近期低點 (非記憶)

// 6. 列印與系統狀態記憶 (防止盤中無限洗頻報錯)
Var: IntrabarPersist vIsFilledPrinted(True);      // 成交回報是否已印過
Var: IntrabarPersist vDynAlerted(False);          // 動態停利達標是否已跳過警示
Var: IntrabarPersist vRejectAlertPrinted(False);  // 擋單原因是否已印過
Var: IntrabarPersist vConfigPrinted(False);       // 初始設定狀態是否已印過
Var: IntrabarPersist vSignalFired(False);         // 目前是否正在排隊等待進場
Var: IntrabarPersist vSignalFireTime(0);          // 開始排隊進場的秒數時間點
Var: IntrabarPersist vLastBestTF(0);              // 上一次大腦選中的最佳時區
Var: IntrabarPersist vLastBrainPrintTime(0);      // 上次大腦運算結果列印的時間
Var: IntrabarPersist vHighestScoreToday(0);       // 紀錄今天洗價過程中，出現過的最高得分
Var: IntrabarPersist vDailyPosReported(False);    // 今日戰情室回報是否已顯示
Var: IntrabarPersist vDailySummaryPrinted(False); // 收盤總結是否已列印

// 7. 風險環境狀態記憶 (紀錄前一秒大盤狀態)
Var: IntrabarPersist vLastCategory("");           // 上一次的戰場環境名稱
Var: IntrabarPersist vMemMarket(0);               // 大盤狀態記憶 (1:大漲, 0:平穩, -1:大跌)
Var: IntrabarPersist vMemStock(0);                // 個股狀態記憶 (1:大漲, 0:平穩, -1:大跌)

// 8. 探底接回專屬記憶
Var: IntrabarPersist vWaitBuyBack(False); // 狀態：是否正在等待探底反彈
Var: IntrabarPersist vBottomTracking(999999); // 記憶：探底過程的最低點
Var: IntrabarPersist vOldEntryPrice(0); // 記憶：上一次進場的成本價
Var: IntrabarPersist vLastExitPrice(0); // 宣告上次出場價格變數
Var: IntrabarPersist vLastExitReasonType(0); // 記憶上次出場原因 (1: 停利, -1: 停損/破線, 0: 無)
// ========================================================
// ========================================================

// 【代碼翻譯】GetField("參考價", "D") 抓取今日開盤基準價。為避免無資料的例外狀況，加上容錯機制 (Default:=0)，若仍取不到則抓昨收。
vRefPrice = GetField("參考價", "D", Default := 0);   
If vRefPrice = 0 Then vRefPrice = GetField("Close", "D")[1]; 
  
// ========================================================     
// 3. 換日記憶重置與環境評估 (每天開盤洗腦機制)    
// ========================================================     
If IsFirstCall("Date") Then Begin // BE_100
// 【機制解析】Date <> Date[1] 是判斷是否為新交易日的標準寫法。當進入新的一天時，必須把所有 IntrabarPersist 記憶變數清空歸零，確保昨日的訊號或獲利計算不會繼承到今日。
    // 【實戰代碼翻譯】清空昨日戰損與進場記憶，準備迎接新戰場
    vTradesToday = 0;    
    vLastExitBar = -999;     
    vLastAlertStr = "";      
    vFirstSignalTime = 0;    
    vFirstSignalPrice = 0;    
    vRejectAlertPrinted = False;     
    vIntervalHigh = 0; vIntervalLow = 99999;    
    vFirstSignalClose = 0; vFirstSignalLow = 0;    
    vMorningLow = 99999; vDayLow = 99999;     
    vWaitTime = 090000; vMorningHigh = 0;  
    
    // 換日重置探底接回狀態
    vWaitBuyBack = False;
    vBottomTracking = 999999;
    vOldEntryPrice = 0;
    vLastExitReasonType = 0; // 換日清空出場原因記憶
    
    // ★ 換日重置所有印字鎖與全域極值 // 【實戰代碼翻譯】重置庫存回報與全域軌跡追蹤
    vDailyPosReported = False; 
    vDailySummaryPrinted = False; 
    vSurgeMaxPrice = 0; 
    
    // ★ 新增：換日強制重置今日最高得分，避免跨日錯誤繼承
    vHighestScoreToday = 0;
    vTrackDayHigh = High;
    vTrackDayHighTime = Time;
    vTrackDayLow = Low;
    vTrackDayLowTime = Time;
  
    // 【機制解析】計算近 N 日的平均震幅 (vNDayAmp)。這是 AI 判斷「股性是瘋狗還是死魚」的重要依據。
    vAmpSum = 0;    
    For j = 1 to pVolDays Begin // BE_100.1
        // 【代碼翻譯】利用 For 迴圈往前回溯計算過去 N 日的平均震幅，將高低價差除以收盤價。此數值將作為後續 AI 自適應判斷股性 (溫和或瘋狗) 的核心依據。
        If GetField("Close", "D")[j+1] > 0 Then Begin // BE_100.1.1
            vAmpSum = vAmpSum + ((GetField("High", "D")[j] - GetField("Low", "D")[j]) / GetField("Close", "D")[j+1] * 100);
        End; // BE_100.1.1
    End; // BE_100.1
    If pVolDays > 0 Then vNDayAmp = vAmpSum / pVolDays Else vNDayAmp = 0;    
  
    If pTradeStyle = 1 Then Begin // BE_100.2
        vAutoDailyTest = True; vS19 = "強制波段(看日均)";  
    End // BE_100.2
    Else If pTradeStyle = 2 Then Begin // BE_100.3
        vAutoDailyTest = False; vS19 = "強制當沖(看分均)";  
    End // BE_100.3
    Else Begin // BE_100.4
        // 【代碼翻譯】若選擇 AI 自適應模式 (pTradeStyle = 3)，則會觀察前一天的 20 日乖離率與 N 日震幅。若乖離過大或震幅劇烈，AI 會自動縮短週期，將策略降級為當沖打短模式以規避波段回撤風險。
        initMA20 = Average(GetField("Close", "D"), 20);  
        If initMA20 > 0 Then initBias = (GetField("Close", "D")[1] - initMA20) / initMA20 * 100 Else initBias = 0;  
          
        If initBias > 8.0 or vNDayAmp >= 6.0 Then Begin // BE_100.4.1
            vAutoDailyTest = False; vS19 = "AI判定:當沖(避險打短)";  
        End // BE_100.4.1
        Else Begin // BE_100.4.2
            vAutoDailyTest = True;  vS19 = "AI判定:波段(趨勢穩健)";  
        End; // BE_100.4.2
    End; // BE_100.4
  
    If pStrategyMode = 1 Then vS1 = "標準" Else If pStrategyMode = 2 Then vS1 = "多頭" Else If pStrategyMode = 3 Then vS1 = "糾結" Else vS1 = "大戶護盤";     
    If pCatchUpMode = 1 Then vS2 = "無限制" Else If pCatchUpMode = 2 Then vS2 = "區間智慧K" Else If pCatchUpMode = 4 Then vS2 = "MACD縮腳" Else vS2 = "放棄";    
    If pAutoCloseDT Then vS3 = "清倉" Else vS3 = "留倉";    
    If pAutoSellDyn Then vS8 = "自動賣" Else vS8 = "僅警示";    
    If pMomentum = 1 Then vS14 = "紅K" Else vS14 = "過昨收";    
    If pNoLossExit Then vS22 = "虧損死不退場" Else vS22 = "正常停損";    
    If pMAType = 1 Then vSMAType = "短E長S" Else If pMAType = 2 Then vSMAType = "全EMA" Else If pMAType = 3 Then vSMAType = "全WMA" Else If pMAType = 4 Then vSMAType = "全SMA" Else vSMAType = "全RMA";    
    If pUseTVLogic Then vSTVLogic = "開啟" Else vSTVLogic = "關閉";    
    
    // 【機制解析】動態防追高上限 (vGapLimit)。如果前兩天震幅很小，今天追高上限就會被壓縮；如果前兩天大洗盤，追高空間就會被放寬，避免錯過強勢股。
    If vRefPrice > 0 Then Begin // BE_100.5
        // 【代碼翻譯】防追高機制：可設定固定百分比，或計算近期兩根 K 棒的震幅作為動態追高上限 (vGapLimit)，避免買在急拉末端的尖點。
        If pGapMode = 1 Then vGapLimit = pFixedGap     
        Else Begin // BE_100.5.1
            If GetField("Close", "D")[2] > 0 and GetField("Close", "D")[3] > 0 Then Begin // BE_100.5.1.1
                vGapLimit = (((GetField("High", "D")[1] - GetField("Low", "D")[1]) / GetField("Close", "D")[2]) + ((GetField("High", "D")[2] - GetField("Low", "D")[2]) / GetField("Close", "D")[3])) / 2 * 100 * pDynGapMult;    
            End // BE_100.5.1.1
            Else vGapLimit = pFixedGap;     
            If vGapLimit < 1.5 Then vGapLimit = 1.5; If vGapLimit > 6.0 Then vGapLimit = 6.0;    
        End; // BE_100.5.1
        vGapPrice = vRefPrice * (1 + (vGapLimit / 100.0));    
        If pGapMode = 1 Then vS15 = "固定(" + NumToStr(vGapLimit, 1) + "%)" Else vS15 = "動態(" + NumToStr(vGapLimit, 1) + "%)";    
    End // BE_100.5
    Else Begin // BE_100.6
        vGapLimit = 999.0;  
        vS15 = "防呆(無限制)";  
    End; // BE_100.6
    
    If vAutoDailyTest = True Then vBreakoutPriceStr = " |突破:日均線" Else vBreakoutPriceStr = " |突破:分K均線";    
    If pStrictBreak Then vS12 = "嚴格秒砍" Else vS12 = "容忍" + NumToStr(pBreakTolerance, 1) + "%";    
    vSMinProfit = NumToStr(pMinProfit, 1) + "%";    
    
    If pAutoGearMode = 1 Then vSGearStr = "股價位階(5檔)" Else vSGearStr = NumToStr(pVolDays, 0) + "日震幅(" + NumToStr(vNDayAmp, 2) + "%)";    
    If pUseChipsHold Then vSChips = "開啟" Else vSChips = "關閉";  
    
    // ★ 更新此處的字串代號對應
    vCurrentAlertStr = Symbol + "庫存:" + numToStr(filledAtBroker ,0) + " [自檢] 09[濾網]:" + vS1 + " |10[上車]:" + vS2 + " |14[模式]:" + vS19 + vBreakoutPriceStr     
                     + " |21[目標]:" + NumToStr(pTargetProfit, 1) + "%(" + vS8 + ") |30[移停]:" + vSMinProfit     
                     + " |32/33[破線]:" + vS12 + " |35[動能]:" + vS14 + " |36[防追高]:" + vS15 + " |02/42[凹單]:" + vS22    
                     + " |44[均線]:" + vSMAType + " |43[共振]:" + vSTVLogic + " |34[護盤]:" + vSChips;    
 
    
    Print(NumToStr(Date, 0), NumToStr(Time, 0), vCurrentAlertStr);    
    
    vNeededCap = Open * 1000 * pTradeQty;    
    Print(NumToStr(Date, 0), NumToStr(Time, 0), Symbol, " [引擎啟動檢測] Z[排檔]:", vSGearStr,     
          " | D[單次預算]:", NumToStr(vNeededCap/10000, 2), "萬 / 0-A[總預算]:", NumToStr(pTotalCapital, 0), "萬");    
End; // BE_100

// ========================================================
// ★ 全域極值與時間軌跡追蹤 (動態更新 09:00:00 ~ 13:29:00)
// ========================================================
// 【機制解析】盤中動態紀錄當日最高點與最低點及其發生時間。這仰賴宣告為 IntrabarPersist 的 vTrackDayHigh，確保逐筆洗價時數值能即時向上推升。
// 【機制解析】IntrabarPersist 的實戰應用。只要目前價格破了今天的高點，就立刻把高點與發生時間記下來，提供給 AI 日誌做覆盤追蹤。

If Time >= 090000 and Time <= 132900 Then Begin // BE_200
    If High > vTrackDayHigh Then Begin // BE_200.1
        vTrackDayHigh = High;
        vTrackDayHighTime = Time;
    End; // BE_200.1
    If Low < vTrackDayLow Then Begin // BE_200.2
        vTrackDayLow = Low;
        vTrackDayLowTime = Time;
    End; // BE_200.2
End; // BE_200

// ★ 預先封裝軌跡字串，供日誌隨時取用
vTrackStr = " | DayO=" + NumToStr(GetField("Open", "D"), 2) + 
            " | DayH=" + NumToStr(vTrackDayHigh, 2) + "@" + NumToStr(vTrackDayHighTime, 0) + 
            " | DayL=" + NumToStr(vTrackDayLow, 2) + "@" + NumToStr(vTrackDayLowTime, 0);

// ========================================================     
// 4-A. 全域籌碼與大戶指標 (複合式大戶防禦網 The Golden Filter)
// ========================================================     
If CurrentTime >= 090000 and CurrentTime <= 134500 Then Begin // BE_300
    // 1. 計算大戶淨買超張數
    vBigPlayerNetBuy = (GetField("買進特大單量", "D", default:=0) + GetField("買進大單量", "D", default:=0)) - (GetField("賣出特大單量", "D", default:=0) + GetField("賣出大單量", "D", default:=0)); 
    
    // 2. 取得當日累計總量 (指定 "D" 確保抓到日總量，避開1分K陷阱)
    vDailyVolume = GetField("Volume", "D");
    
    // 3. 計算大戶佔比 (%)
    If vDailyVolume > 0 Then 
        vBigPlayerRatio = (vBigPlayerNetBuy / vDailyVolume) * 100.0 
    Else 
        vBigPlayerRatio = 0;

    // 4. 判斷是否啟動籌碼護盤免死金牌 (vIsChipProtect)
    If pUseChipsHold Then Begin // BE_300.1
        // 條件A (中小型股)：佔比 > 3% 且 淨買超 > 150張
        // 條件B (大型權值)：絕對淨買超 > 1500張
        If (vBigPlayerRatio > 3.0 and vBigPlayerNetBuy > 150) or (vBigPlayerNetBuy > 1500) Then 
            vIsChipProtect = True
        Else 
            vIsChipProtect = False;
    End // BE_300.1
    Else Begin // BE_300.2
        vIsChipProtect = False;
    End; // BE_300.2
End // BE_300
Else Begin // BE_301
    vBigPlayerNetBuy = 0;
    vIsChipProtect = False;
End; // BE_301

// ========================================================     
// 4-C. 戰場環境偵測  (大趨勢判讀)   
// ========================================================     
// 【機制解析】依據設定的均線型態 (SMA, EMA, WMA)，計算日線級別的 5/10/20 均線，用以判斷當前股票是多頭排列、空頭排列還是糾結盤整。

If pMAType = 1 or pMAType = 4 Then Begin // BE_400
    vDailyMA5 = Average(GetField("Close", "D"), 5);        
    vDailyMA10 = Average(GetField("Close", "D"), 10);     
    vDailyMA20 = Average(GetField("Close", "D"), 20);     
End // BE_400
Else If pMAType = 2 Then Begin // BE_401
    vDailyMA5 = xf_EMA("D", GetField("Close", "D"), 5);    
    vDailyMA10 = xf_EMA("D", GetField("Close", "D"), 10);    
    vDailyMA20 = xf_EMA("D", GetField("Close", "D"), 20);    
End // BE_401
Else If pMAType = 3 Then Begin // BE_402
    vDailyMA5 = WMA( GetField("Close", "D"), 5);    
    vDailyMA10 = WMA( GetField("Close", "D"), 10);    
    vDailyMA20 = WMA(GetField("Close", "D"), 20);    
End // BE_402
Else If pMAType = 5 Then Begin // BE_403
    vDailyMA5 = xf_EMA("D", GetField("Close", "D"), 9);        
    vDailyMA10 = xf_EMA("D", GetField("Close", "D"), 19);     
    vDailyMA20 = xf_EMA("D", GetField("Close", "D"), 39);     
End; // BE_403
    
dMaxMA = MaxList(vDailyMA5, vDailyMA10, vDailyMA20);     
dMinMA = MinList(vDailyMA5, vDailyMA10, vDailyMA20);     
  
If dMinMA > 0 and (dMaxMA / dMinMA) <= 1.03 Then vTrendText = "[糾結]" Else If vDailyMA5 > vDailyMA10 and vDailyMA10 > vDailyMA20 Then vTrendText = "[多頭]" Else vTrendText = "[標準]";     
If vDailyMA20 <= 0 Then Return;     
// 【實戰代碼翻譯】評估大趨勢是否符合進場資格。若是保守型(多頭)，要求 5>10>20 完美排列；若是積極型(標準)，只要過 20MA 即可。  
// 【代碼翻譯】依據不同的 pStrategyMode，設定不同的進場門檻：積極型只需站上 20MA，穩健型則需要均線呈多頭排列，糾結型專抓突破，大單護盤模式看籌碼。
If pStrategyMode = 1 Then vIsDailyBull = GetField("Close", "D") > vDailyMA20     
Else If pStrategyMode = 2 Then vIsDailyBull = GetField("Close", "D") > vDailyMA20 and vDailyMA5 > vDailyMA10 and vDailyMA10 > vDailyMA20     
Else If pStrategyMode = 3 Then vIsDailyBull = GetField("Close", "D") > vDailyMA20 and (dMaxMA / dMinMA) <= 1.03
Else If pStrategyMode = 4 Then vIsDailyBull = GetField("Close", "D") > vDailyMA20 and ((vBigPlayerRatio > 3.0 and vBigPlayerNetBuy > 150) or (vBigPlayerNetBuy > 1500));     
     
If vRefPrice > 0 Then Begin // BE_404
    vTodayRisePct = (Close - vRefPrice) / vRefPrice * 100;    
    vDailyAmp = (GetField("High", "D") - GetField("Low", "D")) / vRefPrice * 100;    
End // BE_404
Else Begin // BE_405
    vTodayRisePct = 0;    
    vDailyAmp = 0;    
End; // BE_405
    
If pMomentum = 1 Then vIsMoney = Close > vRefPrice and Close >= Open Else vIsMoney = Close > vRefPrice;    
If vDailyMA20 > 0 Then vBias = (Close - vDailyMA20) / vDailyMA20 * 100 Else vBias = 0;     
If vBias < 5 Then vBiasDesc = "安全" Else If vBias < 10 Then vBiasDesc = "強勢" Else If vBias < 15 Then vBiasDesc = "警戒" Else vBiasDesc = "危險";     
     
// ========================================================     
// 5. 核心短線時區掃描  (跨頻率雷達)  
// ========================================================     
// 【機制解析】這裡大量使用了跨頻率指標計算 (xfMin_EMA, xfMin_MACD)，讓腳本能夠同時「偷看」1分、5分、15分、30分鐘級別的均線與 MACD 柱狀圖狀態，形成多時區共振分析。
// 【機制解析 - 跨頻率偷看】這裡使用 xfMin_EMA，讓腳本在 1 分 K 的頻率下，可以同時算出 5、10、15、30 分鐘級別的均線。這是「多時區共振」的核心技術。

If pMAType = 1 or pMAType = 2 Then Begin // BE_500
    ema1 = xfMin_EMA("1", GetField("Close", "1"), 20); ema2 = xfMin_EMA("2", GetField("Close", "2"), 20); ema3 = xfMin_EMA("3", GetField("Close", "3"), 20);  
    ema5 = xfMin_EMA("5", GetField("Close", "5"), 20); ema10 = xfMin_EMA("10", GetField("Close", "10"), 20); ema15 = xfMin_EMA("15", GetField("Close", "15"), 20); ema30 = xfMin_EMA("30", GetField("Close", "30"), 20);     
    ma5_5 = xfMin_EMA("5", GetField("Close", "5"), 5); ma10_5 = xfMin_EMA("10", GetField("Close", "10"), 5); ma15_5 = xfMin_EMA("15", GetField("Close", "15"), 5); ma30_5 = xfMin_EMA("30", GetField("Close", "30"), 5);    
End // BE_500
Else If pMAType = 3 Then Begin // BE_501
    ema1 = WMA(GetField("Close", "1"), 20); ema2 = WMA(GetField("Close", "2"), 20); ema3 = WMA(GetField("Close", "3"), 20);    
    ema5 = WMA(GetField("Close", "5"), 20); ema10 = WMA(GetField("Close", "10"), 20); ema15 = WMA(GetField("Close", "15"), 20); ema30 = WMA(GetField("Close", "30"), 20);    
    ma5_5 = WMA(GetField("Close", "5"), 5); ma10_5 = WMA(GetField("Close", "10"), 5); ma15_5 = WMA(GetField("Close", "15"), 5); ma30_5 = WMA(GetField("Close", "30"), 5);    
End // BE_501
Else If pMAType = 4 Then Begin // BE_502
    ema1 = Average(GetField("Close", "1"), 20); ema2 = Average(GetField("Close", "2"), 20); ema3 = Average(GetField("Close", "3"), 20);    
    ema5 = Average(GetField("Close", "5"), 20); ema10 = Average(GetField("Close", "10"), 20); ema15 = Average(GetField("Close", "15"), 20); ema30 = Average(GetField("Close", "30"), 20);    
    ma5_5 = Average(GetField("Close", "5"), 5); ma10_5 = Average(GetField("Close", "10"), 5); ma15_5 = Average(GetField("Close", "15"), 5); ma30_5 = Average(GetField("Close", "30"), 5);    
End // BE_502
Else If pMAType = 5 Then Begin // BE_503
    ema1 = xfMin_EMA("1", GetField("Close", "1"), 39); ema2 = xfMin_EMA("2", GetField("Close", "2"), 39); ema3 = xfMin_EMA("3", GetField("Close", "3"), 39);    
    ema5 = xfMin_EMA("5", GetField("Close", "5"), 39); ema10 = xfMin_EMA("10", GetField("Close", "10"), 39); ema15 = xfMin_EMA("15", GetField("Close", "15"), 39); ema30 = xfMin_EMA("30", GetField("Close", "30"), 39);    
    ma5_5 = xfMin_EMA("5", GetField("Close", "5"), 9); ma10_5 = xfMin_EMA("10", GetField("Close", "10"), 9); ma15_5 = xfMin_EMA("15", GetField("Close", "15"), 9); ma30_5 = xfMin_EMA("30", GetField("Close", "30"), 9);    
End; // BE_503

// 【實戰代碼翻譯】計算每個時區的「乖離得分 (vScore)」。價格站上均線越遠，得分越高。    
If ema5 <= 0 or ema10 <= 0 or ema15 <= 0 or ema30 <= 0 Then Return;    
    
MACD(Close, 12, 26, 9, macdValue1m, macdMA1m, macdOsc1m);  
xfMin_MACD("2",  GetField("Close", "2"),  12, 26, 9, vM_Val2,  vM_MA2,  vM_Osc2);  
xfMin_MACD("3",  GetField("Close", "3"),  12, 26, 9, vM_Val3,  vM_MA3,  vM_Osc3);   
xfMin_MACD("5",  GetField("Close", "5"),  12, 26, 9, vM_Val5,  vM_MA5,  vM_Osc5);  
xfMin_MACD("10", GetField("Close", "10"), 12, 26, 9, vM_Val10, vM_MA10, vM_Osc10);  
xfMin_MACD("15", GetField("Close", "15"), 12, 26, 9, vM_Val15, vM_MA15, vM_Osc15);  
xfMin_MACD("30", GetField("Close", "30"), 12, 26, 9, vM_Val30, vM_MA30, vM_Osc30);  
xfMin_MACD("60", GetField("Close", "60"), 12, 26, 9, vM_Val60, vM_MA60, vM_Osc60);  
  
ema1 = xfMin_EMA("1", GetField("Close", "1"), 20); 
// 【代碼翻譯】計算各分鐘級別相對於該級別均線的「乖離率得分」(vScore)。這將用於後續 AI 決定在哪個時區發動進場。
If ema1 > 0 Then vScore1 = (GetField("Close", "1") - ema1) / ema1  Else vScore1 = 0; 
If ema2 > 0 Then vScore2 = (GetField("Close", "2") - ema2) / ema2  Else vScore2 = 0; 
If ema3 > 0 Then vScore3 = (GetField("Close", "3") - ema3) / ema3  Else vScore3 = 0; 
If ema5 > 0 Then vScore5 = (GetField("Close", "5") - ema5) / ema5  Else vScore5 = 0;     
If ema10 > 0 Then vScore10 = (GetField("Close", "10") - ema10) / ema10  Else vScore10 = 0;     
If ema15 > 0 Then vScore15 = (GetField("Close", "15") - ema15) / ema15  Else vScore15 = 0;     
If ema30 > 0 Then vScore30 = (GetField("Close", "30") - ema30) / ema30  Else vScore30 = 0;     

vMaxScore = 0.0; 
vMinPosScore = 999.0; 
vBestTF = 30; 

// 【代碼翻譯】AI 時區挑選器：若選擇「爆發動能」，則在所有級別中尋找突破乖離最大的一組 (vMaxScore)；若選擇「安全起漲」，則尋找剛突破 0 軸的正乖離最小值 (vMinPosScore)。
// 【機制解析】AI 時區挑選器。若目標設為「爆發動能」，AI 會在所有時區中尋找「得分最高(正乖離最大)」的那個時區當作今天的發動引擎。
If pTFTarget = 1 Then Begin // BE_504
    If vScore1 > vMaxScore Then Begin vMaxScore = vScore1; vBestTF = 1; End; // BE_504.1
    If vScore2 > vMaxScore Then Begin vMaxScore = vScore2; vBestTF = 2; End; // BE_504.2
    If vScore3 > vMaxScore Then Begin vMaxScore = vScore3; vBestTF = 3; End; // BE_504.3
    If vScore5 > vMaxScore Then Begin vMaxScore = vScore5; vBestTF = 5; End; // BE_504.4
    If vScore10 > vMaxScore Then Begin vMaxScore = vScore10; vBestTF = 10; End; // BE_504.5
    If vScore15 > vMaxScore Then Begin vMaxScore = vScore15; vBestTF = 15; End; // BE_504.6
    If vScore30 > vMaxScore Then Begin vMaxScore = vScore30; vBestTF = 30; End; // BE_504.7
End // BE_504
Else If pTFTarget = 2 Then Begin // BE_505
    If vScore1 > 0 and vScore1 < vMinPosScore Then Begin vMinPosScore = vScore1; vBestTF = 1; End; // BE_505.1
    If vScore2 > 0 and vScore2 < vMinPosScore Then Begin vMinPosScore = vScore2; vBestTF = 2; End; // BE_505.2
    If vScore3 > 0 and vScore3 < vMinPosScore Then Begin vMinPosScore = vScore3; vBestTF = 3; End; // BE_505.3
    If vScore5 > 0 and vScore5 < vMinPosScore Then Begin vMinPosScore = vScore5; vBestTF = 5; End; // BE_505.4
    If vScore10 > 0 and vScore10 < vMinPosScore Then Begin vMinPosScore = vScore10; vBestTF = 10; End; // BE_505.5
    If vScore15 > 0 and vScore15 < vMinPosScore Then Begin vMinPosScore = vScore15; vBestTF = 15; End; // BE_505.6
    If vScore30 > 0 and vScore30 < vMinPosScore Then Begin vMinPosScore = vScore30; vBestTF = 30; End; // BE_505.7
      
    If vMinPosScore = 999.0 Then vMaxScore = 0 Else vMaxScore = vMinPosScore; 
End; // BE_505

If pAutoBonus Then Begin // BE_506
    vRealBonusMult = 50.0 + (vNDayAmp * 20.0);      
    If vRealBonusMult > 300.0 Then vRealBonusMult = 300.0;      
End // BE_506
Else Begin // BE_507
    vRealBonusMult = pBonusMult;   
End; // BE_507

If vMaxScore > vHighestScoreToday Then vHighestScoreToday = vMaxScore;

// 【代碼翻譯】動態目標設定 (vDynamicTarget)：以參數 pBaseTarget 為基底起跳，加上乖離得分與獎金乘數 (vRealBonusMult) 的乘積，推算出當前合理的停利空間。
// 【實戰代碼翻譯】計算動態目標價：基底(2.5%或3.5%) + (AI得分 * 動能獎金乘數)。股性越活潑，AI給的目標就越高，自動拉開停利空間。
vFinalScore = vMaxScore; 

If GetField("漲停價", "D") > 0 and Close >= GetField("漲停價", "D") * 0.99 Then Begin // BE_508
    If vFinalScore < vHighestScoreToday Then Begin vFinalScore = vHighestScoreToday; End; // BE_508.1
End; // BE_508

// ★ 依據當前戰略模式 (波段或當沖) 切換對應的停利基底
If vAutoDailyTest = True Then 
    vCurrentBaseTarget = pBaseTargetSW 
Else 
    vCurrentBaseTarget = pBaseTargetDT;

vDynamicTarget = vCurrentBaseTarget + (vFinalScore * vRealBonusMult);    
If vDynamicTarget > pTargetProfit Then vDynamicTarget = pTargetProfit;

// ======================================================== 
// ★ AI 時區大腦動態切換與列印 (防洗頻：限制只在空手時列印)
// ======================================================== 
If pMACDFreqMode = 2 and vBestTF <> vLastBestTF Then Begin // BE_600
    vLastBestTF = vBestTF; 
    
    // ★ 修正：加入 Position = 0，買進後大腦即閉嘴待命
    // 【機制解析】XQ 逐筆洗價非常容易印出海量訊息洗版。加入 Position = 0 與 TimeDiff 間隔 60 秒的限制，能有效防止空手等待期或持倉期產生的龐大無用日誌。
    If Position = 0 and TimeDiff(CurrentTime, vLastBrainPrintTime, "S") >= 60 Then Begin // BE_600.1
        If pTFTarget = 1 Then vModeStr = "爆發動能(最大乖離)" Else vModeStr = "安全起漲(最小正乖離)"; 
          
        Print(NumToStr(Date, 0), NumToStr(Time, 0), Symbol,  
              " [AI 時區大腦] 啟動模式: ", vModeStr,  
              " | 鎖定最佳時區: ", NumToStr(vBestTF, 0), " 分 K", 
              " | 參考得分: ", NumToStr(vMaxScore*100, 2), "%",
              " | 當下動態目標: ", NumToStr(vDynamicTarget, 2), "%"); 
              
        vLastBrainPrintTime = CurrentTime; 
    End; // BE_600.1
End; // BE_600

vIsBerserk = False; 
 
If pMACDFreqMode = 2 Then Begin // BE_601
    If vNDayAmp >= 8.5 or (vRefPrice > 0 and GetField("Open", "D") >= vRefPrice * 1.03) Then Begin // BE_601.1
        // 【代碼翻譯】「極限瘋狗模式」(vIsBerserk)：若近期股性極度活潑或今天開盤直接跳空漲超 3%，則放寬 MACD 濾網，加速追擊。
        vIsBerserk = True; 
    End; // BE_601.1
End; // BE_601
 
If pMACDFreqMode = 1 Then Begin // BE_602
    If pMACDFixedFreq = "1" Then _calcFreq = 1 Else If pMACDFixedFreq = "2" Then _calcFreq = 2 Else If pMACDFixedFreq = "3" Then _calcFreq = 3 Else If pMACDFixedFreq = "10" Then _calcFreq = 10 Else If pMACDFixedFreq = "15" Then _calcFreq = 15 Else If pMACDFixedFreq = "30" Then _calcFreq = 30 Else If pMACDFixedFreq = "60" Then _calcFreq = 60 Else _calcFreq = 5;    
End // BE_602
Else Begin // BE_603
    _calcFreq = vBestTF;     
End; // BE_603
    
If pMACDFreqMode = 0 or vIsBerserk = True Then Begin // BE_604
    macdOsc5m = macdOsc1m;   
    vIsOscBull = True; vIsOscShrink = True; 
End // BE_604
Else Begin // BE_605
    If _calcFreq = 1 Then macdOsc5m = macdOsc1m Else If _calcFreq = 2 Then macdOsc5m = vM_Osc2 Else If _calcFreq = 3 Then macdOsc5m = vM_Osc3 Else If _calcFreq = 10 Then macdOsc5m = vM_Osc10 Else If _calcFreq = 15 Then macdOsc5m = vM_Osc15 Else If _calcFreq = 30 Then macdOsc5m = vM_Osc30 Else If _calcFreq = 60 Then macdOsc5m = vM_Osc60 Else macdOsc5m = vM_Osc5;    
    // 【代碼翻譯】MACD 縮腳/翻紅濾網：要求大時區 (macdOsc5m) 與 小時區 (macdOsc1m) 必須呈現同步走強或綠柱縮腳的狀態，避免進在動能轉弱點。
    vIsOscBull = (macdOsc5m > 0) and (macdOsc1m > macdOsc1m[1]);    
    vIsOscShrink = (macdOsc5m < 0 and macdOsc5m > macdOsc5m[1]) and (macdOsc1m > macdOsc1m[1]);    
End; // BE_605
    
If pUseTVLogic Then Begin // BE_606
    tvIsDailyResonance = (GetField("Close", "D") > vDailyMA20) and (vDailyMA5 > vDailyMA20);    
    tv30mMA20 = ema30; tv30mMA5 = ma30_5;    
    tvIs30mResonance = (GetField("Close", "30") > tv30mMA20) and (tv30mMA5 > tv30mMA20);    
    tvPerfectResonance = tvIsDailyResonance and tvIs30mResonance;    
End // BE_606
Else Begin tvPerfectResonance = True; End; // BE_607
    
If vAutoDailyTest Then Begin // BE_608
    vIsTFBull = True; vIsTFBreak = Close < vDailyMA20; vCrossPrice = vDailyMA20; vCond1 = True; vCond2 = True;      
End // BE_608
Else Begin // BE_609
    vChipCondition = True;      
    If Position = 0 Then vCheckTF = vBestTF Else vCheckTF = vLockTF;      
    vIsTFBull = False; vIsTFBreak = False;      
    
    If vCheckTF = 5 Then Begin // BE_609.1
        vCrossPrice = ema5; vIsTFBull = GetField("Close", "5") > vCrossPrice and GetField("Close", "5") > ma5_5; vIsTFBreak = GetField("Close", "5") < vCrossPrice;      
    End // BE_609.1
    Else If vCheckTF = 10 Then Begin // BE_609.2
        vCrossPrice = ema10; vIsTFBull = GetField("Close", "10") > vCrossPrice and GetField("Close", "10") > ma10_5; vIsTFBreak = GetField("Close", "10") < vCrossPrice;      
    End // BE_609.2
    Else If vCheckTF = 15 Then Begin // BE_609.3
        vCrossPrice = ema15; vIsTFBull = GetField("Close", "15") > vCrossPrice and GetField("Close", "15") > ma15_5; vIsTFBreak = GetField("Close", "15") < vCrossPrice;      
    End // BE_609.3
    Else Begin // BE_609.4
        vCrossPrice = ema30; vIsTFBull = GetField("Close", "30") > vCrossPrice and GetField("Close", "30") > ma30_5; vIsTFBreak = GetField("Close", "30") < vCrossPrice;      
    End; // BE_609.4
    vCond1 = GetField("Close", "60") > Average(GetField("Close", "60"), 20); vCond2 = ma5_5 Crosses Above ema5;      
End; // BE_609
    
If Close < 10 Then vTickSize = 0.01 Else If Close < 50 Then vTickSize = 0.05 Else If Close < 100 Then vTickSize = 0.1    
Else If Close < 500 Then vTickSize = 0.5 Else If Close < 1000 Then vTickSize = 1 Else vTickSize = 5;    
    
vUpLimit = GetField("漲停價", "D");    
If vUpLimit = 0 Then vUpLimit = GetField("Close", "D")[1] * 1.1;     
If vUpLimit > 0 Then Begin // BE_610
    vTicksToLimit = (vUpLimit - Close) / vTickSize; vSpacePct = (vUpLimit - Close) / Close * 100; 
End; // BE_610
    
vNeededCap = Close * 1000 * pTradeQty;      
vTickYield = (vTickSize / Close) * 100;    
If pUseTickPriority = True Then Begin // BE_611
    // 【代碼翻譯】Tick 獲利效率排隊 (Tick Priority)：判斷跳動一個檔位的獲利百分比。若獲利極厚 (>0.45%)，則秒搶 (0秒)；若偏薄，則強迫排隊等待 3 秒或 8 秒，放棄容易滑價的毛躁行情。
    If vTickYield >= 0.45 Then vPrioritySeconds = 0 Else If vTickYield >= 0.20 Then vPrioritySeconds = 3 Else vPrioritySeconds = 8;          
End // BE_611
Else Begin // BE_612
    vPrioritySeconds = 0;                
End; // BE_612
    
If vNeededCap > (pTotalCapital * 10000) Then Begin // BE_613
    vSensitivityMode = "【財務防禦(極穩)】"; vAutoFilter = (macdOsc5m > macdOsc5m[1] and macdOsc5m[1] > macdOsc5m[2]);      
End // BE_613
Else If pAutoGearMode = 1 Then Begin // BE_614
    If Close >= 1000 Then Begin vSensitivityMode = "【千金級(極敏銳)】"; vAutoFilter = True; End // BE_614.1
    Else If Close >= 500 Then Begin vSensitivityMode = "【高價級(微敏銳)】"; vAutoFilter = (macdOsc5m > 0); End // BE_614.2
    Else If Close >= 100 Then Begin vSensitivityMode = "【中價級(標準穩健)】"; vAutoFilter = (macdOsc5m > macdOsc5m[1]); End // BE_614.3
    Else Begin vSensitivityMode = "【低價級(高防禦)】"; vAutoFilter = (macdOsc5m > macdOsc5m[1] and macdOsc5m[1] > macdOsc5m[2]); End; // BE_614.4
End // BE_614
Else Begin // BE_615
    If vNDayAmp < 3.0 Then Begin vSensitivityMode = "【冷靜股性(微敏銳)】"; vAutoFilter = (macdOsc5m > 0); End // BE_615.1
    Else If vNDayAmp < 6.0 Then Begin vSensitivityMode = "【正常股性(標準穩健)】"; vAutoFilter = (macdOsc5m > macdOsc5m[1]); End // BE_615.2
    Else Begin vSensitivityMode = "【瘋狗股性(高防禦)】"; vAutoFilter = (macdOsc5m > macdOsc5m[1] and macdOsc5m[1] > macdOsc5m[2]); End; // BE_615.3
End; // BE_615

If vIsBerserk = True and vNeededCap <=(pTotalCapital * 10000) Then Begin // BE_616
    vSensitivityMode = "【極限瘋狗(卸甲追擊)】"; vAutoFilter = True; 
End; // BE_616

// ★ 解決 XQ IFF 無法回傳字串的問題
If vIsBerserk = True Then vBerserkStr = "True" Else vBerserkStr = "False";

// ========================================================     
// 6. 進場指揮所 (動態時間階梯 + 雙軌防護網與訊號確認)    
// ========================================================     
vAntiGapCond = True;    
    
If pAntiGapDown = True Then Begin // BE_700
    // 【代碼翻譯】動態 ORB (開盤區間突破) 冷卻機制：根據昨日/今日開盤的漲幅落差，決定 09:00~09:05 之間不同的觀望時間 (vWaitTime)，避免開高走低的誘多陷阱。
    // 【機制解析】動態 ORB (開盤區間突破) 冷卻機制。根據開盤跌幅，決定要觀望到 09:01 還是 09:05。在這段時間內找出的最低點 (vMorningLow) 就是今天的鐵底防線。

    If Time = 090000 or (Date <> Date[1]) Then Begin // BE_700.1
        If vTodayRisePct <= -2.0 Then vWaitTime = 090200      
        Else If vTodayRisePct > -2.0 and vTodayRisePct <= 0 Then vWaitTime = 090100      
        Else If vTodayRisePct > 0 and vTodayRisePct < 2.0 Then vWaitTime = 090100      
        Else If vTodayRisePct >= 2.0 and vTodayRisePct < 4.0 Then vWaitTime = 090300      
        Else vWaitTime = 090500;     
    End; // BE_700.1
    
    If Time <= vWaitTime Then Begin // BE_700.2
        If Low < vMorningLow Then vMorningLow = Low; vDayLow = vMorningLow; vIsORB_Break = False; vIsRebound = False; vAntiGapCond = False;     
        If Time <> Time[1] Then Begin // BE_700.2.1
            vCurrentAlertStr = Symbol + " [防護冷卻中] 等待至:" + NumToStr(vWaitTime, 0) + " | 底線:" + NumToStr(vMorningLow, 2) + " | 現價:" + NumToStr(Close, 2);    
            If vCurrentAlertStr <> vLastAlertStr Then Begin Print(NumToStr(Date, 0), NumToStr(Time, 0), vCurrentAlertStr); vLastAlertStr = vCurrentAlertStr; End;    
        End; // BE_700.2.1
    End // BE_700.2
    Else Begin // BE_700.3
        If Low < vDayLow Then vDayLow = Low;    
    
        If Close > vMorningLow Then Begin vIsORB_Break = True; vIsRebound = False; End // BE_700.3.1
        Else If Close >= (vDayLow * 1.008) Then Begin vIsORB_Break = False; vIsRebound = True; End // BE_700.3.2
        Else Begin // BE_700.3.3
            vIsORB_Break = False; vIsRebound = False;   
            
            // ★ 修正：加入 Position = 0，買進後不再印破底尋底，避免洗頻
            If Position = 0 Then Begin // BE_700.3.3.1
                If (vIsDailyBull and vIsMoney and vIsTFBull) or (vIsDailyBull and vCond1 and vCond2) Then Begin // BE_700.3.3.1.1
                   If Time <> Time[1] Then Begin // BE_700.3.3.1.1.1
                       vCurrentAlertStr = Symbol + " [破底尋底中] 低於早盤底線且未達反彈標準，觀望防接刀。";    
                       If vCurrentAlertStr <> vLastAlertStr Then Begin Print(NumToStr(Date, 0), NumToStr(Time, 0), vCurrentAlertStr); vLastAlertStr = vCurrentAlertStr; End;    
                   End; // BE_700.3.3.1.1.1
                End; // BE_700.3.3.1.1
            End; // BE_700.3.3.1
        End; // BE_700.3.3
        If vIsORB_Break = True or vIsRebound = True Then vAntiGapCond = True Else vAntiGapCond = False;    
    End; // BE_700.3
End; // BE_700
    
vIsBerserk = False; 
If vNDayAmp >= 8.5 or (vRefPrice > 0 and GetField("Open", "D") >= vRefPrice * 1.03) Then Begin // BE_701
    vIsBerserk = True; 
End; // BE_701

If vIsBerserk = True Then vBerserkStr = "True" Else vBerserkStr = "False";
 
Var: vFinalOscBull(False); 
If vIsBerserk = True Then vFinalOscBull = True Else vFinalOscBull = vIsOscBull; 

// 【實戰代碼翻譯】終極訊號確認 (vIsDayTradeSignal / vIsSwingSignal)。必須同時滿足：站上均線、MACD縮腳、乖離沒破表、而且通過了早盤的防跌破測試 (vAntiGapCond)。
vIsDayTradeSignal = vIsDailyBull and vIsMoney and vIsTFBull and vFinalOscBull and (vTodayRisePct <= vGapLimit)   
                    and (vBias <= pMaxBias) and (Close >= pMinPrice and Close <= pMaxPrice) and tvPerfectResonance   
                    and vAntiGapCond and vAutoFilter;   
 
vIsSwingSignal = vIsDailyBull and vCond1 and vCond2 and vFinalOscBull and (vTodayRisePct <= vGapLimit)   
                 and (vBias <= pMaxBias) and (Close >= pMinPrice and Close <= pMaxPrice) and tvPerfectResonance   
                 and vAntiGapCond and vAutoFilter; 
 
If (vIsSwingSignal or vIsDayTradeSignal) and vIsBerserk = True Then vSensitivityMode = "【極限瘋狗(卸甲追擊)】";  

If Position = 0 and vFirstSignalTime > 0 Then Begin // BE_702
    If Close < ema10 or Close < vFirstSignalLow Then Begin // BE_702.1
        vFirstSignalTime = 0; vFirstSignalPrice = 0; vFirstSignalClose = 0; vFirstSignalLow = 0; vIntervalHigh = 0; vIntervalLow = 99999;
        vRejectAlertPrinted = False; 
        
        // ★ 終極修正：把系統歷史回放產生的「虛擬進場次數」強制洗掉，與真實帳戶同步！
        // 【機制解析】XQ 的洗價機制在重新啟動時會回放歷史 K 棒，這容易導致腳本累積錯誤的內部變數 (如進場次數)。這邊加入歸零邏輯確保真實上線時帳戶次數同步。
        //vTradesToday = 0; //探底/回檔反彈買回取消  測試用
        vSurgeMaxPrice = 0; // 重置急拉最高價
        
        vCurrentAlertStr = Symbol + " [記憶重置] 舊趨勢已破壞，大腦清除首發記憶，準備抓取新波段！";
        If vCurrentAlertStr <> vLastAlertStr Then Begin Print(NumToStr(Date, 0), NumToStr(Time, 0), vCurrentAlertStr); vLastAlertStr = vCurrentAlertStr; End;
    End; // BE_702.1
End; // BE_702

If (vIsSwingSignal or vIsDayTradeSignal) and vFirstSignalPrice = 0 Then Begin // BE_703
    vFirstSignalPrice = Close; vFirstSignalTime = Time; vFirstSignalClose = Close; vFirstSignalLow = Low; vIntervalHigh = Close; vIntervalLow = Low;    
End; // BE_703
    
If vFirstSignalPrice > 0 Then Begin // BE_704
    If Close > vIntervalHigh Then vIntervalHigh = Close;    
    If Low < vIntervalLow Then vIntervalLow = Low;    
End; // BE_704
    
// ========================================================    
// 8. 訊號執行與【排隊機制】發動   
// ======================================================== 
// 【機制解析】FilledAtBroker 是 XQ 強大的實單庫存抓取函數。利用真實庫存取代腳本虛擬的 Position 來控管張數上限，避免因為系統重啟、手動干預而造成暴衝下單。
// 【機制解析】FilledAtBroker 是真實的券商庫存！用它來取代腳本虛擬部位，是防止斷線重啟後暴衝狂買的最強防線。
vRealPos = FilledAtBroker;
  
If Position = 0 and (pUseBrokerPosCtrl = False or (vRealPos + pTradeQty) <= pMaxBrokerPos) Then Begin // BE_800

// ========================================================
// ★ 動態探底反彈買回機制
// ========================================================
If vWaitBuyBack = True Then Begin // BE_800.1
    // 1. 持續追蹤探底的最低點 (這行照舊，冷卻期內也要繼續找底)
    If Low < vBottomTracking Then vBottomTracking = Low; 
    
    // 【XQ0614 防禦與進化】：必須撐過冷卻期，才准執行後續的接回動作
    If vLastExitBar = -999 or (CurrentBar - vLastExitBar) >= pCoolDownBars Then Begin // BE_800.1.1
        
        // 2. 雙重啟動門檻：跌破上次進場成本 (嚴守紀律的低接) OR 從上次出場價回檔超過設定比例 (強勢波段通道)
        // 這裡改用 pBandPullbackPct 避免參數衝突
        If (Close < vOldEntryPrice) or 
           (Close <= vLastExitPrice * (1 - pBandPullbackPct / 100)) Then Begin // BE_800.1.1.1
            
            // 3. 判斷是否從最低點反彈達標 (彈N檔 或 彈N%)
            If (Close - vBottomTracking >= pBuyBackBounceTicks * vTickSize) or 
               ((Close - vBottomTracking) / vBottomTracking * 100 >= pBuyBackBouncePct) Then Begin // BE_800.1.1.1.1
                
                // 條件達成，市價買回！
                SetPosition(pTradeQty, addSpread(Close,1), label:="【探底/回檔反彈買回】");
                
                // 重置部位與記憶變數 (比照當沖進場規格)
                vOldEntryPrice = Close;  // 更新進場成本，作為下一次的防守基準
                vEntryType = 1; // 視為當沖單
                vEntryDate = Date; // 記錄進場日期 (用於判斷當沖或持倉天數)
                vLockTF = vBestTF; // 鎖定最佳時間頻率
                vInitStop = 0; // 重置初始停損
                vTradesToday = vTradesToday + 1; // 累計今日交易次數 (用於每日交易筆數上限控管)
                vTriggerPrice = Close; // 觸發價格紀錄
                vLockedTarget = vDynamicTarget; // 鎖定本次進場的預期目標價 (避免進場後目標價隨行情波動而變動)
                vDynAlerted = False; // 重置動態警示狀態
                vIsFilledPrinted = False; // 重置成交列印狀態
                vLastAlertStr = ""; // 清除最後警示訊息
                vSurgeMaxPrice = Close;// 記錄進場後的最高價 (作為移動停利/回檔出場的計算基準)
                
                // 買到後關閉雷達，等待下一次停利再開啟
                vWaitBuyBack = False; 
                Return;
            End; // BE_800.1.1.1.1 //BE: 反彈門檻達成
        End; // BE_800.1.1.1 // BE: 啟動門檻達成
        
    End; // BE_800.1.1 // 結束冷卻期判斷
End; // BE_800.1 // BE: 等待買回模式
        
    vAllowEntry = True; vRejectReason = "";    

    // 【實戰代碼翻譯】進場前的各項智慧擋單測試 (預算超支、冷卻期未過、單日次數達標、位階過高)        
    If vTradesToday >= pMaxTrades Then Begin vAllowEntry = False; vRejectReason = "17[部位] 達單日次數上限"; End; // BE_800.2
    If vNeededCap > (pTotalCapital*10000 * 1.5) Then Begin vAllowEntry = False; vRejectReason = "01[資金] 嚴重超出預算1.5倍"; End; // BE_800.3
    // 修改：補上遺漏的 18 號參數冷卻期檢查！確保距離上次出場超過設定的 K 棒數
    If vLastExitBar <> -999 and (CurrentBar - vLastExitBar) < pCoolDownBars Then Begin vAllowEntry = False; vRejectReason = "18[進] 觸發強制冷卻期"; End; // BE_800.4
    
    // ========================================================
    // ★ 新增：停利後新訊號進場防刷單濾網 (檢驗價差是否足夠)
    // ========================================================
    If vLastExitReasonType = 1 And vLastExitPrice > 0 Then Begin // BE_800.5
        // 計算現價與上次停利出場價的絕對價差百分比
        If AbsValue(Close - vLastExitPrice) / vLastExitPrice * 100.0 < pReEntryGapPct Then Begin // BE_800.5.1
            vAllowEntry = False; 
            vRejectReason = "53[進] 距上次停利價差不足 " + NumToStr(pReEntryGapPct, 1) + "%"; 
        End; // BE_800.5.1
    End; // BE_800.5
    
    If vFirstSignalTime > 0 and Time > vFirstSignalTime Then Begin // BE_800.6
        If pCatchUpMode = 2 Then Begin // BE_800.6.1
            If vIntervalHigh > vIntervalLow Then vIntRatio = (Close - vIntervalLow) / (vIntervalHigh - vIntervalLow) Else vIntRatio = 0.5;    
            vDynamicCeiling = vFirstSignalLow + ((vFirstSignalClose - vFirstSignalLow) * vIntRatio);    
            If Close > vDynamicCeiling Then Begin vAllowEntry = False; vRejectReason = "10[上車] 映射位階過高"; End; // BE_800.6.1.1
            If Close < ema10 Then Begin vAllowEntry = False; vRejectReason = "10[上車] 趨勢破壞(跌破10分K均)"; End; // BE_800.6.1.2
            If vTodayRisePct >= (vDynamicTarget * 0.6) Then Begin vAllowEntry = False; vRejectReason = "10[上車] 今日空間耗盡"; End; // BE_800.6.1.3
        End // BE_800.6.1
        Else If pCatchUpMode = 3 Then Begin // BE_800.6.2
            vAllowEntry = False; vRejectReason = "10[上車] 嚴格模式放棄";
        End // BE_800.6.2
        Else If pCatchUpMode = 4 Then Begin // BE_800.6.3
            vDynamicCeiling = vFirstSignalClose * 1.005;        
            
            // ★ 修改：允許綠柱縮腳或紅柱出頭
            If (vIsOscShrink = False) and (vIsOscBull = False) Then Begin // BE_800.6.3.1
                vAllowEntry = False; 
                vRejectReason = "B[上車] MACD未縮腳或未翻紅";   
            End // BE_800.6.3.1
            Else If Close > vDynamicCeiling Then Begin // BE_800.6.3.2
                vAllowEntry = False; 
                vRejectReason = "B[上車] 不追高(高於首發價)"; 
            End; // BE_800.6.3.2
            
            If Close < ema10 Then Begin vAllowEntry = False; vRejectReason = "B[上車] 趨勢破壞(跌破10分K均)"; End; // BE_800.6.3.3
        End; // BE_800.6.3
    End; // BE_800.6
    
    // ========================================================
    // ★ 進場濾網：停損防凹單機制 (當日不回補)
    // ========================================================
    If (vLastExitReasonType = -1) and (Date = GetFieldDate("Date")) Then Begin // BE_800.7
        vAllowEntry = False; 
        vRejectReason = "54[進] 今日已觸發保命停損，啟動鐵血紀律，當日鎖死不再進場"; 
    End; // BE_800.7

    If pUseTVLogic and tvPerfectResonance = False Then Begin vAllowEntry = False; vRejectReason = "43[共振] TV共振消失"; End; // BE_800.8
    If vIsSwingSignal = False and vIsDayTradeSignal = False Then Begin vAllowEntry = False; End; // BE_800.9
    
    If vAllowEntry = True Then Begin // BE_800.10
            
        Condition99 = False;    
        // 【機制解析】排隊機制 (TickPriority)。如果跳一檔賺很少，強迫等待 3~8 秒 (vPrioritySeconds)，確認買氣延續才放行，不當無腦衝鋒的炮灰。
            
        If vPrioritySeconds = 0 Then Begin // BE_800.10.1
            Condition99 = True;    
        End // BE_800.10.1
        Else Begin // BE_800.10.2
            If vSignalFired = False Then Begin // BE_800.10.2.1
                vSignalFired = True; vSignalFireTime = CurrentTime;       
                Print(NumToStr(Date, 0), NumToStr(Time, 0), " [排隊等待] ", Symbol, " 效率:", NumToStr(vTickYield, 2), "%", " 禮讓:", NumToStr(vPrioritySeconds,0), "秒");    
            End; // BE_800.10.2.1
            If vSignalFired = True and TimeDiff(CurrentTime, vSignalFireTime, "S") >= vPrioritySeconds Then Begin // BE_800.10.2.2
                Condition99 = True; vSignalFired = False;    
            End; // BE_800.10.2.2
        End; // BE_800.10.2

            
        If Condition99 = True Then Begin // BE_800.10.3
            // 【機制解析】SetPosition 是 XQ 自動交易送出委託的核心語法。addSpread(Close, 1) 代表向上讓價一檔買進 (確保成交)。Label="【標籤】" 可在下單明細中方便查驗。
            // 【實戰代碼翻譯】正式送出委託！addSpread(Close, 1) 代表往上讓一檔買進，確保高勝率訊號能確實成交。
                If vIsSwingSignal and Position[1] =0 Then Begin // BE_800.10.3.1
                If vIsBerserk = True Then Begin SetPosition(pTradeQty, addSpread(Close,1), label:="【極限瘋狗波段】"); End // BE_800.10.3.1.1
                Else Begin SetPosition(pTradeQty, addSpread(Close,1), label:="波段進場"); End; // BE_800.10.3.1.2
                 
                vEntryType = 2; vEntryDate = Date; vLockTF = 5; vInitStop = 0; vTradesToday = vTradesToday + 1; vTriggerPrice = Close; vLockedTarget = vDynamicTarget; vDynAlerted = False; vIsFilledPrinted = False; vLastAlertStr = ""; vSurgeMaxPrice = Close;       
                     
                vCurrentAlertStr = Symbol + " [進場確認] " + vSensitivityMode + " 價:" + NumToStr(vTriggerPrice, 2) 
                                 + " | 最佳時區:" + NumToStr(vBestTF, 0) + "分 (得分:" + NumToStr(vMaxScore*100, 1) + "%)"                
                                 + " | 距漲停:" + NumToStr(vTicksToLimit, 0) + "檔 | 需預算:" + NumToStr(vNeededCap/10000, 1) + "萬"    
                                 + " | 漲幅:" + NumToStr(vTodayRisePct, 2) + "% | 引擎:" + vSGearStr + " | AI倍數:" + NumToStr(vRealBonusMult, 0)
                                 //  加上這一行 
                                 + " | 大戶護盤:" + NumToStr(vBigPlayerNetBuy, 0) + "張 (佔比:" + NumToStr(vBigPlayerRatio, 1) + "%)";    
                If vCurrentAlertStr <> vLastAlertStr Then Begin Print(NumToStr(Date, 0), NumToStr(Time, 0), vCurrentAlertStr); vLastAlertStr = vCurrentAlertStr; End;       
                
                // ★ AI_DATA 買進紀錄
                vAILogStr = "[AI_DATA] Action=BUY | Sym=" + Symbol + " | Date=" + NumToStr(Date, 0) + " | Time=" + NumToStr(Time, 0) + " | Price=" + NumToStr(vTriggerPrice, 2) + " | Pnl=0.0 | Pos=" + NumToStr(Position, 0) + " | AvgP=" + NumToStr(FilledAvgPrice, 2) + " | NetBuy=" + NumToStr(vBigPlayerNetBuy, 0) + vTrackStr + " | Mode=" + vSensitivityMode + " | TF=" + NumToStr(vBestTF, 0) + " | Score=" + NumToStr(vMaxScore*100, 2) + " | Amp=" + NumToStr(vNDayAmp, 2) + " | Cap=" + NumToStr(vNeededCap/10000, 1) + " | Target=" + NumToStr(vDynamicTarget, 2) + " | Berserk=" + vBerserkStr + " | Market=" + vStateCategory + " | Reason=波段進場"; 
                Print(vAILogStr);

            End // BE_800.10.3.1
            Else If vIsDayTradeSignal and Position[1] = 0 Then Begin // BE_800.10.3.2
                If vIsBerserk = True Then Begin SetPosition(pTradeQty, addSpread(Close,1), label:="【極限瘋狗當沖】"); End // BE_800.10.3.2.1
                Else Begin SetPosition(pTradeQty, addSpread(Close,1), label:="當沖進場"); End; // BE_800.10.3.2.2
                 
                vEntryType = 1; vEntryDate = Date; vLockTF = vBestTF; vInitStop = 0; vTradesToday = vTradesToday + 1; vTriggerPrice = Close; vLockedTarget = vDynamicTarget; vDynAlerted = False; vIsFilledPrinted = False; vLastAlertStr = ""; vSurgeMaxPrice = Close;       
                     
                vCurrentAlertStr = Symbol + " [進場確認] " + vSensitivityMode + " 價:" + NumToStr(vTriggerPrice, 2) 
                                 + " | 最佳時區:" + NumToStr(vBestTF, 0) + "分 (得分:" + NumToStr(vMaxScore*100, 1) + "%)"                
                                 + " | 距漲停:" + NumToStr(vTicksToLimit, 0) + "檔 | 需預算:" + NumToStr(vNeededCap/10000, 1) + "萬"    
                                 + " | 結構:日+" + NumToStr(vBestTF, 0) + "分 | 引擎:" + vSGearStr + " | AI倍數:" + NumToStr(vRealBonusMult, 0);    
                If vCurrentAlertStr <> vLastAlertStr Then Begin Print(NumToStr(Date, 0), NumToStr(Time, 0), vCurrentAlertStr); vLastAlertStr = vCurrentAlertStr; End;       
                
                // ★ AI_DATA 買進紀錄
                vAILogStr = "[AI_DATA] Action=BUY | Sym=" + Symbol + " | Date=" + NumToStr(Date, 0) + " | Time=" + NumToStr(Time, 0) + " | Price=" + NumToStr(vTriggerPrice, 2) + " | Pnl=0.0 | Pos=" + NumToStr(Position, 0) + " | AvgP=" + NumToStr(FilledAvgPrice, 2) + " | NetBuy=" + NumToStr(vBigPlayerNetBuy, 0) + vTrackStr + " | Mode=" + vSensitivityMode + " | TF=" + NumToStr(vBestTF, 0) + " | Score=" + NumToStr(vMaxScore*100, 2) + " | Amp=" + NumToStr(vNDayAmp, 2) + " | Cap=" + NumToStr(vNeededCap/10000, 1) + " | Target=" + NumToStr(vDynamicTarget, 2) + " | Berserk=" + vBerserkStr + " | Market=" + vStateCategory + " | Reason=當沖進場"; 
                Print(vAILogStr);
            End; // BE_800.10.3.2
        End; // BE_800.10.3
            
    End // BE_800.10
    Else Begin // BE_800.11
        If vSignalFired = True Then Begin // BE_800.11.1
            Print(NumToStr(Date, 0), NumToStr(Time, 0), " [取消排隊] ", Symbol, " ", vRejectReason,  NumToStr(vFirstSignalPrice, 2) , " 濾網中斷，放棄進場。"); vSignalFired = False;       
        End; // BE_800.11.1
            
        If vRejectAlertPrinted = False and (vIsSwingSignal or vIsDayTradeSignal) Then Begin // BE_800.11.2
            vCurrentAlertStr = Symbol + " [智慧擋單] " + vRejectReason + "。首發時間:" + NumToStr(vFirstSignalTime, 0) + "。首發價:" + NumToStr(vFirstSignalPrice, 2) + " 現價:" + NumToStr(Close, 2);       
            If vCurrentAlertStr <> vLastAlertStr Then Begin // BE_800.11.2.1
                Print(NumToStr(Date, 0), NumToStr(Time, 0), vCurrentAlertStr); 
                vLastAlertStr = vCurrentAlertStr; 
                // ★ AI_DATA 擋單紀錄
                vAILogStr = "[AI_DATA] Action=BLOCK | Sym=" + Symbol + " | Date=" + NumToStr(Date, 0) + " | Time=" + NumToStr(Time, 0) + " | Price=" + NumToStr(Close, 2) + " | Pnl=0.0 | Pos=" + NumToStr(Position, 0) + " | AvgP=" + NumToStr(FilledAvgPrice, 2) + " | NetBuy=" + NumToStr(vBigPlayerNetBuy, 0) + vTrackStr + " | Mode=" + vSensitivityMode + " | TF=" + NumToStr(vBestTF, 0) + " | Score=" + NumToStr(vMaxScore*100, 2) + " | Amp=" + NumToStr(vNDayAmp, 2) + " | Cap=" + NumToStr(vNeededCap/10000, 1) + " | Target=" + NumToStr(vDynamicTarget, 2) + " | Berserk=" + vBerserkStr + " | Market=" + vStateCategory + " | Reason=" + vRejectReason; 
                Print(vAILogStr); //(列印進場日誌)
            End; // BE_800.11.2.1
            vRejectAlertPrinted = True;       
        End; // BE_800.11.2
    End; // BE_800.11
End; // BE_800
    
// ========================================================     
// 7. 出場與防護指令 (重構優先權：確保保底不漏接)    
// ========================================================     
If Position > 0 Then Begin // BE_900

// 【代碼翻譯】斷線/重啟防護：如果發現目前有部位 (Position>0 或庫存均價大於 0)，但缺少進場種類記憶 (vEntryType=0)，系統會自動接管，並透過抓取全日最高得分還原目標，防止因重啟造成瞎砍。
// 【機制解析】重啟接管機制。如果系統內部沒有進場記憶，但券商庫存 (FilledAvgPrice) 卻有貨，代表剛剛斷線重啟了。立刻抓今天的最高得分來還原停利目標！
    // 如果沒有進場記憶，且真實庫存大於 0，但均價還沒傳過來，就先不要動作，等下一筆洗價
    If vEntryType = 0 and FilledAtBroker > 0 and FilledAvgPrice = 0 Then Begin // BE_900.1
        Print(NumToStr(Date, 0), NumToStr(Time, 0), Symbol, " [警告] 偵測到庫存，但券商尚未回傳均價，等待資料同步中...");
        Return; // 強制中斷這次洗價，等下一筆資料
    End; // BE_900.1

// 資料齊全後，再正式接管
    If vEntryType = 0 and FilledAvgPrice > 0 Then Begin // BE_900.2
        vEntryType = 2; 
        vTriggerPrice = FilledAvgPrice; 
        
        // ★ 修正核心：重啟接管時，強制抓取今日歷史洗價出現過的「最高得分」來還原目標
        // 依據當前戰略模式切換接管時的基底
        If vAutoDailyTest = True Then
            vLockedTarget = pBaseTargetSW + (vHighestScoreToday * vRealBonusMult)
        Else
            vLockedTarget = pBaseTargetDT + (vHighestScoreToday * vRealBonusMult);
            
        If vLockedTarget > pTargetProfit Then vLockedTarget = pTargetProfit;
        
        vIsFilledPrinted = True; // 避免重啟時重複印出成交回報
        vSurgeMaxPrice = Close; 
        
        If vFirstSignalTime > 0 Then Begin vDisplayEntryTime = vFirstSignalTime; End // BE_900.2.1
        Else If FilledRecordCount > 0 Then Begin vDisplayEntryTime = FilledRecordTime(1); vFirstSignalTime = vDisplayEntryTime; End; // BE_900.2.2

        vCurrentAlertStr = Symbol + " [系統重啟接管] 首發/進場時間:" + NumToStr(vDisplayEntryTime, 0) + " | 偵測庫存均價:" + NumToStr(FilledAvgPrice, 2) + " | 抓取最高得分還原目標:" + NumToStr(vLockedTarget, 2) + "%";
        If vCurrentAlertStr <> vLastAlertStr Then Begin Print(NumToStr(Date, 0), NumToStr(Time, 0), vCurrentAlertStr); vLastAlertStr = vCurrentAlertStr; End; // BE_900.2.3
    End; // BE_900.2

    If vLockedTarget = 0 Then vLockedTarget = pTargetProfit;       
   
    If vInitStop = 0 and FilledAvgPrice > 0 Then Begin // BE_900.3
        vInitStop = FilledAvgPrice * (1 - (pStopLoss / 100.0));   
        vHighSinceEntry = MaxList(Close, FilledAvgPrice);  
        
        vRealMinProfitPrice = FilledAvgPrice * (1 + (pMinProfit / 100.0)); 
        vRealTargetPrice = FilledAvgPrice * (1 + (vLockedTarget / 100.0)); 
        
        // 【機制解析】為求計算嚴謹並避免因跳動點距誤差而無法停利/停損，依照股價區間將 % 數停利停損價 Round (四捨五入) 至正確的最小跳動 TickSize。
        If vRealTargetPrice < 10 Then vTickTargetPrice = Round(vRealTargetPrice / 0.01, 0) * 0.01 Else If vRealTargetPrice < 50 Then vTickTargetPrice = Round(vRealTargetPrice / 0.05, 0) * 0.05 Else If vRealTargetPrice < 100 Then vTickTargetPrice = Round(vRealTargetPrice / 0.1, 0) * 0.1 Else If vRealTargetPrice < 500 Then vTickTargetPrice = Round(vRealTargetPrice / 0.5, 0) * 0.5 Else If vRealTargetPrice < 1000 Then vTickTargetPrice = Round(vRealTargetPrice / 1.0, 0) * 1.0 Else vTickTargetPrice = Round(vRealTargetPrice / 5.0, 0) * 5.0;
        If vRealMinProfitPrice < 10 Then vTickMinProfit = Round(vRealMinProfitPrice / 0.01, 0) * 0.01 Else If vRealMinProfitPrice < 50 Then vTickMinProfit = Round(vRealMinProfitPrice / 0.05, 0) * 0.05 Else If vRealMinProfitPrice < 100 Then vTickMinProfit = Round(vRealMinProfitPrice / 0.1, 0) * 0.1 Else If vRealMinProfitPrice < 500 Then vTickMinProfit = Round(vRealMinProfitPrice / 0.5, 0) * 0.5 Else If vRealMinProfitPrice < 1000 Then vTickMinProfit = Round(vRealMinProfitPrice / 1.0, 0) * 1.0 Else vTickMinProfit = Round(vRealMinProfitPrice / 5.0, 0) * 5.0;
    End; // BE_900.3

    // ========================================================
    // ★ 新增：庫存戰情回報與彈窗警示 (針對抱單過夜或重啟接管)  動態急拉停利 (滾動視窗追蹤)
    // 【機制解析】Lowest 尋找最近 15 根 K 棒的低點。如果短時間內拉開了 4.5% (瘋狗急拉)，只要稍微回檔 2 個 Tick，立刻市價收割，絕不抱上抱下。
    // ========================================================
    If vDailyPosReported = False and FilledAvgPrice > 0 and vTickTargetPrice > 0 Then Begin // BE_900.4
        vDailyPosReported = True; // 標記今日已回報
        If vIsFilledPrinted = True Then Begin // BE_900.4.1
            vCurrentAlertStr = Symbol + " [庫存戰情警示] 持倉均價:" + NumToStr(FilledAvgPrice, 2) + " | 今日預計停利:" + NumToStr(vRealTargetPrice, 2) + "(" + NumToStr(vTickTargetPrice, 2) + ")" + " | 底線:" + NumToStr(vInitStop, 2) + " | filledAtBroker[1]=0以防止 09 濾網重複進場" +  NumToStr(vRealPos[1], 1);
            Print(NumToStr(Date, 0), NumToStr(Time, 0), vCurrentAlertStr);
            
            // ★ 呼叫 XQ 系統彈窗與聲音警示！
            Alert(Symbol + " 庫存均價:" + NumToStr(FilledAvgPrice, 2) 
                         + " 今日預計停利:" + NumToStr(vTickTargetPrice, 2) 
                         + " 今日預計獲利:" + NumToStr((vTickTargetPrice - FilledAvgPrice) / FilledAvgPrice * 100, 2) + "%" 
                         + " 漲跌停:" + NumToStr(GetField("漲停價", "D"), 2) + " / " + NumToStr(GetField("跌停價", "D"), 2));
        End; // BE_900.4.1
    End; // BE_900.4

    If FilledAvgPrice > 0 and vIsFilledPrinted = False and vTriggerPrice > 0 Then Begin // BE_900.5
        vIsFilledPrinted = True;     
        vCurrentAlertStr = Symbol + " [成交回報] 首發時間:" + NumToStr(vFirstSignalTime, 0) + " | 均價:" + NumToStr(FilledAvgPrice, 2) + " | 觸發價:" + NumToStr(vTriggerPrice, 2) + " | 目標停利:" + NumToStr(vRealTargetPrice, 2) + "(" + NumToStr(vTickTargetPrice, 2) + ")" + " | 移停啟動:" + NumToStr(vRealMinProfitPrice, 2) + "(" + NumToStr(vTickMinProfit, 2) + ")" + " | 死亡線:" + NumToStr(vInitStop, 2);     
        If vCurrentAlertStr <> vLastAlertStr Then Begin Print(NumToStr(Date, 0), NumToStr(Time, 0), vCurrentAlertStr); vLastAlertStr = vCurrentAlertStr; End; // BE_900.5.1
    End; // BE_900.5
    
    If vInitStop > 0 Then Begin // BE_900.6
        vProfitPct = (Close - FilledAvgPrice) / FilledAvgPrice * 100;     
        If Close > vHighSinceEntry Then vHighSinceEntry = Close;     
              
        sumTR = 0;     
        For i = 0 to 13 Begin // BE_900.6.1
            dTR = MaxList(GetField("High", "D")[i] - GetField("Low", "D")[i], AbsValue(GetField("High", "D")[i] - GetField("Close", "D")[i+1]), AbsValue(GetField("Low", "D")[i] - GetField("Close", "D")[i+1])); sumTR = sumTR + dTR; 
        End; // BE_900.6.1
        vMyATR = sumTR / 14.0; vDynStop = vHighSinceEntry - (vMyATR * pATRMult);     
        If vDynStop < vInitStop Then vDynStop = vInitStop;     
        
        // ========================================================
        // ★ 動態急拉停利 (滾動視窗追蹤)
        // ========================================================
        // 【機制解析】傳統停利都是固定 % 數，這段邏輯改以 Lowest 尋找最近 pSurgeBars (滾動視窗) 的相對低點，藉此算出急拉波段的真實幅度。只要拉出空間並從高檔回檔 (Tick或%)，立刻入袋。
        // 1. 動態抓取近期低點 (取代死板的 GetField("Low", "D"))
        vRecentLow = Lowest(Low, pSurgeBars); 

        // 2. 判斷是否構成急拉條件
        If (vRecentLow > 0) Then Begin // BE_900.6.2
            If ((Close - vRecentLow) / vRecentLow) >= (pSurgePct / 100.0) Then Begin // BE_900.6.2.1
                vCondSurge = True;
            End; // BE_900.6.2.1
        End; // BE_900.6.2


        // ========================================================
        // ★ XQ0614 獨家防護網：盤中暫緩交易 (瞬間價格穩定措施) 出關偵測
        // ========================================================
        // 若在盤中 (避開早盤與尾盤) 偵測到 TickGroup = -1，代表剛從集合競價出關
        If Time > 090500 and Time < 132000 Then Begin
            If GetField("TickGroup", "Tick") = -1 Then Begin
                // 重置最高價為出關開出價，避免拿被關前的高價直接觸發回檔
                vSurgeMaxPrice = Close; 
                // 記錄出關的電腦時間
                vHaltImmunityTime = CurrentTime; 
                
                vCurrentAlertStr = Symbol + " [系統防護] 觸發瞬間價格穩定措施出關，重置急拉最高價，啟動 15 秒冷卻防護！";
                If vCurrentAlertStr <> vLastAlertStr Then Begin 
                    Print(NumToStr(Date, 0), NumToStr(Time, 0), vCurrentAlertStr); 
                    vLastAlertStr = vCurrentAlertStr; 
                End;
            End;
        End;
		
        // 3. 進入急拉狀態後，利用 IntrabarPersist 動態追蹤最高價
        If vCondSurge = True Then Begin // BE_900.6.3
            If Close > vSurgeMaxPrice Then Begin vSurgeMaxPrice = Close; End; // BE_900.6.3.1
        End; // BE_900.6.3

        // 4. 確認是否達到最低停利門檻
        vCondSurgeProfit = Close >= FilledAvgPrice * (1 + (pMinSurgeProfit / 100.0));

        // 5. 動態計算 Tick Size 避免高低價位跳動單位不同
        If vSurgeMaxPrice < 10 Then vSurgeTickSize = 0.01 
        Else If vSurgeMaxPrice < 50 Then vSurgeTickSize = 0.05 
        Else If vSurgeMaxPrice < 100 Then vSurgeTickSize = 0.1 
        Else If vSurgeMaxPrice < 500 Then vSurgeTickSize = 0.5 
        Else If vSurgeMaxPrice < 1000 Then vSurgeTickSize = 1 
        Else vSurgeTickSize = 5;

        // 6. 計算回檔條件 (檔位回檔 或 %數回檔，雙重防線) (加入免死金牌過濾)
        If vSurgeMaxPrice > 0 Then Begin // BE_900.6.4
			// 檢查距離出關時間是否小於 15 秒。若在免死金牌時間內，強迫阻斷回檔訊號
            If vHaltImmunityTime > 0 and TimeDiff(CurrentTime, vHaltImmunityTime, "S") <= 15 Then Begin
                vCondPullback = False;
            End
            Else Begin
                // 正常回檔判斷 (檔位回檔 或 %數回檔，雙重防線)
            vCondPullback = (vSurgeMaxPrice - Close >= pPullbackTicks * vSurgeTickSize) and 
                            ((vSurgeMaxPrice - Close) / vSurgeMaxPrice >= (pPullbackPct / 100.0));
			End;
		End// BE_900.6.4
        Else Begin // BE_900.6.5
            vCondPullback = False;
        End; // BE_900.6.5
              
        // 【代碼翻譯】SetPosition(0) 在 XQ 的含義就是「平倉清空部位」(即回到空手狀態)，並非反手做空 (反手做空為 SetPosition(-1))。此處為出場區塊。
        // 【實戰代碼翻譯】嚴格的階梯式出場邏輯。先看是否達標停利 -> 再看是否時間到了該當沖平倉 -> 再看是否急拉回檔 -> 最後看破線或停損。
        If (vLockedTarget > 0) and (Close >= vTickTargetPrice) Then Begin // BE_900.6.6
            If pAutoSellDyn Then Begin // BE_900.6.6.1
                SetPosition(0, vTickTargetPrice, label:="波動達標自動停利(21/28/45)"); 
                vLastExitBar = CurrentBar;
                vLastExitReasonType = 1; // <--- 標記為停利
                vLastExitPrice = Close;  // <--- 無條件紀錄出場價
                
                // ★ 啟動探底雷達
                If pEnableBuyBack Then Begin // BE_900.6.6.1.1
                    vWaitBuyBack = True; vBottomTracking = Low; vOldEntryPrice = FilledAvgPrice; 
                End; // BE_900.6.6.1.1
            End // BE_900.6.6.1
            Else If vDynAlerted = False Then Begin // BE_900.6.6.2
                vDynAlerted = True; 
            End; // BE_900.6.6.2
        End // BE_900.6.6
        Else If ((vTodayRisePct >= 8.5) or (vDailyAmp >= 10.0)) and (Close >= vTickMinProfit) Then Begin // BE_900.6.7
            If pAutoSellDyn Then Begin // BE_900.6.7.1
                SetPosition(0, vTickMinProfit, label:="巨震漲停鎖利(28/30)"); 
                vLastExitBar = CurrentBar;
                vLastExitReasonType = 1; // <--- 標記為停利
                vLastExitPrice = Close;  // <--- 無條件紀錄出場價
                
                // ★ 啟動探底雷達
                If pEnableBuyBack Then Begin // BE_900.6.7.1.1
                    vWaitBuyBack = True; vBottomTracking = Low; vOldEntryPrice = FilledAvgPrice; 
                End; // BE_900.6.7.1.1
            End; // BE_900.6.7.1
        End // BE_900.6.7
        Else If (vEntryType = 1) and (pAutoCloseDT = True) and (Time >= 132000) and (pMasterNoLossSwitch = False or vProfitPct >= 0) Then Begin // BE_900.6.8
            SetPosition(0, close, label:="當沖自動清倉(15/02)"); 
            vLastExitBar = CurrentBar;
            vLastExitReasonType = 1; // <--- 標記為停利(時間清倉若未虧損，視同停利基準)
            vLastExitPrice = Close;  // <--- 無條件紀錄出場價
        End // BE_900.6.8
        Else If (vEntryType = 2) and (Date = vEntryDate) and (vProfitPct >= 5.0) Then Begin // BE_900.6.9
            SetPosition(0, close, label:="首日暴利停利"); 
            vLastExitBar = CurrentBar; // <--- 補上更新出場K棒，維持冷卻期判斷一致
            vLastExitReasonType = 1; // <--- 標記為停利            
            vLastExitPrice = Close;  // <--- 無條件紀錄出場價
            
            // ★ 啟動探底雷達
            If pEnableBuyBack Then Begin // BE_900.6.9.1
                vWaitBuyBack = True; vBottomTracking = Low; vOldEntryPrice = FilledAvgPrice; 
            End; // BE_900.6.9.1
        End // BE_900.6.9
        Else If (vEntryType = 2) and (vProfitPct >= pTargetProfit) Then Begin // BE_900.6.10
            SetPosition(0, close, label:="波段強制停利(21)"); 
            vLastExitBar = CurrentBar;
            vLastExitReasonType = 1; // <--- 標記為停利
            vLastExitPrice = Close;  // <--- 無條件紀錄出場價
            
            // ★ 啟動探底雷達
            If pEnableBuyBack Then Begin // BE_900.6.10.1
                vWaitBuyBack = True; vBottomTracking = Low; vOldEntryPrice = FilledAvgPrice; 
            End; // BE_900.6.10.1
        End // BE_900.6.10
        Else If (vEntryType = 1) and (vHighSinceEntry >= FilledAvgPrice * 1.03) Then Begin // BE_900.6.11
            vTrailStopPrice = vHighSinceEntry - (vMyATR * 0.5);  
            If (Close >= vTickMinProfit) and (Close <= vTrailStopPrice) Then Begin // BE_900.6.11.1
                SetPosition(0, close, label:="當沖高檔鎖利"); 
                vLastExitBar = CurrentBar; // <--- 補上更新出場K棒
                vLastExitReasonType = 1; // <--- 標記為停利
                vLastExitPrice = Close;  // <--- 無條件紀錄出場價
                
                // ★ 啟動探底雷達
                If pEnableBuyBack Then Begin // BE_900.6.11.1.1
                    vWaitBuyBack = True; vBottomTracking = Low; vOldEntryPrice = FilledAvgPrice; 
                End; // BE_900.6.11.1.1
            End // BE_900.6.11.1
            Else If Close = vHighSinceEntry Then Begin // BE_900.6.11.2
                vCurrentAlertStr = Symbol + " [高空追蹤中] 最高價 " + NumToStr(vHighSinceEntry, 2) + "，短防守 " + NumToStr(vTrailStopPrice, 2) + " (深洗盤將由均線接管)"; 
                If vCurrentAlertStr <> vLastAlertStr Then Begin Print(NumToStr(Date, 0), NumToStr(Time, 0), vCurrentAlertStr); vLastAlertStr = vCurrentAlertStr; End; // BE_900.6.11.2.1
            End; // BE_900.6.11.2
        End // BE_900.6.11
        Else If vCondSurge and vCondSurgeProfit and vCondPullback Then Begin // BE_900.6.12
            If pAutoSellDyn Then Begin // BE_900.6.12.1
                SetPosition(0, Close, label:="急拉回檔停利(23-26)"); 
                vLastExitBar = CurrentBar;
                vLastExitReasonType = 1; // <--- 標記為停利
                vLastExitPrice = Close;  // <--- 無條件紀錄出場價
                
                // ★ 啟動探底雷達
                If pEnableBuyBack Then Begin // BE_900.6.12.1.1
                    vWaitBuyBack = True; vBottomTracking = Low; vOldEntryPrice = FilledAvgPrice; 
                End; // BE_900.6.12.1.1
                
                vAILogStr = "[AI_DATA] Action=SELL | Sym=" + Symbol + " | Date=" + NumToStr(Date, 0) + " | Time=" + NumToStr(Time, 0) + " | Price=" + NumToStr(Close, 2) + " | Pnl=" + NumToStr(vProfitPct, 2) + " | Pos=" + NumToStr(Position, 0) + " | AvgP=" + NumToStr(FilledAvgPrice, 2) + " | NetBuy=" + NumToStr(vBigPlayerNetBuy, 0) + vTrackStr + " | Mode=" + vSensitivityMode + " | TF=" + NumToStr(vLockTF, 0) + " | Score=" + NumToStr(vMaxScore*100, 2) + " | Amp=" + NumToStr(vNDayAmp, 2) + " | Cap=" + NumToStr(vNeededCap/10000, 1) + " | Target=" + NumToStr(vDynamicTarget, 2) + " | Berserk=" + vBerserkStr + " | Market=" + vStateCategory + " | Reason=急拉回檔停利";
                Print(vAILogStr);
            End // BE_900.6.12.1
            Else If vDynAlerted = False Then Begin // BE_900.6.12.2
                vDynAlerted = True; 
            End; // BE_900.6.12.2
        End // BE_900.6.12
        Else If vIsTFBreak Then Begin // BE_900.6.13
            If vIsChipProtect Then Begin // BE_900.6.13.1
                vCurrentAlertStr = Symbol + " [籌碼護盤] 均線破位，但偵測到大戶防禦網 (淨買超 " + NumToStr(vBigPlayerNetBuy,0) + " 張)。攔截平倉指令，強勢續抱！"; 
                If vCurrentAlertStr <> vLastAlertStr Then Begin Print(NumToStr(Date, 0), NumToStr(Time, 0), vCurrentAlertStr); vLastAlertStr = vCurrentAlertStr; End; // BE_900.6.13.1.1
            End // BE_900.6.13.1
            Else Begin // BE_900.6.13.2
                If close >= vTickMinProfit Then Begin // BE_900.6.13.2.1
                    SetPosition(0, close, label:="破線停利(30/44)"); 
                    vLastExitBar = CurrentBar; 
                    vLastExitReasonType = 1; // <--- 標記為停利
                    vLastExitPrice = Close;  // <--- 無條件紀錄出場價
                    
                    Print(NumToStr(Date, 0), NumToStr(Time, 0), Symbol, " [出場執行] 破線停利 | 觸發價:", NumToStr(Close, 2), " | 獲利:", NumToStr(vProfitPct, 2), "%");
                End // BE_900.6.13.2.1
                Else If pStrictBreak = True and (pMasterNoLossSwitch = False or vProfitPct >= 0) Then Begin // BE_900.6.13.2.2
                    SetPosition(0, close, label:="嚴格破線(32/02/44)"); vLastExitBar = CurrentBar; 
                    vLastExitReasonType = -1; // <--- 標記為停損
                    vLastExitPrice = Close;   // <--- 確保紀錄停損出場價
                    Print(NumToStr(Date, 0), NumToStr(Time, 0), Symbol, " [出場執行] 嚴格破線停損/停利");
                End // BE_900.6.13.2.2
                Else If (pStrictBreak = False) and (Close <= vCrossPrice * (1 - (pBreakTolerance / 100.0))) and (pMasterNoLossSwitch = False or vProfitPct >= 0)  Then Begin // BE_900.6.13.2.3
                    SetPosition(0, close, label:="容忍極限(33/02/44)"); vLastExitBar = CurrentBar;
                    vLastExitReasonType = -1; // <--- 標記為停損
                    vLastExitPrice = Close;   // <--- 確保紀錄停損出場價                    
                    Print(NumToStr(Date, 0), NumToStr(Time, 0), Symbol, " [出場執行] 跌破容忍極限出場");
                End; // BE_900.6.13.2.3
            End; // BE_900.6.13.2
        End // BE_900.6.13
        Else If (pNoLossExit = False) and (Close <= vInitStop) and (pMasterNoLossSwitch = False or vProfitPct >= 0) Then Begin // BE_900.6.14
            SetPosition(0, close, label:="保命停損(31/42/02)"); vLastExitBar = CurrentBar;
            vLastExitReasonType = -1; // <--- 標記為停損
            vLastExitPrice = Close;   // <--- 確保紀錄停損出場價        
            Print(NumToStr(Date, 0), NumToStr(Time, 0), Symbol, " [出場執行] 保命停損斷頭 | 觸發價:", NumToStr(Close, 2));
        End; // BE_900.6.14
    End; // BE_900.6
End; // BE_900

// ========================================================
If Time = 132900 Then Begin // BE_1000
    If FilledAvgPrice > 0 Then Begin // BE_1000.1
        vFinalProfitPct = (Close - FilledAvgPrice) / FilledAvgPrice * 100.0;
        vEndReportStr = Symbol + " [收盤總結-抱單中] 結算價:" + NumToStr(Close, 2) + " | 庫存:" + NumToStr(Position , 0) + " | 均價:" + NumToStr(FilledAvgPrice, 2) + " | 帳面損益:" + NumToStr(vFinalProfitPct, 2) + "%" + " | 今日最強動能記憶:" + NumToStr(vHighestScoreToday, 4) + " | 最終動態目標:" + NumToStr(vDynamicTarget, 2) + "%  抱單過夜，防線鎖定！";
    End // BE_1000.1
    Else Begin // BE_1000.2
        vEndReportStr = Symbol + " [收盤總結-空手] 結算價:" + NumToStr(Close, 2) + " | 庫存:" + NumToStr(Position , 0) + " | 均價:" + NumToStr(FilledAvgPrice, 2) + " | 狀態: 目前無部位  引擎休眠，等待明日訊號！";
    End; // BE_1000.2
    Print(NumToStr(Date, 0), NumToStr(Time, 0), vEndReportStr);
    
End; // BE_1000

// ========================================================
// ★ 環境風險監控 (V7.576 防彈遲滯版)
// ========================================================

// 【代碼翻譯】讀取大盤 GetSymbolField("TSE.TW") 用以與個股進行相對強弱比對。計算大盤與個股的單日漲跌 % 數，藉此切換多空環境警報。
// 【實戰代碼翻譯】如果大盤大跌 1.5% (vMemMarket = -1)，個股也大跌 7% (vMemStock = -1)，系統會發出「雙重警報：崩跌確認，嚴守防線」的紅色警告。
vTSE_Ref = GetSymbolField("TSE.TW", "Close", "D")[1]; 
If vTSE_Ref <> 0 Then vMarketPct = (GetSymbolField("TSE.TW", "Close") - vTSE_Ref) / vTSE_Ref * 100.0;
vStock_Ref = GetField("參考價", "D", Default := 0); 
If vStock_Ref <> 0 Then vStockPct = (Close - vStock_Ref) / vStock_Ref * 100.0;

If vMemMarket = 1 Then Begin // BE_1100
    If vMarketPct < 1.0 Then Begin vMemMarket = 0; End; // BE_1100.1
End // BE_1100
Else If vMemMarket = -1 Then Begin // BE_1101
    If vMarketPct > -1.0 Then Begin vMemMarket = 0; End; // BE_1101.1
End // BE_1101
Else Begin // BE_1102
    If vMarketPct >= 1.5 Then Begin vMemMarket = 1; End; // BE_1102.1
    If vMarketPct <= -1.5 Then Begin vMemMarket = -1; End; // BE_1102.2
End; // BE_1102

If vMemStock = 1 Then Begin // BE_1200
    If vStockPct < 6.0 Then Begin vMemStock = 0; End; // BE_1200.1 
End // BE_1200
Else If vMemStock = -1 Then Begin // BE_1201
    If vStockPct > -6.0 Then Begin vMemStock = 0; End; // BE_1201.1
End // BE_1201
Else Begin // BE_1202
    If vStockPct >= 7.0 Then Begin vMemStock = 1; End; // BE_1202.1
    If vStockPct <= -7.0 Then Begin vMemStock = -1; End; // BE_1202.2
End; // BE_1202

vStateCategory = ""; vActionMsg = "";
bIsMarketEvent = (vMemMarket <> 0);
bIsStockEvent = (vMemStock <> 0) or (vDailyAmp >= 8.0);

If bIsMarketEvent and bIsStockEvent Then Begin // BE_1300
    If vMemMarket = -1 and vMemStock = -1 Then Begin vStateCategory = "雙重警報"; vActionMsg = " 崩跌確認，覆巢無完卵，嚴守防線！(系統性崩盤)"; End // BE_1300.1
    Else If vMemMarket = 1 and vMemStock = 1 Then Begin vStateCategory = "雙重強攻"; vActionMsg = " 順風狂飆，鎖定動能高水位！(順風吃肉)"; End // BE_1300.2
    Else If vMemMarket = -1 and vMemStock = 1 Then Begin vStateCategory = "逆勢妖股"; vActionMsg = " 大盤殺盤它卻強攻，抱緊處理！(超級強勢股)"; End // BE_1300.3
    Else If vMemMarket = 1 and vMemStock = -1 Then Begin vStateCategory = "極度弱勢"; vActionMsg = " 環境大漲卻崩跌，提防重大利空！(個股有暗傷)"; End // BE_1300.4
    Else Begin vStateCategory = "雙重波動"; vActionMsg = " 大盤動盪疊加個股洗盤，緊盯線型！(渾水摸魚期)"; End; // BE_1300.5
End // BE_1300
Else If bIsMarketEvent Then Begin // BE_1301
    If vMemMarket = 1 Then Begin vStateCategory = "大盤強勢"; vActionMsg = "  環境順風推升，個股目前平穩續抱。"; End // BE_1301.1
    Else If vMemMarket = -1 Then Begin vStateCategory = "大盤弱勢"; vActionMsg = "  系統性風險增高，個股暫未波及，警戒。"; End; // BE_1301.2
End // BE_1301
Else If bIsStockEvent Then Begin // BE_1302
    If vMemStock = 1 Then Begin vStateCategory = "個股強攻"; vActionMsg = "  獨立發動強烈攻勢，啟動高點記憶防線！"; End // BE_1302.1
    Else If vMemStock = -1 Then Begin vStateCategory = "個股弱勢"; vActionMsg = "  面臨極端賣壓，確認是否觸發停損機制。"; End // BE_1302.2
    Else If vDailyAmp >= 8.0 Then Begin vStateCategory = "個股洗盤"; vActionMsg = "  主力激烈洗盤博弈，避免頻繁進出。"; End; // BE_1302.3
End; // BE_1302

If vStateCategory <> "" and vStateCategory <> vLastCategory Then Begin // BE_1400
    vLastCategory = vStateCategory; 
    vPrintMsg = "【風控】日期:" + NumToStr(Date, 0) + " | " + NumToStr(Time, 0) + "  【" + vStateCategory + "】大盤(" + NumToStr(vMarketPct,2) + "%) | 個股(" + NumToStr(vStockPct,2) + "%)" + vActionMsg + " 現價:" + NumToStr(close,2);
    vPopMsg = NumToStr(Date, 0) + "【" + vStateCategory + "】大盤" + NumToStr(vMarketPct,2) + "%|個股" + NumToStr(vStockPct,2) + "%" + vActionMsg + " 現價:" + NumToStr(close,2);
    Print(vPrintMsg); Alert(vPopMsg); 
End; // BE_1400

// 只在當天的 K 棒，且只印一次，避開歷史資料的 0
If Date = CurrentDate and vTestPrinted = False Then Begin // BE_1500
    Print(NumToStr(Date,0), NumToStr(Time,0), "【介面強制指定測試】");
    Print("1. 策略部位 (Position) = ", Position);
    Print("2. 實際部位 (Filled) = ", Filled);
    Print("3. 買進成本 (FilledAvgPrice) = ", FilledAvgPrice);
    Print("4. 券商庫存 (FilledAtBroker) = ", FilledAtBroker, " <- 因為是手動指定，這裡必然是0");
    Print("5. 成交紀錄 (FilledRecordCount) = ", FilledRecordCount, " <- 沒有實體下單，必然也是0");
    Print("6. 進場前一刻空手Position[1] = ",  Position[1], " <- 進場條件[1]前一刻必須空手，以防止 09 濾網重複進場");
    
    vTestPrinted = True;
End; // BE_1500

// 當「現有庫存」不等於「前一筆洗價的庫存」時，觸發列印
If isfirstcall("") and vRealPos <> vRealPos[1] Then Begin // BE_1600
    alert("【庫存異動通知】", Symbol, " | 原庫存:", NumToStr(vRealPos[1], 0), " -> 現庫存:", NumToStr(vRealPos, 0), " | 現價:", NumToStr(Close, 2)," | Position[1]", NumToStr(Position[1], 0));
End; // BE_1600
