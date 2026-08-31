tStamp != date '+%m-%d_%H%M'
TS0 = mkdir -p $(dir $@); date >> $@; printf "$$(tail $@)\n" > $@; chgrp tmp $@
TS = -@$(TS0)

EMACS := emacs -Q --batch

ifndef asset
asset := TEST-0
$(info using default asset=$(asset))
endif

assets/done/$(asset): generated/iterate-tables.el $(wildcard assets/$(asset)/*.org)
	@mkdir -p $(dir $@)
	$(EMACS) -l shalaev.el -l generated/iterate-tables.el --eval '(iterate-tables-for "$(CURDIR)/assets" "$(asset)")'
	$(TS)

generated/%.el: %.org
	$(EMACS) --eval "(progn(mapc #'require '(org org-table)) (org-babel-tangle-file \"$<\"))"

clean:
	-rm -r assets/done/$(asset)
	find assets/$(asset) -mindepth 1 -maxdepth 1 -type f -name "*.org" -not -name 000.org -exec rm {} \;

.PHONY: clean assets/done/$(asset)

# $(EMACS) --eval "(require 'org)" --eval '(org-babel-tangle-file "$<")'
