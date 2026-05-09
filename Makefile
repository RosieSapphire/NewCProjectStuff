BUILD_DIR := build

# Configuration
DEBUG_MODE  ?= 1
VERBOSE     ?=
WANT_COLORS ?= 1

# General
NAME        := color_converter
ELF_FILE    := $(BUILD_DIR)/$(NAME).elf
SRC_DIRS    := .
SRC_FILES   := $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.c))
SRC_FILES   := $(abspath $(SRC_FILES)) # Get absolute paths
SRC_FILES   := $(SRC_FILES:$(CURDIR)/%=%) # Normalize the paths
OBJ_FILES   := $(SRC_FILES:%.c=$(BUILD_DIR)/%.o)
SUCCESS_MSG := Built [$(ELF_FILE)] successfully!

# Compiler
CC          := clang-20
WARN_IGNORE := -Wno-variadic-macros \
	       -Wno-reserved-macro-identifier \
	       -Wno-reserved-identifier \
	       -Wno-format-nonliteral \
	       -Wno-unsafe-buffer-usage \
	       -Wno-disabled-macro-expansion # Due to an LLVM error... fuck
CFLAGS      := -Wall \
	       -Wextra \
	       -Weverything \
	       -Werror \
	       -pedantic \
	       -ansi \
	       $(WARN_IGNORE)

# Set default terminal color values as unset
COL_RED :=
COL_GRN :=
COL_YEL :=
COL_BLU :=
COL_PUR :=
COL_GRY :=
COL_END :=

# If we want colors, `NO_COLOR` isn't defined, terminal's not retarded,
# we have `tput`, said `tput` allows for colors, then we set them up!
ifneq ($(and                                                        \
       $(if $(WANT_COLORS),1,),                                     \
       $(if $(NO_COLOR),,1),                                        \
       $(filter-out dumb,$(TERM)),                                  \
       $(shell command -v tput 2>/dev/null),                        \
       $(filter-out 0,$(shell tput colors 2>/dev/null))),)
	COL_RED := $(shell tput setaf 1)
	COL_GRN := $(shell tput setaf 2)
	COL_YEL := $(shell tput setaf 3)
	COL_BLU := $(shell tput setaf 4)
	COL_PUR := $(shell tput setaf 5)
	COL_GRY := $(shell tput setaf 6)
	COL_END := $(shell tput sgr0)
endif

# Debug mode changes
ifdef DEBUG_MODE
	CFLAGS      += -O0 -ggdb3 -fsanitize=address,leak,null -D_DEBUG
	SUCCESS_MSG +=  $(COL_RED)(DEBUG ENABLED)$(COL_END)
else
	CFLAGS += -O3 -ffast-math -g0 -DNDEBUG
endif

# Verbosity
V := @
ifdef VERBOSE
	V :=
endif

.PHONY: all clean

# Build commands
all: $(ELF_FILE)

$(ELF_FILE): $(OBJ_FILES)
	@mkdir -p $(dir $@)
	@echo "    $(COL_PUR)[LD] $@ <- $<$(COL_END)"
	$(V)$(CC) $(CFLAGS) -o $@ $^
	@echo "$(COL_GRN)$(SUCCESS_MSG)$(COL_END)"

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	@echo "    $(COL_BLU)[CC] $@ <- $<$(COL_END)"
	$(V)$(CC) $(CFLAGS) -o $@ -c $<

# Cleanup
clean:
	@echo "Cleaning previous build..."
	$(V)rm -rf $(BUILD_DIR) $(ELF_FILE) compile_commands.json .cache/
