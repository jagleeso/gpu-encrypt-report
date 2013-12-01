####################################################################################################
# Latex stuff.
####################################################################################################


# report: report.pdf
# .PHONY: report
# 
# LATEX_FLAGS = -interaction nonstopmode 
# 
# report.pdf: report.tex report/scalability_table.txt report/fragmentation_table.txt report/sequential_speed_table.txt
# 	rm -f report.aux report.bbl
# 	latex $(LATEX_FLAGS) report.tex
# 	bibtex report
# 	latex $(LATEX_FLAGS) report.tex
# 	latex $(LATEX_FLAGS) report.tex
# 	dvips -o report.ps report.dvi
# 	ps2pdf report.ps
# 
# report/scalability_table.txt: report/mk_table.py
# 	report/mk_table.py report scalability > $@
# 
# report/fragmentation_table.txt: report/mk_table.py
# 	report/mk_table.py report fragmentation > $@
# 
# report/sequential_speed_table.txt: report/mk_table.py
# 	report/mk_table.py report sequential_speed > $@

final_report: final_report.pdf
.PHONY: final_report

LATEX_FLAGS = -interaction nonstopmode

%.pdf: %.tex
	rm -f $*.aux $*.bbl
	latex $(LATEX_FLAGS) $*.tex
	bibtex $*
	latex $(LATEX_FLAGS) $*.tex
	latex $(LATEX_FLAGS) $*.tex
	dvips -o $*.ps $*.dvi
	ps2pdf $*.ps

# LATEX_FLAGS = -interaction nonstopmode --enable-write18

# final_report.pdf: final_report.tex
# 	rm -f final_report.aux final_report.bbl
# 	pdflatex $(LATEX_FLAGS) final_report.tex
# 	bibtex final_report
# 	pdflatex $(LATEX_FLAGS) final_report.tex
