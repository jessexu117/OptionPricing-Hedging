function [ Call,pCall,Put,pPut ] = BinPrice( Price,pCStrike,pPStrike,pCash,Rate,Volatility,Time,Yield )
% 二元期权定价
if nargin == 7
    Yield = 0;
end

S = Price;  % Current price
K1 = S*pPStrike;   % Strike P:K1, C:K2
K2 = S*pCStrike;  
r = Rate;
q = Yield;  % Dividend Yield
sigma = Volatility;
T = Time;
R = pCash*S;  % pCash is the proportion

d1 = (log(S/K2)+(r-q+.5*sigma^2)*T)/(sigma*sqrt(T));
d2 = d1-sigma*sqrt(T);
d3 = (log(S/K1)+(r-q+.5*sigma^2)*T)/(sigma*sqrt(T));
d4 = d3-sigma*sqrt(T);

%Call Option price
Call = R*exp(-r*T)*normcdf(d2,0,1);
pCall = Call/S;
%Put Option Price
Put = R*exp(-r*T)*normcdf(-d4,0,1);
pPut = Put/S;

end