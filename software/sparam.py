
from vna import VNA
import matplotlib.pyplot as plt
import numpy as np
import time
import skrf
import pickle

def iq_to_sparam(iqs, freqs, ports, sw_correction=True):
    sparams = []

    if len(ports) == 1:
        for f in range(len(freqs)):
            if ports[0] == 1:
                s = iqs[f][('a',1)]/iqs[f][('rx1',1)]
            else:
                s = iqs[f][('b',2)]/iqs[f][('rx2',2)]
            sparams.append(s)
    elif len(ports) == 2:
        for f in range(len(freqs)):
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

def sw_terms(iqs, freqs):
    """Switch terms from IQ"""
    sparams = []

    for f in range(len(freqs)):
        sw_f = iqs[f][('rx2',1)]/iqs[f][('b',1)]
        sw_r = iqs[f][('rx1',2)]/iqs[f][('a',2)]
        sparams.append( [[sw_f, 0], [0, sw_r]] )

    return skrf.Network(s=sparams, f=freqs, f_unit='Hz')


vna = VNA()

ports = [1, 2]
sw_correction = True

freqs = np.linspace(30e6, 8.5e9, 801)

vna.set_tx_mux('iq', sample_input='adc')
vna.write_att(7.0)
vna.write_sample_time(int(40e6/1000+100))
vna.write_io(pwdn=0, mixer_enable=0, led=1, adc_oe=0, adc_shdn=0)
vna.write_pll_io(lo_ce=1, source_ce=1, lo_rf=1, source_rf=1)
iqs = [{} for i in range(len(freqs))]

time.sleep(0.5)

first = True
for port in ports:
    tag = 1
    for e,freq in enumerate(freqs):
        if freq > 4.5e9:
            vna.write_att(0)
        vna.write_switches(tx_filter=freq, port=port, rx_sw='rx1')
        vna.program_sources(freq, 2e6)
        if first:
            time.sleep(20e-3)
            vna.write_pll(vna.lo)
            vna.write_pll(vna.source)
            first = False
            for i in range(4):
                iq, sw, t = vna.read_iq()
        time.sleep(1e-3)
        vna.write_tag(tag)
        i = 0
        while True:
            iq, sw, t = vna.read_iq()
            if t != tag:
                continue
            i += 1
            iqs[e].setdefault((sw,port), iq)

            print(freq, sw, 20*np.log10(np.abs(iq)))
            if i == 4:
                break
        tag = (tag + 1) % 256

plt.figure()
net = iq_to_sparam(iqs, freqs, ports, sw_correction=sw_correction)
net.plot_s_db()
net.write_touchstone('response.s{}p'.format(net.nports))

if not sw_correction and len(ports) == 2:
    sw = sw_terms(iqs, freqs)
    sw.write_touchstone('sw_terms.s2p')

pickle.dump( (freqs, iqs), open( "iqs.p", "wb" ) )
plt.ylim([-100, 0])
plt.show()
