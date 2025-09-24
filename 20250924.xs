// [XQ] 開盤雙向獨立監控策略 (v7 - 修正語法錯誤)
// --------------------------------------------------
// 說明：
// 本策略在開盤時，會 "同時" 建立「作多」與「作空」兩個獨立的邏輯劇本，
// 並計算各自的停利/停損價位。
// 盤中會持續監控價格，當任一劇本的出場條件被觸發時，
// 就會執行該筆交易並結束當日所有操作，避免多空邏輯互相干擾。
//
// **重要設定**：
// - 執行頻率：建議使用1分鐘線，並開啟逐筆洗價。
// --------------------------------------------------

// ---------- 參數設定 ----------
input:
    In_LongProfitTarget(1.5, "B1-作多停利目標(%)"),
    In_LongStopLoss(2, "B1-作多停損幅度(%)"),
    In_ShortProfitTarget(1.5, "S1-作空停利目標(%)"),
    In_ShortStopLoss(2, "S1-作空停損幅度(%)");

// ---------- 內部變數 ----------
variable: intrabarpersist B1_Active(false);          // B1作多劇本是否啟用
variable: intrabarpersist B1_EntryPrice(0);        // B1進場價
variable: intrabarpersist B1_TakeProfitPrice(0);   // B1停利價
variable: intrabarpersist B1_StopLossPrice(0);     // B1停損價

variable: intrabarpersist S1_Active(false);          // S1作空劇本是否啟用
variable: intrabarpersist S1_EntryPrice(0);        // S1進場價
variable: intrabarpersist S1_TakeProfitPrice(0);   // S1停利價
variable: intrabarpersist S1_StopLossPrice(0);     // S1停損價

// ---------- 每日重置狀態 ----------
if Date <> Date[1] then begin
    B1_Active = false;
    B1_EntryPrice = 0;
    B1_TakeProfitPrice = 0;
    B1_StopLossPrice = 0;
    
    S1_Active = false;
    S1_EntryPrice = 0;
    S1_TakeProfitPrice = 0;
    S1_StopLossPrice = 0;
end;

// ---------- 核心交易邏輯 ----------
// 【開盤時，建立兩個邏輯劇本】
if IsSessionFirstBar and Position = 0 then begin
    // 建立 B1 作多劇本
    B1_Active = true;
    B1_EntryPrice = Open;
    B1_TakeProfitPrice = Open * (1 + In_LongProfitTarget / 100);
    B1_StopLossPrice = Open * (1 - In_LongStopLoss / 100);
    
    // 建立 S1 作空劇本
    S1_Active = true;
    S1_EntryPrice = Open;
    S1_TakeProfitPrice = Open * (1 - In_ShortProfitTarget / 100);
    S1_StopLossPrice = Open * (1 + In_ShortStopLoss / 100);
end;

// 【盤中監控與執行】
// 只有在無實際庫存，且任一劇本啟用時才進行判斷
if Position = 0 then begin

    // --- 監控 B1 作多劇本的出場條件 ---
    if B1_Active then begin
        // 觸及停利價
        if High >= B1_TakeProfitPrice then begin
            SetPosition(1, B1_TakeProfitPrice, label:="B1-觸及停利進場");
            B1_Active = false; 
            S1_Active = false; 
        end
        // 觸及停損價
        else if Low <= B1_StopLossPrice then begin
            SetPosition(1, B1_StopLossPrice, label:="B1-觸及停損進場");
            B1_Active = false; 
            S1_Active = false; 
        end;
    end
    
    // --- 監控 S1 作空劇本的出場條件 ---
    // **修正點：將 "end;" 後面的分號移除，讓 else if 可以正確連接**
    else if S1_Active then begin
        // 觸及停利價
        if Low <= S1_TakeProfitPrice then begin
            SetPosition(-1, S1_TakeProfitPrice, label:="S1-觸及停利進場");
            S1_Active = false; 
            B1_Active = false; 
        end
        // 觸及停損價
        else if High >= S1_StopLossPrice then begin
            SetPosition(-1, S1_StopLossPrice, label:="S1-觸及停損進場");
            S1_Active = false; 
            B1_Active = false; 
        end;
    end;
end;

// 【平倉邏輯】
// 當有庫存時，代表已有一個劇本被觸發進場，此時立即平倉來完成該筆模擬交易
if Position <> 0 then begin
    if B1_Active = false and S1_Active = false then // 確保是因觸發而進場的
    begin
        SetPosition(0, Market, label:="完成當日交易後平倉");
    end;
end;
