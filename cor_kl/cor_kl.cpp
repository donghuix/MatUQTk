#include <cstdio>
#include <stddef.h>
#include <fstream>
#include <string>
#include <math.h>
#include <iostream>
#include "assert.h"

#include <getopt.h>
#include "Array1D.h"
#include "Array2D.h"

#include "kle.h"
#include "tools.h"
#include "arrayio.h"
#include "arraytools.h"
#include "error_handlers.h"


using namespace std;

#define NEIG 10
#define PAR 5.0
#define XGRIDFILE   "xgrid.dat"


/// \brief Displays information about this program
int usage(){
  printf("usage: cor_kl [-h]  [-x<cov_type>] [-r<cov_file>] [-s<samples_file>] [-t<xgrid_file>] [-p<param>] [-e<neig>] [-n<nt>]\n");
  printf(" -h                 : print out this help message \n");

  printf(" -x <cov_type>     : define the covariance type \n");
  printf(" -r <cov_file>     : define the file from which the covariance is being read, if any\n");
  printf(" -s <samples_file> : define the file from which the sample curves are being read, if any\n");

  printf(" -t <xgrid_file>       : define the file from which the x- grid is being read (default=%s) \n",XGRIDFILE);
  printf(" -p <param>        : define the parameter of the covariance (default=%lg) \n",PAR);
  printf(" -e <neig>          : define the number of eigenvalues retained (default=%d) \n",NEIG);
  printf("================================================================================\n");
  printf("Input:: Nothing hard-coded.\n");
  printf("Output:: cov_out.dat, eig.dat, KLmodes.dat(scaled), rel_diag.dat(which fraction of the pointwise variance is captured),\n");
        ("      :: mean.dat and xi_data.dat(if covariance is based on read samples)\n");
  printf("--------------------------------------------------------------------------------\n");
  printf("Comments:\n");
  printf("================================================================================\n");
  exit(0);
  return 0;
}


