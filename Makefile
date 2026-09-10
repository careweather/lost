# Copyright (c) 2020 Mark Polyakov, Karen Haining, Edward Zhang
# (If you edit the file, add your name here!)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Compile src/*.cpp and test/*.cpp into build/, generating dependency .d files too (see
# https://stackoverflow.com/q/2394609)

BUILD_DIR := build
SRCS := $(wildcard src/*.cpp)
TESTS := $(wildcard test/*.cpp)
MANS := $(wildcard documentation/*.man)
MAN_TXTS := $(patsubst documentation/%.man, documentation/%.txt, $(MANS))
MAN_HS := $(patsubst documentation/%.man, documentation/man-%.h, $(MANS))
DOXYGEN_DIR := ./documentation/doxygen
OBJS := $(patsubst src/%.cpp,$(BUILD_DIR)/src/%.o,$(SRCS))
TEST_OBJS := $(patsubst test/%.cpp,$(BUILD_DIR)/test/%.o,$(TESTS)) $(filter-out $(BUILD_DIR)/src/main.o, $(OBJS))
DEPS := $(OBJS:.o=.d) $(patsubst test/%.cpp,$(BUILD_DIR)/test/%.d,$(TESTS))
BIN  := lost
TEST_BIN := ./lost-test

BSC  := bright-star-catalog.tsv

LIBS     := -L/opt/homebrew/lib -lcairo
CFLAGS = -I/opt/homebrew/include/cairo
CXXFLAGS := $(CXXFLAGS) -Ivendor -Isrc -Idocumentation -Wall -Wextra -Wno-missing-field-initializers -pedantic --std=c++14
RELEASE_CXXFLAGS := $(CXXFLAGS) -O3
# debug flags:
CXXFLAGS := $(CXXFLAGS) -ggdb -fno-omit-frame-pointer
ifndef LOST_DISABLE_ASAN
	CXXFLAGS := $(CXXFLAGS) -fsanitize=address
endif

RELEASE_LDFLAGS := $(LDFLAGS)

# debug link flags:
ifndef LOST_DISABLE_ASAN
	LDFLAGS := $(LDFLAGS) -fsanitize=address
endif

all: $(BIN) $(BSC)

release: CXXFLAGS := $(RELEASE_CXXFLAGS)
release: LDFLAGS := $(RELEASE_LDFLAGS)
release: all

$(BIN): $(OBJS)
	$(CXX) $(LDFLAGS) -o $(BIN) $(OBJS) $(LIBS)

documentation/%.txt: documentation/%.man
	groff -mandoc -Tascii $< > $@
	printf '\0' >> $@

documentation/man-%.h: documentation/%.txt
	xxd -i $< > $@

$(BUILD_DIR)/src/main.o: $(MAN_HS)

docs:
	doxygen

lint:
	cpplint --recursive src test

$(BUILD_DIR)/src/%.o: src/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -MMD -c $< -o $@

$(BUILD_DIR)/test/%.o: test/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -MMD -c $< -o $@

-include $(DEPS)

test: $(BIN) $(BSC) $(TEST_BIN)
	$(TEST_BIN)
	# bash ./test/scripts/pyramid-incorrect.sh
	bash ./test/scripts/readme-examples-test.sh
	bash ./test/scripts/random-crap.sh
	bash ./test/scripts/centroids-input.sh
	# bash ./test/scripts/tetra.sh

$(TEST_BIN): $(TEST_OBJS)
	$(CXX) $(LDFLAGS) -o $(TEST_BIN) $(TEST_OBJS) $(LIBS)

clean:
	rm -rf $(BUILD_DIR) $(MAN_HS)
	rm -rf $(DOXYGEN_DIR)
	# leftover objects from when .o/.d were written next to sources
	rm -f src/*.o src/*.d test/*.o test/*.d

clean_all: clean
	rm -f $(BSC)

.PHONY: all clean test docs lint
