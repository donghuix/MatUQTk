from sys import platform
import numpy as np
import os
import shutil
import sys
import glob

def p_pce_bcs(uqtkbin,pars,xtrain,ytrain,xval,yval,del_opt,cur_dir=None,tag=None):

    if cur_dir == None:
        run_in_parallel = False
    else:
        run_in_parallel = True

    ntrain,nout   = ytrain.shape
    nval,nout     = yval.shape
    pccf_all      = []
    mindex_all    = []
    ytrain_pc     = np.empty((ntrain,nout))
    yval_pc       = np.empty((nval,nout))
    err_train     = np.empty((ntrain,nout))
    err_val       = np.empty((nval,nout))

    pc_type       = pars['pc_type']
    in_pcdim      = pars['in_pcdim']
    out_pcord     = pars['out_pcord']
    pred_mode     = pars['pred_mode']
    tol           = pars['tol']

    print('************ Trainning Surrogate Model ************')

    if run_in_parallel:
        if not os.path.isdir(cur_dir + '/tmp' + str(tag)):
            os.mkdir(cur_dir + '/tmp' + str(tag))
        os.chdir(cur_dir + '/tmp' + str(tag))

    for i in range(nout):
        print('##################################################')
        print('-------------------- ' + str(i) + 'th QOI --------------------')
        ydata = ytrain[:,i]

        np.savetxt('ydata.dat',ydata,delimiter='\t')

        if platform == 'darwin':
            cmd = uqtkbin + 'gen_mi -x"TO" -p ' + str(out_pcord) + ' -q' + str(in_pcdim) + ' > gmi.log'
        elif platform == 'win32':
            cmd = uqtkbin + 'gen_mi.exe -x"TO" -p ' + str(out_pcord) + ' -q' + str(in_pcdim) + ' > gmi.log'
        print('Running ' + cmd)

        os.system(cmd)

        if platform == 'win32':
            os.system('mv mindex.dat mi.dat')
        elif platform == 'darwin':
            os.system('mv mindex.dat mi.dat')
        mi = np.loadtxt('mi.dat')
        npc = mi.shape[0]

        xcheck = np.vstack((xtrain,xval))
        regparams = np.ones((npc,1))

        np.savetxt('xdata.dat',xtrain,delimiter='\t')
        np.savetxt('xcheck.dat',xcheck,delimiter='\t')
        np.savetxt('regparams.dat',regparams,delimiter='\t')

        if platform == 'darwin':
            cmd = uqtkbin + 'regression -x xdata.dat -y ydata.dat -b PC_MI -s ' + pc_type +       \
                    ' -p mi.dat -w regparams.dat -m ' + pred_mode + ' -r wbcs -t xcheck.dat -c ' + \
                    str(tol) + ' > regr.log'
        elif platform == 'win32':
            cmd = uqtkbin + 'regression.exe -x xdata.dat -y ydata.dat -b PC_MI -s ' + pc_type +   \
                    ' -p mi.dat -w regparams.dat -m ' + pred_mode + ' -r wbcs -t xcheck.dat -c ' + \
                    str(tol) + ' > regr.log'
        print('Running ' + cmd)

        os.system(cmd)

        # Get the PC coefficients and multiindex and the predictive errorbars
        pccf   = np.loadtxt('coeff.dat')
        mindex = np.loadtxt('mindex_new.dat')

        # Append the results
        pccf_all.append(pccf)
        mindex_all.append(mindex)

        # Evaluate surrogate at training points
        print('Evaluating surrogate at %d training points' % ntrain)
        ytrain_pc[:,i] = model_pc(uqtkbin,xtrain,pccf,mindex,pars,del_opt)
        err_train[i]   = np.linalg.norm(ytrain[:,i]-ytrain_pc[:,i])/np.linalg.norm(ytrain[:,i])
        print('Surrogate relative error at training points : ' + str(err_train[i]))

        # Evaluate surrogate at validating points
        print('Evaluating surrogate at %d validating points' % nval)
        yval_pc[:,i] = model_pc(uqtkbin,xval,pccf,mindex,pars,del_opt)
        err_val[i]   = np.linalg.norm(yval[:,i]-yval_pc[:,i])/np.linalg.norm(yval[:,i])
        print('Surrogate relative error at validating points : ' + str(err_val[i]))
    
    if run_in_parallel:
        os.chdir(cur_dir)

    if del_opt:
        if run_in_parallel:
            shutil.rmtree(cur_dir + '/tmp' + str(tag)) 
        else:
            os.remove("xcheck.dat") 
            os.remove("regparams.dat")
            os.remove("regr.log")
            os.remove("mi.dat")
            os.remove("gmi.log") 
            os.remove("mindex_new.dat")
            os.remove("coeff.dat")
            os.remove("lambdas.dat")
            os.remove("selected.dat")
            os.remove("Sig.dat")
            os.remove("sigma2.dat")
            os.remove("ycheck.dat") 
            os.remove("ycheck_var.dat")

    return ytrain_pc, yval_pc, pccf_all, mindex_all

