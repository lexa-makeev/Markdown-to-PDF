SOURCES = sections/01-intro.md \
          sections/02-architecture.md \
          sections/03-parallelism.md \
          sections/04-experiments.md \
          sections/05-related-work.md \
          sections/06-conclusion.md \
          templates/footer.md

all: runpandoc

runpandoc:
	pandoc $(SOURCES) -o result_article.pdf \
	--pdf-engine=xelatex \
    -d default.yaml \
    -F pandoc-crossref \
	--citeproc \
	--metadata-file pdf.yaml
	
