"""Interstellar dust extinction functions."""
import numpy as np
cimport numpy as np
from scipy.interpolate import splmake, spleval

__version__ = "0.1.0.dev"


# -----------------------------------------------------------------------------
# Cardelli, Clayton & Mathis (1989)

cdef inline void ccm89ab_ir_invum(double x, double *a, double *b):
    """ccm89 a, b parameters for 0.3 < x < 1.1 (infrared)"""
    cdef double y
    y = x**1.61
    a[0] = 0.574 * y
    b[0] = -0.527 * y


cdef inline void ccm89ab_opt_invum(double x, double *a, double *b):
    """ccm89 a, b parameters for 1.1 < x < 3.3 (optical)"""

    cdef double y

    y = x - 1.82
    a[0] = ((((((0.329990*y - 0.77530)*y + 0.01979)*y + 0.72085)*y - 0.02427)*y
             - 0.50447)*y + 0.17699)*y + 1.0
    b[0] = ((((((-2.09002*y + 5.30260)*y - 0.62251)*y - 5.38434)*y + 1.07233)*y
             + 2.28305)*y + 1.41338)*y


cdef inline void ccm89ab_uv_invum(double x, double *a, double *b):
    """ccm89 a, b parameters for 3.3 < x < 8.0 (ultraviolet)"""
    cdef double y, y2, y3

    y = x - 4.67
    a[0] = 1.752 - 0.316*x - (0.104 / (y*y + 0.341))
    y = x - 4.62
    b[0] = -3.090 + 1.825*x + (1.206 / (y*y + 0.263))
    if x > 5.9:
        y = x - 5.9
        y2 = y * y
        y3 = y2 * y
        a[0] += -0.04473*y2 - 0.009779*y3
        b[0] += 0.2130*y2 + 0.1207*y3


cdef inline void ccm89ab_fuv_invum(double x, double *a, double *b):
    """ccm89 a, b parameters for 8 < x < 11 (far-UV)"""
    cdef double y, y2, y3

    y = x - 8.
    y2 = y * y
    y3 = y2 * y
    a[0] = -0.070*y3 + 0.137*y2 - 0.628*y - 1.073
    b[0] = 0.374*y3 - 0.420*y2 + 4.257*y + 13.670


cdef inline void ccm89ab_invum(double x, double *a, double *b):
    if x < 1.1:
        ccm89ab_ir_invum(x, a, b)
    elif x < 3.3:
        ccm89ab_opt_invum(x, a, b)
    elif x < 8.:
        ccm89ab_uv_invum(x, a, b)
    else:
        ccm89ab_fuv_invum(x, a, b)


def ccm89_invum(double[:] x, double a_v, double r_v):
    """ccm89_invum(x, a_v, r_v)

    Cardelli, Clayton & Mathis (1989) extinction function for inverse microns.

    Based on description in http://adsabs.harvard.edu/abs/1989ApJ...345..245C.

    Parameters
    ----------
    x : numpy.ndarray (1-d)
        Wavenumber in [microns]^(-1).
    a_v : float
        Scaling parameter, A_V: extinction in magnitudes at characteristic
        V band wavelength.
    r_v : float
        Ratio of total to selective extinction, A_V / E(B-V).

    Returns
    -------
    Extinction in magnitudes at each input wavenumber.
    """

    cdef int i, n
    cdef double a, b
    cdef double[:] result_view
    a = 0.0
    b = 0.0

    n = x.shape[0]
    result = np.empty(n, dtype=np.float)
    result_view = result
    for i in range(n):
        ccm89ab_invum(x[i], &a, &b)
        result_view[i] = a_v * (a + b / r_v)
    return result


def ccm89_aa(double[:] wave, double a_v, double r_v):
    """ccm89_aa(wave, a_v, r_v)

    Cardelli, Clayton & Mathis (1989) extinction function for Angstroms.

    Parameters
    ----------
    wave : numpy.ndarray (1-d)
        Wavelength in Angstroms.
    a_v : float
        Scaling parameter, A_V: extinction in magnitudes at characteristic
        V band wavelength.
    r_v : float
        Ratio of total to selective extinction, A_V / E(B-V).

    Returns
    -------
    Extinction in magnitudes at each input wavelength.
    """

    cdef int i, n
    cdef double a, b
    cdef double[:] result_view
    a = 0.0
    b = 0.0

    n = wave.shape[0]
    result = np.empty(n, dtype=np.float)
    result_view = result
    for i in range(n):
        ccm89ab_invum(1e4/wave[i], &a, &b)
        result_view[i] = a_v * (a + b / r_v)

    return result

ccm89 = ccm89_aa

# -----------------------------------------------------------------------------
# O'Donnell (1994)

