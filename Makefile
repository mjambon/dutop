VERSION = 1.0.0

dutop: dutop_version.ml dutop.ml
	ocamlopt -o dutop -annot unix.cmxa dutop_version.ml dutop.ml

dutop_version.ml: Makefile
	echo 'let version = "$(VERSION)"' > dutop_version.ml

ifndef PREFIX
PREFIX = $(HOME)
endif

ifndef BINDIR
BINDIR = $(PREFIX)/bin
endif

.PHONY: install uninstall
install:
	@if [ -f $(BINDIR)/dutop ]; \
	  then echo "Error: run '$(MAKE) uninstall' first."; \
	  else \
	    echo "Installing dutop into $(BINDIR)"; \
	    cp dutop $(BINDIR); \
	fi

uninstall:
	rm $(BINDIR)/dutop

.PHONY: clean
clean:
	rm -f *.cm[iox] *.o *.annot *~ dutop dutop_version.ml
