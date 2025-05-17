# Makefile for ShotwellSquareTagger

# Compiler and flags
VALAC = valac
VALAFLAGS = --pkg sqlite3 --pkg gio-2.0

# Target executable name
TARGET = shotwell-square-tagger

# Source files
SOURCES = shotwell-square-tagger.vala

# Build targets
all: $(TARGET)

$(TARGET): $(SOURCES)
	$(VALAC) $(VALAFLAGS) -o $@ $^

# Install target (optional)
install: $(TARGET)
	mkdir -p $(DESTDIR)/usr/local/bin
	install -m 755 $(TARGET) $(DESTDIR)/usr/local/bin/

# Clean target
clean:
	rm -f $(TARGET)
	rm -f *.c

# Run the program
run: $(TARGET)
	./$(TARGET)

.PHONY: all install clean run