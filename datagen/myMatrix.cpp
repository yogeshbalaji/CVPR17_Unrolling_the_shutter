#ifndef MYMATRIX_H
#include "myMatrix.h"
#endif

/* For now, this will calculate the determinant of 3x3 matrix only */
double matDet3(double *in)
{
    double out;
    out = in[0]*(in[4]*in[8]-in[5]*in[7]) - in[3]*(in[1]*in[8]-in[2]*in[7])
    + in[6]*(in[1]*in[5]-in[2]*in[4]);
    return out;
}
/* For now, this will calculate the determinant of 2x2 matrix only */
double matDet2(double *in)
{
    double out;
    out = in[0]*in[3] - in[1]*in[2];
    return out;
}

/* For now, this will calculate the inverse of 3x3 matrix only. This may
 * not be the best implementation of finding the inverse. I just used the
 * formula: the matrix nverse is 1/det * minor of the transposed matrix.
 * Source:http://stackoverflow.com/questions/983999/simple-3x3-matrix-inverse-code-c
 */
void matInverse(double *in, double *out)
{
    double *tmp = new double[36];
    double det_in;
    int i;
    
    det_in = matDet3(in);
    
    tmp[0] = in[4]; tmp[1] = in[5]; tmp[2] = in[7]; tmp[3] = in[8];
    tmp[4] = in[7]; tmp[5] = in[8]; tmp[6] = in[1]; tmp[7] = in[2];
    tmp[8] = in[1]; tmp[9] = in[2]; tmp[10] = in[4]; tmp[11] = in[5];
    tmp[12] = in[6]; tmp[13] = in[8]; tmp[14] = in[3]; tmp[15] = in[5];
    
    tmp[16] = in[0]; tmp[17] = in[2]; tmp[18] = in[6]; tmp[19] = in[8];
    tmp[20] = in[3]; tmp[21] = in[5]; tmp[22] = in[0]; tmp[23] = in[2];
    tmp[24] = in[3]; tmp[25] = in[4]; tmp[26] = in[6]; tmp[27] = in[7];
    tmp[28] = in[6]; tmp[29] = in[7]; tmp[30] = in[0]; tmp[31] = in[1];
    tmp[32] = in[0]; tmp[33] = in[1]; tmp[34] = in[3]; tmp[35] = in[4];
    
    for (i=0; i<9; i++) {
        out[i] = matDet2((tmp+i*4)) / det_in;
    }
    delete[] tmp;
}