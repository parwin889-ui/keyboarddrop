SRCS = main.swift EventTap.swift KeyMap.swift Config.swift KeyAction.swift SettingsWindow.swift L10n.swift Tutorial.swift
BIN = keyboarddrop
TARGET = arm64-apple-macos12.0
FRAMEWORKS = -framework Cocoa -framework CoreGraphics

$(BIN): $(SRCS)
	swiftc -target $(TARGET) -O -o $(BIN) $(SRCS) $(FRAMEWORKS)

run: $(BIN)
	./$(BIN)

clean:
	rm -f $(BIN)

.PHONY: run clean
