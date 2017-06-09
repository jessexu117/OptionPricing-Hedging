function [CallDelta, PutDelta, Gamma, CallTheta, PutTheta, Vega, CallRho, PutRho] ...
    = BS_GreekLetters( Price,Strike,Rate,Time,Volatility,Yield )
% Calculate the Greek letters of B-S model
[CallDelta, PutDelta] = blsdelta(Price, Strike, Rate, Time, Volatility, Yield);
Gamma                 = blsgamma(Price, Strike, Rate, Time, Volatility, Yield);
[CallTheta, PutTheta] = blstheta(Price, Strike, Rate, Time, Volatility, Yield);
Vega                  = blsvega(Price, Strike, Rate, Time, Volatility, Yield);
[CallRho, PutRho]     = blsrho(Price, Strike, Rate, Time, Volatility, Yield);

end