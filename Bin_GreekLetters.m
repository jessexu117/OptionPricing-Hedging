function [CallDelta,PutDelta,CallGamma,PutGamma,CallTheta,PutTheta,CallVega,PutVega,CallRho,PutRho] = ...
    Bin_GreekLetters( Price,pCStrike,pPStrike,Rate,pCash,Volatility,SettlePrice,ExerciseDates,Yield )
if nargin == 8
    Yield = 0;
end
%% 计算二元期权的希腊字母
S0 = SettlePrice;  % Price0为合约签订时的标的价格
K1 = pCStrike*S0;
K2 = pPStrike*S0;
r = Rate;
sigma = Volatility;
q = Yield;

dt = (datenum(ExerciseDates)-datenum(today))/365;  % T-t
St = Price;

%%
m1 = K1*pCash;
m2 = K2*pCash;

d1 = (log(S0/K1)+(r-q+.5*sigma^2)*dt)/(sigma*sqrt(dt));
d2 = d1-sigma*sqrt(dt);

d3 = (log(S0/K2)+(r-q+.5*sigma^2)*dt)/(sigma*sqrt(dt));
d4 = d3-sigma*sqrt(dt);

CallDelta =m1*(exp(-r*dt)*Deriv_Normcdf(d2))/(sigma*sqrt(dt)*St);
PutDelta = -m2*(exp(-r*dt)*Deriv_Normcdf(d4))/(sigma*sqrt(dt)*St);

CallGamma = -m1*(exp(-r*dt)*d1*Deriv_Normcdf(d2))/(sigma^2*St^2*dt);
PutGamma = m2*(exp(-r*dt)*d3*Deriv_Normcdf(d4))/(sigma^2*St^2*dt);

CallTheta = m1*(r*exp(-r*dt)*normcdf(d2)+exp(-r*dt)*Deriv_Normcdf(d2)*(d1/(2*dt)-(r-q)/(sigma*sqrt(dt))));
PutTheta = m2*(r*exp(-r*dt)*(1-normcdf(d4))-exp(-r*dt)*Deriv_Normcdf(d4)*(d3/(2*dt)-(r-q)/(sigma*sqrt(dt))));

CallVega      = m1*(-exp(-r*dt)*Deriv_Normcdf(d2)*(sqrt(dt)+d2/sigma));
PutVega      = m2*(-exp(-r*dt)*Deriv_Normcdf(d4)*(sqrt(dt)+d4/sigma));

CallRho = m1*(-dt*exp(-r*dt)*normcdf(d2)+sqrt(dt)/sigma*exp(-r*dt*Deriv_Normcdf(d2)));
PutRho = m2*(-dt*exp(-r*dt)*(1-normcdf(d4))-sqrt(dt)/sigma*exp(-r*dt*Deriv_Normcdf(d4)));

end