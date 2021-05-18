function [mapparam,pchain] = model_inf(uqtkbin, X, Y, pars, mindex_all, pccf_all, xfix, del_opt, currdir, tag)
% INPUT:
% uqtkbin: UQTk installed function dirctory
% X [ N ]: design or controllable parameter
% Y [ N ]: observations
% pars   : MatUQTk parameter structure
% mindex_all
% pccf_all
% del_opt: del_opt = 1 -> delete all the middle files 
% currdir, tag: for parallel processing 

    if nargin == 8
        parallel_mode = 0;
    elseif nargin == 10
        parallel_mode = 1;
    else
        error('Check the input!!!');
    end
    if isempty(X)
        X = 1 : size(Y,1);
        X = X';
    end
    [nx, dx] = size(X);
    [ny, nl] = size(Y);

    nm = length(mindex_all);
    np = length(pccf_all);

    assert(nx == ny, 'Check the size of X and Y!!!\n');
    assert(nm == np, 'Cehck the size of PC data!!!\n');
    
    if parallel_mode
        workdir = fullfile(currdir,['tmp' tag]);
        if ~exist(workdir,'dir')
            mkdir(workdir);
        end
        cd(workdir);
    end
    dlmwrite('xdata.dat', X, ' ');
    dlmwrite('ydata.dat', Y, ' ');
    dlmwrite('fixindnom.dat',xfix, ' ');
%     dlmwrite('xdata1.dat', X, ' ');
%     dlmwrite('ydata1.dat', Y, ' ');

    for i = 1 : nm

        mindex = mindex_all{i};
        pccf   = pccf_all{i};
        
        dlmwrite(['mindexp.' num2str(i-1) '.dat'], mindex, ' ');
        dlmwrite(['pccfp.' num2str(i-1) '.dat'], pccf, ' ');
        
        dlmwrite(['mindexp.' num2str(i-1) '_pred.dat'], mindex, ' ');
        dlmwrite(['pccfp.' num2str(i-1) '_pred.dat'], pccf, ' ');

    end
    
    if strcmp(pars.pc_type,'LU')
        a = -1;
        b = 1;
    end
    PDIM = pars.in_pcdim - size(xfix,1);
    
    %cmd = [uqtkbin 'model_inf -f pcs -l classical -d ' num2str(PDIM) ' > inference.log'];
    if ispc
        cmd =[uqtkbin 'model_inf.exe -f pcs -l classical -s pci -g 0.5 -z -u 5 -a ' num2str(a) ' -b ' num2str(b) ' -d ' num2str(PDIM) ' -m 10000 -o 0 -v fixindnom.dat > inference.log'];
        fprintf(['Running ' cmd]);
    else
        cmd = [uqtkbin 'model_inf -f pcs -l classical -s pci -g 0.5 -z -u 5 -a ' num2str(a) ' -b ' num2str(b) ' -d ' num2str(PDIM) ' -m 10000 -o 0 -v fixindnom.dat > inference.log'];
        fprintf(['Running ' cmd '\n']);
    end
    [status,cmdout] = system(cmd,'-echo');
    %chain = load('chain.dat');
    %likelihood = chain(:,end);
    %ibest = find(likelihood == max(likelihood));
    %mapparam = nanmean(chain(ibest,2:end-3),1);
    mapparam = load('mapparam.dat');
    pchain   = load('pchain.dat');
    if parallel_mode
        cd(currdir);
    end
    if del_opt
        if parallel_mode
            delete(fullfile(['tmp' tag],'*'));
            rmdir(fullfile(['tmp' tag]));
        else
            delete mindexp*dat pccfp*dat;
            delete xdata.dat ydata.dat;
            delete parampccfs.dat fmeans_sams.dat datavars.dat fvars.dat fmeans.dat ...
                   pvars.dat pmeans.dat mapparam.dat pchain.dat;
            %Do NOT delete chain.dat to be able to construct posterior PDF
            delete chain.dat;
        end
    end

end

