# 肚子扫描仪开发命令入口。
#
# 常用：
#   make run        构建 debug APK，安装并启动到 USB 真机
#   make check      format + analyze + test
# 设备选择：默认取第一台 USB 真机；多设备时用 DEVICE=<serial> 指定，
# 例如 `make run DEVICE=emulator-5554`。
#
# 注意：小米等设备需要在「开发者选项」开启「USB 安装」，
# 否则 adb install 会报 INSTALL_FAILED_USER_RESTRICTED。

ADB ?= adb
APP_ID := com.example.child_doctor_app
MAIN_ACTIVITY := $(APP_ID)/.MainActivity
DEBUG_APK := build/app/outputs/flutter-apk/app-debug.apk

# 第一台 USB 真机：adb devices -l 中带 usb: 传输标记的 device 行。
# 无线调试（tcpip）和模拟器没有 usb: 标记，不会被选中。
DEVICE := $(shell $(ADB) devices -l 2>/dev/null | awk '/usb:/ && / device / {print $$1; exit}')

.PHONY: help devices run run-attach install uninstall \
        pubget format analyze test test-device build-debug build-release check clean

help:
	@echo "目标："
	@echo "  make run            构建 debug APK，安装并启动到 USB 真机"
	@echo "  make run-attach     以 flutter run 附加到真机（带热重载）"
	@echo "  make install        把已构建的 debug APK 安装到真机"
	@echo "  make uninstall      从真机卸载 App"
	@echo "  make devices        列出 adb 设备"
	@echo "  make pubget         安装依赖"
	@echo "  make format         dart format 检查"
	@echo "  make analyze        flutter analyze"
	@echo "  make test           单元 + Widget + Golden 测试"
	@echo "  make test-device    真机集成测试（integration_test）"
	@echo "  make build-debug    构建 debug APK"
	@echo "  make build-release  构建内部测试 release APK"
	@echo "  make check          format + analyze + test 全量检查"
	@echo "可用 DEVICE=<serial> 覆盖设备选择。"

devices:
	$(ADB) devices -l

run: build-debug
	@test -n "$(DEVICE)" || { echo "未找到 USB 真机；先 make devices 查看，或用 DEVICE=<serial> make run 指定"; exit 1; }
	$(ADB) -s $(DEVICE) install -r $(DEBUG_APK)
	$(ADB) -s $(DEVICE) shell am start -S -n $(MAIN_ACTIVITY)

run-attach:
	@test -n "$(DEVICE)" || { echo "未找到 USB 真机；先 make devices 查看，或用 DEVICE=<serial> make run-attach 指定"; exit 1; }
	flutter run -d $(DEVICE)

install:
	@test -n "$(DEVICE)" || { echo "未找到 USB 真机；先 make devices 查看，或用 DEVICE=<serial> make install 指定"; exit 1; }
	$(ADB) -s $(DEVICE) install -r $(DEBUG_APK)

uninstall:
	@test -n "$(DEVICE)" || { echo "未找到 USB 真机；先 make devices 查看，或用 DEVICE=<serial> make uninstall 指定"; exit 1; }
	$(ADB) -s $(DEVICE) uninstall $(APP_ID)

pubget:
	flutter pub get

format:
	dart format --set-exit-if-changed lib test integration_test

analyze:
	flutter analyze

test:
	flutter test

test-device:
	@test -n "$(DEVICE)" || { echo "未找到 USB 真机；先 make devices 查看，或用 DEVICE=<serial> make test-device 指定"; exit 1; }
	flutter test integration_test -d $(DEVICE)

build-debug:
	flutter build apk --debug

build-release:
	flutter build apk --release

check: format analyze test

clean:
	flutter clean
