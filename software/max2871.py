from __future__ import division
from fractions import Fraction

class MAX2871():
    def __init__(self):
        #Register definitions:
        # (Register: name: (First bit, Length, [value]))
        self.register_def = {
                0:{'int':(31, 1), 'n':(15, 16), 'frac':(3, 12)},
                1:{'reserved0':(31, 1), 'cpl':(29, 2), 'cpt': (27, 2), 'p':(15,12), 'm':(3,12)},
                2:{'lds':(31,1), 'sdn':(29,2), 'mux':(26,3), 'dbr':(25,1), 'rdiv2':(24,1), 'r':(14,10),
                    'reg4db':(13,1), 'cp':(9,4), 'ldf':(8,1), 'ldp':(7,1), 'pdp':(6,1), 'shdn':(5,1),
                    'tri':(4,1), 'rst':(3,1)},
                3:{'vco':(26,6), 'vas_shdn':(25,1), 'vas_temp':(24,1), 'reserved1':(19,5), 'csm':(18,1),
                    'mutedel':(17,1), 'cdm':(15,2), 'cdiv':(3,12)},
                4:{'reserved2':(29,3), 'sdldo':(28,1), 'sddiv':(27,1), 'sdref':(26,1), 'bs_msb':(24,2),
                    'fb':(23,1), 'diva':(20,3), 'bs_lsb':(12,8), 'sdvco':(11,1), 'mtld':(10,1),
                    'bdiv':(9,1), 'rfb_en':(8,1), 'bpwr':(6,2), 'rfa_en':(5,1), 'apwr':(3,2)},
                5:{'reserved3':(31,1), 'vas_dly':(29,2), 'reserved4':(26,3), 'sdlo_pll':(25,1),
                    'f01':(24,1), 'ld':(22,2), 'reserved5':(19,3), 'mux3':(18,1), 'reserved6':(7,11),
                    'adcs':(6,1), 'adcm':(3,3)},
                6:{'die_id':(28,4), 'reserved7':(24,4), 'por':(23,1), 'adc':(16,7), 'adcv':(15,1),
                    'reserved8':(10,5), 'vasa':(9,1), 'v':(3,6)}
        }
        self.registers = [0]*8
        self.modified = [False]*8

        #Check unique names
        keys = []
        for key in self.register_def.itervalues():
            for r in key:
                if r in keys:
                    raise Exception("Duplicate register {}".format(r))
                keys.append(r)

    def freq_to_regs(self, fout, fpd, m=4095, fb=1, apwr=0, rfa_en=1):
        """Output register values for fout output frequency given
        the phase comparator frequency fpd.
        fb = Counter feedback position. 0 = Divider, 1 = VCO.
        M = Fractional modulus. f = (N + F/M)*fpd """
        #Reg4:reserved2 must be 3
        self.write_value(reserved2=3)
        self.write_value(pdp=1) #Positive phase-detector polarity
        self.write_value(cpl=2) #Charge pump linearity 20%
        self.write_value(cp=12) #Charge pump current. Icp = (1.63/Rset)*(1+cp)
        self.write_value(ld=1) #Digital lock detect pin function
        self.write_value(ldf=0) #Fractional-N lock detect
        self.write_value(r=1) #Reference divide by 1
        self.write_value(p=1) #Phase, recommended 1
        self.write_value(sdn=2) #Low-spur mode 1
        self.write_value(apwr=apwr)
        self.write_value(rfa_en=rfa_en)

        #self.write_value(dbr=1) #R doubler

        if fpd < 32e6:
            self.write_value(lds=0)
        else:
            self.write_value(lds=1)

        self.write_value(mux3=0)
        self.write_value(mux=0) # Tri-state

        if 3e9 <= fout:
            self.write_value(diva=0)
            div = 1
        elif 1.5e9 <= fout:
            self.write_value(diva=1)
            div = 2
        elif 750e6 <= fout:
            self.write_value(diva=2)
            div = 4
        elif 375e6 <= fout:
            self.write_value(diva=3)
            div = 8
        elif 187.5e6 <= fout:
            self.write_value(diva=4)
            div = 16
        elif 93.75e6 <= fout:
            self.write_value(diva=5)
            div = 32
        elif 46.875e6 <= fout:
            self.write_value(diva=6)
            div = 64
        else:
            self.write_value(diva=7)
            div = 128

        fvco = fout*div
        for i in xrange(2):
            d = 1 if fb else min(div, 16)
            n = int((fvco/fpd)/d)
            if 19 <= n <= 4091:
                break
            else:
                fb = int(not fb)

        self.write_value(fb=fb)
        self.write_value(n=n)

        self.write_value(cdiv=int(round(fpd/100e3)))

        bs = int(round(fpd/50e3))
        if bs > 1023:
            bs = 1023
        self.write_value(bs_msb=bs >> 8)
        self.write_value(bs_lsb=bs & 0xFF)

        if 1:
            #Choose best f/m to minimize frequency error
            x = Fraction((fvco-d*fpd*n)/(d*fpd)).limit_denominator(4095)
            f = x.numerator
            m = x.denominator
            if f == 1 and m == 1:
                f = 4094
                m = 4095
        else:
            #Fixed modulus
            f = int(round(m*(fvco-d*fpd*n)/(d*fpd)))

        if m < 2 or m > 4095:
            if f == 0:
                #Integer mode
                #TODO: Set integer mode
                m = 2
            else:
                raise ValueError("Invalid M value {}. 2 <= M <= 4095. f = {}".format(m, f))
        self.write_value(m=m)
        self.write_value(frac=f)

        #print ((n+f/m)*fpd*d)/div,
        #print 'f {} m {} n {} d {} div {} fb {}'.format(f,m,n,d,div,fb)
        #print 'fvco {} fout {}'.format(fvco, fvco/div)
        assert 3e9 <= fvco <= 6.25e9
        assert f < m
        assert 19 <= n <= 4091
        #fvco = d*fpd*(n+f/m)


        #VCO number, fmin, fmax
        #https://github.com/EttusResearch/uhd/blob/master/host/lib/usrp/common/max287x.hpp
        vcos = [
            (0,2767776024.0,2838472816.0),
            (1,2838472816.0,2879070053.0),
            (1,2879070053.0,2921202504.0),
            (3,2921202504.0,2960407579.0),
            (4,2960407579.0,3001687422.0),
            (5,3001687422.0,3048662562.0),
            (6,3048662562.0,3097511550.0),
            (7,3097511550.0,3145085864.0),
            (8,3145085864.0,3201050835.0),
            (9,3201050835.0,3259581909.0),
            (10,3259581909.0,3321408729.0),
            (11,3321408729.0,3375217285.0),
            (12,3375217285.0,3432807972.0),
            (13,3432807972.0,3503759088.0),
            (14,3503759088.0,3579011283.0),
            (15,3579011283.0,3683570865.0),
            (20,3683570865.0,3711845712.0),
            (21,3711845712.0,3762188221.0),
            (22,3762188221.0,3814209551.0),
            (23,3814209551.0,3865820020.0),
            (24,3865820020.0,3922520021.0),
            (25,3922520021.0,3981682709.0),
            (26,3981682709.0,4043154280.0),
            (27,4043154280.0,4100400020.0),
            (28,4100400020.0,4159647583.0),
            (29,4159647583.0,4228164842.0),
            (30,4228164842.0,4299359879.0),
            (31,4299359879.0,4395947962.0),
            (33,4395947962.0,4426512061.0),
            (34,4426512061.0,4480333656.0),
            (35,4480333656.0,4526297331.0),
            (36,4526297331.0,4574689510.0),
            (37,4574689510.0,4633102021.0),
            (38,4633102021.0,4693755616.0),
            (39,4693755616.0,4745624435.0),
            (40,4745624435.0,4803922123.0),
            (41,4803922123.0,4871523881.0),
            (42,4871523881.0,4942111286.0),
            (43,4942111286.0,5000192446.0),
            (44,5000192446.0,5059567510.0),
            (45,5059567510.0,5136258187.0),
            (46,5136258187.0,5215827295.0),
            (47,5215827295.0,5341282949.0),
            (49,5341282949.0,5379819310.0),
            (50,5379819310.0,5440868434.0),
            (51,5440868434.0,5500079705.0),
            (52,5500079705.0,5555329630.0),
            (53,5555329630.0,5615049833.0),
            (54,5615049833.0,5676098527.0),
            (55,5676098527.0,5744191577.0),
            (56,5744191577.0,5810869917.0),
            (57,5810869917.0,5879176194.0),
            (58,5879176194.0,5952430629.0),
            (59,5952430629.0,6016743964.0),
            (60,6016743964.0,6090658690.0),
            (61,6090658690.0,6128133570.0),
            (63,6128133570.0,6200000001.0),

        ]

        for vco in xrange(len(vcos)):
            if vcos[vco][1] < fvco <= vcos[vco][2]:
                #print vcos[vco][0], fvco
                self.write_value(vco=vcos[vco][0])
                break
        else:
            raise Exception('No suitable VCO found. fvco = {}'.format(fvco))

        self.write_value(vas_shdn=1)

        return ((n+f/m)*fpd*d)/div

    def find_reg(self, reg):
        """Finds register by name"""
        for key, val in self.register_def.iteritems():
            if reg in val.keys():
                return key, val[reg]
        return None, None

    def write_value(self, **kw):
        """Write value to register, doesn't update the device"""
        for reg, val in kw.iteritems():
            #print "{} = {}".format(reg, val)
            reg_n, reg_def = self.find_reg(reg)
            if reg_n == None:
                raise ValueError("Register {} not found".format(reg))
            reg_start = reg_def[0]
            reg_len = reg_def[1]
            if val > 2**reg_len or val < 0:
                raise ValueError("Invalid value, got: {}, maximum {}".format(val, reg_len))
            #Clear previous value
            self.registers[reg_n] &= (~((((2**reg_len-1))&0xFFFFFFFF) << reg_start) & 0xFFFFFFFF)
            self.registers[reg_n] |= (val) << reg_start
            self.modified[reg_n] = True
        return
