function [CallDelta,PutDelta,Gamma,CallTheta,PutTheta,Vega,CallRho,PutRho] ...
    = AsianGreeksLevy(AssetPrice,Strike,Sigma,Rates,Settle,ExerciseDates)
%% function to caculate the Greeks of Asian options
% in the file, a Levy model is used
% Create RateSpec from the interest rate term structure
StartDates = '12-March-2014';
EndDates = '12-March-2020';
%Rates = 0.0405;   
Compounding = -1;
Basis = 1;

RateSpec = intenvset('ValuationDate', StartDates, 'StartDates', StartDates, ...
    'EndDates', EndDates, 'Rates', Rates, 'Compounding', ...
    Compounding, 'Basis', Basis);

StockSpec = stockspec(Sigma, AssetPrice);
                                
OptSpec = 'call';                
OutSpec = {'Delta';'Gamma';'Theta';'Vega';'Rho'};
% Arithmetric Asian option using Levy model
[CallDelta,Gamma,CallTheta,Vega,CallRho] = asiansensbylevy(RateSpec, StockSpec, OptSpec, Strike, Settle,...
                            ExerciseDates,'OutSpec',OutSpec);
        
% Geometric Asian option using Kemna-Vorst method
% [DeltaLKV,s] = asiansensbykv(RateSpec, StockSpec, OptSpec, Strike, Settle,...
%                         ExerciseDates,  'OutSpec', OutSpec)

OptSpec = 'put';
OutSpec = {'Delta';'Theta';'Rho'};
[PutDelta,PutTheta,PutRho] = asiansensbylevy(RateSpec, StockSpec, OptSpec, Strike, Settle,...
                            ExerciseDates,'OutSpec',OutSpec);
end