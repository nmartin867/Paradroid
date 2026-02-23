APP_NAME    := ScrcpyConnect
APP_DIR     := $(APP_NAME).app
DMG_FILE    := $(APP_NAME).dmg
DMG_STAGE   := dmg-staging
BINARY      := .build/release/$(APP_NAME)
ICON_SRC    := AppIcon.png
ICON_ICNS   := Resources/AppIcon.icns
ICONSET_DIR := Resources/AppIcon.iconset

ICON_SIZES := 16 32 64 128 256 512 1024

.PHONY: all build app dmg icon clean run

all: app

# Build the Swift binary
build: $(BINARY)

$(BINARY): $(shell find Sources -name '*.swift') Package.swift
	swift build -c release

# Generate .icns from source PNG (only rebuilds when PNG changes)
icon: $(ICON_ICNS)

$(ICON_ICNS): $(ICON_SRC)
	@mkdir -p $(ICONSET_DIR)
	sips -z   16   16 $(ICON_SRC) --out $(ICONSET_DIR)/icon_16x16.png      > /dev/null 2>&1
	sips -z   32   32 $(ICON_SRC) --out $(ICONSET_DIR)/icon_16x16@2x.png   > /dev/null 2>&1
	sips -z   32   32 $(ICON_SRC) --out $(ICONSET_DIR)/icon_32x32.png      > /dev/null 2>&1
	sips -z   64   64 $(ICON_SRC) --out $(ICONSET_DIR)/icon_32x32@2x.png   > /dev/null 2>&1
	sips -z  128  128 $(ICON_SRC) --out $(ICONSET_DIR)/icon_128x128.png    > /dev/null 2>&1
	sips -z  256  256 $(ICON_SRC) --out $(ICONSET_DIR)/icon_128x128@2x.png > /dev/null 2>&1
	sips -z  256  256 $(ICON_SRC) --out $(ICONSET_DIR)/icon_256x256.png    > /dev/null 2>&1
	sips -z  512  512 $(ICON_SRC) --out $(ICONSET_DIR)/icon_256x256@2x.png > /dev/null 2>&1
	sips -z  512  512 $(ICON_SRC) --out $(ICONSET_DIR)/icon_512x512.png    > /dev/null 2>&1
	sips -z 1024 1024 $(ICON_SRC) --out $(ICONSET_DIR)/icon_512x512@2x.png > /dev/null 2>&1
	iconutil -c icns $(ICONSET_DIR) -o $(ICON_ICNS)
	@rm -rf $(ICONSET_DIR)
	@echo "Generated $(ICON_ICNS)"

# Package into .app bundle
app: $(BINARY) $(ICON_ICNS)
	@rm -rf $(APP_DIR)
	@mkdir -p $(APP_DIR)/Contents/MacOS
	@mkdir -p $(APP_DIR)/Contents/Resources
	cp $(BINARY) $(APP_DIR)/Contents/MacOS/
	cp Sources/Info.plist $(APP_DIR)/Contents/Info.plist
	cp $(ICON_ICNS) $(APP_DIR)/Contents/Resources/
	@echo "Built: $(APP_DIR)"

# Create DMG installer with drag-to-Applications
dmg: app
	@rm -rf $(DMG_STAGE) $(DMG_FILE)
	@mkdir -p $(DMG_STAGE)
	cp -R $(APP_DIR) $(DMG_STAGE)/
	ln -s /Applications $(DMG_STAGE)/Applications
	hdiutil create $(DMG_FILE) -volname "$(APP_NAME)" -srcfolder $(DMG_STAGE) -ov -format UDZO
	@rm -rf $(DMG_STAGE)
	@echo "Created: $(DMG_FILE)"

# Build and launch
run: app
	open $(APP_DIR)

clean:
	rm -rf .build $(APP_DIR) $(DMG_FILE) $(DMG_STAGE) $(ICONSET_DIR)
