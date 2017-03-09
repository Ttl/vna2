import sys
import skrf
import matplotlib.pyplot as plt
import numpy as np
skrf.stylely()

def tline_input(zl, z0, t, f):
    c = 299792458
    w = c/f
    b = np.pi*2/w
    l = t*c
    return z0*(zl+1j*z0*np.tan(b*l))/(z0+1j*zl*np.tan(b*l))

def gamma(zl, z0):
    return (zl-z0)/(zl+z0)

def make_open(freqs, c0, c1, c2, c3, offset_t, offset_z0):
    c_coefs = [c0*1e-15, c1*1e-27, c2*1e-36, c3*1e-45]

    reactance = []
    for f in freqs:
        c = 0
        for i in xrange(len(c_coefs)):
            c += c_coefs[i]*f**i
        xc = (-1.0j/(2*np.pi*f*c))
        reactance.append(xc)
    reactance = np.array(reactance)
    sparam = gamma(tline_input(reactance, offset_z0, offset_t, freqs), 50)

    return skrf.Network(s=sparam, f=freqs, f_unit='Hz')

def make_short(freqs, l0, l1, l2, l3, offset_t, offset_z0):
    c_coefs = [l0*1e-12, l1*1e-24, l2*1e-34, l3*1e-42]

    reactance = []
    for f in freqs:
        c = 0
        for i in xrange(len(c_coefs)):
            c += c_coefs[i]*f**i
        xc = (1.0j*2*np.pi*f*c)
        reactance.append(xc)
    reactance = np.array(reactance)
    sparam = gamma(tline_input(reactance, offset_z0, offset_t, freqs), 50)

    return skrf.Network(s=sparam, f=freqs, f_unit='Hz')

def make_load(freqs, r0, l0, l1, l2, l3, offset_t, offset_z0):
    c_coefs = [l0*1e-12, l1*1e-24, l2*1e-34, l3*1e-42]

    reactance = []
    for f in freqs:
        c = 0
        for i in xrange(len(c_coefs)):
            c += c_coefs[i]*f**i
        xc = (1.0j*2*np.pi*f*c)
        reactance.append(xc)
    reactance = np.array(reactance)
    sparam = gamma(tline_input(r0+reactance, offset_z0, offset_t, freqs), 50)

    return skrf.Network(s=sparam, f=freqs, f_unit='Hz')


o = skrf.Network('open.s1p')
s = skrf.Network('short.s1p')
l = skrf.Network('load.s1p')
dut = skrf.Network(sys.argv[1])

freqs = o.frequency

o_i = skrf.Network('../cal_kit/open.s1p')
s_i = skrf.Network('../cal_kit/short.s1p')
l_i = skrf.Network('../cal_kit/load.s1p')

o_i = o_i.interpolate(freqs)
s_i = s_i.interpolate(freqs)
l_i = l_i.interpolate(freqs)

#o_i = make_open(freqs, 4.46941071, -1353.09191861,  2189.61227292,  -143.3687188, 31.1e-12, 50)
#s_i = make_short(freqs, 64.1413939,  -11375.46199962,  -3975.09654213,    -77.69120398, 31.1e-12 ,50)
#l_i = make_load(freqs, 50.0, 95.97419879,  -61.62497249,  262.22809906, -881.59180129, 31.1e-12, 50)



cal = skrf.OnePort(\
        measured = [o, s, l],
        ideals =[o_i, s_i, l_i]
        )

coefs = cal.coefs
print coefs.keys()

for k in coefs.keys():
    plt.figure()
    plt.title(k)
    plt.plot(20*np.log10(np.abs(coefs[k])))

plt.figure()
dut_cal = cal.apply_cal(dut)
dut_cal.plot_s_db()
plt.show(block=True)

