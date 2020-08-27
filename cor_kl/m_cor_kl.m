function [outputs,status,cmdout] = m_cor_kl(cor_kl_exe,data,e)
% matlab interface for Karhunen-Loeve Decomposition
% #-INPUTS-# 
% cor_kl_exe: directory of cor_kl execute file
% data: [N x M], N is the dimensionality of the multivariate random
%       variables, M is the number of samples
% e: number of eigenvalues requested
% #--------#
%
% #-OUTPUTS-#
% outputs: structure data for the results
% status, cmdout: outputs from command line
% #---------#
%
% Donghui Xu, 08/26/2020

    if ( ~exist(cor_kl_exe,'file') )
        error([cor_kl_exe ' does not exist!'])
    end
    save('ydata.dat','data','-ascii');
    m = size(data,1);
    xgrid = 1 : m; xgrid = xgrid';
    save('xgrid.dat','xgrid','-ascii');
    cmd = [cor_kl_exe ' -s ydata.dat -t xgrid.dat -e ' num2str(e)];
    
    [status,cmdout] = system(cmd,'-echo');
    
    outputs = struct([]);
    outputs(1).mu = load('mean.dat');
    outputs(1).xi = load('xi_data.dat');
    outputs(1).KLmodes = load('KLmodes.dat');
    outputs(1).eig = load('eig.dat');
    outputs(1).rel_diag = load('rel_diag.dat');
    outputs(1).cov_out = load('cov_out.dat');
    
    % clean the files
    delete xi_data.dat mean.dat KLmodes.dat eig.dat rel_diag.dat cov_out.dat;
    delete ydata.dat xgrid.dat;
end

