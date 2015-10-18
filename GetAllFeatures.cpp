#include <limits>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "mex.h" 

#define round(x) (x<0?ceil((x)-0.5):floor((x)+0.5))

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	double xData;
	double *xData1 = mxGetPr(prhs[0]);
	double *xData2 = mxGetPr(prhs[1]);
	double *xData3 = mxGetPr(prhs[2]);
	double *xData4 = mxGetPr(prhs[3]);

	//int D = mxGetNumberOfDimensions(prhs[0]);
	double objW = (double)* (mxGetPr(prhs[4]));
	double objH = (double)* (mxGetPr(prhs[5]));
	double *featsize = mxGetPr(prhs[6]); //4*2

	int sbin = (int)* (mxGetPr(prhs[7]));
	double *offset = mxGetPr(prhs[8]); //4*2
	int xoffset[4],yoffset[4];
    int imgxoffset = (int)* (mxGetPr(prhs[9]));
	int imgyoffset = (int)* (mxGetPr(prhs[10]));
    int objBlockW=(int)round((double)objW /(double)sbin)-1;
    int objBlockH=(int)round((double)objH /(double)sbin)-1;

	int blockW[4], blockH[4],length;
	int lengthTotal=0;
	int i,j,ii,jj,k,t,col,p;
	for(i=0;i<4;i++){
		blockW[i] = (int)featsize[4+i];
		blockH[i] = (int)featsize[i];
		length = (blockW[i]-objBlockW+1)*(blockH[i]-objBlockH+1);
		lengthTotal = lengthTotal+length;
		xoffset[i]= (int)offset[i];
		yoffset[i]= (int)offset[4+i];
	}

	plhs[0] = mxCreateDoubleMatrix(lengthTotal, objBlockH*objBlockW*9+1, mxREAL);
	plhs[1] = mxCreateDoubleMatrix(lengthTotal, 4, mxREAL);
	plhs[2] = mxCreateDoubleMatrix(lengthTotal, 2, mxREAL);
	double *feat_out = mxGetPr(plhs[0]);
	double *location_out = mxGetPr(plhs[1]);
	double *center_out = mxGetPr(plhs[2]);
	
	t=-1;
	for(p=0;p<4;p++){	
		for(j=0;j<blockH[p]-objBlockH+1;j++){ 
			for(i=0;i<blockW[p]-objBlockW+1;i++){	
				t++;
				col=-1;
				location_out[t+1*lengthTotal] = (double)j*8+1+yoffset[p]+imgyoffset;
				location_out[t+0*lengthTotal] = (double)i*8+1+xoffset[p]+imgxoffset;
				location_out[t+3*lengthTotal] = (double)j*8+objH+yoffset[p]+imgyoffset;
				location_out[t+2*lengthTotal] = (double)i*8+objW+xoffset[p]+imgxoffset;
				center_out[t+0*lengthTotal] = (double)j*8+0.5*objH+yoffset[p]+imgyoffset;
				center_out[t+1*lengthTotal] = (double)i*8+0.5*objW+xoffset[p]+imgxoffset;
				for(k=0;k<9;k++){
					for(ii=i;ii<i+objBlockW;ii++){
						for(jj=j;jj<j+objBlockH;jj++){ 				
							col++;
							if(p==0){xData=(double)xData1[blockW[p]*blockH[p]*k+ii*blockH[p]+jj];}
							else if(p==1){xData=(double)xData2[blockW[p]*blockH[p]*k+ii*blockH[p]+jj];}
							else if(p==2){xData=(double)xData3[blockW[p]*blockH[p]*k+ii*blockH[p]+jj];}
							else if(p==3){xData=(double)xData4[blockW[p]*blockH[p]*k+ii*blockH[p]+jj];}
							feat_out[col*lengthTotal+t] = xData;			
						}
					}
				}
                feat_out[(objBlockH*objBlockW*9)*lengthTotal+t]=1;
			}
		}	
	}
	return;
}