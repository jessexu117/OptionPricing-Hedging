function [ y ] = Deriv_Normcdf( x )
%% 标准正态分布的导数方程
y = 1/sqrt(2*pi)*exp(-(x^2)/2);
end

