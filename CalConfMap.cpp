#include "math.h"
#include <limits>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "mex.h" 

#define round(x) (x<0?ceil((x)-0.5):floor((x)+0.5))

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
    
	double *loc_confidence = mxGetPr(prhs[0]);
    int imgW = (int)* (mxGetPr(prhs[1]));
    int imgH = (int)* (mxGetPr(prhs[2]));
    double *bbcenter = mxGetPr(prhs[3]);
    int len = (int)* (mxGetPr(prhs[4]));
	
    plhs[0] = mxCreateDoubleMatrix(imgH,imgW,mxREAL);
	double *inconf_map = mxGetPr(plhs[0]);
	int i,j,k,tempx,tempy;

	for (i=0;i<imgH;i++){
        for(j=0;j<imgW;j++){
			inconf_map[i+j*imgH]=0;
		}
	}

	for(i=0;i<len;i++){
        for(j=0;j<4;j++){
            for(k=0;k<4;k++){
                tempx=(int)bbcenter[i]+j-1;
                tempy=(int)bbcenter[i+len]+k-1;
				if(tempx>=0 && tempx<imgH && tempy>=0 && tempy<imgW){
		           inconf_map[tempx+tempy*imgH] = (double)loc_confidence[i];
				}
            }
        }
	}
	return;
}