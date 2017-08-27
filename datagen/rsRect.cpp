/*
 * Function name  : rsRect.cpp
 * Author name    : Vijay Rengarajan
 * Creation date  : June 8, 2015
 *
 * Syntax:
 * targetImage = rsImage(sourceImage, homographies, sourceOrigin, wtMethod, searchRowSize)
 *
 * sourceImage : grayscale (nrows x ncols) or colour (nrows x ncols x 3)
 *
 * homographies : 3x3*nrows matrix
 *   Each has to be invertible. When homography is applied on the target,
 *   we get the source image. Every three column pair is a homography.
 *
 * sourceOrigin: The (0,0) location in sourceImage
 *   This is the point around which the image will be rotated.
 *
 * wtMethod: Weighting method for intensities during target-source mapping
 *   (1) IDW using 1, (2) IDW using max, (3) Closest pixel.
 *   IDW = inverse distance weighting.
 * 
 * searchRowSize : Number of rows to search before and after
 * 
 * Updates:
 * Created : June 8, 2015
 */

#include "mex.h"
#include<math.h>
#include "myMatrix.h"

/* This is the RS rectification function. I use target-to-source mapping.
 * For every pixel in the target grid, I find pixels of ith row in the
 * source grid which map to ith row when ith homography is used. I weigh
 * these intensities to get the target intensity. Three types of weighing:
 * (1) IDW using 1, (2) IDW using max, (3) Closest pixel.
 */
