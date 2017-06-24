%% Real-time hedge
clear;clc;close all;
%w = windmatlab;

%% Hedge parameter setting---OTC
Code    = 'M1709.DCE';  % Code of underlying asset
Side    = 'sellcall'; % Side: sellcall,sellput,buycall,buyput
Strike  = 2712;      % Strike price
Type    = 4;         % Type of option   European:1  American:2  Asian:3  Binary:4
Premium = 1.1;       % 期权定价时波动率的溢价幅度
Yield   = 0;
%% parameter of binary option
pCStrike    = 0.95;   % Call Strike变动幅度
pPStrike    = 1.05;   % Put Strike变动幅度
pCash       = 0.05;   % 支付额占现价的比率
SettlePrice = 6888;   %二元期权签约时的标的价格
%% 亚式期权
Settle = '2017-5-24';        % 签约日期
ExerciseDates = '2017-8-24'; % 行权日期

Time = (datenum(ExerciseDates)-datenum(today))/365;

%% (加速)预加载数据
%Price = w.wsq(Code,'rt_last');   % 期货最新价格
Price = 2661;
%Rate  = w.wsq('CGB1Y.WI','rt_last')/100; % SHIBOR利率
Rate = 0.03;
%[EstVol,GarchVol,SellVol,BuyVol] = EstVolatility(Code);

%PremiumVol = Premium*max(GarchVol,SellVol);
PremiumVol = 0.27;
%DiscountVol = (2-Premium)*min(GarchVol,BuyVol);
DiscountVol = 0.27;
%fprintf('历史均值估计的波动率为 %f\n',EstVol);
%fprintf('GARCH模型估计的波动率为 %f\n',GarchVol);

% if strcmp(Side,'sellcall') || strcmp(Side,'sellput')
%     fprintf('卖出期权所估计的波动率为 %f\n',SellVol);
%     fprintf('卖出期权时定价所使用波动率为 %f\n\n',PremiumVol);
     Volatility = PremiumVol;
     EstVol = 0.27;
% elseif strcmp(Side,'buycall') || strcmp(Side,'buyput')
%     fprintf('买入期权所估计的波动率为 %f\n',BuyVol);
%     fprintf('买入期权时定价所使用波动率为 %f\n\n',DiscountVol);
%     Volatility = DiscountVol;
% end

%% 逻辑判断
if Type == 1
    [CallPrice,PutPrice] = blsprice(Price, Strike, Rate, Time, Volatility,Yield);
    if strcmp(Side,'buycall') || strcmp(Side,'sellcall')
        OurPrice = CallPrice;
    elseif strcmp(Side,'buyput') || strcmp(Side,'sellput')
        OurPrice = PutPrice;
    end
    fprintf('我们对该欧式期权的定价为：%f\n',OurPrice);
    
    [CallDelta,PutDelta,Gamma,CallTheta,PutTheta,Vega,CallRho,PutRho] ...
    = BS_GreekLetters(Price,Strike,Rate,Time,EstVol,Yield);

elseif Type == 2
    [ AmeCallPrice,AmePutPrice,~,~,Prob] = CRRPrice(Price,Strike,Rate,Time,Volatility,Yield);
    if strcmp(Side,'buycall') || strcmp(Side,'sellcall')
        OurPrice = AmeCallPrice;
    elseif strcmp(Side,'buyput') || strcmp(Side,'sellput')
        OurPrice = AmePutPrice;
    end
    fprintf('我们对该美式期权的定价为：%f，Prob = %f\n',OurPrice,Prob);
    
    [CallDelta,PutDelta,Gamma,CallTheta,PutTheta,Vega,CallRho,PutRho] ...
    = BS_GreekLetters(Price,Strike,Rate,Time,EstVol,Yield);


elseif Type == 3
    if strcmp(Side,'buycall') || strcmp(Side,'sellcall')
        [AsianPrice,Var,UP] = Asian_improve(Price,Strike,Rate,Time,Volatility,1);
    elseif strcmp(Side,'buyput') || strcmp(Side,'sellput')
        [AsianPrice,Var,UP] = Asian_improve(Price,Strike,Rate,Time,Volatility,0);
    end
    fprintf('我们对该亚式期权的定价为：%f\n',AsianPrice);
    fprintf('亚式期权价格的方差为 %f  0.95置信区间的期权价格上下界为[%f, %f]\n ',Var,UP);
    
   [CallDelta,PutDelta,Gamma,CallTheta,PutTheta,Vega,CallRho,PutRho] ...
   = AsianGreeksLevy(Price,Strike,EstVol,Rate,Settle,ExerciseDates);