cdef inline void od94ab_opt_invum(double x, double *a, double *b):
    """od94 a, b parameters for 1.1 < x < 3.3 (optical)"""
    cdef double y

    y = x - 1.82
    a[0] = (((((((-0.505*y + 1.647)*y - 0.827)*y - 1.718)*y + 1.137)*y +
              0.701)*y - 0.609)*y + 0.104)*y + 1.0
    b[0] = (((((((3.347*y - 10.805)*y + 5.491)*y + 11.102)*y - 7.985)*y -
              3.989)*y + 2.908)*y + 1.952)*y


cdef inline void od94ab_invum(double x, double *a, double *b):
    if x < 1.1:
        ccm89ab_ir_invum(x, a, b)
    elif x < 3.3:
        od94ab_opt_invum(x, a, b)
    elif x < 8.:
        ccm89ab_uv_invum(x, a, b)
    else:
        ccm89ab_fuv_invum(x, a, b)


def od94_invum(double[:] x, double a_v, double r_v):
    """od94_invum(x, a_v, r_v)

    O'Donnell (1994) dust extinction function for x in inverse microns.
    """

    cdef int i, n
    cdef double a, b
    a = 0.0
    b = 0.0

    n = x.shape[0]
    result = np.empty(n, dtype=np.float)
    for i in range(n):
        od94ab_invum(x[i], &a, &b)
        result[i] = a_v * (a + b / r_v)
    return result


def od94_aa(double[:] wave, double a_v, double r_v):
    """od94_aa(wave, a_v, r_v)

    O'Donnell (1994) dust extinction function for wavelength in Angstroms.
    """

    cdef int i, n
    cdef double a, b
    a = 0.0
    b = 0.0

    n = wave.shape[0]
    result = np.empty(n, dtype=np.float)
    for i in range(n):
        od94ab_invum(1e4/wave[i], &a, &b)
        result[i] = a_v * (a + b / r_v)
    return result


od94 = od94_aa

# -----------------------------------------------------------------------------
# gcc 09

cdef double gcc09ab_uv_invum(double x, double *a, double *b):
    """gcc09 a, b parameters for x > 3.3 (ultraviolet)"""
    cdef double y, y2, y3

    y = x - 4.57
    a[0] = 1.896 - 0.372*x - 0.0108 / (y*y + 0.0422)
    y = x - 4.59
    b[0] = -3.503 + 2.057*x + 0.718 / (y*y + 0.0530*3.1)
    if x > 5.9:
        y = x - 5.9
        y2 = y * y
        y3 = y * y2
        a[0] += -0.110 * y2 - 0.0099 * y3
        b[0] += 0.537 * y2 + 0.0530 * y3


cdef inline void gcc09ab_invum(double x, double *a, double *b):
    if x < 1.1:
        ccm89ab_ir_invum(x, a, b)
    elif x < 3.3:
        od94ab_opt_invum(x, a, b)
    else:
        gcc09ab_uv_invum(x, a, b)


def gcc09_aa(double[:] wave, double a_v, double r_v):
    """gcc09_aa(wave, a_v, r_v)"""

    cdef int i, n
    cdef double a, b
    a = 0.0
    b = 0.0

    n = wave.shape[0]
    result = np.empty(n, dtype=np.float)
    for i in range(n):
        gcc09ab_invum(1e4/wave[i], &a, &b)
        result[i] = a_v * (a + b / r_v)
    return result


gcc09 = gcc09_aa

# -----------------------------------------------------------------------------
# Fitzpatrick 1999

DEF F99_X0 = 4.596
DEF F99_GAMMA = 0.99
DEF F99_C3 = 3.23
DEF F99_C4 = 0.41
DEF F99_C5 = 5.9
DEF F99_X02 = F99_X0 * F99_X0
DEF F99_GAMMA2 = F99_GAMMA * F99_GAMMA

# Used for wave < 2700.
cdef double _f99uv(double wave, double a_v, double r_v):
    """Fitzpatrick (1999) function for wavelengths < 2700 Angstroms"""
    cdef double c1, c2, d, x, x2, y, y2, rv2, k

    c2 =  -0.824 + 4.717 / r_v
    c1 =  2.030 - 3.007 * c2

    x = 1.e4 / wave
    x2 = x * x
    y = x2 - F99_X02
    d = x2 / (y * y + x2 * F99_GAMMA2)
    k = c1 + c2 * x + F99_C3 * d
    if x >= F99_C5:
        y = x - F99_C5
        y2 = y * y
        k += F99_C4 * (0.5392 * y2 + 0.05644 * y2 * y)

    return a_v * (1. + k / r_v)