void rsRect(double *source, double *target, double *H, int nrows,
        int ncols, int nchan, double orig_row, double orig_col,
        int wt_meth, int homo_win)
{
    // Number of pixels
    int npix;
    
    // 2D point vars
    int src_row, src_col, f_src_row, f_src_col;
    double  tgt_row, tgt_col, src_row_ni, src_col_ni;
    
    // 1D point vars
    int tgt_idx, src_idx;
    
    // Loop vars
    int i, j, k, ii, jj, m, n;
    
    // Homo window
    int homo_min, homo_max;
    
    // Bilinear interpolation vars
    int *src_col_list = new int[2];
    int *src_row_list = new int[2];
    double *wt_list = new double[4];
    double *bil_int = new double[nchan];
    double *thisH;
    double wt;
    
    // Distance weighting vars
    double dist, sum_dist, max_dist, sum_val_dist, min_dist;
    int val_count, min_dist_idx;
    double EPS = 1.1;
    int MAX_VAL_COUNT = 40;
    double *val_dist = new double[MAX_VAL_COUNT];
    double *val_int = new double[nchan*MAX_VAL_COUNT];
    
    int loc_in_count = 0;
    int valid_pix = 1;
    npix = nrows * ncols;
    
    /* ------------------------------------
     * For every pixel
     * ------------------------------------
     */
    for(i=0; i<ncols; i++) {
        for(j=0; j<nrows; j++) {
            
            /* Initialize accumulation values */
            sum_dist = 0;
            val_count = 0;
            sum_val_dist = 0;
            
            /* Target index is also used during bilinear interp */
            tgt_idx = i*nrows + j;
            
            /* Default intensity of target is zero */
            for (k=0; k<nchan; k++) {
                target[k*npix + tgt_idx] = 0;
            }
            
            /* For every homography within the given window*/
            homo_min = j - homo_win;
            homo_max = j + homo_win;
            
            if (homo_min < 0) homo_min = 0;
            if (homo_max >= nrows) homo_max = nrows-1;
            
            valid_pix = 1;
            for(m=homo_min; m<=homo_max; m++) {
                
                /* Initialize bilinear intensity values */
                for (k=0; k<nchan; k++) {
                    bil_int[k] = 0;
                }
                
                /* --------------------------------------------------------
                 * Homography mapping from target to source
                 * --------------------------------------------------------
                 */
                
                /* Get row number and col number of the target grid. Offset
                 * and move the origin.
                 */
                tgt_col = i - orig_col;
                tgt_row = j - orig_row;
                
                /* Apply homography corresponding to this row to get non-int
                 * row,col of source grid .
                 */
                thisH = H + m*9;
                src_col_ni = (thisH[0]*tgt_col + thisH[3]*tgt_row + thisH[6]) / (thisH[2]*tgt_col + thisH[5]*tgt_row + thisH[8]);
                src_row_ni = (thisH[1]*tgt_col + thisH[4]*tgt_row + thisH[7]) / (thisH[2]*tgt_col + thisH[5]*tgt_row + thisH[8]);
                
                /* Uncompensate the origin to get back to the source row and
                 * col numbers.
                 */
                src_col_ni = src_col_ni + orig_col;
                src_row_ni = src_row_ni + orig_row;
                
                /* If the mapped point falls near the row same as homography index */
                dist = abs((double)m - src_row_ni);
                
                if (dist <= EPS && val_count < MAX_VAL_COUNT) {
                    /* ---------------------------
                     * Bilinear interpolation
                     * ---------------------------
                     */
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
                    
                    /* For every pair of row,col in the four-point set */
                    loc_in_count = 0;
                    for (ii=0; ii<2; ii++) {
                        for (jj=0; jj<2; jj++) {
                            /* Get this row and this col number, and weight */
                            src_col = src_col_list[ii];
                            src_row = src_row_list[jj];
                            wt = wt_list[ii*2 + jj];
                            
                            /* Get 1D index of target and source points */
                            src_idx = (int)(src_col*nrows + src_row);
                            
                            /* Map intensity to target only if the source point is
                             * within the source image. Else, assign 0. Do for all
                             * colour channels
                             */
                            if (src_row >=0 && src_row < nrows && src_col >=0 && src_col < ncols) {
                                for (k=0; k<nchan; k++) {
                                    loc_in_count = loc_in_count + 1;
                                    bil_int[k] = bil_int[k] + wt * source[k*npix + src_idx];
                                }
                            }
                        } // end for jj
                    } // end for ii
                    
                    /* ----------------------------------------------
                     * Store this intensity and other related values.
                     * ----------------------------------------------
                     */
                    val_dist[val_count] = dist;
                    sum_dist = sum_dist + dist;
                    if (dist < min_dist || val_count == 0) {
                        min_dist = dist;
                        min_dist_idx = val_count;
                    }
                    if (dist > max_dist || val_count == 0) {
                        max_dist = dist;
                    }
                    for (k=0; k<nchan; k++) {
                        val_int[val_count*nchan + k] = bil_int[k];
                        bil_int[k] = 0;
                    }
                    val_count = val_count + 1;
                    if (loc_in_count < 4)
                        valid_pix = 0;
                }
            } // end for m<nhomo
            
            if (valid_pix == 1)
                target[nchan*npix + tgt_idx] = 1.0;
            else
                target[nchan*npix + tgt_idx] = 0.0;
            if (val_count == 0)
                target[nchan*npix + tgt_idx] = 0.0;
            
            if (val_count > 0) {
                /* --------------------------------------------------------------
                 * Only if there is some mapping, do this, otherwise default (0)
                 * --------------------------------------------------------------
                 */
                switch(wt_meth) {
                    case 1:
                        /* -----------------------------------------------
                         * Inverse distance weighting - Method 1
                         * -----------------------------------------------
                         */
                        if (sum_dist > 1e-3) {
                            max_dist = max_dist / sum_dist;
                            for (n=0; n<val_count; n++) {
                                val_dist[n] = 1 - val_dist[n] / sum_dist;
                                sum_val_dist = sum_val_dist + val_dist[n];
                            }
                            for (n=0; n<val_count; n++) {
                                val_dist[n] = val_dist[n] / sum_val_dist;
                            }
                            
                            for (k=0; k<nchan; k++) {
                                for (n=0; n<val_count; n++) {
                                    target[k*npix + tgt_idx] = target[k*npix + tgt_idx] +
                                            val_dist[n] * val_int[n*nchan +k];
                                }
                            }
                        }
                        else {
                            /* All distances are zero, i.e. exactly map on row */
                            for (k=0; k<nchan; k++) {
                                for (n=0; n<val_count; n++) {
                                    target[k*npix + tgt_idx] = target[k*npix + tgt_idx] +
                                            val_int[n*nchan + k] / val_count;
                                }
                            }
                        }
                        break;
                    case 2:
                        /* -----------------------------------------------
                         * Inverse distance weighting - Method 2
                         * -----------------------------------------------
                         */
                        if (sum_dist > 1e-3) {
                            max_dist = max_dist / sum_dist;
                            for (n=0; n<val_count; n++) {
                                val_dist[n] = max_dist - val_dist[n] / sum_dist;
                                sum_val_dist = sum_val_dist + val_dist[n];
                            }
                            for (n=0; n<val_count; n++) {
                                val_dist[n] = val_dist[n] / sum_val_dist;
                            }
                            
                            for (k=0; k<nchan; k++) {
                                for (n=0; n<val_count; n++) {
                                    target[k*npix + tgt_idx] = target[k*npix + tgt_idx] +
                                            val_dist[n] * val_int[n*nchan +k];
                                }
                            }
                        }
                        else {
                            /* All distances are zero, i.e. exactly map on row */
                            for (k=0; k<nchan; k++) {
                                for (n=0; n<val_count; n++) {
                                    target[k*npix + tgt_idx] = target[k*npix + tgt_idx] +
                                            val_int[n*nchan + k] / val_count;
                                }
                            }
                        }
                        break;
                    case 3:
                        /* --------------------
                         * Use closest point
                         * --------------------
                         */
                        for (k=0; k<nchan; k++) {
                            target[k*npix + tgt_idx] = val_int[min_dist_idx*nchan + k];
                        }
                        break;
                    case 4:
                        /* -----------------------------------------------
                         * Inverse distance weighting - Method 3
                         * -----------------------------------------------
                         */
                        if (sum_dist > 1e-3) {
                            for (n=0; n<val_count; n++) {
                                val_dist[n] = 1 - val_dist[n];
                                sum_val_dist = sum_val_dist + val_dist[n];
                            }
                            for (n=0; n<val_count; n++) {
                                val_dist[n] = val_dist[n] / sum_val_dist;
                            }
                            
                            for (k=0; k<nchan; k++) {
                                for (n=0; n<val_count; n++) {
                                    target[k*npix + tgt_idx] = target[k*npix + tgt_idx] +
                                            val_dist[n] * val_int[n*nchan +k];
                                }
                            }
                        }
                        else {
                            /* All distances are zero, i.e. exactly map on row */
                            for (k=0; k<nchan; k++) {
                                for (n=0; n<val_count; n++) {
                                    target[k*npix + tgt_idx] = target[k*npix + tgt_idx] +
                                            val_int[n*nchan + k] / val_count;
                                }
                            }
                        }
                        break;
                }
            }
            
        } // end for j<nrows
    } // end for i<ncols
    delete[] src_col_list;
    delete[] src_row_list;
    delete[] wt_list;
    delete[] bil_int;
    //    delete[] thisH;
    delete[] val_dist;
    delete[] val_int;
}

