#!/usr/bin/env python
import skrf
import matplotlib.pyplot as plt
import numpy as np
import sys
skrf.stylely()

# Calibration standards measured as two-port
# Can be one-port and then combined as two-port
# when not using SixteenTerm calibration
oo = skrf.Network('open_open.s2p')
ss = skrf.Network('short_short.s2p')
ll = skrf.Network('load_load.s2p')
through = skrf.Network('through.s2p')

freqs = through.f
frequency = through.frequency

o_i = skrf.Network('../cal_kit/open.s1p')
s_i = skrf.Network('../cal_kit/short.s1p')
l_i = skrf.Network('../cal_kit/load.s1p')

o_i = o_i.interpolate(frequency)
s_i = s_i.interpolate(frequency)
l_i = l_i.interpolate(frequency)

ll_i = skrf.two_port_reflect(l_i, l_i)
ss_i = skrf.two_port_reflect(s_i, s_i)
oo_i = skrf.two_port_reflect(o_i, o_i)

#Make ideal through
through_z0 = 46
through_delay = 100e-12
d = 2*np.pi*through_delay
att = np.log(10**(-0.1/20))/6e9
g = d+1j*att
through_s = [[[0,np.exp(-1j*g*f)],[np.exp(-1j*g*f),0]] for f in freqs]
through_i = skrf.Network(s=through_s, f=freqs, f_unit='Hz', z0=through_z0)
through_i.renormalize(50)

ll_i = skrf.two_port_reflect(l_i, l_i)
ls_i = skrf.two_port_reflect(l_i, s_i)
sl_i = skrf.two_port_reflect(s_i, l_i)
ss_i = skrf.two_port_reflect(s_i, s_i)
oo_i = skrf.two_port_reflect(o_i, o_i)

if 0:
    # Classic VNA calibration
    cal = skrf.TwelveTerm(\
            measured = [oo, ss, ll, through],
            ideals =[oo_i, ss_i, ll_i, through_i],
            isolation=ll,
            n_thrus = 1,
            )
    cal.run()
elif 1:
    # Doesn't require fully known through standard
    cal = skrf.UnknownThru(\
            measured = [oo, ss, ll, through],
            ideals =[oo_i, ss_i, ll_i, through_i],
            n_thrus = 1,
            )
    cal.run()
elif 0:
    sl = skrf.Network('short_load.s2p')
    ls = skrf.Network('load_short.s2p')
    # Calibrates leakage terms
    cal = skrf.SixteenTerm(\
            measured = [oo, ss, sl, ls, ll, through],
            ideals =[oo_i, ss_i, sl_i, ls_i, ll_i, through_i],
            n_thrus = 1,
            )
    cal.run()

if 0:
    # Plot calibration error terms
    coefs = cal.coefs
    for k in list(coefs.keys()):
        plt.figure()
        plt.title(k)
        plt.plot(freqs, 20*np.log10(np.abs(coefs[k])))

plt.figure(figsize=(8,5))
for dut in sys.argv[1:]:
    dut = skrf.Network(dut)
    dut.frequency.unit = "GHz"
    dut = cal.apply_cal(dut)
    dut.plot_s_db()

dut.write_touchstone('dut_calibrated.s2p')
plt.show(block=True)
