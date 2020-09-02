function pcoutput = model_pc(uqtkbin,xtrain,mindex,pccf,pc_type,del_opt)
    
    % PC surrogate evaluator %
    
    % print "Running the surrogate model with parameters ", mparam
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
    
    % delte files
    if del_opt
        delete mindex.dat; 
        delete pccf.dat; 
        delete xdata.dat;
        delete ydata.dat; 
        delete fev.log;
    end

end

