function pars = set_pce_pars(pc_type,pred_mode,tol,in_pcdim,out_pcord, ...
                             ntrain,nval)
%
%
    pars = struct([]);
    pars(1).pc_type   = pc_type;
    pars(1).pred_mode = pred_mode;
    pars(1).tol       = tol;
    pars(1).in_pcdim  = in_pcdim;
    pars(1).out_pcord = out_pcord;
    pars(1).ntrain    = ntrain;
    pars(1).nval      = nval;
    
end

