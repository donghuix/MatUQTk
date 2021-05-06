import h5py
import numpy as np
import sys
import json
from joblib import Parallel, delayed,cpu_count
sys.path.append('/qfs/people/xudo627/MatUQTk/pytools/')
from pytools import p_pce_bcs, model_inf
#import multiprocessing as mp

cur_dir = '/compyfs/xudo627/ELM_Runoff_Sensitivity/Construct_PCE/data_01'
uqtkbin = '/qfs/people/xudo627/UQTk-install/bin/'
pars = dict()
pars['pc_type']   = 'LU'
pars['in_pcdim']  = 11
pars['out_pcord'] = 3
pars['pred_mode'] = 'ms'
pars['tol']       = 1e-3
xtrain_1 = np.loadtxt('../../code/xtrain_1.dat')
xval_1   = np.loadtxt('../../code/xval_1.dat')
xtrain_2 = np.loadtxt('../../code/xtrain_2.dat')
xval_2   = np.loadtxt('../../code/xval_2.dat')
x1       = np.vstack((xtrain_1,xval_1))
x2       = np.vstack((xtrain_2,xval_2))
xall     = np.vstack((x1,x2))

f = h5py.File('yall.mat')
ysim = f['yall']

ntot,nmon,ncell = ysim.shape

yall = np.empty((ncell,ntot,12))

for i in range(ncell):
	print(i)
	tmp = ysim[:,:,i]
	for j in range(ntot):
		yall[i,j,:] = np.nanmean(np.reshape(tmp[j,:],(12,20)),axis=1)

print(yall[1,:,:].shape)
ytrain = yall[:,:100,:]
yval   = yall[:,100:120,:]
xtrain = xall[:100,:]
xval   = xall[100:120,:]

f.close()

num_cores = 40

results =  Parallel(n_jobs=num_cores)(delayed(p_pce_bcs)(uqtkbin,pars,xtrain,ytrain[i,:,:],xval,yval[i,:,:],0, cur_dir,i) for i in range(80))

ytrain_pc = np.empty((ncell,100,12))
yval_pc   = np.empty((ncell,20,12))
mindex_all= []
pccf_all  = []
for i in range(len(results)):
	ytrain_pc[i,:,:] = results[i][0]
	yval_pc[i,:,:] = results[i][1]
	pccf_all.append(results[i][2])
	mindex_all.append(results[i][3])

 with open('mindex_all.json','w') as fp:
 	json.dump(mindex_all,fp)
 with open('pccf_all.json','w') as fp:
 	json.dump(pccf_all,fp)
 with open('ytrain_pc.json','w') as fp:
 	json.dump(ytrain_pc.tolist(),fp)
 with open('yval_pc.json','w') as fp:
 	json.dump(yval_pc.tolist(),fp)