def _f99kknots(double[:] xknots, double r_v):
    cdef double c1, c2, d, x, x2, y, rv2
    cdef int i
    c2 =  -0.824 + 4.717 / r_v
    c1 =  2.030 - 3.007 * c2
    rv2 = r_v * r_v

    kknots = np.empty(9, dtype=np.float)
    kknots[0] = -r_v
    kknots[1] = 0.26469 * r_v/3.1 - r_v
    kknots[2] = 0.82925 * r_v/3.1 - r_v
    kknots[3] = -0.422809 + 1.00270*r_v + 2.13572e-04*rv2 - r_v
    kknots[4] = -5.13540e-02 + 1.00216 * r_v - 7.35778e-05*rv2 - r_v
    kknots[5] = 0.700127 + 1.00184*r_v - 3.32598e-05*rv2 - r_v
    kknots[6] = (1.19456 + 1.01707*r_v - 5.46959e-03*rv2 +
                 7.97809e-04 * rv2 * r_v - 4.45636e-05 * rv2*rv2 - r_v)
    for i in range(7,9):
        x2 = xknots[i] * xknots[i]
        y = (x2 - F99_X02)
        d = x2 /(y * y + x2 * F99_GAMMA2)
        kknots[i] = c1 + c2*xknots[i] + F99_C3 * d

    return kknots


class F99Extinction(object):
    """Fitzpatrick (1999) dust extinction function with fixed R_V."""

    _XKNOTS = 1.e4 / np.array([np.inf, 26500., 12200., 6000., 5470.,
                               4670., 4110., 2700., 2600.])

    def __init__(self, r_v=3.1):
        self.r_v = r_v

        kknots = _f99kknots(self._XKNOTS, r_v)
        self._spline = splmake(self._XKNOTS, kknots, order=3)

    def __call__(self, np.ndarray wave not None, double a_v):
        cdef double[:] wave_view, out_view
        cdef double r_v = self.r_v
        cdef double ebv = a_v / r_v
        cdef int i

        # Optical/IR spline: evaluate at all wavelengths; we will overwrite
        # the UV points afterwards.
        out = spleval(self._spline, 1e4 / wave)  # this is actually "k"

        # Analytic function in the UV (< 2700 Angstroms).
        wave_view = wave
        out_view = out
        for i in range(wave_view.shape[0]):
            # for optical/IR, out is actually k, but we wanted
            # a_v/r_v * (k+r_v), so we adjust here.
            if wave_view[i] > 2700.:
                out_view[i] = ebv * (out_view[i] + r_v)

            # for UV, we overwrite the array with the UV function value.
            else:
                out_view[i] = _f99uv(wave_view[i], a_v, r_v)

        return out


# functional interface for Fitzpatrick (1999) with R_V = 3.1
f99 = F99Extinction(3.1)
f99.__doc__ = "Fitzpatrick (1999) dust extinction law for R_V = 3.1."

# -----------------------------------------------------------------------------
# Fitzpatrick & Massa 2007

DEF FM07_X0 = 4.592
DEF FM07_GAMMA = 0.922
DEF FM07_C1 = -0.175
DEF FM07_C2 = 0.807
DEF FM07_C3 = 2.991
DEF FM07_C4 = 0.319
DEF FM07_C5 = 6.097
DEF FM07_X02 = FM07_X0 * FM07_X0
DEF FM07_GAMMA2 = FM07_GAMMA * FM07_GAMMA
DEF FM07_R_V = 3.1  # Fixed for the time being (used in fm07kknots)

# Used for wave < 2700.
def _fm07uv(double[:] wave, double a_v):
    cdef double d, x, x2, y, k
    cdef int i, n

    n = wave.shape[0]
    res = np.empty(n, dtype=np.float)
    for i in range(0, n):
        x = 1.e4 / wave[i]
        x2 = x * x
        y = x2 - FM07_X02
        d = x2 / (y*y + x2 * FM07_GAMMA2)
        k = FM07_C1 + FM07_C2 * x + FM07_C3 * d
        if x > FM07_C5:
            y = x - FM07_C5
            k += FM07_C4 * y * y
        res[i] = a_v * (1. + k / 3.1)

    return res

# This is mainly defined here rather than as a constant in the public module
# so that we don't have to define the FM07 constants in two places.
def _fm07kknots(double[:] xknots):
    cdef double d
    cdef int i, n

    n = xknots.shape[0]
    kknots = np.empty(n, dtype=np.float)
    for i in range(0, 5):
        kknots[i] = (-0.83 + 0.63*FM07_R_V) * xknots[i]**1.84 - FM07_R_V
    kknots[5] = 0.
    kknots[6] = 1.322
    kknots[7] = 2.055
    for i in range(8, 10):
        d = xknots[i]**2 / ((xknots[i]**2 - FM07_X02)**2 +
                            xknots[i]**2 * FM07_GAMMA2)
        kknots[i] = FM07_C1 + FM07_C2 * xknots[i] + FM07_C3 * d
    return kknots


# -----------------------------------------------------------------------------
# Calzetti 2000
# http://adsabs.harvard.edu/abs/2000ApJ...533..682C
