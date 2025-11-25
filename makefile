all: runpandoc

runpandoc:
	pandoc markdown.md -o result_article.pdf \
	--pdf-engine=xelatex \
	-d default.yaml \
	--citeproc \
	-F pandoc-crossref \
	--variable mainfont="Times New Roman" \
	--variable geometry="margin=2cm"
