function [ y ] = Deriv_Normcdf( x )
%% 标准累计正态分布函数
y = 1/sqrt(2*pi)*exp(-(x^2)/2);
end

