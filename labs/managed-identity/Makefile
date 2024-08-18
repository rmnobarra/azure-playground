.PHONY: all bootstrap caos check fix put-down default

default: 
	@echo "Options:"
	@echo "make all           - Executa a tarefa default"
	@echo "make up            - Executa bootstrap.sh: Cria o ambiente"
	@echo "make caos          - Executa caos-level-01.sh: Injeta falhas"
	@echo "make check         - Executa check.sh: Verifica o ambiente"
	@echo "make fix           - Executa fix-level-01.sh: Corrige o ambiente"
	@echo "make down          - Executa put-down.sh: Derruba o ambiente"

all: default

up:
	./bootstrap.sh

caos:
	./caos-level-01.sh

check:
	./check.sh

fix:
	./fix-level-01.sh

down:
	./put-down.sh
