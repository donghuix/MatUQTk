function data_kl = m_cor_kl_reconstruct(xi,neig,mu,KLmodes)
    [nsam,neig2] = size(xi);
    if neig > neig2
        error('Select a smaller neig!!!\n');
    end
    ndim        = length(mu);
    data_kl     = NaN(nsam,ndim);
    for i = 1 : nsam
        data_kl(i,:) = mu;
        for j = 1 : neig
            data_kl(i,:) = data_kl(i,:) + xi(i,j).*KLmodes(:,j)';
        end
    end
end

