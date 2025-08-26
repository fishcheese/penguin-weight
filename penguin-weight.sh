#!/bin/sh

# Шуточный скрипт для взвешивания пакетов системы

echo "🧙‍♂️ Запускаем магический калькулятор веса пингвина..."
echo "📦 Взвешиваем вашего пингвина..."
sleep 1

# Переменная для количества пакетов
PACKAGE_COUNT=0
CUSTOM_COUNT=0

# Проверяем аргументы командной строки
for arg in "$@"
do
    case $arg in
        --packages=*)
        CUSTOM_COUNT=1
        PACKAGE_COUNT="${arg#*=}"
        echo "🎯 Используем пользовательское количество пакетов: $PACKAGE_COUNT"
        ;;
    esac
done

# Если не указано пользовательское количество, считаем автоматически
if [ "$CUSTOM_COUNT" -eq 0 ]; then
    # Переменные для разных типов пакетов
    LOCAL_PACKAGES=0
    FLATPAK_PACKAGES=0
    NIX_PACKAGES=0
    
    echo "🔍 Ищем пакеты в системе..."

    # Функция для безопасного подсчета пакетов
    count_packages() {
        local command="$1"
        local count=0
        if command -v $command >/dev/null 2>&1; then
            count=$($2 2>/dev/null | wc -l)
            # Вычитаем заголовки если нужно
            if [ "$count" -gt 0 ]; then
                count=$((count - ${3:-0}))
            fi
            if [ "$count" -lt 0 ]; then
                count=0
            fi
        fi
        echo "$count"
    }

    # Основные менеджеры пакетов (считаем все доступные)
    echo "📦 Ищем основные пакеты..."
    
    # Debian/Ubuntu (dpkg)
    if command -v dpkg >/dev/null 2>&1; then
        DPKG_COUNT=$(dpkg -l 2>/dev/null | grep -c '^ii' || echo 0)
        echo "   📦 Найдено dpkg пакетов: $DPKG_COUNT"
        LOCAL_PACKAGES=$((LOCAL_PACKAGES + DPKG_COUNT))
    fi

    # RedHat/Fedora (rpm)
    if command -v rpm >/dev/null 2>&1; then
        RPM_COUNT=$(rpm -qa 2>/dev/null | wc -l || echo 0)
        echo "   📦 Найдено rpm пакетов: $RPM_COUNT"
        LOCAL_PACKAGES=$((LOCAL_PACKAGES + RPM_COUNT))
    fi

    # Arch Linux (pacman)
    if command -v pacman >/dev/null 2>&1; then
        PACMAN_COUNT=$(pacman -Q 2>/dev/null | wc -l || echo 0)
        echo "   📦 Найдено pacman пакетов: $PACMAN_COUNT"
        LOCAL_PACKAGES=$((LOCAL_PACKAGES + PACMAN_COUNT))
    fi

    # NixOS (nix)
    if command -v nix-store >/dev/null 2>&1; then
        echo "🐧 Ищем Nix пакеты..."
        # Более точный подсчет для NixOS
        if [ -f /run/current-system/sw/bin/.nix-profile-manifest ]; then
            NIX_COUNT=$(nix-store -q --requisites /run/current-system/sw 2>/dev/null | grep -v '\.drv$' | wc -l || echo 0)
        else
            # Для не-NixOS систем с установленным Nix
            NIX_COUNT=$(nix-store -q --requisites ~/.nix-profile 2>/dev/null | grep -v '\.drv$' | wc -l || echo 0)
        fi
        echo "   📦 Найдено Nix пакетов: $NIX_COUNT"
        NIX_PACKAGES=$NIX_COUNT
    fi

    # Flatpak пакеты (исправленный подсчет)
    echo "📦 Ищем Flatpak пакеты..."
    if command -v flatpak >/dev/null 2>&1; then
        # Пробуем разные методы подсчета
        FLATPAK_METHOD1=0
        FLATPAK_METHOD2=0
        
        # Метод 1: список приложений
        FLATPAK_METHOD1=$(flatpak list --app --columns=application 2>/dev/null | grep -v '^Application ID' | wc -l || echo 0)
        
        # Метод 2: список всех установленных пакетов (более точный)
        FLATPAK_METHOD2=$(flatpak list --all --columns=application 2>/dev/null | grep -v '^Application ID' | wc -l || echo 0)
        
        # Метод 3: через flatpak info (самый надежный)
        FLATPAK_METHOD3=0
        if command -v flatpak >/dev/null 2>&1; then
            FLATPAK_METHOD3=$(flatpak list --app --columns=installation,application 2>/dev/null | 
                             awk '{print $1}' | sort -u | while read -r install; do
                                 flatpak list --app --columns=application --installation="$install" 2>/dev/null
                             done | wc -l || echo 0)
        fi
        
        # Берем максимальное значение из доступных методов
        FLATPAK_COUNT=$((FLATPAK_METHOD1 > FLATPAK_METHOD2 ? FLATPAK_METHOD1 : FLATPAK_METHOD2))
        FLATPAK_COUNT=$((FLATPAK_COUNT > FLATPAK_METHOD3 ? FLATPAK_COUNT : FLATPAK_METHOD3))
        
        echo "   📦 Найдено Flatpak пакетов: $FLATPAK_COUNT"
        FLATPAK_PACKAGES=$FLATPAK_COUNT
    else
        echo "   🔶 Flatpak не установлен"
        FLATPAK_PACKAGES=0
    fi

    # Snaps (добавляем поддержку snap)
    SNAP_PACKAGES=0
    if command -v snap >/dev/null 2>&1; then
        SNAP_COUNT=$(snap list 2>/dev/null | grep -v '^Name' | wc -l || echo 0)
        echo "   📦 Найдено Snap пакетов: $SNAP_COUNT"
        SNAP_PACKAGES=$SNAP_COUNT
    fi

    # Общее количество пакетов
    PACKAGE_COUNT=$((LOCAL_PACKAGES + FLATPAK_PACKAGES + NIX_PACKAGES + SNAP_PACKAGES))
    
    echo "📊 Итоговый подсчет:"
    echo "   🐧 Основные пакеты: $LOCAL_PACKAGES"
    echo "   📦 Flatpak: $FLATPAK_PACKAGES"
    echo "   ❄️  Nix: $NIX_PACKAGES"
    echo "   ⚡ Snap: $SNAP_PACKAGES"
