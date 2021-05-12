function [allsens_main,allsens_total,allsens_joint] = m_pce_sens(uqtkbin,pars,mindex_all,pccf_all,currdir,tag)
    
    if nargin == 4
        parallel_mode = 0;
    elseif nargin == 6
        parallel_mode = 1;
    else
        error('Check the input!!!');
    end

    pc_type  = pars.pc_type;
    in_pcdim = pars.in_pcdim;
    nout     = length(mindex_all);

    allsens_main  = zeros(nout,in_pcdim);
    allsens_total = zeros(nout,in_pcdim);
    allsens_joint = zeros(nout,in_pcdim,in_pcdim);
    
    if parallel_mode
        workdir = fullfile(currdir,['tmp' num2str(tag)]);
        if ~exist(workdir,'dir')
            mkdir(workdir);
        end
        cd(workdir);
    end
    
    for i = 1 : nout
       mindex = mindex_all{i};
       pccf   = pccf_all{i};
       save('PCcoeff.dat','pccf',  '-ascii');
       dlmwrite('mindex.dat',int64(mindex),'delimiter','\t');

       cmd = [uqtkbin 'pce_sens -m mindex.dat -f PCcoeff.dat -x ' pc_type ' > pcsens.log'];
       fprintf(['Running ' cmd '\n']);

       [status,cmdout] = system(cmd,'-echo');

       allsens_main(i,:)    = load('mainsens.dat');
       allsens_total(i,:)   = load('totsens.dat');
       allsens_joint(i,:,:) = load('jointsens.dat');
    end
    
    if parallel_mode
        cd(currdir);
    end
    if parallel_mode
        delete(fullfile(['tmp' num2str(tag)],'*'));
        rmdir(fullfile(['tmp' num2str(tag)]));
    else
        delete PCcoeff.dat mindex.dat mainsens.dat totsens.dat jointsens.dat
        delete sp_mindex.*.dat varfrac.dat
    end
end

