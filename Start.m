%% 实时定价与对冲监控系统
clear;clc;close all;
warning off; %#ok<*WNOFF>

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 注意：修改参数需删除InitDelta.mat文件，添加参数时不必删除！
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% OTC 定价参数设置 定价只需在后面加item即可
ud.code    = {'M1709.DCE'; 'M1709.DCE'; 'C1709.DCE'; 'C1709.DCE'}; % 标的资产代码；详细可参考文件：期货标的Wind列表.pdf
ud.side    = {'sellcall'; 'sellcall'; 'sellcall'; 'sellcall'};         % 交易方向：sellcall, buycall, sellput, buyput
ud.strike  = [2705; 2705; 1650; 1650];                        % 执行价格
ud.exercisedates = {'2017-8-23'; '2017-8-23'; '2017-8-23'; '2017-8-23'}; % 行权日期
ud.type    = [3; 1; 3; 1];        % 期权类型：European:1  American:2  Asian:3  Binary:4
ud.premium = [1.1; 1.1; 1.1; 1.1]; % 期权定价时波动率的溢价幅度
ud.yield   = [0; 0; 0; 0];        % 股票期权股息，暂时不适用于亚式期权
%% 对冲参数设置
ud.hedge    = [1; 0; 1; 0];            % 是否对冲设置: 0/1
ud.volume   = [9; 9; 30; 30];      % 交易量
ud.ordinaryDelta = [0.2; 0.2; 0.2; 0.2]; % 日常Delta变动阈值
ud.lastweekDelta = [0.15; 0.25; 0.15; 0.25]; % 最后一周Delta变动阈值
ud.lastdayDelta  = [0.1; 0.3; 0.1; 0.3]; % 最后一天Delta变动阈值

%% 亚式期权和二元期权参数设置：
ud.settle = { '2017-5-23';  '2017-5-23'; '2017-5-23'; '2017-5-23'}; % 签约日期，只适用于二元期权和亚式期权

%% 二元期权参数设置：不是二元期权则设为0
ud.pCStrike = [0.95; 0.95; 1.05; 1];    % Call Strike变动幅度
ud.pPStrike = [1.05; 0.95; 0.95; 1];    % Put Strike变动幅度
ud.pCash    = [0.05; 0.05; 0.05; 1];    % 支付额占现价的比率
% 以下仅用于二元期权对冲
ud.settleprice = [2888; 6888; 4388; 3150]; % 二元期权签约时的标的价格

%% 监控参数设置
t = timer;
t.Name     = 'HedgeTimer';
t.UserData = ud;              % 传入数据
t.TimerFcn = @DynamicHedge;
t.Period   = 300;             % 执行任务间隔时间
t.ExecutionMode = 'fixedrate';  

%t.TasksToExecute = 1;        % 如果不对冲，则值运行一次

%% Start/Stop
start(t);
%pause(3600*3);
%{
stop(t)     % 停止监控
%}