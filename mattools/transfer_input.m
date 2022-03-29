function y = transfer_input(x,lb,ub,debug)
    if nargin == 3
        debug = 0;
    end
    if debug
        disp(['size(x) =' num2str(size(x))]);
        disp(['size(lb) =' num2str(size(lb))]);
        disp(['size(ub) =' num2str(size(ub))]);
    end
    y = x.*(ub - lb)./2 + (ub + lb)./2;
end