def model_inf(uqtkbin, X, Y, pars, mindex_all, pccf_all, del_opt, cur_dir=None, tag=None):
# INPUT:
# uqtkbin: UQTk installed function dirctory
# X [ N ]: design or controllable parameter
# Y [ N ]: observations
# pars   : MatUQTk parameter structure
# mindex_all
# pccf_all
# del_opt: del_opt = 1 -> delete all the middle files 
# currdir, tag: for parallel processing     
    if cur_dir == None:
        run_in_parallel = False
    else:
        run_in_parallel = True
    
    if X == None:
        X = np.arange(len(mindex_all))+1
    if not isinstance(Y, list):
        ny = 1
        nx = 1
    else:
        nx = len(X)
        ny = len(Y)
    nm = len(mindex_all)
    nf = len(pccf_all)
    assert(nx == ny, 'Check the size of X and Y!!!')
    assert(nm == nf, 'Cehck the size of PC data!!!')

    pc_type       = pars['pc_type']
    in_pcdim      = pars['in_pcdim']
    out_pcord     = pars['out_pcord']
    pred_mode     = pars['pred_mode']
    tol           = pars['tol']

    if 'nmcmc' in pars.keys():
        nmcmc = pars['nmcmc']
    else:
        nmcmc = 10000

    if run_in_parallel:
        if not os.path.isdir(cur_dir + '/tmp' + str(tag)):
            os.mkdir(cur_dir + '/tmp' + str(tag))
        os.chdir(cur_dir + '/tmp' + str(tag))
    
    np.savetxt('xdata.dat',X,delimiter='\t')
    np.savetxt('ydata.dat',Y,delimiter='\t')

    for i in range(nm):
        mindex = mindex_all[i]
        pccf   = pccf_all[i]
        np.savetxt('mindexp.'+str(i)+'.dat',mindex,delimiter='\t')
        np.savetxt('pccfp.'+str(i)+'.dat',pccf,delimiter='\t')
        np.savetxt('mindexp.'+str(i)+'_pred.dat',mindex,delimiter='\t')
        np.savetxt('pccfp.'+str(i)+'_pred.dat',pccf,delimiter='\t')
    
    if pc_type == 'LU':
        a = -1
        b = 1
    else:
        sys.exit(pc_type + ' is not surpported now.')
    
    if platform == 'darwin':
        cmd = uqtkbin + 'model_inf -f pcs -l classical -a ' + str(a) + ' -b ' + str(b) +  ' -d ' +    \
                str(in_pcdim) + ' -m ' + str(nmcmc) + ' -o ' + str(out_pcord) + ' > inference.log'  
    elif platform == 'win32':
        cmd = uqtkbin + 'model_inf.exe -f pcs -l classical -a ' + str(a) + ' -b ' + str(b) +  ' -d '+ \
                str(in_pcdim) + ' -m ' + str(nmcmc) + ' -o ' + str(out_pcord) + ' > inference.log'    
    print('Running ' + cmd)

    os.system(cmd)

    mapparam = np.loadtxt('mapparam.dat')
    pchain   = np.loadtxt('pchain.dat')

    if run_in_parallel:
        os.chdir(cur_dir)

    if del_opt:
        if run_in_parallel:
            shutil.rmtree(cur_dir + '/tmp' + str(tag)) 
        else:
            os.remove("xdata.dat") 
            os.remove("ydata.dat")
            os.remove("parampccfs.dat")
            os.remove("fmeans_sams.dat")
            os.remove("datavars.dat") 
            os.remove("fvars.dat")
            os.remove("fmeans.dat")
            os.remove("pvars.dat")
            os.remove("pmeans.dat")
            os.remove("mapparam.dat")
            os.remove("pchain.dat")
            os.remove("chain.dat") 
            for file in glob.glob('mindexp*dat'):
                os.remove(file)
            for file in glob.glob('pccfp*dat'):
                os.remove(file)
    return mapparam, pchain
        

def model_pc(uqtkbin, x, pccf, mindex, pars, del_opt):
    """PC surrogate evaluator"""

    np.savetxt('mindex.dat',mindex,fmt='%d')
    np.savetxt('pccf.dat',pccf)
    pctype=pars['pc_type']

    np.savetxt('xdata.dat',x)
    cmd="pce_eval -x'PC_mi' -f'pccf.dat' -s"+pctype+" -r'mindex.dat' > fev.log"
    print("Running %s" % cmd)
    os.system(uqtkbin+cmd)
    pcoutput=np.loadtxt('ydata.dat')

    if del_opt:
        os.remove("mindex.dat") 
        os.remove("pccf.dat")
        os.remove("xdata.dat")
        os.remove("ydata.dat")
        os.remove("fev.log")

    return pcoutput

def test(uqtkbin,pars,xtrain,ytrain,xval,yval,del_opt):
    print('this is test!')