/* Matlab calls this function */
void mexFunction(int nhls, mxArray *plhs[], int nrls, const mxArray *prhs[])
{
    int nrows, ncols, ndim, nchan, i, j;
    
    double *source, *target, *H,  *orig, *wt_meth, *homo_win;
    const int *siz;
    
    
    /* Create pointer to inputs */
    source = mxGetPr(prhs[0]); // source image
    H = mxGetPr(prhs[1]); // homography is of length 9*nrows
    orig = mxGetPr(prhs[2]); // origin of the source grid
    wt_meth = mxGetPr(prhs[3]); // weighting method
    homo_win = mxGetPr(prhs[4]); // homography search window size
    
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
    
    int *siz_new = new mwSize(3);
    siz_new[0] = siz[0];
    siz_new[1] = siz[1];
    siz_new[2] = nchan+1;
    
    const int* siz_new_const = const_cast<const int*>(siz_new);
    /* Create the output matrix */
    plhs[0] = mxCreateNumericArray(3,siz_new_const,mxDOUBLE_CLASS,mxREAL);
    
    /* Get a pointer to the output matrix */
    target = mxGetPr(plhs[0]);
    
    /* Call the function */
    rsRect(source, target, H, nrows, ncols, nchan, orig[0], orig[1], (int)*wt_meth, (int)*homo_win);
}
