# 	Makefile for Miriad LaTex manuals - only for the experts
#	xx-feb-91   pjt		Created

F=ug
TEX = ug.tex latest.tex 
STY = miriad.sty lablst.sty showlabels.sty 
INC = cmdline.inc concepts.inc crib.inc disclaimer.inc glossary.inc \
       go.inc howto.inc iface.inc image.inc miriad.inc mirtool.inc \
       setup.inc uvvars.inc \
       calib.inc convert.inc flow.inc mapana.inc \
       mapmake.inc inspect.inc trouble.inc program.inc progs.inc
TMP = progi.tmp progt.tmp
EXT =
SUBMIT = $(INC) $(STY) $(TEX) $(EXT) Makefile
SFLAGS =
DIR = $(MIR)/manuals/uguide

help:
	@echo "Make miriad-style manuals using latex"
	@echo "====================================="
	@echo "Macro names:  "
	@echo "  F, TEX, STY, INC, EXT, SUBMIT, DIR"
	@echo "Targets: "
	@echo "  help		this help"
	@echo "  cleanall       clean all .dvi, .aux etc. tex related thingos"
	@echo "  clean [F=$(F)] like cleanall, but only for $(F).* files"
	@echo "  $(F)           make dvi file for manual F=$(F)"
	@echo "  submit         submit text to DIR=$(DIR)"
	@echo "  "
	@echo "The used INC= files in this dir are:"
	@echo "  $(INC)"
	@echo "The used TEX= files in this dir are:"
	@echo "  $(TEX)"
	@echo "The used STY= files in this dir are:"
	@echo "  $(STY)"
	@echo "The used EXT= files in this dir are:"
	@echo "  $(EXT)"
	@echo "The used TMP= files in this dir are:"
	@echo "  $(TMP)"



cleanall:
	@echo "Cleaning all (La)TeX related documents of all files.....";sleep 2
	rm -f *.log *.aux *.toc *.dvi *.lot *.lof *.ps *.ind *.idx *.tmp
	rm -rf tmp

clean:
	@echo "Cleaning all (La)TeX related documents for F=$(F)....";sleep 2
	rm -f $(F).log $(F).aux $(F).toc $(F).dvi $(F).lot $(F).lof \
            $(F).ps $(F).ind $(F).idx
	@echo "The .tmp files have not been deleted. Only in 'make cleanall'."

$(F): $(F).dvi

$(F).dvi: $(TEX) $(INC) $(STY) $(TMP)
	@echo "Running latex 3x - will take a while [did you run 'make .prog'?]"
	latex $(F) 
	latex $(F)
	makeindex < $(F).idx > $(F).ind
	latex $(F)
	latex $(F)

$(TMP) .prog:
	@echo "Recreating all doc files from prog, tools and spec:"
	@rm -rf tmp;mkdir tmp
	@(cd tmp;echo prog....;doc -p $(MIR)/src/prog/*/*)
	@(cd tmp;echo tools...;doc -p $(MIR)/src/tools/*)
	@(cd tmp;echo spec....;doc -p $(MIR)/src/spec/*/*)
	@echo functional list in progt.tmp;doc -tU tmp/*.doc > progt.tmp
	@echo alphabeta  list in progi.tmp;doc -iU tmp/*.doc > progi.tmp

tar:
	tar cvf $(F).tar $(SUBMIT)

submit:  .submit

.submit:    $(SUBMIT)
	mir.submit $(SFLAGS) $? $(DIR)
	@touch .submit
    
TEST = test.inc
test:
	echo $(TEST) | latex  latest
	makeindex <latest.idx > latest.ind
	echo $(TEST) | latex  latest
