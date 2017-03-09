import sys
import skrf
import matplotlib.pyplot as plt
import numpy as np
skrf.stylely()

ll = skrf.Network('load_load.s2p')
oo = skrf.Network('open_open.s2p')
ss = skrf.Network('short_short.s2p')
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

through_delay = 51.1e-12
d = 2*np.pi*through_delay
through_s = [[[0,np.exp(-1j*d*f)],[np.exp(-1j*d*f),0]] for f in freqs]
through_i = skrf.Network(s=through_s, f=freqs, f_unit='Hz')

cal = skrf.TwelveTerm(\
        measured = [oo, ss, ll, through],
        ideals =[oo_i, ss_i, ll_i, through_i],
        n_thrus = 1,
        isolation=ll
        )
cal.run()

if 0:
    coefs = cal.coefs
    for k in coefs.keys():
        plt.figure()
        plt.title(k)
        plt.plot(freqs, 20*np.log10(np.abs(coefs[k])))

plt.figure()
for net in sys.argv[1:]:
    dut = skrf.Network(net)
    dut = cal.apply_cal(dut)
    dut.plot_s_db()
    axes = plt.gca()
    axes.set_ylim([-80,10])

dut.write_touchstone('dut_calibrated.s2p')
plt.show(block=True)

