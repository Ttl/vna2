# -*- coding: utf-8 -*-
from __future__ import division
from vna import VNA
import matplotlib.pyplot as plt
import numpy as np
from pyqtgraph.Qt import QtGui, QtCore
import pyqtgraph as pg

plot_points = 1000

def init_vna():
    ref_freq = 40e6

    vna = VNA()

    source_freq = 6.0e9
    lo_freq = source_freq - 2e6

    vna.set_tx_mux('iq', sample_input='adc')

    vna.lo.freq_to_regs(lo_freq, ref_freq, apwr=0)
    vna.source.freq_to_regs(source_freq, ref_freq, apwr=0)

    #vna.dither_en(1)
    #vna.set_tx_mux('samples', sample_input='adc')

    vna.write_sample_time(int(40e6/1000+100))
    #vna.write_sample_time(110000)
    vna.write_io(pwdn=0, mixer_enable=0, led=1, adc_oe=0, adc_shdn=0)
    vna.write_pll_io(lo_ce=1, source_ce=1, lo_rf=1, source_rf=1)
    vna.write_att(0.0)
    vna.write_switches(tx_filter=source_freq, port=2, rx_sw='rx2', rx_sw_force=False)
    vna.write_pll(vna.source)
    vna.write_pll(vna.lo)
    vna.write_pll(vna.source)
    vna.write_pll(vna.lo)

    vna.read_iq()
    vna.read_iq()
    return vna

vna = init_vna()
iqs = {'rx1':[], 'rx2':[], 'a':[], 'b':[], 'none':[], 'unknown':[]}

app = QtGui.QApplication([])

win = pg.GraphicsWindow(title="RX channels")
#win.resize(1000,600)
win.setWindowTitle('RX channels')

# Enable antialiasing for prettier plots
pg.setConfigOptions(antialias=True)

plot = win.addPlot(title="RX channels", labels={'left':'Channel reading [dBFs]', 'bottom':'Samples'})
curve1 = plot.plot(pen='y', name='RX1')
curve2 = plot.plot(pen='g', name='A')
curve3 = plot.plot(pen='r', name='B')
curve4 = plot.plot(pen='b', name='RX2')
plot.addLegend()
plot.legend.addItem(curve1, "RX1")
plot.legend.addItem(curve2, "A")
plot.legend.addItem(curve3, "B")
plot.legend.addItem(curve4, "RX2")
plot.enableAutoRange('xy', False)
plot.setXRange(0, plot_points, padding=0)
plot.setYRange(-100, 0, padding=0)

def update():
    global iqs, vna, curve1, curve2, plot
    for i in xrange(4):
        iq,sw,tag = vna.read_iq()
        iqs[sw].append(20*np.log10(np.abs(iq)))
    rx1 = iqs['rx1'][-plot_points:]
    rx1 = [-100]*(plot_points-len(rx1)) + rx1
    a = iqs['a'][-plot_points:]
    a = [-100]*(plot_points-len(a)) + a
    b = iqs['b'][-plot_points:]
    b = [-100]*(plot_points-len(b)) + b
    rx2 = iqs['rx2'][-plot_points:]
    rx2 = [-100]*(plot_points-len(rx2)) + rx2
    curve1.setData(rx1)
    curve2.setData(a)
    curve3.setData(b)
    curve4.setData(rx2)
timer = QtCore.QTimer()
timer.timeout.connect(update)
timer.start(10)

## Start Qt event loop unless running in interactive mode or using pyside.
if __name__ == '__main__':
    import sys
    if (sys.flags.interactive != 1) or not hasattr(QtCore, 'PYQT_VERSION'):
        QtGui.QApplication.instance().exec_()

