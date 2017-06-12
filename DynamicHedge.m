function [] = DynamicHedge( obj,~ )
%% set user data
w       = windmatlab;
ud      = obj.UserData;
Code    = ud.code;
Side    = ud.side;
Strike  = ud.strike;
Type    = ud.type;
Yield   = ud.yield;
Premium = ud.premium;
%% hedge setting
Hedge   = ud.hedge;
Volume  = ud.volume;
ordinaryDelta = ud.ordinaryDelta;
lstweekDelta  = ud.lastweekDelta;
lstdayDelta   = ud.lastdayDelta;
%% Asian Option data
Settle        = ud.settle;
ExerciseDates = ud.exercisedates;
%% binary option data
pCStrike    = ud.pCStrike;
pPStrike    = ud.pPStrike;
pCash       = ud.pCash;
SettlePrice = ud.settleprice;

N = length(Code);

for i=1:N
    %% (加速)预加载数据
    Time = (datenum(ExerciseDates(i))-datenum(today))/365;
    fprintf('第%d个期权：\n',int8(i));
    Price = w.wsq(char(Code(i)),'rt_last');   % 期货最新价格
    Rate  = w.wsq('CGB1Y.WI','rt_last')/100;  % 一年期国债收益率
    if ~exist('rtWindMat.mat','file')
        rtWind = zeros(10,2);
        save rtWindMat rtWind;
    end
    if isnan(Price) || isnan(Rate)
        fprintf('WindAPI实时数据异常！如果多次提醒此消息，请检查！')
        Price = rtWind(i,1);
        Rate = rtWind(i,2);
    else
        load rtWindMat;
        rtWind(i,1) = Price;
        rtWind(i,2) = Rate;
        save rtWindMat rtWind;
    end
