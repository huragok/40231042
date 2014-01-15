# Generated by the VisualDSP++ IDDE

# Note:  Any changes made to this Makefile will be lost the next time the
# matching project file is loaded into the IDDE.  If you wish to preserve
# changes, rename this file and run it externally to the IDDE.

# The syntax of this Makefile is such that GNU Make v3.77 or higher is
# required.

# The current working directory should be the directory in which this
# Makefile resides.

# Supported targets:
#     DSPEth_Debug
#     DSPEth_Debug_clean

# Define this variable if you wish to run this Makefile on a host
# other than the host that created it and VisualDSP++ may be installed
# in a different directory.

ADI_DSP=D:\program_files\Analog Devices\VisualDSP 4.5


# $VDSP is a gmake-friendly version of ADI_DIR

empty:=
space:= $(empty) $(empty)
VDSP_INTERMEDIATE=$(subst \,/,$(ADI_DSP))
VDSP=$(subst $(space),\$(space),$(VDSP_INTERMEDIATE))

RM=cmd /C del /F /Q

#
# Begin "DSPEth_Debug" configuration
#

ifeq ($(MAKECMDGOALS),DSPEth_Debug)

DSPEth_Debug : ./Debug/DSPEth.dxe 

Debug/dm9000.doj :dm9000.c $(VDSP)/Blackfin/include/string.h $(VDSP)/Blackfin/include/yvals.h $(VDSP)/Blackfin/include/cdefBF561.h $(VDSP)/Blackfin/include/defBF561.h $(VDSP)/Blackfin/include/def_LPBlackfin.h $(VDSP)/Blackfin/include/cdef_LPBlackfin.h types.h bf5xx.h $(VDSP)/Blackfin/include/stdio.h $(VDSP)/Blackfin/include/sys/stdio_bf.h $(VDSP)/Blackfin/include/cdefBF53x.h $(VDSP)/Blackfin/include/sys/platform.h $(VDSP)/Blackfin/include/sys/_adi_platform.h $(VDSP)/Blackfin/include/sys/exception.h dm9000.h EthFunc.h header.h EthPacket.h $(VDSP)/Blackfin/include/stdlib.h $(VDSP)/Blackfin/include/stdlib_bf.h 
	@echo ".\dm9000.c"
	$(VDSP)/ccblkfn.exe -c .\dm9000.c -file-attr ProjectName=DSPEth -g -structs-do-not-overlap -no-multiline -double-size-32 -decls-strong -warn-protos -si-revision 0.3 -proc ADSP-BF561 -o .\Debug\dm9000.doj -MM

Debug/EthFunc.doj :EthFunc.c EthFunc.h header.h dm9000.h types.h EthPacket.h $(VDSP)/Blackfin/include/stdlib.h $(VDSP)/Blackfin/include/yvals.h $(VDSP)/Blackfin/include/stdlib_bf.h $(VDSP)/Blackfin/include/string.h bf5xx.h $(VDSP)/Blackfin/include/stdio.h $(VDSP)/Blackfin/include/sys/stdio_bf.h $(VDSP)/Blackfin/include/cdefBF53x.h $(VDSP)/Blackfin/include/sys/platform.h $(VDSP)/Blackfin/include/sys/_adi_platform.h $(VDSP)/Blackfin/include/cdefBF561.h $(VDSP)/Blackfin/include/defBF561.h $(VDSP)/Blackfin/include/def_LPBlackfin.h $(VDSP)/Blackfin/include/cdef_LPBlackfin.h $(VDSP)/Blackfin/include/sys/exception.h 
	@echo ".\EthFunc.c"
	$(VDSP)/ccblkfn.exe -c .\EthFunc.c -file-attr ProjectName=DSPEth -g -structs-do-not-overlap -no-multiline -double-size-32 -decls-strong -warn-protos -si-revision 0.3 -proc ADSP-BF561 -o .\Debug\EthFunc.doj -MM

