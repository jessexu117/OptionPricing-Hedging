% if nargin == 5
%     Settel = today;
% end
% Create RateSpec from the interest rate term structure
StartDates = '12-March-2014';
EndDates = '12-March-2020';
Rates = 0.0405;   
Compounding = -1;
Basis = 1;

RateSpec = intenvset('ValuationDate', StartDates, 'StartDates', StartDates, ...
    'EndDates', EndDates, 'Rates', Rates, 'Compounding', ...
    Compounding, 'Basis', Basis);

% Define StockSpec with the underlying asset information
Sigma = 0.20;
AssetPrice = 100;

StockSpec = stockspec(Sigma, AssetPrice);

% Define the Asian option
Settle = '12-March-2014';
ExerciseDates = '12-March-2015';
Strike = 90;

OptSpec = 'call';                
OutSpec = {'Delta';'Gamma';'Theta';'Vega';'Rho'};

% Levy model approximation
PriceLevy = asianbylevy(RateSpec, StockSpec, OptSpec, Strike, Settle,...
                        ExerciseDates);

Asian_improve(100,90,0.0405,1,0.2,1)

NumTrials = 200;
NumPeriods = 200;

% Price the arithmetic option 
% PriceAMC = asianbyls(RateSpec, StockSpec, OptSpec, Strike, Settle,...
%                      ExerciseDates,'NumTrials', NumTrials, ...
%                      'NumPeriods', NumPeriods);
% % Price the geometric option 
% PriceGMC = asianbyls(RateSpec, StockSpec, OptSpec, Strike, Settle,...
%                      ExerciseDates,'NumTrials', NumTrials, ...
%                      'NumPeriods', NumPeriods, 'AvgType', AvgType(2));
                 
% Use the antithetic variates method to value the options                 
Antithetic = true;
PriceAMCAntithetic = asianbyls(RateSpec, StockSpec, OptSpec, Strike, Settle,...
                    ExerciseDates,'NumTrials', NumTrials, 'NumPeriods',...
                    NumPeriods, 'Antithetic', Antithetic);
                
                
                

% Asian option using Levy model
[CallDelta,Gamma,CallTheta,Vega,CallRho] = asiansensbylevy(RateSpec, StockSpec, OptSpec, Strike, Settle,...
                            ExerciseDates,'OutSpec',OutSpec);
CallDelta
                        
% Asian option using Kemna-Vorst method
asiansensbykv(RateSpec, StockSpec, OptSpec, Strike, Settle,...
                        ExerciseDates,  'OutSpec', OutSpec)
% 
% OptSpec = 'put';
% OutSpec = {'Delta';'Theta';'Rho'};
% [PutDelta,PutTheta,PutRho] = asiansensbylevy(RateSpec, StockSpec, OptSpec, Strike, Settle,...
%                             ExerciseDates,'OutSpec',OutSpec);