elseif Type == 4
    [ BinCall,pCall,BinPut,pPut ] = BinPrice(Price,pCStrike,pPStrike,pCash,Rate,Volatility,Time,Yield);
    if strcmp(Side,'buycall') || strcmp(Side,'sellcall')
        OurPrice = BinCall;
        pS = pCall;
    elseif strcmp(Side,'buyput') || strcmp(Side,'sellput')
        OurPrice = BinPut;
        pS = pPut;
    end
    fprintf('我们对该二元期权的定价为：%f\n',OurPrice);
    fprintf('期权价格/标的价格 = %f\n',pS);
    
    [CallDelta,PutDelta,CallGamma,PutGamma,CallTheta,PutTheta,CallVega,PutVega,CallRho,PutRho] = ...
     Bin_GreekLetters( Price,pCStrike,pPStrike,Rate,pCash,EstVol,SettlePrice,ExerciseDates,Yield);
    
else
    msgbox('期权类型输入错误！');
end

if Type == 4 
    if strcmp(Side,'sellput') 
        fprintf('\nPutDelta: %f\n',-PutDelta);
        fprintf('PutGamma: %f\n',-PutGamma);
        fprintf('PutTheta: %f\n',-PutTheta);
        fprintf('PutVega: %f\n',-PutVega);
        fprintf('PutRho: %f\n',-PutRho);
    elseif strcmp(Side,'buycall') 
        fprintf('\nCallDelta: %f\n',CallDelta);
        fprintf('CallGamma: %f\n',CallGamma);
        fprintf('CallTheta: %f\n',CallTheta);
        fprintf('CallVega: %f\n',CallVega);
        fprintf('CallRho: %f\n',CallRho);
    elseif strcmp(Side,'buyput')
        fprintf('\nPutDelta: %f\n',PutDelta);
        fprintf('PutGamma: %f\n',PutGamma);
        fprintf('PutTheta: %f\n',PutTheta);
        fprintf('PutVega: %f\n',PutVega);
        fprintf('PutRho: %f\n',PutRho);
    elseif strcmp(Side,'sellcall')
        fprintf('\nCallDelta: %f\n',-CallDelta);
        fprintf('CallGamma: %f\n',-CallGamma);
        fprintf('CallTheta: %f\n',-CallTheta);
        fprintf('CallVega: %f\n',-CallVega);
        fprintf('CallRho: %f\n',-CallRho);
    else
        error('交易方向输入错误！');
    end
else 
    if strcmp(Side,'sellput') 
        fprintf('\nCallDelta: %f\n',abs(PutDelta));
        fprintf('Gamma: %f\n',-abs(Gamma));
        fprintf('CallTheta: %f\n',abs(PutTheta));
        fprintf('Vega: %f\n',-abs(Vega));
        fprintf('CallRho: %f\n',abs(PutRho));
    elseif strcmp(Side,'buycall') 
        fprintf('\nCallDelta: %f\n',abs(CallDelta));
        fprintf('Gamma: %f\n',abs(Gamma));
        fprintf('CallTheta: %f\n',-abs(CallTheta));
        fprintf('Vega: %f\n',abs(Vega));
        fprintf('CallRho: %f\n',abs(CallRho));
    elseif strcmp(Side,'buyput')
        fprintf('\nPutDelta: %f\n',-abs(PutDelta));
        fprintf('Gamma: %f\n',abs(Gamma));
        fprintf('PutTheta: %f\n',-abs(PutTheta));
        fprintf('Vega: %f\n',abs(Vega));
        fprintf('PutRho: %f\n',-abs(PutRho));
    elseif strcmp(Side,'sellcall')
        fprintf('\nPutDelta: %f\n',-abs(CallDelta));
        fprintf('Gamma: %f\n',-abs(Gamma));
        fprintf('PutTheta: %f\n',abs(CallTheta));
        fprintf('Vega: %f\n',-abs(Vega));
        fprintf('PutRho: %f\n',-abs(CallRho));
    else
        error('交易方向输入错误！');
    end
end