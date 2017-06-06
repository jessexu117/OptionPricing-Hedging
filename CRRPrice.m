function [ AmeCallPrice,AmePutPrice,ErouCallPrice,ErouPutPrice,Prob ] = CRRPrice( Price,Strike,Rate,Time,Volatility,Yield,Step )
%% 利用二叉树期权定价模型对欧式和美式期权定价
if nargin == 5
    Step = 1000;
    Yield = 0;
elseif nargin == 6
    Step = 1000;
end

r  = Rate;
S0 = Price;
K = Strike;
T = Time;
sigma = Volatility;
q = Yield;
n = Step;
dt = T/n;

%% Calculate each parameter of binary tree
u = exp(sigma*sqrt(dt));      % upward rate
d = 1/u;                      % downward rate
p = (exp((r-q)*dt)-d)/(u-d);  % probobility of upward rate

%% Create binary tree,i: row,j:column,Sx:price matrix,fx:intrinsic value of option
Sx = zeros(n+1,n+1);
callfx = zeros(n+1,n+1);
putfx = zeros(n+1,n+1);
for j = 1:n+1
    for i = 1:j
        Sx(i,j) = S0*(u^(j-i))*(d^(i-1));
        callfx(i,j) = max(Sx(i,j)-K,0);  % Call option  
        putfx(i,j) = max(-Sx(i,j)+K,0);  % Put option
    end
end

%% Calculate price matrix of American Option:Afx and European Option:Efx
CallAfx = zeros(n+1,n+1);
PutAfx  = zeros(n+1,n+1);
CallEfx = zeros(n+1,n+1);
PutEfx  = zeros(n+1,n+1);
for i = 1:n+1           % option price when expired(j=n+1)
    CallAfx(i,n+1) = callfx(i,n+1);
    PutAfx(i,n+1)  = putfx(i,n+1);
    CallEfx(i,n+1) = callfx(i,n+1);
    PutEfx(i,n+1)  = putfx(i,n+1);
end
for jj = 1:n            % derive option prices when j=n-1,n-2,…,1
    j = n+1-jj;
    for i = 1:j
        CallEfx(i,j) = exp(-r*dt)*(p*CallEfx(i,j+1)+(1-p)*CallEfx(i+1,j+1));
        PutEfx(i,j)  = exp(-r*dt)*(p*PutEfx(i,j+1)+(1-p)*PutEfx(i+1,j+1));
        CallAfx(i,j) = max(exp(-r*dt)*(p*CallAfx(i,j+1)+(1-p)*CallAfx(i+1,j+1)),callfx(i,j));
        PutAfx(i,j)  = max(exp(-r*dt)*(p*PutAfx(i,j+1)+(1-p)*PutAfx(i+1,j+1)),putfx(i,j));
    end
end

%% get price and probability
AmeCallPrice  = CallAfx(1,1);
AmePutPrice   = PutAfx(1,1);
ErouCallPrice = CallEfx(1,1);
ErouPutPrice  = PutEfx(1,1);
Prob          = (exp((r-q)*dt)-d)/(u-d);

end