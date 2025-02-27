#!/bin/bash

show_logo() {
    echo "=========================================="
    echo "       🚀 TURBO FIREWALL 🚀               "
    echo "=========================================="
    echo ""
}

install_firewall() {
    echo "Installing Turbo Firewall rules..."

    apt update && apt upgrade -y

    read -p "Please enter your SSH port: " SSH_PORT

    if [[ $SSH_PORT -ne 22 ]]; then
        echo "You have entered a custom SSH port: $SSH_PORT"
        echo "Please ensure that your SSH service is running on this port before proceeding."
        echo "We will now open port $SSH_PORT for you."
    else
        echo "You have selected the default SSH port (22)."
    fi

    ufw allow $SSH_PORT/tcp
    echo "✅ SSH port $SSH_PORT (TCP) has been allowed."

    echo "🔹 Enabling and configuring UFW..."
    ufw --force enable

    PORTS=(80 8080 8880 2052 2082 2086 2095 443 8443 2053 2083 2087 2096)
    for PORT in "${PORTS[@]}"; do
        ufw allow $PORT/tcp
        ufw allow $PORT/udp
    done

    BLOCKED_IPS=("10.0.0.0/8" "100.64.0.0/10" "172.16.0.0/12" "198.18.0.0/15" "169.254.0.0/16" "141.101.78.0/23" "173.245.48.0/20" "18.208.0.0/16" "200.0.0.0/8" "102.0.0.0/8")
    for IP in "${BLOCKED_IPS[@]}"; do
        ufw deny out to $IP
    done

    echo "🔹 Installing iptables-persistent..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update && apt-get install -y iptables-persistent

    echo "🔹 Applying iptables rules..."
    for IP in "${BLOCKED_IPS[@]}"; do
        iptables -A INPUT -s $IP -j DROP
        iptables -A OUTPUT -d $IP -j DROP
        iptables -A FORWARD -s $IP -j DROP
        iptables -A FORWARD -d $IP -j DROP
    done

    BLOCKED_PORTS=(166 3364 16658 24940 302 5564)
    for PORT in "${BLOCKED_PORTS[@]}"; do
        iptables -A INPUT -p tcp --dport $PORT -j DROP
        iptables -A INPUT -p udp --dport $PORT -j DROP
        iptables -A OUTPUT -p tcp --sport $PORT -j DROP
        iptables -A OUTPUT -p udp --sport $PORT -j DROP
        iptables -A FORWARD -p tcp --dport $PORT -j DROP
        iptables -A FORWARD -p udp --dport $PORT -j DROP
    done

    echo "🔹 Saving iptables rules..."
    iptables-save > /etc/iptables/rules.v4
    iptables-save > /etc/iptables/rules.v6

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
    echo "Removing default Turbo Firewall rules..."

    PORTS=(80 8080 8880 2052 2082 2086 2095 443 8443 2053 2083 2087 2096)
    for PORT in "${PORTS[@]}"; do
        ufw delete allow $PORT/tcp
        ufw delete allow $PORT/udp
    done

    echo "🔹 Flushing iptables rules..."
    iptables -F
    iptables -X
    iptables -Z
    iptables -t nat -F

    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT

    echo "🔹 Deleting saved iptables rules..."
    rm -f /etc/iptables/rules.v4
    rm -f /etc/iptables/rules.v6

    echo "🔹 Resetting UFW..."
    ufw --force reset

    echo "✅ All default Turbo Firewall rules have been removed!"
}

status() {
    echo "🔹 Showing current iptables rules and status..."
    iptables -L -v -n
}

show_menu() {
    show_logo
    echo "1) Install Turbo Firewall"
    echo "2) Allow Port"
    echo "3) Uninstall Turbo Firewall (Remove all rules)"
    echo "4) View Status (Blocked Packets)"
    echo "5) Exit"
    echo ""
    read -p "Choose an option: " OPTION

    case $OPTION in
        1) install_firewall ;;
        2) allow_port ;;
        3) uninstall_firewall ;;
        4) status ;;
        5) exit 0 ;;
        *) echo "Invalid option. Please choose between 1-5."; sleep 2; show_menu ;;
    esac
}

show_menu
