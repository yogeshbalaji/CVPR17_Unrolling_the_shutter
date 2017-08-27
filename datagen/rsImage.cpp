/*
 * Function name  : rsImage.cpp
 * Author name    : Vijay Rengarajan
 * Creation date  : June 5, 2015
 *
 * Syntax:
 * targetImage = rsImage(sourceImage, homographies, sourceOrigin)
 *
 * sourceImage : grayscale (nrows x ncols) or colour (nrows x ncols x 3)
 *
 * homographies : 3x3*nrows matrix
 *   Each has to be invertible. When homography is applied on the source,
 *   we get the target image. Inside the function, we find the inverse to
 *   map from the target grid to souce grid. Every three column pair is a
 *   homography.
 *
 * sourceOrigin: The (0,0) location in sourceImage
 *   This is the point around which the image will be rotated.
 *
 * Updates:
 * June 5, 2015 : Created
 * June 8, 2015 : Initialized the target pixels to zero before bilinear
 *                intepolation, so that I will just sum up intensities
 *                for all four corner points.
 */

#include "mex.h"
#include<math.h>
#include "myMatrix.h"

/* This is the warping function. I use target-to-source mapping. For every
 * pixel in the target grid, I find the correponding pixel in the source
 * grid using the inverse homography. I pick the homography corresponding
 * to that particular row. I use bilinear interpolation with
 * zero padding outside the source image region. The origin is provided by
 * the user.
 */
void rsImage(double *source, double *target, double *origH,
        int nrows, int ncols, int nchan, double orig_row, double orig_col)
{
    // Number of pixels
    int npix;
    
    // 2D point vars
    int src_row, src_col, f_src_row, f_src_col;
    double tgt_row, tgt_col, src_row_ni, src_col_ni;
    
    // 1D point vars
    int tgt_idx, src_idx;
    
    // Loop vars
    int i, j, k, ii, jj;
    
    // Bilinear interp vars
    int *src_col_list = new int[2];
    int *src_row_list = new int[2];
    double *wt_list = new double[4];
    double *H = new double[9*nrows];
    double *thisH;
    double wt;
    
    npix = nrows * ncols;
    
    /* Calculate homography inverse for target to source mapping */
    for (i=0; i<nrows; i++) {
        matInverse(origH + i*9, H + i*9);
    }
    
    /* ------------------------------------
     * For every pixel in target
     * ------------------------------------
     */
    for(i=0; i<ncols; i++) {
        for(j=0; j<nrows; j++) {
            
            /* --------------------------------------------------------
             * Homography mapping from target to source
             * --------------------------------------------------------
             */
            
            /* Get row number and col number of the target grid. Move the
             * origin.
             */
            tgt_row = j - orig_row;
            tgt_col = i - orig_col;
            
            /* Apply homography corresponding to this row to get non-int
             * row,col of source grid .
             */
            thisH = H + j*9;
            src_col_ni = (thisH[0]*tgt_col + thisH[3]*tgt_row + thisH[6]) / (thisH[2]*tgt_col + thisH[5]*tgt_row + thisH[8]);
            src_row_ni = (thisH[1]*tgt_col + thisH[4]*tgt_row + thisH[7]) / (thisH[2]*tgt_col + thisH[5]*tgt_row + thisH[8]);
            
            /* Uncompensate the origin to get back to the source row and
             * col numbers.
             */
            src_col_ni = src_col_ni + orig_col;
            src_row_ni = src_row_ni + orig_row;
            
            /* ---------------------------
             * Bilinear interpolation
             * ---------------------------
             */
            /* For bilinear interpolation */
            f_src_col = (int)floor(src_col_ni);
            f_src_row = (int)floor(src_row_ni);
            
            src_col_list[0] = f_src_col;
            src_col_list[1] = f_src_col+1;
            src_row_list[0] = f_src_row;
            src_row_list[1] = f_src_row+1;
            
            /* Weights for four corners.
             * The order is top-left, bottom-left, top-right, bottom-right.
             */
            wt_list[0] = (1 - src_col_ni + f_src_col) * (1 - src_row_ni + f_src_row);
            wt_list[1] = (1 - src_col_ni + f_src_col) * (src_row_ni - f_src_row);
            wt_list[2] = (src_col_ni - f_src_col) * (1 - src_row_ni + f_src_row);
            wt_list[3] = (src_col_ni - f_src_col) * (src_row_ni - f_src_row);
            
            tgt_idx = i*nrows + j;
            /* Default intensity of target is zero */
            for (k=0; k<nchan; k++) {
                target[k*npix + tgt_idx] = 0;
            }
            
            /* For every pair of row,col in the four-point set */
            for (ii=0; ii<2; ii++) {
                for (jj=0; jj<2; jj++) {
                    /* Get this row and this col number, and weight */
                    src_col = src_col_list[ii];
                    src_row = src_row_list[jj];
                    wt = wt_list[ii*2 + jj];
                    
                    /* Get 1D index of target and source points */
                    src_idx = src_col*nrows + src_row;
                    
                    /* Map intensity to target only if the source point is
                     * within the source image. Do for all colour channels.
                     */
                    if (src_row >=0 && src_row < nrows && src_col >=0 && src_col < ncols) {
                        for (k=0; k<nchan; k++) {
                            target[k*npix + tgt_idx] = target[k*npix + tgt_idx] + wt * source[k*npix + src_idx];
                        }
                    }
                } // end for jj
            } // end for ii
            
        }
    }
    delete[] src_col_list;
    delete[] src_row_list;
    delete[] wt_list;
//     delete[] thisH;
    delete[] H;
}

/* Matlab calls this function */
void mexFunction(int nhls, mxArray *plhs[], int nrls, const mxArray *prhs[])
{
    int nrows, ncols, ndim, nchan, i, j;
    
    double *source, *target, *H,  *orig;
    const int *siz;
    
    
    /* Create pointer to inputs */
    source = mxGetPr(prhs[0]); // source image
    H = mxGetPr(prhs[1]); // homography is of length 9*nrows
    orig = mxGetPr(prhs[2]); // origin of the source grid
    
    /* Size of the source image */
    ndim = mxGetNumberOfDimensions(prhs[0]); // Number of dimensions
    siz = mxGetDimensions(prhs[0]); // Each element is the size of each dim
    
    /* If the image is neither grayscale nor colour, return */
    if (ndim < 2 || ndim > 3) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notImage","Not a valid image\n");
    }
    
    nrows = (int) siz[0];
    ncols = (int) siz[1];
    if (ndim == 2) { nchan = 1; }
    else { nchan = 3; }
    
    
    /* Create the output matrix */
    plhs[0] = mxCreateNumericArray(ndim,siz,mxDOUBLE_CLASS,mxREAL);
    
    /* Get a pointer to the output matrix */
    target = mxGetPr(plhs[0]);
    
    /* Call the function */
    rsImage(source, target, H, nrows, ncols, nchan, orig[0], orig[1]);
}