Debug/set_PLL.doj :set_PLL.c system.h $(VDSP)/Blackfin/include/cdefBF561.h $(VDSP)/Blackfin/include/defBF561.h $(VDSP)/Blackfin/include/def_LPBlackfin.h $(VDSP)/Blackfin/include/cdef_LPBlackfin.h $(VDSP)/Blackfin/include/ccblkfn.h $(VDSP)/Blackfin/include/stdlib.h $(VDSP)/Blackfin/include/yvals.h $(VDSP)/Blackfin/include/stdlib_bf.h $(VDSP)/Blackfin/include/sys/platform.h $(VDSP)/Blackfin/include/sys/_adi_platform.h $(VDSP)/Blackfin/include/sys/exception.h 
	@echo ".\set_PLL.c"
	$(VDSP)/ccblkfn.exe -c .\set_PLL.c -file-attr ProjectName=DSPEth -g -structs-do-not-overlap -no-multiline -double-size-32 -decls-strong -warn-protos -si-revision 0.3 -proc ADSP-BF561 -o .\Debug\set_PLL.doj -MM

./Debug/DSPEth.dxe :$(VDSP)/Blackfin/ldf/ADSP-BF561.ldf $(VDSP)/Blackfin/lib/bf566_rev_0.0/crtsf561y.doj ./Debug/dm9000.doj ./Debug/EthFunc.doj ./Debug/set_PLL.doj $(VDSP)/Blackfin/lib/cplbtab561a.doj $(VDSP)/Blackfin/lib/bf566_rev_0.0/crtn561y.doj $(VDSP)/Blackfin/lib/bf566_rev_0.0/libsmall561y.dlb $(VDSP)/Blackfin/lib/bf566_rev_0.0/libio561y.dlb $(VDSP)/Blackfin/lib/bf566_rev_0.0/libc561y.dlb $(VDSP)/Blackfin/lib/bf566_rev_0.0/librt_fileio561y.dlb $(VDSP)/Blackfin/lib/bf566_rev_0.0/libevent561y.dlb $(VDSP)/Blackfin/lib/bf566_rev_0.0/libcpp561y.dlb $(VDSP)/Blackfin/lib/bf566_rev_0.0/libcpprt561y.dlb $(VDSP)/Blackfin/lib/bf566_rev_0.0/libx561y.dlb $(VDSP)/Blackfin/lib/bf566_rev_0.0/libf64ieee561y.dlb $(VDSP)/Blackfin/lib/bf566_rev_0.0/libdsp561y.dlb $(VDSP)/Blackfin/lib/bf566_rev_0.0/libsftflt561y.dlb $(VDSP)/Blackfin/lib/bf566_rev_0.0/libetsi561y.dlb $(VDSP)/Blackfin/lib/bf566_rev_0.0/libprofile561y.dlb $(VDSP)/Blackfin/lib/bf566_rev_0.0/Debug/libssl561y.dlb $(VDSP)/Blackfin/lib/bf566_rev_0.0/Debug/libdrv561y.dlb 
	@echo "Linking..."
	$(VDSP)/ccblkfn.exe .\Debug\dm9000.doj .\Debug\EthFunc.doj .\Debug\set_PLL.doj -L .\Debug -add-debug-libpaths -flags-link -od,.\Debug -o .\Debug\DSPEth.dxe -proc ADSP-BF561 -si-revision 0.3 -MM

endif

ifeq ($(MAKECMDGOALS),DSPEth_Debug_clean)

DSPEth_Debug_clean:
	-$(RM) "Debug\dm9000.doj"
	-$(RM) "Debug\EthFunc.doj"
	-$(RM) "Debug\set_PLL.doj"
	-$(RM) ".\Debug\DSPEth.dxe"
	-$(RM) ".\Debug\*.ipa"
	-$(RM) ".\Debug\*.opa"
	-$(RM) ".\Debug\*.ti"
	-$(RM) ".\*.rbld"

endif


