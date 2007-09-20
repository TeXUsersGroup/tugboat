opt = -interaction=nonstopmode
latex = latex $(opt)
pdflatex = latex $(opt)

tugboat.pdf: ltugcomn.sty tugboat.dtx
	$(pdflatex) tugboat.dtx
	$(pdflatex) tugboat.dtx

ltugcomn.sty ltugboat.sty: tugboat.dtx
	$(latex) tugboat.ins

