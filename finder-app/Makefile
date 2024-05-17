ifdef CROSS_COMPILE
	CC="$(CROSS_COMPILE)gcc"
endif

.PHONY: clean default

default: writer
	@echo "Building default target ..."

writer: writer.c
	$(CC) $< -o $@

clean:
	@echo "Cleaning build ..."
	$(RM) writer
