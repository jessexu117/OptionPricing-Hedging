function [ EstVol,GarchVol,SellVol,BuyVol ] = EstVolatility( Code )
% 根据传入的标的期货代码，根据历史均值方法和GARCH模型方法估计其波动率
%% Estimate historical volatility with HV30 data
answer = who('w');
if(isempty(answer) || ~isa(w,'windMATLAB'))
    w = windmatlab;
end
if ~isconnected(w)
    msgbox('Wind Disconnected!') 
end

myToday     = datestr(today,'yyyy-mm-dd');
HV30Data    = GetHV30(Code);
AverageHV30 = mean(HV30Data);         % Average HV30 of last 3 years
LatestHV30  = GetHV30Latest(Code);    % Latest HV30

SamePeriodHV30 = GetHV30SameTime(Code);
if ~iscell(SamePeriodHV30)
    AverageHisHV30 = mean(SamePeriodHV30);    % Average of HV30 in the same time of past years
else
    AverageHisHV30 = AverageHV30;
end

% Our real estimated volatility
EstVol  = 1/3*AverageHV30+1/3*LatestHV30+1/3*AverageHisHV30;

% Volatility we wanna sell
SellVol = 1/3*AverageHV30+1/3*max(AverageHV30,AverageHisHV30)+1/3*max(AverageHV30,LatestHV30);
BuyVol  = 1/3*AverageHV30+1/3*min(AverageHV30,AverageHisHV30)+1/3*min(AverageHV30,LatestHV30);

%% Estimate volatility with ARMA-GARCH
% calculate the active future code
ActiveCode = HandleCode(Code);
Series     = w.wsd(ActiveCode,'close','ED-3Y',myToday,'TradingCalendar=DCE');
Series     = Series(~isnan(Series));
retSeries  = price2ret(Series);
model      = arima('ARLags',1,'MALags',1,'Variance',garch(5,5));         % Model setting
fit_model  = estimate(model,retSeries,'Variance0',{'Constant0',0.00001},'Display','off'); % Fit model with observation series
[E0,V0]    = infer(fit_model,retSeries);
[~,~,V]    = forecast(fit_model,21,'Y0',retSeries,'E0',E0,'V0',V0);     % Forcast 20 steps
GarchVol   = sqrt(V(1))*sqrt(242);
% GarchVol = 0.18;
end
