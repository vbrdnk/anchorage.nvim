.PHONY: fmt lint test test-file clean pr-ready

PLENARY_PATH ?= $(HOME)/.local/share/nvim/lazy/plenary.nvim
NVIM         ?= nvim

fmt:
	echo "====> Formatting"
	stylua lua/ tests/ --config-path=stylua.toml

lint:
	echo "====> Linting"
	luacheck lua/ --config .luacheckrc --globals vim Snacks

test:
	echo "====> Testing"
	PLENARY_PATH=$(PLENARY_PATH) $(NVIM) --headless --noplugin \
	  -u tests/minimal_init.lua \
	  -c "PlenaryBustedDirectory tests/ { sequential = true, minimal_init = 'tests/minimal_init.lua' }"

test-file:
	PLENARY_PATH=$(PLENARY_PATH) $(NVIM) --headless --noplugin \
	  -u tests/minimal_init.lua \
	  -c "PlenaryBustedFile $(FILE)"

clean:
	echo "====> Cleaning"
	rm -f /tmp/anchorage_tests/*.json

pr-ready: fmt lint test
