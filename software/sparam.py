from __future__ import division
from vna import VNA
import matplotlib.pyplot as plt
import numpy as np
import time
import skrf
import pickle

def iq_to_sparam(iqs, freqs, ports, sw_correction=True):
    sparams = []

    if len(ports) == 1:
        for f in xrange(len(freqs)):
            if ports[0] == 1:
                s = iqs[f][('a',1)]/iqs[f][('rx1',1)]
            else:
                s = iqs[f][('b',2)]/iqs[f][('rx2',2)]
            sparams.append(s)
    elif len(ports) == 2:
        for f in xrange(len(freqs)):
            s11 = []
            s12 = []
            s21 = []
            s22 = []
            if sw_correction:
                D = 1.0 - (iqs[f][('rx2',1)]/iqs[f][('rx1',1)])*(iqs[f][('rx1',2)]/iqs[f][('rx2',2)])
                sm11 = (1.0/D)*( iqs[f][('a',1)]/iqs[f][('rx1',1)] - (iqs[f][('a',2)]/iqs[f][('rx2',2)])*(iqs[f][('rx2',1)]/iqs[f][('rx1',1)]) )
                sm12 = (1.0/D)*( iqs[f][('a',2)]/iqs[f][('rx2',2)] - (iqs[f][('a',1)]/iqs[f][('rx1',1)])*(iqs[f][('rx1',2)]/iqs[f][('rx2',2)]) )
                sm21 = (1.0/D)*( iqs[f][('b',1)]/iqs[f][('rx1',1)] - (iqs[f][('b',2)]/iqs[f][('rx2',2)])*(iqs[f][('rx2',1)]/iqs[f][('rx1',1)]) )
                sm22 = (1.0/D)*( iqs[f][('b',2)]/iqs[f][('rx2',2)] - (iqs[f][('b',1)]/iqs[f][('rx1',1)])*(iqs[f][('rx1',2)]/iqs[f][('rx2',2)]) )
            else:
                sm11 =  iqs[f][('a',1)]/iqs[f][('rx1',1)]
                sm12 =  iqs[f][('a',2)]/iqs[f][('rx2',2)]
                sm21 =  iqs[f][('b',1)]/iqs[f][('rx1',1)]
                sm22 =  iqs[f][('b',2)]/iqs[f][('rx2',2)]
            s11.append(sm11)
            s12.append(sm12)
            s21.append(sm21)
            s22.append(sm22)
            sparams.append( [[np.mean(s11), np.mean(s12)], [np.mean(s21), np.mean(s22)]] )

    return skrf.Network(s=sparams, f=freqs, f_unit='Hz')


ref_freq = 40e6

vna = VNA()

ports = [1, 2]

freqs = np.linspace(30e6, 6e9, 200)

vna.set_tx_mux('iq', sample_input='adc')
vna.write_att(8.0)
vna.write_sample_time(int(40e6/200+100))
vna.write_io(pwdn=0, mixer_enable=0, led=1, adc_oe=0, adc_shdn=0)
vna.write_pll_io(lo_ce=1, source_ce=1, lo_rf=1, source_rf=1)
iqs = [{} for i in xrange(len(freqs))]

first = True
for port in ports:
    tag = 1
    for e,freq in enumerate(freqs):
        vna.write_switches(tx_filter=freq, port=port, rx_sw='rx1')
        source_freq = freq
        lo_freq = source_freq - 2e6
        lo_f = vna.lo.freq_to_regs(lo_freq, ref_freq, apwr=0)
        source_f = vna.source.freq_to_regs(source_freq, ref_freq, apwr=0)
        vna.write_pll(vna.source)
        vna.write_pll(vna.lo)
        if first:
            time.sleep(20e-3)
            vna.write_pll(vna.source)
            vna.write_pll(vna.lo)
            first = False
        vna.write_tag(tag)
        i = 0
        while True:
            iq, sw, t = vna.read_iq()
            #print t,tag
            if t != tag:
                continue
            i += 1
            #if sw == 'rx1' and 20*np.log10(np.abs(iq)) < -70:
            #    raise Exception()
            iqs[e].setdefault((sw,port), iq)

            print freq, sw, 20*np.log10(np.abs(iq))
            if i == 4:
                break
        tag = (tag + 1) % 256

#s = []
#for f in range(len(freqs)):
#    s.append( [[iqs['a'][f]/iqs['rx1'][f]]] )

plt.figure()
net = iq_to_sparam(iqs, freqs, ports, sw_correction=False)
#net = skrf.Network(f=freqs, f_unit='Hz', s=np.array(s))
net.plot_s_db()
#plt.figure()
#net.plot_s_deg()
net.write_touchstone('response.s{}p'.format(net.nports))

pickle.dump( (freqs, iqs), open( "iqs.p", "wb" ) )

#plt.figure()
#plt.title('S11')
#plt.plot(20*np.log10(np.abs(s)))
#plt.grid(True)
#plt.xlabel('Frequency [Hz]')
#plt.ylabel('S11 [dB]')

#plt.figure()
#for k in iqs.keys():
#    if len(iqs[k]) > 0:
#        print len(iqs[k])
#        plt.plot(freqs, 180/np.pi*(np.angle(iqs[k])), label=k)
#plt.figure()
#for k in iqs.keys():
#    print k, 20*np.log10(np.abs(iqs[k]))
#    if len(iqs[k]) > 0:
#        plt.plot(freqs, 20*np.log10(np.abs(iqs[k])), label=k)
#plt.legend(loc='best')
#plt.xlabel('Frequency [Hz]')
#plt.ylabel('Power [dBFs]')
#plt.ylim([-140, 0])
#plt.grid(True)
#plt.figure()
#plt.plot(180/np.pi*np.angle(iqs))
plt.show()

