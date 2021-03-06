#define LEN_LPF_MCVSD1 30
#define LEN_LPF_MCVSD2 4
#define LEN_LPF_CVSD 18

static fract16 lpf_mcvsd1[LEN_LPF_MCVSD1] = {
164,
186,
251,
356,
496,
665,
854,
1055,
1258,
1455,
1635,
1790,
1913,
1999,
2042,
2042,
1999,
1913,
1790,
1635,
1455,
1258,
1055,
854,
665,
496,
356,
251,
186,
164
};

static fract16 lpf_mcvsd2[LEN_LPF_MCVSD2] = {
1311,
12616,
12616,
1311,
};

static fract16 lpf_cvsd[LEN_LPF_CVSD] = {
164,
227,
410,
686,
1019,
1364,
1674,
1907,
2032,
2032,
1907,
1674,
1364,
1019,
686,
410,
227,
164
};