fi

echo "📊 Общее количество пакетов: $PACKAGE_COUNT"

# Магическая формула расчёта веса
# 1640 пакетов = 320 кг, 1900 пакетов = 320 кг
# Линейная интерполяция между этими значениями

if [ "$PACKAGE_COUNT" -le 1640 ]; then
    # До 1640 пакетов - линейный рост
    WEIGHT=$((PACKAGE_COUNT * 320 / 1640))
    if [ "$WEIGHT" -lt 1 ]; then
        WEIGHT=1
    fi
elif [ "$PACKAGE_COUNT" -le 1900 ]; then
    # Между 1640 и 1900 - всегда 320 кг (магия!)
    WEIGHT=320
else
    # После 1900 - экспоненциальный рост веса
    EXTRA_PACKAGES=$((PACKAGE_COUNT - 1900))
    WEIGHT=$((320 + EXTRA_PACKAGES * EXTRA_PACKAGES / 100))
fi

FINAL_WEIGHT=$((WEIGHT))

if [ "$FINAL_WEIGHT" -lt 1 ]; then
    FINAL_WEIGHT=1
fi

echo ""
echo "⚖️  Результаты взвешивания:"
echo "--------------------------------"
echo "📦 Общее количество пакетов: $PACKAGE_COUNT"
echo "🏋️‍♂️ Общий вес пингвина: $FINAL_WEIGHT кг"
echo "--------------------------------"

# Шуточные комментарии в зависимости от веса
if [ "$FINAL_WEIGHT" -lt 200 ]; then
    echo -e "\033[31m🚨 Ваш пингвин голодает!!! 🚨\033[0m"
    echo -e "\033[31m🆘  Срочно покормите его!!! 🆘\033[0m"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u critical "🚨 Ваш пингвин голодает!!! 🚨
🆘  Срочно покормите его!!! 🆘" -h string:sound-name:dialog-error-critical
    fi

elif [ "$FINAL_WEIGHT" -lt 230 ]; then
    echo "🏋 Ваш пингвин довольно спортивный! "
elif [ "$FINAL_WEIGHT" -lt 280 ]; then
    echo "📊 Отличный вес пингвина!"
    echo "   Есть всё, что нужно!"
elif [ "$FINAL_WEIGHT" -lt 320 ]; then
    echo "⚠️  Приближаемся к магическому весу!"
    echo "   Скоро вес стабилизируется... или нет?"
elif [ "$FINAL_WEIGHT" -eq 320 ]; then
    echo "🪄 Магические 320 кг!"
    echo "   Пингвин сыт и доволен 🐧👍"
elif [ "$FINAL_WEIGHT" -lt 400 ]; then
    echo "⚠️ Тяжелая система! Ваш пингвин перевесил 320 кг!!!"
    echo "   Возможно, стоит подумать о диете?"
else
    echo -e "\033[31m💥 КРИТИЧЕСКИЙ ВЕС!!! Система вот-вот рухнет!!! 💥\033[0m"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u critical "💥 КРИТИЧЕСКИЙ ВЕС!!!
Системa вот-вот рухнет!!! 💥" -h string:sound-name:dialog-error-critical
    fi
fi