/// \brief Program to do Karhunen-Loeve decomposition
/// given covariance type or covariance matrix in a file or samples
int main(int argc, char *argv[])
{
  cout << "******************cor_kl.cpp start*********************" << endl;
  // Set the default values
  int neig=NEIG;
  double param=PAR;
  char* xgrid_file=XGRIDFILE;

  char* cov_type;
  char* cov_file;
  char* samples_file;

  bool xflag=false;
  bool rflag=false;
  bool sflag=false;

  // Read the user input
  int c;

  while ((c=getopt(argc,(char **)argv,"hx:r:s:t:e:p:"))!=-1){
    switch (c) {
    case 'h':
      usage();
      break;
    case 'x':
      xflag=true;
      cov_type =  optarg;
      break;
    case 'r':
      rflag=true;
      cov_file=optarg;
      break;
    case 's':
      sflag=true;
      samples_file=optarg;
      break;
    case 't':
      xgrid_file=optarg;
      break;
    case 'e':
      neig =  strtol(optarg, (char **)NULL,0);
      break;
    case 'p':
      param =  strtod(optarg, (char **)NULL);
      break;
    }
  }

  if (!xflag && !rflag &&!sflag)
    throw Tantrum("Please either provide covariance type, or samples or covariance file!");

  // Print the input information on screen
  if ( rflag )
    cout<<"Will read the covariance from file "<<cov_file<<endl<<flush;
  else if ( sflag )
    cout<<"Will compute covariance based on samples from file "<<samples_file<<endl<<flush;
  else if ( xflag )
    cout<<"Will generate covariance of type "<<cov_type<<endl<<flush;

  cout<<"X-grid is read from file " << xgrid_file << endl << flush;
  cout<<"param = "<<param<<endl<<flush;
  cout<<"neig   = "<<neig  <<endl<<flush;

  /*----------------------------------------------------------------------------*/
  int nsamples;
  Array2D<double> samples;


  // Read the xgrid file
  Array2D<double> xgrid;
  read_datafileVS(xgrid,xgrid_file);
  // Get dimensions
  int nx   = xgrid.XSize();
  int ndim = xgrid.YSize();

  // Set the (isotropic) parameter vector
  Array1D<double> params(ndim,param);

  Array2D<double> uco(nx,nx,0.e0);

  if ( xflag ){

    for(int ix=0;ix<nx;ix++){
      Array1D<double> xgridi;
      getRow(xgrid,ix,xgridi);
      for(int jx=0;jx<nx;jx++){
        Array1D<double> xgridj;
        getRow(xgrid,jx,xgridj);
        uco(ix,jx)=covariance(xgridi,xgridj,params,cov_type);
      }
    }

  }
  else if(rflag){

    read_datafile(uco,cov_file);

  }
  else if(sflag){

    read_datafileVS(samples,samples_file);
    nsamples=samples.YSize();
    assert( nx == (int) samples.XSize());

    Array1D<double> mean(nx,0.e0);

    double sum;
    for(int ix=0;ix<nx;ix++){
      sum=0.0;
      for(int ir = 0; ir < nsamples; ir++) sum += samples(ix,ir);
      mean(ix) = sum/nsamples;
    }
    write_datafile_1d(mean,"mean.dat");

    /* Compute the upper triangular part */
    for(int ix=0;ix<nx;ix++){
      for(int jx=ix;jx<nx;jx++){
        sum=0.0;
        for(int ir=0;ir<nsamples;ir++){
          sum += (samples(ix,ir)-mean(ix))*(samples(jx,ir)-mean(jx));
        }
        uco(ix,jx) = sum/nsamples;
      }
    }
    /* Transpose to fill out the lower triangle */
    for(int ix=0;ix<nx;ix++)
      for(int jx=0;jx<ix;jx++)
        uco(ix,jx) = uco(jx,ix) ;

  }

  write_datafile( uco, "cov_out.dat" );

  //  Performing KL decomposition
  cout << "*******Starting KL decomposition*******" << endl;


  Array1D<double> xgrid_ind(nx);
  if (sflag){
    for (int ix=0;ix<nx;ix++)
     xgrid_ind(ix)=ix;
  }
  else
    read_datafile_1d(xgrid_ind,xgrid_file);

  KLDecompUni decomposer(xgrid_ind);
  int n_eig = decomposer.decompose(uco,neig);

  if(n_eig <  neig){
    printf("There are only %d  eigenvalues available (requested %d) \n",n_eig, neig);
    neig = n_eig;
  }

  const Array1D<double>& eig_values = decomposer.eigenvalues();
  const Array2D<double>& KL_modes   = decomposer.KLmodes();

  cout << "*******KL decomposition is done*******" << endl;

  cout << "Obtained " << n_eig << " eigenvalues:" << endl;
  Array1D<double> eig(n_eig,0.e0);
  for(int i_eig = 0; i_eig < n_eig; i_eig++){
    eig(i_eig)=eig_values(i_eig);
    cout << i_eig << " : " << eig_values(i_eig) << endl;
  }
  write_datafile_1d(eig,"eig.dat");

  Array1D<double> sum(nx,0.e0);
  Array1D<double> rel(nx,0.e0);
  for(int ix=0;ix<nx;ix++){
    for(int i_eig=0;i_eig<n_eig;i_eig++){
      sum(ix) += eig_values(i_eig)*KL_modes(ix,i_eig)*KL_modes(ix,i_eig);
    }
    rel(ix)=sum(ix)/uco(ix,ix);
  }
  write_datafile_1d(rel,"rel_diag.dat");

  Array2D<double> scaledKLmodes(nx,n_eig,0.e0);
  for(int ix=0;ix<nx;ix++){
    for(int i_eig=0;i_eig<n_eig;i_eig++)
      scaledKLmodes(ix,i_eig)=KL_modes(ix,i_eig)*sqrt(eig_values(i_eig));
  }
  write_datafile(scaledKLmodes,"KLmodes.dat");

  if(sflag){

    // Project realizations onto KL modes and write results to file
    Array2D<double> xi(neig, nsamples, 0.e0);
    decomposer.KLproject(samples, xi);

    Array2D<double> xit(nsamples,neig,0.e0);
    transpose(xi,xit);
    write_datafile(xit,"xi_data.dat");

  }

  cout << "******************cor_kl.cpp end***********************" << endl;
  return 0;

}



