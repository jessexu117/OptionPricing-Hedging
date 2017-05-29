function SPaths=AssetPaths(S0,mu,sigma,T,NSteps,NRepl)
% AssetPaths   生成NRepl个长度为NSteps服从几何布朗运动的路径
% S0           股票市场价格
% mu           资产收益率均值（年收益对数）
% sigma        资产收益标准差（年收益对数）
% NSteps       时间段数量
% NRepl        样本路径数量

SPaths=zeros(NRepl,1+NSteps);
SPaths(:,1)=S0;
dt=T/NSteps;
nudt=(mu-0.5*sigma^2)*dt;
sidt=sigma*sqrt(dt);

for i=1:NRepl
    for j=1:NSteps
        SPaths(i,j+1)=SPaths(i,j)*exp(nudt+sidt*randn);
    end
end

end
