function [ ActiveCode ] = HandleCode( Code )
%% 根据传入的期货代码处理得到相应的活跃期货合约的代码

is_letter = isletter(Code);   % 判断是否为字母

if length(Code) == 10
    ActiveCode = strcat(Code(1:2),Code(7:end));
elseif length(Code) == 9
    if is_letter(2) == 1
        ActiveCode = strcat(Code(1:2),Code(6:end));
    else 
        ActiveCode = strcat(Code(1),Code(6:end));
    end
else
    error('你输入的标的代码有误！');
end

end

