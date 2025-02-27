#!/bin/bash

# لینک گیت‌هاب ریپازیتوری
REPO_URL="https://raw.githubusercontent.com/mansnetworker/Turbo-Firewall/main/turbo-firewall.sh""

show_logo() {
    echo "=========================================="
    echo "       🚀 TURBO FIREWALL 🚀               "
    echo "=========================================="
    echo "🔗 GitHub Repository: $REPO_URL"
    echo ""
}

install_firewall() {
    echo "Installing Turbo Firewall rules..."

    # 1️⃣ اجرای UFW و فعال‌سازی آن
    echo "🔹 Enabling and configuring UFW..."
    ufw --force enable

    # لیست پورت‌هایی که باید باز شوند (TCP و UDP)
    PORTS=(80 8080 8880 2052 2082 2086 2095 443 8443 2053 2083 2087 2096)
    for PORT in "${PORTS[@]}"; do
        ufw allow $PORT/tcp
        ufw allow $PORT/udp
    done

    # آی‌پی‌هایی که باید فقط **ترافیک خروجی** آنها مسدود شود
    BLOCKED_IPS=(
        "10.0.0.0/8"
        "172.16.0.0/12"
        "172.64.0.0/13"
        "198.18.0.0/15"
        "141.101.78.0/23"
        "173.245.48.0/20"
        "18.102.0.0/8"
        "102.0.0.0/8"
    )
    for IP in "${BLOCKED_IPS[@]}"; do
        ufw deny out to $IP  # فقط مسدود کردن ترافیک خروجی
    done

    # 2️⃣ نصب iptables-persistent (بعد از UFW)
    echo "🔹 Installing iptables-persistent..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update && apt-get install -y iptables-persistent

    # 3️⃣ اجرای iptables با قوانین کامل برای INPUT, FORWARD, OUTPUT
    echo "🔹 Applying iptables rules..."

    # مسدود کردن آی‌پی‌های خاص در همه‌ی زنجیره‌ها
    for IP in "${BLOCKED_IPS[@]}"; do
        iptables -A INPUT -s $IP -j DROP
        iptables -A OUTPUT -d $IP -j DROP
        iptables -A FORWARD -s $IP -j DROP
        iptables -A FORWARD -d $IP -j DROP
    done

    # مسدود کردن پورت‌های خاص در INPUT, OUTPUT و FORWARD
    BLOCKED_PORTS=(166 3364 16658 24940 302 5564)
    for PORT in "${BLOCKED_PORTS[@]}"; do
        iptables -A INPUT -p tcp --dport $PORT -j DROP
        iptables -A INPUT -p udp --dport $PORT -j DROP
        iptables -A OUTPUT -p tcp --sport $PORT -j DROP
        iptables -A OUTPUT -p udp --sport $PORT -j DROP
        iptables -A FORWARD -p tcp --dport $PORT -j DROP
        iptables -A FORWARD -p udp --dport $PORT -j DROP
    done

    # 4️⃣ ذخیره قوانین iptables برای بوت بعدی
    echo "🔹 Saving iptables rules..."
    iptables-save > /etc/iptables/rules.v4
    iptables-save > /etc/iptables/rules.v6  # برای IPv6

    echo "✅ Turbo Firewall setup complete!"
    ufw status verbose
    iptables -L -n -v
}

allow_port() {
    echo "Enter the ports you want to allow (comma-separated, e.g., 5454,4343):"
    read -p "Ports: " PORTS_INPUT

    IFS=',' read -ra PORTS <<< "$PORTS_INPUT"

    for PORT in "${PORTS[@]}"; do
        if [[ $PORT =~ ^[0-9]+$ ]] && ((PORT >= 1 && PORT <= 65535)); then
            ufw allow $PORT/tcp
            ufw allow $PORT/udp
            echo "✅ Port $PORT (TCP/UDP) has been allowed."
        else
            echo "⚠️ Invalid port: $PORT (must be a number between 1-65535). Skipping..."
        fi
    done

    echo "✅ All valid ports have been allowed!"
    ufw status verbose
}

uninstall_firewall() {
    echo "Removing all Turbo Firewall rules..."

    # 1️⃣ حذف قوانین UFW
    echo "🔹 Removing UFW rules..."
    PORTS=(80 8080 8880 2052 2082 2086 2095 443 8443 2053 2083 2087 2096)
    for PORT in "${PORTS[@]}"; do
        ufw delete allow $PORT/tcp
        ufw delete allow $PORT/udp
    done

    BLOCKED_IPS=(
        "10.0.0.0/8"
        "172.16.0.0/12"
        "172.64.0.0/13"
        "198.18.0.0/15"
        "141.101.78.0/23"
        "173.245.48.0/20"
        "18.102.0.0/8"
        "102.0.0.0/8"
    )
    for IP in "${BLOCKED_IPS[@]}"; do
        ufw delete deny out to $IP  # حذف فقط ترافیک خروجی مسدود شده
    done

    # 2️⃣ حذف همه قوانین `iptables`
    echo "🔹 Flushing iptables rules..."
    iptables -F
    iptables -X
    iptables -Z
    iptables -t nat -F

    echo "🔹 Resetting iptables policies to default..."
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT

    # حذف فایل‌های ذخیره‌شده `iptables`
    echo "🔹 Deleting saved iptables rules..."
    rm -f /etc/iptables/rules.v4
    rm -f /etc/iptables/rules.v6

    echo "✅ All Turbo Firewall rules have been removed!"
}

show_menu() {
    show_logo
    echo "1) Install Turbo Firewall"
    echo "2) Allow Port"
    echo "3) Uninstall Turbo Firewall (Remove all rules)"
    echo "4) Exit"
    echo ""
    read -p "Choose an option: " OPTION

    case $OPTION in
        1) install_firewall ;;
        2) allow_port ;;
        3) uninstall_firewall ;;
        4) exit 0 ;;
        *) echo "Invalid option. Please choose between 1-4."; sleep 2; show_menu ;;
    esac
}

show_menu
