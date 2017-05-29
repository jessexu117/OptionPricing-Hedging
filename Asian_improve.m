function [Price,Var,UP]=Asian_improve(S0,K,r,T,sigma,type,divide,road,control)
% Asian_improve     亚式期权蒙特卡洛定价改进模型——采用控制变量技术
% S0                标的资产价格                 
% K                 执行价格
% r                 无风险年利率
% T                 剩余期限（年化）
% sigma             股票波动的标准差
% type              定价期权的类型，1表示看涨期权定价，0表示看跌期权定价
% divide            每条路径的采样点，时间离散的步数
% road              模拟的路径的数量
% control           控制变量技术所产生的资产价格路径数量

% Price             期权理论价格                         
% Var               期权理论价格的方差
% UP                95%置信区间的期权价格上下界 

if nargin == 6
    divide  = 1500;
    road    = 3000;
    control = 3000;
elseif nargin == 7
    road    = 3000;
    control = 3000;
elseif nargin == 8
    control = 3000;
end

%% 控制变量技术设置
controlpath  = AssetPaths(S0,r,sigma,T,divide,control);
sumroad      = sum(controlpath,2);
avg_randroad = mean(controlpath(:,2:(divide+1)),2);
clear controlpath;   % 释放内存
if type == 0
    control_profit = exp(-r*T)*max(0,K-avg_randroad);
elseif type == 1
    control_profit = exp(-r*T)*max(0,avg_randroad-K);
else 
    error('您输入了错误的type,请输入0或1');
end

MatCov = cov(sumroad,control_profit);      % 求协方差
bb = var(sumroad);
c  = -MatCov(1,2)/bb;
Eall = S0*((1-exp(r*T))/(1-exp(r*T/(divide+1))));   % 所有时点资产价格求和的期望值

%% 求改进的期权价格数值
control_payoff=zeros(road,1);
for i=1:road
    stock_path = AssetPaths(S0,r,sigma,T,divide,1);
    if type == 0
        payoff = exp(-r*T)*max(0,K-mean(stock_path(2:(divide+1))));
    elseif type == 1
        payoff = exp(-r*T)*max(0,mean(stock_path(2:(divide+1)))-K);
    end
    control_payoff(i) = payoff+c*(sum(stock_path)-Eall);
end
[Price,Var,UP] = normfit(control_payoff);     

end
