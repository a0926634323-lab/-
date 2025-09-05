// 聲明輸入參數 
Input: Period(20, "計算週期"); 
Input: VolRatio(2, "爆量倍數"); 
Input: EntrySize(1, "進場張數"); 
Input: ProfitRatio(1.05, "停利比"); 
Input: BullishThreshold(2, "累計看漲門檻"); // 達到此門檻才進場 
Input: BearishThreshold(-2, "累計看跌門檻"); // 達到此門檻才平倉 
 
// 聲明累計變數 
Var: score(0); 
Var: LastEntryPrice(0); 
 
// 判斷量價關係並給予分數 (此為單日的訊號分數) 
Value1 = Close; 
Value2 = Close[1]; 
Value3 = Volume; 
Value4 = Volume[1]; 
Value5 = Average(Volume, 5); 
Value6 = Highest(High, Period); 
Value7 = Lowest(Low, Period); 
 
// 計算當日總分數 
Var: current_score(0); 
if (Value1 > Value2 and Value3 < Value4) then current_score += 1; 
if (Value1 = Value7 and Value3 > Value5 * VolRatio) then current_score += 1; 
if (Value1 >= Value2 and Value3 < Value4) then current_score += 1; 
 
if (Value1 < Value2 and Value3 < Value4) then current_score -= 1; 
if (Value1 <= Value2 and Value3 > Value5 * VolRatio) then current_score -= 1; 
if (Value1 < Value7 and Value3 < Value5) then current_score -= 1; 
if (Value1 = Value6 and Value3 > Value5 * VolRatio) then current_score -= 1; 
 
// 累計分數 
score = score + current_score; 
 
// 執行交易邏輯 
// 多單進場：當累計分數達到門檻，且目前無部位 
if score >= BullishThreshold and Position = 0 then begin 
    SetPosition(EntrySize); 
    LastEntryPrice = Close; 
end; 
 
// 多單平倉：當累計分數轉弱，或達到停利條件 
if Position > 0 then begin 
    if score <= BearishThreshold and Close >= LastEntryPrice * ProfitRatio then begin 
        SetPosition(0); 
    end; 
end; 
{ 
// 空單進場：當累計分數達到門檻，且目前無部位 
if score <= -BullishThreshold and Position = 0 then begin 
    SetPosition(-EntrySize); 
end; 
 
// 空單平倉：當累計分數轉強 
if score >= -BearishThreshold and Position < 0 then begin 
    SetPosition(0); 
end; 
}
