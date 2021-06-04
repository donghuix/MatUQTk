function [outputs,status,cmdout] = m_cor_kl(cor_kl_exe,data,e,reconstruct,currdir,tag)
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
    
    if nargin == 4
        parallel_mode = 0;
    elseif nargin == 6
        parallel_mode = 1;
    else
        error('Check the input!!!');
    end
    
    if parallel_mode
        workdir = fullfile(currdir,['tmp' num2str(tag)]);
        if ~exist(workdir,'dir')
            mkdir(workdir);
        end
        cd(workdir);
    end
    
    if ( ~exist(cor_kl_exe,'file') )
        error([cor_kl_exe ' does not exist!'])
    end
    
    if nargin == 3
        reconstruct = 0;
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
    
    if reconstruct
        [nsam,neig] = size(outputs.xi);
        ndim        = length(outputs.mu);
        data_kl     = NaN(nsam,ndim);
        for i = 1 : nsam
            data_kl(i,:) = outputs.mu;
            for j = 1 : neig
                data_kl(i,:) = data_kl(i,:) + outputs.xi(i,j).*outputs.KLmodes(:,j)';
            end
        end
        outputs(1).data_kl = data_kl;
    end
    
    % clean the files
    if parallel_mode
        cd(currdir);
        delete(fullfile(['tmp' num2str(tag)],'*'));
        rmdir(fullfile(['tmp' num2str(tag)]));
    else
        delete xi_data.dat mean.dat KLmodes.dat eig.dat rel_diag.dat cov_out.dat;
        delete ydata.dat xgrid.dat;
    end
end

