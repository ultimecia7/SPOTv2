#include <math.h>
#include "mex.h"

// NOTE: This function is for grayscale images!


// small value, used to avoid division by zero
#define eps 0.0001
#define round(x) (x<0?ceil((x)-0.5):floor((x)+0.5))

// unit vectors used to compute gradient orientation
double uu[9] = {1.0000, 
		0.9397, 
		0.7660, 
		0.500, 
		0.1736, 
		-0.1736, 
		-0.5000, 
		-0.7660, 
		-0.9397};
double vv[9] = {0.0000, 
		0.3420, 
		0.6428, 
		0.8660, 
		0.9848, 
		0.9848, 
		0.8660, 
		0.6428, 
		0.3420};

static inline double min(double x, double y) { return (x <= y ? x : y); }
static inline double max(double x, double y) { return (x <= y ? y : x); }

static inline int min(int x, int y) { return (x <= y ? x : y); }
static inline int max(int x, int y) { return (x <= y ? y : x); }

// main function:
// takes a double color image and a bin size 
// returns HOG features
void process(const mxArray *mximage, const mxArray *mxsbin, mxArray *mxfeat, mxArray *mxfeat1, mxArray *mxfeat2, mxArray *mxfeat3) {
  double *im = (double *)mxGetPr(mximage);
  const int *dims = mxGetDimensions(mximage);
  if (mxGetNumberOfDimensions(mximage) != 2||
      mxGetClassID(mximage) != mxDOUBLE_CLASS)
    mexErrMsgTxt("Invalid input");

  int step=4;
  int sbin = (int)mxGetScalar(mxsbin);

  // memory for caching orientation histograms & their norms
  int blocks[2];
  blocks[0] = (int)round((double)dims[0]/(double)sbin);
  blocks[1] = (int)round((double)dims[1]/(double)sbin);
  double *hist  = (double *)mxCalloc(blocks[0]*blocks[1]*18, sizeof(double));
  double *hist1 = (double *)mxCalloc(blocks[0]*blocks[1]*18, sizeof(double));
  double *hist2 = (double *)mxCalloc(blocks[0]*blocks[1]*18, sizeof(double));
  double *hist3 = (double *)mxCalloc(blocks[0]*blocks[1]*18, sizeof(double));

  double *norm  = (double *)mxCalloc(blocks[0]*blocks[1], sizeof(double));
  double *norm1 = (double *)mxCalloc(blocks[0]*blocks[1], sizeof(double));
  double *norm2 = (double *)mxCalloc(blocks[0]*blocks[1], sizeof(double));
  double *norm3 = (double *)mxCalloc(blocks[0]*blocks[1], sizeof(double));

  // memory for HOG features
  int out[3];
  out[0] = max(blocks[0]-2, 0);
  out[1] = max(blocks[1]-2, 0);
  out[2] = 18;

  double *feat  = (double *)mxGetPr(mxfeat);
  double *feat1 = (double *)mxGetPr(mxfeat1);
  double *feat2 = (double *)mxGetPr(mxfeat2);
  double *feat3 = (double *)mxGetPr(mxfeat3);

  int visible[2];
  visible[0] = blocks[0]*sbin;
  visible[1] = blocks[1]*sbin;
  
  for (int x = 1; x < visible[1]-1+step; x++) {
    for (int y = 1; y < visible[0]-1+step; y++) {
      // first color channel
      double *s = im + min(x, dims[1]-2)*dims[0] + min(y, dims[0]-2);
      double dy = *(s+1) - *(s-1);
      double dx = *(s+dims[0]) - *(s-dims[0]);
      double v = dx*dx + dy*dy;

      // snap to one of 18 orientations
      double best_dot = 0;
      int best_o = 0;
      for (int o = 0; o < 9; o++) {
	       double dot = uu[o]*dx + vv[o]*dy;
			if (dot > best_dot) {
			  best_dot = dot;
			  best_o = o;
			} 
			else if (-dot > best_dot) {
			  best_dot = -dot;
			  best_o = o+9;
			}
      }
      
      // add to 4 histograms around pixel using linear interpolation
	  // 1 layer
      double xp = ((double)x+0.5)/(double)sbin - 0.5;
      double yp = ((double)y+0.5)/(double)sbin - 0.5;
      int ixp = (int)floor(xp);
      int iyp = (int)floor(yp);
      double vx0 = xp-ixp;
      double vy0 = yp-iyp;
      double vx1 = 1.0-vx0;
      double vy1 = 1.0-vy0;
      v = sqrt(v);

      if (ixp >= 0 && iyp >= 0 && x < visible[1]-1 && y< visible[0]-1) {
	*(hist + ixp*blocks[0] + iyp + best_o*blocks[0]*blocks[1]) += 
	  vx1*vy1*v;
      }

      if (ixp+1 < blocks[1] && iyp >= 0 && x < visible[1]-1 && y< visible[0]-1) {
	*(hist + (ixp+1)*blocks[0] + iyp + best_o*blocks[0]*blocks[1]) += 
	  vx0*vy1*v;
      }

      if (ixp >= 0 && iyp+1 < blocks[0] && x < visible[1]-1 && y< visible[0]-1) {
	*(hist + ixp*blocks[0] + (iyp+1) + best_o*blocks[0]*blocks[1]) += 
	  vx1*vy0*v;
      }

      if (ixp+1 < blocks[1] && iyp+1 < blocks[0] && x < visible[1]-1 && y< visible[0]-1) {
	*(hist + (ixp+1)*blocks[0] + (iyp+1) + best_o*blocks[0]*blocks[1]) += 
	  vx0*vy0*v;
      }
	  

	  //3 layer
      xp = ((double)x-step+0.5)/(double)sbin - 0.5;
      yp = ((double)y+0.5)/(double)sbin - 0.5;
      ixp = (int)floor(xp);
      iyp = (int)floor(yp);
      vx0 = xp-ixp;
      vy0 = yp-iyp;
      vx1 = 1.0-vx0;
      vy1 = 1.0-vy0;

      if (ixp >= 0 && iyp >= 0 && x>=step+1 && y< visible[0]-1 && x< visible[1]-1+step) {
	*(hist2 + ixp*blocks[0] + iyp + best_o*blocks[0]*blocks[1]) += 
	  vx1*vy1*v;
      }

      if (ixp+1 < blocks[1] && iyp >= 0 && x>=step+1 && y< visible[0]-1 && x< visible[1]-1+step) {
	*(hist2 + (ixp+1)*blocks[0] + iyp + best_o*blocks[0]*blocks[1]) += 
	  vx0*vy1*v;
      }

      if (ixp >= 0 && iyp+1 < blocks[0] && x>=step+1 && y< visible[0]-1 && x< visible[1]-1+step) {
	*(hist2 + ixp*blocks[0] + (iyp+1) + best_o*blocks[0]*blocks[1]) += 
	  vx1*vy0*v;
      }

      if (ixp+1 < blocks[1] && iyp+1 < blocks[0] && x>=step+1 && y< visible[0]-1 && x< visible[1]-1+step) {
	*(hist2 + (ixp+1)*blocks[0] + (iyp+1) + best_o*blocks[0]*blocks[1]) += 
	  vx0*vy0*v;
      }


	   //2 layer
      xp = ((double)x+0.5)/(double)sbin - 0.5;
      yp = ((double)y-step+0.5)/(double)sbin - 0.5;
      ixp = (int)floor(xp);
      iyp = (int)floor(yp);
      vx0 = xp-ixp;
      vy0 = yp-iyp;
      vx1 = 1.0-vx0;
      vy1 = 1.0-vy0;

       if (ixp >= 0 && iyp >= 0 && x < visible[1]-1 && y< visible[0]-1+step && y>=step+1) {
	*(hist1 + ixp*blocks[0] + iyp + best_o*blocks[0]*blocks[1]) += 
	  vx1*vy1*v;
      }

      if (ixp+1 < blocks[1] && iyp >= 0 && x < visible[1]-1 && y< visible[0]-1+step && y>=step+1) {
	*(hist1 + (ixp+1)*blocks[0] + iyp + best_o*blocks[0]*blocks[1]) += 
	  vx0*vy1*v;
      }

      if (ixp >= 0 && iyp+1 < blocks[0] && x < visible[1]-1 && y< visible[0]-1+step && y>=step+1) {
	*(hist1 + ixp*blocks[0] + (iyp+1) + best_o*blocks[0]*blocks[1]) += 
	  vx1*vy0*v;
      }

      if (ixp+1 < blocks[1] && iyp+1 < blocks[0] && x < visible[1]-1 && y< visible[0]-1+step && y>=step+1) {
	*(hist1 + (ixp+1)*blocks[0] + (iyp+1) + best_o*blocks[0]*blocks[1]) += 
	  vx0*vy0*v;
      }

	  //4 layer
      xp = ((double)x-step+0.5)/(double)sbin - 0.5;
      yp = ((double)y-step+0.5)/(double)sbin - 0.5;
      ixp = (int)floor(xp);
      iyp = (int)floor(yp);
      vx0 = xp-ixp;
      vy0 = yp-iyp;
      vx1 = 1.0-vx0;
      vy1 = 1.0-vy0;

      if (ixp >= 0 && iyp >= 0 && y>=step+1 && x< visible[1]-1+step && x>=step+1 && y< visible[0]-1+step) {
	*(hist3 + ixp*blocks[0] + iyp + best_o*blocks[0]*blocks[1]) += 
	  vx1*vy1*v;
      }

      if (ixp+1 < blocks[1] && iyp >= 0 && y>=step+1 && x< visible[1]-1+step && x>=step+1 && y< visible[0]-1+step) {
	*(hist3 + (ixp+1)*blocks[0] + iyp + best_o*blocks[0]*blocks[1]) += 
	  vx0*vy1*v;
      }

      if (ixp >= 0 && iyp+1 < blocks[0] && y>=step+1 && x< visible[1]-1+step && x>=step+1 && y< visible[0]-1+step) {
	*(hist3 + ixp*blocks[0] + (iyp+1) + best_o*blocks[0]*blocks[1]) += 
	  vx1*vy0*v;
      }

      if (ixp+1 < blocks[1] && iyp+1 < blocks[0] && y>=step+1 && x< visible[1]-1+step && x>=step+1 && y< visible[0]-1+step) {
	*(hist3 + (ixp+1)*blocks[0] + (iyp+1) + best_o*blocks[0]*blocks[1]) += 
	  vx0*vy0*v;
      }

    }
  }

  // compute energy in each block by summing over orientations
  for (int o = 0; o < 9; o++) {
    double *src1 = hist + o*blocks[0]*blocks[1];
    double *src2 = hist + (o+9)*blocks[0]*blocks[1];
	double *src11 = hist1 + o*blocks[0]*blocks[1];
    double *src21 = hist1 + (o+9)*blocks[0]*blocks[1];
	double *src12 = hist2 + o*blocks[0]*blocks[1];
    double *src22 = hist2 + (o+9)*blocks[0]*blocks[1];
	double *src13 = hist3 + o*blocks[0]*blocks[1];
    double *src23 = hist3 + (o+9)*blocks[0]*blocks[1];

    double *dst = norm;
	double *dst1 = norm1;
	double *dst2 = norm2;
	double *dst3 = norm3;


	double *end = norm + blocks[1]*blocks[0];

    while (dst < end) {
      *(dst++) += (*src1 + *src2) * (*src1 + *src2);
      src1++;
      src2++;
	  *(dst1++) += (*src11 + *src21) * (*src11 + *src21);
      src11++;
      src21++;
	  *(dst2++) += (*src12 + *src22) * (*src12 + *src22);
      src12++;
      src22++;
	  *(dst3++) += (*src13 + *src23) * (*src13 + *src23);
      src13++;
      src23++;
	}
  }

  // compute features
  for (int x = 0; x < out[1]; x++) {
    for (int y = 0; y < out[0]; y++) {
      double *dst = feat + x*out[0] + y;      
      double *src, *p, n1, n2, n3, n4;
	  double *dst1 = feat1 + x*out[0] + y;      
      double *src1,  n11, n21, n31, n41;
	  double *dst2 = feat2 + x*out[0] + y;      
      double *src2,  n12, n22, n32, n42;
	  double *dst3 = feat3 + x*out[0] + y;      
      double *src3,  n13, n23, n33, n43;

      p = norm + (x+1)*blocks[0] + y+1;
      n1 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
      p = norm + (x+1)*blocks[0] + y;
      n2 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
      p = norm + x*blocks[0] + y+1;
      n3 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
      p = norm + x*blocks[0] + y;      
      n4 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);

	  p = norm1 + (x+1)*blocks[0] + y+1;
      n11 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
      p = norm1 + (x+1)*blocks[0] + y;
      n21 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
      p = norm1 + x*blocks[0] + y+1;
      n31 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
      p = norm1 + x*blocks[0] + y;      
      n41 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);

	  p = norm2 + (x+1)*blocks[0] + y+1;
      n12 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
      p = norm2 + (x+1)*blocks[0] + y;
      n22 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
      p = norm2 + x*blocks[0] + y+1;
      n32 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
      p = norm2 + x*blocks[0] + y;      
      n42 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);

	  p = norm3 + (x+1)*blocks[0] + y+1;
      n13 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
      p = norm3 + (x+1)*blocks[0] + y;
      n23 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
      p = norm3 + x*blocks[0] + y+1;
      n33 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
      p = norm3 + x*blocks[0] + y;      
      n43 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);

      // contrast-sensitive features
      src  = hist + (x+1)*blocks[0] + (y+1);
	  src1 = hist1 + (x+1)*blocks[0] + (y+1);
	  src2 = hist2 + (x+1)*blocks[0] + (y+1);
	  src3 = hist3 + (x+1)*blocks[0] + (y+1);

      for (int o = 0; o < 18; o++) {
		double h1 = min(*src * n1, 0.2);
		double h2 = min(*src * n2, 0.2);
		double h3 = min(*src * n3, 0.2);
		double h4 = min(*src * n4, 0.2);
		*dst = 0.5 * (h1 + h2 + h3 + h4);
		dst += out[0]*out[1];
		src += blocks[0]*blocks[1];

		h1 = min(*src1 * n11, 0.2);
		h2 = min(*src1 * n21, 0.2);
		h3 = min(*src1 * n31, 0.2);
		h4 = min(*src1 * n41, 0.2);
		*dst1 = 0.5 * (h1 + h2 + h3 + h4);
		dst1 += out[0]*out[1];
		src1 += blocks[0]*blocks[1];

		h1 = min(*src2 * n12, 0.2);
		h2 = min(*src2 * n22, 0.2);
		h3 = min(*src2 * n32, 0.2);
		h4 = min(*src2 * n42, 0.2);
		*dst2 = 0.5 * (h1 + h2 + h3 + h4);
		dst2 += out[0]*out[1];
		src2 += blocks[0]*blocks[1];

		h1 = min(*src3 * n13, 0.2);
		h2 = min(*src3 * n23, 0.2);
		h3 = min(*src3 * n33, 0.2);
		h4 = min(*src3 * n43, 0.2);
		*dst3 = 0.5 * (h1 + h2 + h3 + h4);
		dst3 += out[0]*out[1];
		src3 += blocks[0]*blocks[1];
      }
    }
  }

  mxFree(hist);
  mxFree(norm);
  mxFree(hist1);
  mxFree(norm1);
  mxFree(hist2);
  mxFree(norm2);
  mxFree(hist3);
}

// matlab entry point
// F = features(image, bin)
// image should be color with double values
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
  if (nrhs != 2)
    mexErrMsgTxt("Wrong number of inputs"); 
  if (nlhs != 4)
    mexErrMsgTxt("Wrong number of outputs");

  const int *dims = mxGetDimensions(prhs[0]);
  int sbin = (int)mxGetScalar(prhs[1]);
  int blocks[2];
  blocks[0] = (int)round((double)dims[0]/(double)sbin);
  blocks[1] = (int)round((double)dims[1]/(double)sbin);
  int out[3];
  out[0] = max(blocks[0]-2, 0);
  out[1] = max(blocks[1]-2, 0);
  out[2] = 18;
   
  plhs[0] = mxCreateNumericArray(3, out, mxDOUBLE_CLASS, mxREAL);
  plhs[1] = mxCreateNumericArray(3, out, mxDOUBLE_CLASS, mxREAL);
  plhs[2] = mxCreateNumericArray(3, out, mxDOUBLE_CLASS, mxREAL);
  plhs[3] = mxCreateNumericArray(3, out, mxDOUBLE_CLASS, mxREAL);

  process(prhs[0], prhs[1], plhs[0], plhs[1], plhs[2], plhs[3]);
}