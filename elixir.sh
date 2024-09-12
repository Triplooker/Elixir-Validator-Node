#!/bin/bash

BOLD='\033[1m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
NC='\033[0m'

command_exists() {
    command -v "$1" &> /dev/null
}

echo ""

if command_exists nvm; then
    echo -e "${GREEN}NVM уже установлен.${NC}"
else
    echo -e "${YELLOW}Установка NVM...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Это загружает nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Это загружает автозаполнение для nvm
fi

if command_exists node; then
    echo -e "${GREEN}Node.js уже установлен: $(node -v)${NC}"
else
    echo -e "${YELLOW}Установка Node.js...${NC}"
    nvm install node
    nvm use node
    echo -e "${GREEN}Node.js установлен: $(node -v)${NC}"
fi

echo -e "${BOLD}${CYAN}Проверка установки Docker...${NC}"
if ! command_exists docker; then
    echo -e "${RED}Docker не установлен. Установка Docker...${NC}"
    sudo apt update && sudo apt install -y curl net-tools
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    echo -e "${GREEN}Docker успешно установлен.${NC}"
else
    echo -e "${GREEN}Docker уже установлен.${NC}"
fi

# Генерация файла переменных окружения
ENV_FILE="validator.env"
echo -e "${BOLD}${CYAN}Создание файла переменных окружения: ${ENV_FILE}${NC}"

echo "ENV=testnet-3" > $ENV_FILE
IP_ADDRESS=$(curl -s ifconfig.me)  # Автоматическое получение IP-адреса
echo "STRATEGY_EXECUTOR_IP_ADDRESS=$IP_ADDRESS" >> $ENV_FILE

read -p "Введите отображаемое имя для вашего валидатора: " DISPLAY_NAME
echo "STRATEGY_EXECUTOR_DISPLAY_NAME=$DISPLAY_NAME" >> $ENV_FILE

read -p "Введите адрес кошелька для получения вознаграждений валидатора: " BENEFICIARY
echo "STRATEGY_EXECUTOR_BENEFICIARY=$BENEFICIARY" >> $ENV_FILE

read -p "Введите приватный ключ валидатора: " PRIVATE_KEY
echo "SIGNER_PRIVATE_KEY=$PRIVATE_KEY" >> $ENV_FILE

echo ""
echo -e "${BOLD}${CYAN}Файл $ENV_FILE был создан со следующим содержимым:${NC}"
cat $ENV_FILE
echo ""

read -p "Вы завершили шаги по созданию и ставке токенов? (y/n): " response
if [[ "$response" =~ ^[yY]$ ]]; then
    echo -e "${BOLD}${CYAN}Загрузка образа валидатора Elixir Protocol...${NC}"
    docker pull elixirprotocol/validator:v3
else
    echo -e "${RED}Задача не завершена. Выход из скрипта.${NC}"
    exit 1
fi

echo ""
echo -e "${BOLD}${CYAN}Запуск Docker...${NC}"
docker run -d --env-file $ENV_FILE --name elixir -p 17690:17690 --restart unless-stopped elixirprotocol/validator:v3
echo ""
echo -e "${BOLD}${CYAN}Выполнение скрипта завершено успешно.${NC}"