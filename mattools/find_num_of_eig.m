function neig = find_num_of_eig(eig,thre)
    if nargin == 1
        thre = 0.95;
    end
    for i = 1 : length(eig)
        if sum(eig(1:i))/sum(eig) >= thre
            neig = i;
            break;
        end
    end
end

