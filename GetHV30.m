function [ HV30 ] = GetHV30( Code )
%% 计算过去3年的HV30序列数据
answer = who('w');
if(isempty(answer) || ~isa(w,'windMATLAB'))
    w = windmatlab;
end
if ~isconnected(w)
    msgbox('Wind Disconnected!')
end
%% 获取数据
myToday     = datestr(today,'yyyy-mm-dd');
ActiveCode  = HandleCode(Code);
PriceSeries = w.wsd(ActiveCode,'close','ED-3Y',myToday,'TradingCalendar=DCE');
PriceSeries = PriceSeries(~isnan(PriceSeries));
n = length(PriceSeries);
%% 计算HV30
dailyReturn = zeros(n-2,1);
for i = 1:n-2
    dailyReturn(i) = log(PriceSeries(i+1)/PriceSeries(i));
end
HV30 = zeros(n-22,1);
for i = 21:n-2
    HV30(i-20) = std(dailyReturn(i-20:i))*sqrt(252);
end
HV30 = HV30(HV30 < 1);

end
