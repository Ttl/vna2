
import pylibftdi as ftdi
from max2871 import MAX2871
import time
import matplotlib.pyplot as plt
import numpy as np

ref_freq = 40e6

class VNA():
    def __init__(self):
        self.device = ftdi.Device(mode='t', interface_select=ftdi.INTERFACE_B)
        self.device.open()
        self.lo = MAX2871()
        self.source = MAX2871()
        self.current_switches = None
        self.current_att = None

        self.source_harmonic = 5
        self.lo_harmonic = 3
        self.max_nonharmonic_freq = 6.3e9

    def array_to_int(self, a, reverse=False):
        if reverse:
            a = a[::-1]
        l = len(a)
        x = 0
        for i in range(0,l):
            x = (x<<8) + a[i]
        return x


    def read_samples(self):

        def twos_comp(val, bits):
            """compute the 2's compliment of int value val"""
            if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
                val = val - (1 << bits)        # compute negative value
            return val                         # return positive value as is

        bytes_in = []
        while True:
            r = self.device.read(1)
            if len(r) == 0:
                continue
            if ord(r) != 0xaa:
                continue
            r = self.device.read(1)
            #Size, don't care
            if self.device.read(1) != '\x02':
                continue
            if self.device.read(1) != '\x00':
                continue
            break
        for i in range(10001-1):
            s = self.device.read(1)
            if len(s) == 1:
                bytes_in.append(ord(s))

        print((bytes_in[:10]))
        samples = []
        for i in range(len(bytes_in)//2):
            samples.append(twos_comp((bytes_in[2*i]<<8)+bytes_in[2*i+1], 16))
        with open('samples.txt', 'w') as f:
            f.write('\n'.join(map(str,samples))+'\n')
        return samples

    def read_iq(self):

        def twos_comp(val, bits):
            """compute the 2's compliment of int value val"""
            if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
                val = val - (1 << bits)        # compute negative value
            return val                         # return positive value as is

        def sw(sw):
            if sw == 1:
                return 'rx1'
            if sw == 2:
                return 'a'
            if sw == 3:
                return 'rx2'
            if sw == 4:
                return 'b'
            if sw == 0:
                return 'none'
            return 'unknown'

        while True:
            r = self.device.read(1)
            if len(r) == 0:
                continue
            if ord(r) != 0xaa:
                continue
            r = self.device.read(1)
            if ord(r) != 0x19:
                continue
            r = self.device.read(1)
            if ord(r) != 0x01:
                continue
            break
        iq = list(map(ord, self.device.read(23)))

        i = iq[0:7]
        q = iq[7:14]
        cycles = iq[14:21]
        rx_sw = sw(iq[21])
        tag = iq[22]
        #print i,q,cycles
        i = twos_comp(self.array_to_int(i, reverse=True), 8*7)
        q = twos_comp(self.array_to_int(q, reverse=True), 8*7)
        cycles = self.array_to_int(cycles, reverse=True)
        gain = 1.0/((2**21))
        i *= gain/cycles
        q *= gain/cycles
        #print i, q, cycles
        return i+1j*q, rx_sw, tag

    def write_att(self, att):
        if self.current_att == att:
            return 0
        def reverse_bits(x, n=8):
            result = 0
            for i in range(n):
                if (x >> i) & 1:
                    result |= 1 << (n - 1 - i)
            return result

        if att > 31.75:
            raise ValueError("Too high attenuation. Max 31.75 dB, got {}".format(att))
        #Bits must be shifted LSB first, but FPGA shifts MSB first
        w = reverse_bits(int(round(att/0.25)))
        assert 0 <= w <= 255
        assert w & 0x01 == 0x00
        self.current_att = att
        return self.to_device(6, [w])

    def write_switches(self, tx_filter, port, rx_sw, rx_sw_force=False):
        if port == 1:
            port_sw = 1
        elif port == 2:
            port_sw = 2
        elif port == 0:
            port_sw = 0
        else:
            raise ValueError("Invalid port {}. Valid values are 0-2.".format(port))

        try:
            rx_sw = rx_sw.lower()
        except AttributeError:
            rx_sw = str(rx_sw)

        if rx_sw == 'rx1':
            rx_sw = (1 << 5) | (1 << 1)
        elif rx_sw == 'a':
            rx_sw = (1 << 5) | (1 << 0)
        elif rx_sw == 'b':
            rx_sw = (1 << 4) | (1 << 3)
        elif rx_sw == 'rx2':
            rx_sw = (1 << 4) | (1 << 2)
        elif rx_sw == 'none':
            rx_sw = 0
        else:
            raise ValueError("Invalid RX port: {}. Valid values are: none, A, B, RX1, RX2".format(rx_sw))

        #0 1.1 - 2.1
        #1 2.1 - 4.2
        #2 4.2 - 6.0
        #3 0.1 - 1.1
        if tx_filter < 1.1e9:
            b1 = (1 << 3)
        elif tx_filter < 2.1e9:
            b1 = (1 << 0)
        elif tx_filter < 4.2e9:
            b1 = (1 << 1)
        else:
            b1 = (1 << 2)
        b1 |= (port_sw & 0x3) << 4
        b2 = rx_sw & 0x3f
        if rx_sw_force:
            b2 |= (1 << 6)
        if [b1,b2] != self.current_switches:
            self.current_switches = [b1,b2]
            return self.to_device(1, [b1,b2])
        return 0

    def write_io(self, pwdn, mixer_enable, led, adc_oe, adc_shdn):
        #pwdn: Amplifier enabled when low
        b1 = ((adc_shdn & 1) << 4) | ((adc_oe & 1) << 3) | ((led & 1) << 2) | ((mixer_enable & 1) << 1) | ((pwdn &1) << 0)
        return self.to_device(2, [b1])

    def write_tag(self, tag):
        return self.to_device(11, [tag])

    def write_pll(self, pll):
        for i in range(5,-1, -1):
            reg = pll.registers[i] | i
            if i != 0 and pll.written_regs[i] == reg:
                continue
            self.write_pll_reg(pll, reg)
            pll.written_regs[i] = reg

    def write_sample_time(self, samples):
        b1 = (samples & 0x000000ff) >> 0
        b2 = (samples & 0x0000ff00) >> 8
        b3 = (samples & 0x00ff0000) >> 16
        b4 = (samples & 0xff000000) >> 24
        return self.to_device(5, [b4,b3,b2,b1])

    def write_echo(self, word):
        return self.to_device(10, [word & 0xff])

    def read_echo(self):
        for i in range(1000):
            r = self.device.read(1)
            if len(r) != 0:
                return r
        return r

    def set_tx_mux(self, mux, sample_input='adc'):
        try:
            mux = mux.lower()
            sample_input = sample_input.lower()
        except AttributeError:
            pass

        self.tx_mux = mux
        if sample_input == 'adc':
            sin = 0
        elif sample_input == 'if':
            sin = 1
        elif sample_input == 'acc':
            sin = 2
        elif sample_input == 'cic':
            sin = 3
        else:
            raise Exception("Invalid sample_input {}. Valid states are 'adc', 'cic', 'acc' and 'if'".format(sample_input))

        if mux == 'iq':
            m = 0
        elif mux == 'samples':
            m = 1
        elif mux == 'io':
            m = 2
        else:
            raise Exception("Invalid mux state {}. Valid states are 'iq' or 'samples'".format(mux))

        return self.to_device(8, [(sin << 2) | m])

    def write_pll_reg(self, pll, reg):
        if pll == self.lo:
            cmd = 3
        elif pll == self.source:
            cmd = 4
        else:
            raise ValueError('Unknown PLL')
        b1 = (reg & 0x000000ff) >> 0
        b2 = (reg & 0x0000ff00) >> 8
        b3 = (reg & 0x00ff0000) >> 16
        b4 = (reg & 0xff000000) >> 24
        return self.to_device(cmd, [b4,b3,b2,b1])

    def write_pll_io(self, lo_ce, source_ce, lo_rf, source_rf):
        b1 = ((lo_rf&1) << 3) | ((source_rf&1) << 2) | ((source_ce&1) << 1) | ((lo_ce&1) << 0)
        return self.to_device(7, [b1])

    def dither_en(self, enable):
        b1 = 0 if enable else 1
        return self.to_device(9, [b1])

    def to_device(self, cmd, packet):
        p = ''.join(map(chr, packet))
        l = chr(len(packet))
        w = '\xaa'+l+chr(cmd)+p
        #print 'Wrote', map(ord,w)
        wrote = self.device.write(w)
        if wrote != len(w):
            raise Exception()
        #time.sleep(1e-3)
        return wrote

    def program_sources(self, source_freq, if_freq=2e6):
        source_harm = 1
        lo_harm = 1
        if source_freq > self.max_nonharmonic_freq:
            source_harm = self.source_harmonic
            lo_harm = self.lo_harmonic
        source_freq /= source_harm
        lo_freq = (source_freq * source_harm + if_freq) / lo_harm
        lo_apwr = 1
        source_apwr = 0 if source_harm == 1 else 2
        lo_f = self.lo.freq_to_regs(lo_freq, ref_freq, apwr=lo_apwr)
        self.write_pll(self.lo)
        source_f = self.source.freq_to_regs(source_freq, ref_freq, apwr=source_apwr)
        self.write_pll(self.source)
        return lo_f, source_f
