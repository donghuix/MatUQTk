function [mapparam,pchain] = model_inf(uqtkbin, X, Y, pars, mindex_all, pccf_all, del_opt)
% INPUT:
% X [ N, S ], N values of inputs, S is dimension of xi
% Y [ N, 1 ], N values of observations
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

    dlmwrite('xdata.dat', X, ' ');
    dlmwrite('ydata.dat', Y, ' ');
    dlmwrite('xdata1.dat', X, ' ');
    dlmwrite('ydata1.dat', Y, ' ');

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
    PDIM = pars.in_pcdim;
    
    %cmd = [uqtkbin 'model_inf -f pcs -l classical -d ' num2str(PDIM) ' > inference.log'];
    if ispc
        cmd =[uqtkbin 'model_inf.exe -f pcs -l classical -a' num2str(a) ' -b ' num2str(b) ' -d ' num2str(PDIM) ' -m 10000 -o ' num2str(pars.out_pcord) ' > inference.log'];
        fprintf(['Running ' cmd]);
    else
        cmd = [uqtkbin 'model_inf -f pcs -l classical -a' num2str(a) ' -b ' num2str(b) ' -g 1 -d ' num2str(PDIM) ' -m 10000 -o ' num2str(pars.out_pcord) ' > inference.log'];
        fprintf(['Running ' cmd '\n']);
    end
    [status,cmdout] = system(cmd,'-echo');
    %chain = load('chain.dat');
    %likelihood = chain(:,end);
    %ibest = find(likelihood == max(likelihood));
    %mapparam = nanmean(chain(ibest,2:end-3),1);
    mapparam = load('mapparam.dat');
    pchain   = load('pchain.dat');
    
    if del_opt
        delete mindexp*dat pccfp*dat;
        delete xdata.dat ydata.dat;
        delete parampccfs.dat fmeans_sams.dat datavars.dat fvars.dat fmeans.dat ...
               pvars.dat pmeans.dat mapparam.dat pchain.dat;
        %Do NOT delete chain.dat to be able to construct posterior PDF
        delete chain.dat;
    end

end

