function [ytrain_pc, yval_pc,err_train, err_val, pccf_all, mindex_all, allsens_main,allsens_total,allsens_joint] =  ...
          m_pce_bcs(uqtkbin,pars,xtrain,ytrain,xval,yval,del_opt,currdir,tag)
    
    if nargin < 7
        del_opt = 1; % Default mode is to delete all the files
    end
    if nargin == 6
        parallel_mode = 0;
    elseif nargin == 9
        parallel_mode = 1;
    else
        error('Check the input!!!');
    end
    
    [ntrain,nout] = size(ytrain);
    [nval,~]      = size(yval);
    assert(ntrain == pars.ntrain & nval == pars.nval);
    
    % Pre-allocate arrays and lists to store results
    pccf_all  = cell(nout,1);
    mindex_all= cell(nout,1);
    ytrain_pc = NaN(ntrain,nout);
    yval_pc   = NaN(nval,nout);
    err_train = NaN(nout,1);
    err_val   = NaN(nout,1);
    
    % Read parameters
    pc_type   = pars.pc_type;
    in_pcdim  = pars.in_pcdim;
    out_pcord = pars.out_pcord;
    pred_mode = pars.pred_mode;
    tol       = pars.tol;
    
    if parallel_mode
        workdir = fullfile(currdir,['tmp' num2str(tag)]);
        if ~exist(workdir,'dir')
            mkdir(workdir);
        end
        cd(workdir);
    end
    
    fprintf('\n\n************ Trainning Surrogate Model ************\n');
    for i = 1 : nout
        
        fprintf('\n###################################################\n');
        fprintf(['-------------------- ' num2str(i) 'th QOI --------------------\n\n']);
        ydata = ytrain(:,i);
        
        %save('ydata.dat','ydata','-ascii');
        dlmwrite('ydata.dat',ydata,' ');
        % Generate PC multiindex
        if ispc
            cmd= [uqtkbin 'gen_mi.exe -x"TO" -p' num2str(out_pcord) ' -q' num2str(in_pcdim) ' > gmi.log'];
            fprintf(['Running gen_mi.exe -x"TO" -p' num2str(out_pcord) ' -q' num2str(in_pcdim) ' > gmi.log \n']);
        else
            cmd= [uqtkbin 'gen_mi -x"TO" -p' num2str(out_pcord) ' -q' num2str(in_pcdim) ' > gmi.log; mv mindex.dat mi.dat'];
            fprintf(['Running ' cmd '\n']);
        end
   
        [status,cmdout] = system(cmd,'-echo');
        if ispc
            system('mv mindex.dat mi.dat');
        end
        mi=load('mi.dat'); 
        [npc,~] = size(mi);

        xcheck    = [xtrain; xval];
        regparams = ones(npc,1);
        save('xdata.dat','xtrain','-ascii');
        save('xcheck.dat','xcheck','-ascii');
        save('regparams.dat','regparams','-ascii');
        
        if ispc
            cmd=[uqtkbin 'regression.exe -x xdata.dat -y ydata.dat -b PC_MI -s ' pc_type ' -p mi.dat -w regparams.dat -m ' pred_mode ' -r wbcs -t xcheck.dat -c ' num2str(tol) ' > regr.log'];
            fprintf(['Running regression.exe -x xdata.dat -y ydata.dat -b PC_MI -s ' pc_type ' -p mi.dat -w regparams.dat -m ' pred_mode ' -r wbcs -t xcheck.dat -c ' num2str(tol) ' > regr.log \n']);
        else
            cmd=[uqtkbin 'regression -x xdata.dat -y ydata.dat -b PC_MI -s ' pc_type ' -p mi.dat -w regparams.dat -m ' pred_mode ' -r wbcs -t xcheck.dat -c ' num2str(tol) ' > regr.log'];
            fprintf(['Running ' cmd '\n']);
        end
        
        [status,cmdout] = system(cmd,'-echo');
        
        fprintf(cmdout);
        
        % Get the PC coefficients and multiindex and the predictive errorbars
        pccf   = load('coeff.dat');
        mindex = load('mindex_new.dat'); 

        % Append the results
        pccf_all{i}   = pccf;
        mindex_all{i} = mindex;

        % Evaluate surrogate at training points
        sprintf('Evaluating surrogate at %d training points', ntrain);
        ytrain_pc(:,i) = model_pc(uqtkbin,xtrain,mindex,pccf,pc_type,del_opt);
        err_train(i)=norm(ytrain(:,i)-ytrain_pc(:,i))/norm(ytrain(:,i));
        fprintf(['Surrogate relative error at training points : ' num2str(err_train(i)) '\n']);

        % Evaluate surrogate at validate points
        sprintf('Evaluating surrogate at %d training points', nval);
        yval_pc(:,i) = model_pc(uqtkbin,xval,mindex,pccf,pc_type,del_opt);
        err_val(i) = norm(yval(:,i)-yval_pc(:,i))/norm(yval(:,i));
        fprintf(['Surrogate relative error at validation points : ' num2str(err_val(i)) '\n']);
        fprintf('\n###################################################\n');
        
    end
    
    [allsens_main,allsens_total,allsens_joint] = m_pce_sens(uqtkbin,pars,mindex_all,pccf_all);
    
    if parallel_mode
        cd(currdir);
    end
    % delte files
    if del_opt
        if parallel_mode
            delete(fullfile(['tmp' num2str(tag)],'*'));
            rmdir(fullfile(['tmp' num2str(tag)]));
        else
            delete xcheck.dat; delete regparams.dat; delete regr.log;
            delete mi.dat; delete gmi.log; delete mindex_new.dat; delete coeff.dat;

            delete lambdas.dat; delete selected.dat; delete Sig.dat; delete sigma2.dat;
            delete ycheck.dat; delete ycheck_var.dat;
        end
    end
end
    


