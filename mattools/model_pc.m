function pcoutput = model_pc(uqtkbin,xtrain,mindex,pccf,pc_type,del_opt,currdir,tag)
    
    % PC surrogate evaluator %
    
    if nargin == 6
        parallel_mode = 0;
    elseif nargin == 8
        parallel_mode = 1;
    else
        error('Check the input!!!');
    end
    
    % print "Running the surrogate model with parameters ", mparam
    if parallel_mode
        workdir = fullfile(currdir,['tmp' tag]);
        if ~exist(workdir,'dir')
            mkdir(workdir);
        end
        cd(workdir);
    end
    dlmwrite(fullfile(getenv('wkdir'),'mindex.dat'),mindex,'delimiter',' ');
    dlmwrite(fullfile(getenv('wkdir'),'pccf.dat'),pccf,'delimiter',' ');
    pctype = pc_type;
    
    dlmwrite('xdata.dat',xtrain,' ');
    if ispc
        cmd = [uqtkbin 'pce_eval.exe -x"PC_mi" -f"pccf.dat" -s' pctype ' -r"mindex.dat" > fev.log'];
        fprintf(['Running pce_eval.exe -x"PC_mi" -f"pccf.dat" -s' pctype ' -r"mindex.dat" > fev.log \n']);
    else
        cmd = [uqtkbin 'pce_eval -x"PC_mi" -f"pccf.dat" -s' pctype ' -r"mindex.dat" > fev.log'];
        fprintf(['Running ' cmd '\n']);
    end
    [status,cmdout] = system(cmd,'-echo');
    pcoutput = load('ydata.dat');
    
    if parallel_mode
        cd(currdir);
    end
    
    % delte files
    if del_opt
        if parallel_mode
            delete(fullfile(['tmp' tag],'*'));
            rmdir(fullfile(['tmp' tag]));
        else
            delete mindex.dat; 
            delete pccf.dat; 
            delete xdata.dat;
            delete ydata.dat; 
            delete fev.log;
        end
    end

end

