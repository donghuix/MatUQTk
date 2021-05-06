function y = transfer_input(x,lb,ub)
    y = x.*(ub - lb)./2 + (ub + lb)./2;
end

