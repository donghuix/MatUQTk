function [xtrain,ytrain,ntrain,xval,yval,nval] = preprocess_training_data2(xtrain,ytrain,xval,yval,cv,threhold)
    
    xall    = [xtrain; xval];
    yall    = [ytrain; yval];
    ntrain0 = size(ytrain,1);
    nval0   = size(yval,1);
    yall(cv < threhold,:) = [];
    ntot = size(yall,1);
    ntrain = ceil(ntot*(ntrain0/(ntrain0+nval0)));
    nval   = ntot - ntrain;
    xtrain = xall(1:ntrain,:);
    xval   = xall(ntrain+1:ntot,:);
    ytrain = yall(1:ntrain,:);
    yval   = yall(ntrain+1:ntot,:);
    
%     if nargin == 4
%         threhold = 2;
%     end
%     
%     [ntrain,nout] = size(ytrain);
%     [nval,nout] = size(yval);
%     
%     yall = [ytrain; yval];
%     xall = [xtrain; xval];
%     ratio = ntrain / (ntrain+nval);
%     
%     ibad = find(nanmean(yall,2) > threhold * nanmean(nanmean(yall,1)));
%     yall(ibad,:) = [];
%     xall(ibad,:) = [];
%     
%     [ntot,nout] = size(yall);
%     ntrain = ceil(ratio*ntot);
%     nval   = ntot - ntrain;
%     
%     ytrain = yall(1:ntrain,:);
%     yval   = yall(ntrain+1:ntrain+nval,:);
%     xtrain = xall(1:ntrain,:);
%     xval   = xall(ntrain+1:ntrain+nval,:);   
    
end