%    [EstVol,GarchVol,SellVol,BuyVol] = EstVolatility(char(Code(i)));   
% %   调试专用    
     EstVol = 0.16;
     GarchVol = 0.16;
     SellVol = 0.18;
     BuyVol = 0.18;   
    %PremiumVol  = Premium(i)*max(GarchVol,SellVol);
    PremiumVol = 0.26;
    DiscountVol = (2-Premium(i))*min(GarchVol,BuyVol);

    fprintf('历史均值估计的波动率为 %f\n',EstVol);
    fprintf('GARCH模型估计的波动率为 %f\n',GarchVol);

    if strcmp(char(Side(i)),'sellcall') || strcmp(char(Side(i)),'sellput')
        fprintf('卖出期权所估计的波动率为 %f\n',SellVol);
        fprintf('卖出期权时定价所使用波动率为 %f\n\n',PremiumVol);
        Volatility = PremiumVol;
    elseif strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'buyput')
        fprintf('买入期权所估计的波动率为 %f\n',BuyVol);
        fprintf('买入期权时定价所使用波动率为 %f\n\n',DiscountVol);
        Volatility = DiscountVol;
    end

    %% 逻辑判断    
    if Type(i) == 1
        [CallPrice,PutPrice] = blsprice(Price,Strike(i),Rate,Time,Volatility,Yield(i));
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            OurPrice = CallPrice;
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            OurPrice = PutPrice;
        end
        fprintf('我们对该欧式期权的定价为：%f\n',OurPrice);

        [CallDelta,PutDelta,Gamma,CallTheta,PutTheta,Vega,CallRho,PutRho] ...
        = BS_GreekLetters(Price,Strike(i),Rate,Time,EstVol,Yield(i));

    elseif Type(i) == 2
        [ AmeCallPrice,AmePutPrice,~,~,Prob] = CRRPrice(Price,Strike(i),Rate,Time,Volatility,Yield(i));
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            OurPrice = AmeCallPrice;
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            OurPrice = AmePutPrice;
        end
        fprintf('我们对该美式期权的定价为：%f，Prob = %f\n',OurPrice,Prob);

        [CallDelta,PutDelta,Gamma,CallTheta,PutTheta,Vega,CallRho,PutRho] ...
        = BS_GreekLetters(Price,Strike(i),Rate,Time,EstVol,Yield(i));

    elseif Type(i) == 3
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            [AsianPrice,Var,UP] = Asian_improve(Price,Strike(i),Rate,Time,Volatility,1);
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            [AsianPrice,Var,UP] = Asian_improve(Price,Strike(i),Rate,Time,Volatility,0);
        end
        fprintf('我们对该亚式期权的定价为：%f\n',AsianPrice);
        fprintf('亚式期权价格的方差为 %f  0.95置信区间的期权价格上下界为[%f, %f]\n ',Var,UP);

        [CallDelta,PutDelta,Gamma,CallTheta,PutTheta,Vega,CallRho,PutRho] ...
        = AsianGreeksLevy(Price,Strike(i),EstVol,Rate,char(Settle(i)),char(ExerciseDates(i)));

    elseif Type(i) == 4
        [ BinCall,pCall,BinPut,pPut ] = BinPrice(Price,pCStrike(i),pPStrike(i),pCash(i),Rate,Volatility,Time,Yield(i));
        if strcmp(char(Side(i)),'buycall') || strcmp(char(Side(i)),'sellcall')
            OurPrice = BinCall;
            pS = pCall;
        elseif strcmp(char(Side(i)),'buyput') || strcmp(char(Side(i)),'sellput')
            OurPrice = BinPut;
            pS = pPut;
        end
        fprintf('我们对该二元期权的定价为：%f\n',OurPrice);
        fprintf('期权价格/标的价格 = %f\n',pS);
    
        [CallDelta,PutDelta,CallGamma,PutGamma,CallTheta,PutTheta,CallVega,PutVega,CallRho,PutRho] = ...
         Bin_GreekLetters( Price,pCStrike(i),pPStrike(i),Rate,pCash(i),EstVol,SettlePrice(i),char(ExerciseDates(i)),Yield(i));
    
    else
        error('期权类型输入错误！');
    end
    if Type(i) ~= 4 
        if strcmp(char(Side(i)),'sellput') 
            fprintf('\nPutDelta: %f\n',-PutDelta);
            fprintf('Gamma: %f\n',-Gamma);
            fprintf('PutTheta: %f\n',-PutTheta);
            fprintf('Vega: %f\n',-Vega);
            fprintf('PutRho: %f\n',-PutRho);
        elseif strcmp(char(Side(i)),'buycall') 
            fprintf('\nCallDelta: %f\n',CallDelta);
            fprintf('Gamma: %f\n',Gamma);
            fprintf('CallTheta: %f\n',CallTheta);
            fprintf('Vega: %f\n',Vega);
            fprintf('CallRho: %f\n',CallRho);
        elseif strcmp(char(Side(i)),'buyput')
            fprintf('\nPutDelta: %f\n',PutDelta);
            fprintf('Gamma: %f\n',Gamma);
            fprintf('PutTheta: %f\n',PutTheta);
            fprintf('Vega: %f\n',Vega);
            fprintf('PutRho: %f\n',PutRho);
        elseif strcmp(char(Side(i)),'sellcall')
            fprintf('\nCallDelta: %f\n',-CallDelta);
            fprintf('Gamma: %f\n',-Gamma);
            fprintf('CallTheta: %f\n',-CallTheta);
            fprintf('Vega: %f\n',-Vega);
            fprintf('CallRho: %f\n',-CallRho);
        else
            error('交易方向输入错误！');
        end
    else 
        if strcmp(char(Side(i)),'sellput') 
            fprintf('\nPutDelta: %f\n',-PutDelta);
            fprintf('PutGamma: %f\n',-PutGamma);
            fprintf('PutTheta: %f\n',-PutTheta);
            fprintf('PutVega: %f\n',-PutVega);
            fprintf('PutRho: %f\n',-PutRho);
        elseif strcmp(char(Side(i)),'buycall') 
            fprintf('\nCallDelta: %f\n',CallDelta);
            fprintf('CallGamma: %f\n',CallGamma);
            fprintf('CallTheta: %f\n',CallTheta);
            fprintf('CallVega: %f\n',CallVega);
            fprintf('CallRho: %f\n',CallRho);
        elseif strcmp(char(Side(i)),'buyput')
            fprintf('\nPutDelta: %f\n',PutDelta);
            fprintf('PutGamma: %f\n',PutGamma);
            fprintf('PutTheta: %f\n',PutTheta);
            fprintf('PutVega: %f\n',PutVega);
            fprintf('PutRho: %f\n',PutRho);
        elseif strcmp(char(Side(i)),'sellcall')
            fprintf('\nCallDelta: %f\n',-CallDelta);
            fprintf('CallGamma: %f\n',-CallGamma);
            fprintf('CallTheta: %f\n',-CallTheta);
            fprintf('CallVega: %f\n',-CallVega);
            fprintf('CallRho: %f\n',-CallRho);
        else
            error('交易方向输入错误！');
        end
    end
    fprintf('\n\n');
    if Hedge(i) ~= 0
        if ~exist('InitDelta.mat','file')
            InitD = zeros(10,2);
            save InitDelta InitD;
        end
        load InitDelta;
        if InitD(i,1) == 0 && InitD(i,2) == 0
            InitD(i,1) = CallDelta;
            InitD(i,2) = PutDelta;
            save InitDelta InitD;
           %% 初始对冲
            if strcmp(char(Side(i)),'sellcall')
                info = ['第',num2str(i),'个期权：初始对冲先买入',num2str(abs(Volume(i)*CallDelta)),'份标的资产'];
                msgbox(info,'INFO');
            elseif strcmp(char(Side(i)),'sellput')
                info = ['第',num2str(i),'个期权：初始对冲先卖出',num2str(abs(Volume(i)*PutDelta)),'份标的资产'];
                msgbox(info,'INFO');
            elseif strcmp(char(Side(i)),'buyput')
                info = ['第',num2str(i),'个期权：初始对冲先买入',num2str(abs(Volume(i)*PutDelta)),'份标的资产'];
                msgbox(info,'INFO');
            elseif strcmp(char(Side(i)),'buycall')
                info = ['第',num2str(i),'个期权：初始对冲先卖出',num2str(abs(Volume(i)*CallDelta)),'份标的资产'];
                msgbox(info,'INFO');
            else
                error('买卖方向输入错误！');
            end
        else
            CallDeltaChange = abs(CallDelta) - abs(InitD(i,1));
            PutDeltaChange  = abs(PutDelta) - abs(InitD(i,2));
            lastweek = 0;
            lastday  = 0;
            if (datenum(ExerciseDates(i)) - datenum(today)) <= 1
                disp('此期权明天即将到期！\n')
                lastday = 1;
            elseif (datenum(ExerciseDates(i)) - datenum(today)) <= 7
                disp('此期权一周之内即将到期！\n')
                lastweek = 1;
            end
            
            switch(char(Side(i)))
                case 'sellcall'
                    if lastweek == 1 && CallDeltaChange > lstweekDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 1 && CallDeltaChange < -lstweekDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastday == 1 && CallDeltaChange > lstdayDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastday == 1 && CallDeltaChange < -lstdayDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 0 && lastday == 0 && CallDeltaChange > ordinaryDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 0 && lastday == 0 && CallDeltaChange < -ordinaryDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    end
                case 'sellput'
                    if lastweek == 1 && PutDeltaChange > lstweekDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 1 && PutDeltaChange < -lstweekDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastday == 1 && PutDeltaChange > lstdayDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastday == 1 && PutDeltaChange < -lstdayDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 0 && lastday == 0 && PutDeltaChange > ordinaryDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 0 && lastday == 0 && PutDeltaChange < -ordinaryDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    end
                case 'buycall'
                    if lastweek == 1 && CallDeltaChange > lstweekDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 1 && CallDeltaChange < -lstweekDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastday == 1 && CallDeltaChange > lstdayDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastday == 1 && CallDeltaChange < -lstdayDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 0 && lastday == 0 && CallDeltaChange > ordinaryDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    elseif lastweek == 0 && lastday == 0 && CallDeltaChange < -ordinaryDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(CallDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,1) = CallDelta;
                    end
                case 'buyput'
                    if lastweek == 1 && PutDeltaChange > lstweekDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 1 && PutDeltaChange < -lstweekDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastday == 1 && PutDeltaChange > lstdayDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastday == 1 && PutDeltaChange < -lstdayDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 0 && lastday == 0 && PutDeltaChange > ordinaryDelta(i)
                        info = ['第',num2str(i),'个期权：买入',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    elseif lastweek == 0 && lastday == 0 && PutDeltaChange < -ordinaryDelta(i)
                        info = ['第',num2str(i),'个期权：卖出',num2str(abs(PutDeltaChange*Volume(i))),'份标的资产'];
                        msgbox(info,'info');
                        InitD(i,2) = PutDelta;
                    end
            end
            save InitDelta InitD;
        end
    end
end

end