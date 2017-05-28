function [ HV30 ] = GetHV30Latest( Code )
%% 计算最近的HV30
answer = who('w');
if(isempty(answer) || ~isa(w,'windMATLAB'))
    w = windmatlab;
end
if ~isconnected(w) 
    msgbox('Wind Disconnected!')
end

myToday     = datestr(today,'yyyy-mm-dd');
ActiveCode  = HandleCode(Code);
PriceSeries = w.wsd(ActiveCode,'close','ED-1M',myToday,'TradingCalendar=DCE');
PriceSeries = PriceSeries (~isnan(PriceSeries ));
n = length(PriceSeries);

dailyReturn = zeros(n-2,1);
for i = 1:n-2
    dailyReturn(i) = log(PriceSeries(i+1)/PriceSeries(i));
end
HV30 = std(dailyReturn)*sqrt(252);
end

