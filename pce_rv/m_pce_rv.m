function [xtrain, xval] = m_pce_rv(uqtkbin,pars,rngnum,show_log)
    
    if nargin == 3
        show_log = 0; % default: not show log file
    end
    if nargin == 2
        rngnum = 0;
    end
    % Read parameters
    pc_type  = pars.pc_type;
    in_pcdim = pars.in_pcdim;
    ntrain   = pars.ntrain;
    nval     = pars.nval;

    rng(rngnum,'twister');
    r = randi([0 100],1,10);
    if ~isempty(ntrain)
        if ispc
            cmd=[uqtkbin 'pce_rv.exe -w PCvar -d '  num2str(in_pcdim) ' -p ' num2str(in_pcdim) ' -x ' pc_type ' -n ' num2str(ntrain) ' -s ' num2str(r(1)) ' > pcrv.log'];
            fprintf(['Running pce_rv.exe -w PCvar -d '  num2str(in_pcdim) ' -p ' num2str(in_pcdim) ' -x ' pc_type ' -n ' num2str(ntrain) ' -s ' num2str(r(1)) ' > pcrv.log']);
        else
            cmd=[uqtkbin 'pce_rv -w PCvar -d '  num2str(in_pcdim) ' -p ' num2str(in_pcdim) ' -x ' pc_type ' -n ' num2str(ntrain) ' -s ' num2str(r(1)) ' > pcrv.log'];
            fprintf(['Running ' cmd]);
        end
        system(cmd,'-echo');
        xtrain = load('rvar.dat');
        %dlmwrite('xtrain.dat',xtrain,' ');
    else
        xtrain = [];
    end
    
    if ~isempty(nval)
        if ispc
            cmd=[uqtkbin 'pce_rv.exe -w PCvar -d '  num2str(in_pcdim) ' -p ' num2str(in_pcdim) ' -x ' pc_type ' -n ' num2str(nval) ' -s ' num2str(r(2)) ' > pcrv.log'];
        else
            cmd=[uqtkbin 'pce_rv -w PCvar -d '  num2str(in_pcdim) ' -p ' num2str(in_pcdim) ' -x ' pc_type ' -n ' num2str(nval) ' -s ' num2str(r(2)) ' > pcrv.log'];
            fprintf(['Running ' cmd]);
        end
        system(cmd,'-echo');
        xval = load('rvar.dat');
        %dlmwrite('xval.dat',xval,' ');
    else
        xval = [];
    end
    
    if ~show_log
        delete pcrv.log;
    end
    delete rvar.dat;
    
end