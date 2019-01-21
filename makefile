

SRC_DIR=./src
RES_DIR=$(HOME)/GDResults/
TEST_DIR=$(HOME)/tests/actual/
LOG_DIR=$ANADROID_PATH/.ana/



list:
	@echo "install \ndeviceConfig \nAnaDroidconfig \nclear \nuninstall"

install:
	$(SRC_DIR)/setup/configAnaDroid.sh
	$(SRC_DIR)/setup/setupDevice.sh

deviceConfig: 
	$(SRC_DIR)/src/setup/setupDevice.sh

AnaDroidconfig:
	$(SRC_DIR)/setup/configAnaDroid.sh

.PHONY: clear

clear: $(LOG_DIR)/*
	rm -rf $(LOG_DIR)/*

uninstall:
	echo "nada"